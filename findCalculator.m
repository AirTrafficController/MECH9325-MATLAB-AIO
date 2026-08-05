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
            if opts.useLLM                          % optional online re-rank
                pick = llmPickCalculator(parts(s), idx.tools(order(sv>0)));
                if strlength(pick) > 0
                    fprintf('   (AI suggests: %s)\n', pick);
                end
            end
            fprintf('\n');
        end
        if nargout
            out(s).query = char(parts(s));
            out(s).matches = matches;
        end
    end
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
%   Part words decide; context adds a faint tie-break nudge only.
    stepScore = scoreTokens(tokenize(part), idx);
    if max(stepScore) == 0
        sc = scoreTokens(ctxTok, idx);            % nothing usable in the part
    else
        sc = stepScore + 1e-3 * scoreTokens(ctxTok, idx);
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
%   Set up (in your session, not in git):
%       setenv('FINDCALC_LLM_KEY','<your fresh key>')
%       setenv('FINDCALC_LLM_URL','https://.../v1beta/models/<model>:generateContent')
% ======================================================================
function pick = llmPickCalculator(query, candidates)
    pick = "";
    key = string(getenv('FINDCALC_LLM_KEY'));
    url = string(getenv('FINDCALC_LLM_URL'));
    if strlength(key) == 0 || strlength(url) == 0
        warning('findCalculator:noLLMkey', ...
            'useLLM set but FINDCALC_LLM_KEY / FINDCALC_LLM_URL not in environment - skipping AI re-rank.');
        return;
    end
    prompt = "You are picking ONE calculator for a physics/acoustics question. " + ...
        "Reply with the exact tool name only, no other text." + newline + ...
        "Question: " + query + newline + "Tools:" + newline + ...
        strjoin("- " + string(candidates(:)), newline);
    body = struct('contents', struct('parts', struct('text', prompt)));
    try
        opt = weboptions('MediaType','application/json','Timeout',15, ...
                         'HeaderFields',{'x-goog-api-key', char(key)});
        resp = webwrite(char(url), body, opt);
        pick = strtrim(string(resp.candidates(1).content.parts(1).text));
    catch me
        warning('findCalculator:llmFailed', 'AI re-rank failed (%s) - using local ranking.', me.message);
        pick = "";
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
    pat = '\((?:[ivxlcdm]{1,4}|[a-zA-Z]|\d{1,2})\)';    % (i) (ii) (a) (1)
    ix = regexp(qc, pat, 'start');
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
    t = split(lower(strtrim(str)));
    t = erase(t, [",", ".", ";", ":", "?", "!", "(", ")", "-", "/", "=", ...
                  "’", "‘", char(8220), char(8221), """"]);
    t = t(strlength(t) >= 2);               % keep acronyms (lp, la, tl, nr)
    t = t(~ismember(t, stopWords()));
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
