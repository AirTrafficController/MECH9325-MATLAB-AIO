function out = findCalculator(userQuery, context, opts)
%FINDCALCULATOR  Map a multi-part exam question to the calculators to use.
%   FINDCALCULATOR(userQuery) takes either
%     * a string ARRAY / cellstr, one element per sub-question, OR
%     * a single pasted string of the WHOLE question - it is split
%       automatically on part markers "(i) (ii) (a) (b) (1) (2)" (and on
%       newlines / semicolons), with any text before the first marker used
%       as shared context.
%   For each part it prints the top matching calculators (read from
%   calculators.csv: columns ToolName, Keywords), best first.
%
%   FINDCALCULATOR(userQuery, context) forces an extra shared context string
%   mixed into every part (overrides the auto-detected preamble).
%
%   S = FINDCALCULATOR(...) also returns a struct array (one element per
%   part) with fields .query and .matches (ranked ToolName/score), for
%   programmatic use and testing; nothing is printed differently.
%
%   HOW IT MATCHES (deterministic, no toolboxes):
%     * Tokenises, drops stop-words, keeps short acronyms (Lp, LA, Leq, TL...).
%     * Scores shared words by inverse document frequency (IDF) so generic
%       words ("plane", "air", "sound") can't outweigh a rare decisive word
%       ("intensity", "reverberation"). Exact hits score full IDF; a plural
%       or prefix/stem hit ("reverb"->"reverberation") scores half.
%     * The part's own words decide; context only breaks near-ties.
%
%   PERFORMANCE: the CSV is parsed and turned into an INVERTED INDEX
%   (token -> document IDs, with IDF weights) exactly once, then cached in a
%   persistent variable keyed on the file's timestamp. Repeat queries do no
%   file I/O and touch only the documents a query actually mentions, so a
%   lookup is O(number of query words), not O(number of calculators).
%
%   Each part's best match carries a CONFIDENCE tag (high / medium / low)
%   derived from how far ahead #1 is of #2 - a quick read on "how viable"
%   the top pick is; a "low - near tie" tag means eyeball the runners-up.
%
%   FINDCALCULATOR(..., 'useLLM', true) additionally asks an online AI to
%   pick a tool. This is OPTIONAL, needs internet + an API key read from the
%   environment (FINDCALC_LLM_KEY / FINDCALC_LLM_URL), and is therefore NOT
%   exam-safe; the local ranking is always the primary result. Off by default.
%
%   Examples:
%       findCalculator("A plane wave ... (i) Intensity (ii) particle velocity")
%       s = findCalculator(["overall A-weighted level"; "barrier reduction dB(A)"]);
%       findCalculator("temperature from travel time", 'useLLM', true)  % online
    arguments
        userQuery {mustBeTextLike} = ...
            "A plane wave in air. Determine (i) intensity (ii) particle velocity (iii) SPL"
        context   {mustBeTextLike} = ""
        opts.useLLM (1,1) logical = false   % OPTIONAL online AI re-rank (NOT exam-safe)
    end

    % --- normalise + validate input ------------------------------------
    partsIn = normaliseText(userQuery);          % string row, trimmed, no blanks
    context = strtrim(strjoin(normaliseText(context), " "));
    if isempty(partsIn)
        fprintf('--- Solution Pipeline ---\n(empty query - type the quantity you want)\n');
        if nargout, out = struct('query', {}, 'matches', {}); end
        return;
    end
    MAXLEN = 5000;                               % guard against pathological input
    partsIn = arrayfun(@(s) capLen(s, MAXLEN), partsIn);
    context = capLen(context, MAXLEN);

    % --- split a single pasted blob into parts + preamble ---------------
    autoCtx = "";
    if isscalar(partsIn)
        [parts, autoCtx] = splitParts(partsIn);
    else
        parts = partsIn(:).';
    end
    if strlength(context) == 0, context = autoCtx; end

    % --- load (cached) inverted index ----------------------------------
    idx = getIndex();                            % persistent, timestamp-keyed
    ctxTok = tokenize(context);

    % --- rank tools for each part --------------------------------------
    K = 3;
    fprintf('--- Solution Pipeline ---\n');
    if strlength(strtrim(context)) > 0
        fprintf('Context: %s\n\n', truncate(context, 90));
    end
    if nargout, out = repmat(struct('query','','matches',[]), 1, numel(parts)); end

    % Optional online re-rank: ONE request for the whole query (not one per
    % part), with the tool catalogue included so the model knows what each
    % tool does. aiPicks(s) is the suggestion for part s, "" if unavailable.
    aiPicks = strings(1, numel(parts));
    if opts.useLLM
        aiPicks = llmSuggestAll(parts, context, idx);
    end

    for s = 1:numel(parts)
        sc = scorePart(parts(s), ctxTok, idx);
        [sv, order] = sort(sc, 'descend');
        fprintf('Part %d  "%s"\n', s, truncate(parts(s), 70));
        matches = struct('tool', {}, 'score', {});
        if sv(1) <= 0
            fprintf('   (no confident match - rephrase with the quantity you want)\n\n');
        else
            conf = confidence(sv);
            for r = 1:min(K, numel(order))
                if sv(r) <= 0, break; end
                tag = ''; if r == 1, tag = sprintf('   <- best [%s]', conf); end
                fprintf('   %d. %s%s\n', r, idx.tools(order(r)), tag);
                matches(end+1) = struct('tool', idx.tools(order(r)), 'score', sv(r)); %#ok<AGROW>
            end
            if opts.useLLM && s <= numel(aiPicks) && strlength(aiPicks(s)) > 0
                if aiPicks(s) == idx.tools(order(1))
                    fprintf('   (highly matching)\n');
                else
                    fprintf('   (suggests instead: %s)\n', aiPicks(s));
                end
            end
            fprintf('\n');
        end
        if nargout
            out(s).query = char(parts(s));
            out(s).matches = matches;
        end
    end
    fprintf('(wrong or irrelevant pick? log a ticket: reportSearch("your question"))\n');
end

% ======================================================================
% Cached inverted index
% ======================================================================
function idx = getIndex()
    persistent CACHE
    here = fileparts(mfilename('fullpath'));
    csv  = fullfile(here, 'calculators.csv');
    d = dir(csv);
    if isempty(d)
        error('findCalculator:noCSV', 'calculators.csv not found next to findCalculator.m');
    end
    key = sprintf('%s|%d|%.6f', csv, d.bytes, d.datenum);
    if ~isempty(CACHE) && strcmp(CACHE.key, key)
        idx = CACHE; return;                      % cache hit - no file I/O
    end
    idx = buildIndex(csv);
    idx.key = key;
    CACHE = idx;
end

function idx = buildIndex(csv)
    T = readtable(csv, 'TextType', 'string', 'Delimiter', ',');
    if ~all(ismember({'ToolName','Keywords'}, T.Properties.VariableNames))
        error('findCalculator:badCSV', ...
            'calculators.csv must have columns ToolName and Keywords.');
    end
    keep = ~ismissing(T.ToolName) & strlength(strtrim(T.ToolName)) > 0;
    idx.tools = T.ToolName(keep);
    keywords  = T.Keywords(keep);
    idx.keywords = keywords;                      % kept for the AI catalogue
    N = numel(idx.tools);
    idx.N = N;

    descTokens = arrayfun(@(s) tokenize(s), keywords, 'UniformOutput', false);

    % document frequency per token, in one pass (hash map)
    df = containers.Map('KeyType','char','ValueType','double');
    for i = 1:N
        for w = unique(descTokens{i})
            k = char(w);
            if isKey(df, k), df(k) = df(k) + 1; else, df(k) = 1; end
        end
    end
    % IDF + inverted postings (token -> doc ids)
    idx.idf      = containers.Map('KeyType','char','ValueType','double');
    idx.postings = containers.Map('KeyType','char','ValueType','any');
    vocab = keys(df);
    for v = 1:numel(vocab)
        k = vocab{v};
        idx.idf(k) = log((N + 1)/(df(k) + 0.5));
        idx.postings(k) = zeros(1,0);
    end
    for i = 1:N
        for w = unique(descTokens{i})
            k = char(w);
            idx.postings(k) = [idx.postings(k), i];
        end
    end
    idx.vocab = vocab;                            % cellstr, for prefix fallback
end

% ======================================================================
% Scoring
% ======================================================================
function sc = scorePart(part, ctxTok, idx)
%   Part words decide; the shared context (the question's preamble) is a
%   tie-break nudge. A single part-word's IDF (~2-4) still outweighs a lot of
%   context at this weight, so context only tips the balance when the part
%   itself is generic - e.g. a split part like "(i) the rms sound pressure",
%   whose tool is only decided by the preamble ("a spherical source radiates
%   ... into free space"). Too small a weight leaves such parts a coin-flip.
    CTX_WEIGHT = 0.05;
    stepScore = scoreTokens(tokenize(part), idx);
    if max(stepScore) == 0
        sc = scoreTokens(ctxTok, idx);            % nothing usable in the part
    else
        sc = stepScore + CTX_WEIGHT * scoreTokens(ctxTok, idx);
    end
end

function sc = scoreTokens(qtok, idx)
    sc = zeros(idx.N, 1);
    for w = unique(qtok)
        [ids, wgt] = lookup(char(w), idx);
        for j = 1:numel(ids)
            sc(ids(j)) = sc(ids(j)) + wgt(j);
        end
    end
end

function [ids, wgt] = lookup(w, idx)
%LOOKUP  Doc IDs (and IDF weights) a token hits: exact, then plural, then prefix.
    ids = zeros(1,0); wgt = zeros(1,0);
    if isKey(idx.postings, w)
        ids = idx.postings(w); wgt = repmat(idx.idf(w), size(ids)); return;
    end
    if numel(w) > 3 && w(end) == 's'              % plural -> singular
        w2 = w(1:end-1);
        if isKey(idx.postings, w2)
            ids = idx.postings(w2); wgt = repmat(idx.idf(w2), size(ids)); return;
        end
    end
    if numel(w) >= 4                              % stem / prefix, at half weight
        for i = 1:numel(idx.vocab)
            t = idx.vocab{i};
            L = min(numel(t), numel(w));
            if L >= 4 && strncmp(t, w, L)
                pid = idx.postings(t);
                ids = [ids, pid]; %#ok<AGROW>
                wgt = [wgt, repmat(0.5*idx.idf(t), size(pid))]; %#ok<AGROW>
            end
        end
    end
end

% ======================================================================
function c = confidence(sv)
%CONFIDENCE  Label how decisive the top match is, from the score gap.
    if numel(sv) < 2 || sv(2) <= 0
        c = 'high'; return;
    end
    gap = (sv(1) - sv(2)) / sv(1);          % relative lead of #1 over #2
    if     gap >= 0.40, c = 'high';
    elseif gap >= 0.15, c = 'medium';
    else,               c = 'low - near tie, check the runners-up';
    end
end

% ======================================================================
% OPTIONAL online AI re-rank.  Off unless useLLM=true AND the key env var
% is set.  Key is read from the environment at RUN TIME - never stored in
% this file or committed.  Requires internet, so it is NOT usable in the
% exam; the local ranking above is always the primary result.
%   The provider is auto-detected from the URL (an anthropic.com URL uses the
%   Anthropic Messages API with an x-api-key header; anything else uses the
%   Google generateContent shape). Set up (in your session, not in git):
%
%     Anthropic / Claude Haiku (cheapest):
%       setenv('FINDCALC_LLM_KEY','sk-ant-...')                      % a FRESH key
%       setenv('FINDCALC_LLM_URL','https://api.anthropic.com/v1/messages')
%       setenv('FINDCALC_LLM_MODEL','claude-haiku-4-5')             % optional (default)
%
%     Google / Gemini:
%       setenv('FINDCALC_LLM_KEY','<your fresh key>')
%       setenv('FINDCALC_LLM_URL','https://.../v1beta/models/<model>:generateContent')
% ======================================================================
function [key, url, model] = aiConfig()
%AICONFIG  Get the AI key/URL/model from env vars, else the saved config
%   written by findCalcSetup (userpath/findcalc_ai.mat) - so it persists
%   across MATLAB sessions and getAIO without re-running setenv.
    key   = string(getenv('FINDCALC_LLM_KEY'));
    url   = string(getenv('FINDCALC_LLM_URL'));
    model = string(getenv('FINDCALC_LLM_MODEL'));
    if strlength(key) > 0 && strlength(url) > 0, return; end
    up = userpath;
    if isempty(up), return; end
    f = fullfile(up, 'findcalc_ai.mat');
    if ~isfile(f), return; end
    try
        S = load(f);
        if isfield(S, 'cfg')
            c = S.cfg;
            if strlength(key)==0   && isfield(c,'key'),   key   = string(c.key);   end
            if strlength(url)==0   && isfield(c,'url'),   url   = string(c.url);   end
            if strlength(model)==0 && isfield(c,'model'), model = string(c.model); end
        end
    catch
    end
end

function picks = llmSuggestAll(parts, context, idx)
%LLMSUGGESTALL  ONE request that maps every part to a tool. The model is given
%   the shared CONTEXT (so a terse part like "TL at 100 Hz" is understood in
%   the light of the whole question) and the full tool catalogue. Returns a
%   string per part ("" where not resolved). Fewer requests -> fewer 429s.
    picks = strings(1, numel(parts));
    [key, url, model] = aiConfig();   % env vars, else saved findCalcSetup config
    if strlength(key) == 0 || strlength(url) == 0
        fprintf('(re-rank skipped: run findCalcSetup(''sk-...'') once, or set FINDCALC_LLM_KEY/URL)\n\n');
        return;
    end
    % Catalogue: "ToolName :: keywords" (up to ~24 words) so the model knows
    % what each tool computes. Cheap on Haiku, and richer = better picks.
    cat = strings(idx.N, 1);
    for i = 1:idx.N
        kw = tokenize(idx.keywords(i));
        kw = kw(1:min(24, numel(kw)));
        cat(i) = idx.tools(i) + " :: " + strjoin(kw, " ");
    end
    partList = strjoin(compose("%d) %s", (1:numel(parts)).', parts(:)), newline);
    ctxLine = "";
    if strlength(strtrim(context)) > 0
        ctxLine = "SHARED CONTEXT (applies to every part):" + newline + ...
                  string(context) + newline + newline;
    end
    prompt = "You choose the single best acoustics calculator for each PART of an " + ...
        "exam question. Use the SHARED CONTEXT to understand terse parts. Pick " + ...
        "exactly ONE tool per part from the CATALOGUE. IMPORTANT: many multi-part " + ...
        "questions are solved by ONE integrated tool - if a single catalogue tool's " + ...
        "description covers the whole scenario and several of the parts, choose that " + ...
        "same tool for all the parts it covers, rather than switching to a narrower " + ...
        "tool that only fits one part in isolation. Reply with one line per part, " + ...
        "'<part number>: <exact tool name>', copying the tool name verbatim, and " + ...
        "nothing else." + newline + newline + ...
        ctxLine + ...
        "CATALOGUE (tool :: what it covers):" + newline + strjoin(cat, newline) + newline + newline + ...
        "PARTS:" + newline + partList;

    anthropic = contains(lower(url), "anthropic.com");   % provider from the URL
    try
        if anthropic
            if strlength(model) == 0, model = "claude-haiku-4-5"; end
            body = struct('model', char(model), 'max_tokens', 1024, ...
                'messages', {{struct('role','user','content',char(prompt))}});
            opt = weboptions('MediaType','application/json','Timeout',20, ...
                'HeaderFields', {'x-api-key', char(key); 'anthropic-version', '2023-06-01'});
            resp = webwrite(char(url), body, opt);
            txt  = string(elem(resp.content, 1).text);   % content may decode as cell
        else
            body = struct('contents', {{struct('parts', {{struct('text', char(prompt))}})}});
            opt = weboptions('MediaType','application/json','Timeout',20, ...
                'HeaderFields', {'x-goog-api-key', char(key)});
            resp = webwrite(char(url), body, opt);
            cand = elem(resp.candidates, 1);
            txt  = string(elem(cand.content.parts, 1).text);
        end
        picks = parsePicks(txt, numel(parts), idx.tools);
        fprintf('(re-rank: running normally - 1 request for %d parts)\n\n', numel(parts));
    catch me
        reason = me.message;
        if contains(reason, '429'), reason = 'rate limit / quota'; end
        fprintf('(re-rank: it is shitting itself: %s - using local ranking)\n\n', reason);
        picks = strings(1, numel(parts));
    end
end

function e = elem(x, k)
%ELEM  k-th element of a JSON array that MATLAB decoded as EITHER a struct
%   array or a cell array (single-element arrays often become cells).
    if iscell(x), e = x{k}; else, e = x(k); end
end

function picks = parsePicks(txt, n, tools)
%PARSEPICKS  Read "k: tool name" lines; snap each to a real catalogue name.
    picks = strings(1, n);
    lines = splitlines(txt);
    for L = lines(:).'
        m = regexp(L, '^\s*(\d+)\s*[:\)-]\s*(.+?)\s*$', 'tokens', 'once');
        if isempty(m), continue; end
        k = str2double(m{1});
        if isnan(k) || k < 1 || k > n, continue; end
        picks(k) = snapTool(strtrim(m{2}), tools);
    end
end

function name = snapTool(guess, tools)
%SNAPTOOL  Match the model's text to a real tool name (exact, then contains).
    name = "";
    g = lower(strtrim(guess));
    for i = 1:numel(tools)
        if strcmpi(tools(i), g), name = tools(i); return; end
    end
    for i = 1:numel(tools)
        if contains(lower(tools(i)), g) || contains(g, lower(tools(i)))
            name = tools(i); return;
        end
    end
end

% ======================================================================
% Input handling
% ======================================================================
function mustBeTextLike(x)
    if ~(ischar(x) || isstring(x) || iscellstr(x)) %#ok<ISCLSTR>
        error('findCalculator:type', ...
            'Query must be text (char, string, or cellstr), not %s.', class(x));
    end
end

function s = normaliseText(x)
%NORMALISETEXT  Coerce char/string/cellstr to a clean string row vector.
    s = string(x);
    s = s(:).';
    s(ismissing(s)) = "";
    s = strtrim(s);
    s = s(strlength(s) > 0);
end

function s = capLen(s, n)
    if strlength(s) > n, s = extractBefore(s, n+1); end
end

% ======================================================================
function [parts, pre] = splitParts(q)
%SPLITPARTS  Break a pasted question into parts on "(i) (ii) (a) (1) ..."
%   markers (else on newlines / semicolons). Text before the first marker is
%   returned as PRE (shared context).
    qc = char(q(1));
    pat = '\(?(?:[ivxlcdm]{1,4}|[a-zA-Z]|\d{1,2})\)';   % (i) (ii) (a) (1)  or  i) a) 1)
    ix = regexp(qc, pat, 'start');
    % A real part marker sits at a word boundary (start of string or after
    % whitespace). Drop matches glued to the previous character, e.g. the
    % "(A)" inside "dB(A)" - that is a weighting label, not a sub-question,
    % and splitting there would strip the front of the question into context.
    if ~isempty(ix)
        keep = false(1, numel(ix));
        for k = 1:numel(ix)
            keep(k) = ix(k) == 1 || isspace(qc(ix(k)-1));
        end
        ix = ix(keep);
    end
    if ~isempty(ix)
        if ix(1) == 1, pre = ""; else, pre = string(strtrim(qc(1:ix(1)-1))); end
        bounds = [ix, numel(qc)+1];
        parts = strings(1, numel(ix));
        for i = 1:numel(ix)
            parts(i) = strtrim(string(qc(bounds(i):bounds(i+1)-1)));
        end
    else
        pre = "";
        p = strtrim(split(string(qc), [newline, ";"]));
        p = p(strlength(p) > 0);
        parts = reshape(p, 1, []);
        if isempty(parts), parts = string(qc); end
    end
end

% ======================================================================
function s = truncate(str, n)
    s = char(strtrim(str));
    s = regexprep(s, '\s+', ' ');
    if numel(s) > n, s = [s(1:n-1) char(8230)]; end
    s = string(s);
end

% ======================================================================
function t = tokenize(str)
    str = string(str);
    if ~isscalar(str) || ismissing(str) || strlength(str) == 0
        t = strings(1,0); return;
    end
    % Split on commas as well as whitespace so exam notation like "Leq,100s"
    % or "Leq,8h" yields the decisive acronym "leq" instead of the merged
    % junk token "leq100s" (comma-erasure used to glue the number on).
    t = split(replace(lower(strtrim(str)), ",", " "));
    t = erase(t, [",", ".", ";", ":", "?", "!", "(", ")", "-", "/", "=", ...
                  "’", "‘", char(8220), char(8221), """"]);
    t = t(strlength(t) >= 2);               % keep acronyms (lp, la, tl, nr)
    t = t(~ismember(t, stopWords()));
    t = t(cellfun('isempty', regexp(cellstr(t), '^\d+$', 'once')));  % drop bare numbers (100, 1000)
    t = reshape(t, 1, []);
end

function w = stopWords()
    persistent SW
    if isempty(SW)
        SW = ["the","a","an","of","to","in","for","at","on","over","is","are", ...
         "be","this","that","which","have","has","had","it","its","as","by", ...
         "with","from","and","or","so","if","then","than","into","out","up", ...
         "down","about","only","very","can","will","use","using","calculate", ...
         "determine","find","value","values","comprise","measured","terms", ...
         "per","each","initial","final","three","quarters","quarter","one", ...
         "two","eight","period","hour","hours","day","working","phase", ...
         "phases","steady","still","number","rate","we","you","they","there", ...
         "here","what","when","how","following","follows","given","such", ...
         "also","ear","operator","assume","ii","iii","iv","vi","vii", ...
         "viii","ix","corresponding","acting"];
    end
    w = SW;
end
