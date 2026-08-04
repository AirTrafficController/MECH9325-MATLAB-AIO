function findCalculator(userQuery, context)
%FINDCALCULATOR  Map a multi-part exam question to the calculators to use.
%   FINDCALCULATOR(userQuery) takes either
%     * a string ARRAY, one element per sub-question, OR
%     * a single pasted string of the WHOLE question - it is split
%       automatically on part markers "(i) (ii) (a) (b) (1) (2)" (and on
%       newlines / semicolons), with any text before the first marker used
%       as shared context.
%   For each part it prints the top matching calculators (read from
%   calculators.csv: columns ToolName, Keywords), best first.
%
%   FINDCALCULATOR(userQuery, context) forces an extra shared context string
%   that is mixed into every part (overrides the auto-detected preamble).
%
%   Matching removes stop-words, keeps short acronyms (Lp, LA, Leq, TL, NR,
%   SIL, ...) and scores shared words by inverse document frequency (IDF) so
%   generic words ("plane", "air", "sound") don't dominate a rare, decisive
%   word ("intensity", "reverberation"). The part's own words decide; the
%   context only breaks near-ties. It uses one scoring method everywhere -
%   IDF keyword overlap in base MATLAB, with no toolbox dependence - so the
%   ranking is identical on exam lab machines and on a full install.
%
%   Examples:
%       findCalculator("A plane wave ... Determine (i) Intensity (ii) particle velocity (iii) SPL")
%       findCalculator(["overall A-weighted level"; "level after a barrier in dB(A)"])

    if nargin < 1
        userQuery = "A plane wave in air. Determine (i) intensity (ii) particle velocity (iii) SPL";
    end
    if nargin < 2, context = ""; end
    userQuery = string(userQuery);

    % --- split a single pasted blob into parts + preamble ---------------
    autoCtx = "";
    if isscalar(userQuery)
        [parts, autoCtx] = splitParts(userQuery);
    else
        parts = userQuery(:);
    end
    if strlength(strtrim(context)) == 0, context = autoCtx; end

    % --- load the calculator database -----------------------------------
    here = fileparts(mfilename('fullpath'));
    csv  = fullfile(here, 'calculators.csv');
    if ~isfile(csv)
        error('findCalculator:noCSV', 'calculators.csv not found next to findCalculator.m');
    end
    T = readtable(csv, 'TextType', 'string', 'Delimiter', ',');
    tools = T.ToolName;
    descs = T.Keywords;

    descTokens = arrayfun(@(s) tokenize(s), descs, 'UniformOutput', false);
    idf = computeIDF(descTokens);
    ctxTok = tokenize(context);

    % --- rank tools for each part ---------------------------------------
    fprintf('--- Solution Pipeline ---\n');
    if strlength(strtrim(context)) > 0
        fprintf('Context: %s\n\n', truncate(context, 90));
    end
    K = 3;                                        % show top-K candidates
    for s = 1:numel(parts)
        sc = scoreVector(parts(s), ctxTok, descTokens, idf);
        [sv, order] = sort(sc, 'descend');
        fprintf('Part %d  "%s"\n', s, truncate(parts(s), 70));
        if sv(1) <= 0
            fprintf('   (no confident match - rephrase with the quantity you want)\n\n');
            continue;
        end
        shown = 0;
        for r = 1:min(K, numel(order))
            if sv(r) <= 0, break; end
            tag = ''; if r == 1, tag = '   <- best'; end
            fprintf('   %d. %s%s\n', r, tools(order(r)), tag);
            shown = shown + 1;
        end
        if shown == 0
            fprintf('   (no confident match)\n');
        end
        fprintf('\n');
    end
end

% ======================================================================
function sc = scoreVector(part, ctxTok, descTokens, idf)
%SCOREVECTOR  IDF-weighted keyword-overlap score over all tools for one part.
%   The part's own words decide; the context adds only a faint tie-breaking
%   nudge, so a decisive word in the part cannot be swamped by the preamble.
%   One method is used everywhere (no toolbox dependence) so the ranking is
%   identical on exam lab machines and here - unlike length-normalised cosine,
%   IDF overlap does not penalise a tool for having a longer keyword list.
    stepTok = tokenize(part);
    stepScore = idfScore(stepTok, descTokens, idf);
    if max(stepScore) == 0
        sc = idfScore(ctxTok, descTokens, idf);   % nothing in the part itself
    else
        sc = stepScore + 1e-3 * idfScore(ctxTok, descTokens, idf);
    end
end

% ======================================================================
function sc = idfScore(qtok, descTokens, idf)
    N = numel(descTokens);
    sc = zeros(N, 1);
    for i = 1:N
        shared = intersect(qtok, descTokens{i});
        s = 0;
        for k = 1:numel(shared)
            key = char(shared(k));
            if isKey(idf, key), s = s + idf(key); end
        end
        sc(i) = s;
    end
end

% ======================================================================
function idf = computeIDF(descTokens)
    N = numel(descTokens);
    vocab = unique([descTokens{:}]);
    idf = containers.Map('KeyType', 'char', 'ValueType', 'double');
    for v = 1:numel(vocab)
        w = vocab(v);
        df = sum(cellfun(@(d) any(d == w), descTokens));
        idf(char(w)) = log((N + 1)/(df + 0.5));   % rarer word -> higher weight
    end
end

% ======================================================================
function [parts, pre] = splitParts(q)
%SPLITPARTS  Break a pasted question into parts on "(i) (ii) (a) (1) ..."
%   markers (else on newlines / semicolons). Text before the first marker is
%   returned as PRE (shared context).
    qc = char(q(1));
    pat = '\((?:[ivxlcdm]{1,4}|[a-zA-Z]|\d{1,2})\)';    % (i) (ii) (a) (1)
    idx = regexp(qc, pat, 'start');
    if numel(idx) >= 1
        pre = string(strtrim(qc(1:max(idx(1)-1,1))));
        if idx(1) == 1, pre = ""; end
        bounds = [idx, numel(qc)+1];
        parts = strings(numel(idx), 1);
        for i = 1:numel(idx)
            parts(i) = strtrim(string(qc(bounds(i):bounds(i+1)-1)));
        end
    else
        pre = "";
        p = strtrim(split(string(qc), [newline, ";"]));
        p = p(strlength(p) > 0);
        parts = p;
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
    t = split(lower(strtrim(str)));
    t = erase(t, [",", ".", ";", ":", "?", "!", "(", ")", "-", "/", "=", ...
                  "’", "‘", char(8220), char(8221), """"]);
    t = t(strlength(t) >= 2);               % keep acronyms (lp, la, tl, nr)
    t = t(~ismember(t, stopWords()));
    t = t(:).';
end

function w = stopWords()
    w = ["the","a","an","of","to","in","for","at","on","over","is","are", ...
         "be","this","that","which","have","has","had","it","its","as","by", ...
         "with","from","and","or","so","if","then","than","into","out","up", ...
         "down","about","only","very","can","will","use","using","calculate", ...
         "determine","find","value","values","comprise","measured","terms", ...
         "per","each","initial","final","three","quarters","quarter","one", ...
         "two","eight","period","hour","hours","day","working","phase", ...
         "phases","steady","still","number","rate","we","you","they","there", ...
         "here","what","when","how","following","follows","given","such", ...
         "also","ear","operator","its","assume","ii","iii","iv","vi","vii", ...
         "viii","ix","corresponding","acting"];
end
