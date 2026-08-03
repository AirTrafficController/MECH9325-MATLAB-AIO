function findCalculator(userQuery, context)
%FINDCALCULATOR  Map a multi-part exam question to the calculators to use.
%   FINDCALCULATOR(userQuery) takes a string array where each element is one
%   step of a question and prints a step-by-step pipeline of the best-matching
%   tool for each step, read from calculators.csv (columns ToolName, Keywords).
%
%   FINDCALCULATOR(userQuery, context) also mixes a shared context string into
%   every step - use it to pass the question's preamble (e.g. the table header
%   "octave band linear unweighted SPL ... A-weighted") so sparse sub-questions
%   like "Lp over the first quarter" still match well.
%
%   Matching removes common stop-words, keeps short acronyms (Lp, LA, Leq,
%   LAeq, TL, NR, SIL, ...), and scores shared words by their inverse document
%   frequency (IDF) so generic words like "period" or "hour" don't dominate.
%   It uses TF-IDF + cosine similarity (Text Analytics + Statistics toolboxes)
%   when installed, and this IDF keyword score otherwise - so it runs on any
%   MATLAB, including exam lab machines without the toolboxes.
%
%   Example:
%       findCalculator(["Lp over the first quarter hour"; ...
%                       "LAeq over the 8 hour working day"], ...
%                      "octave band linear unweighted SPL and A-weighted")

    if nargin < 1
        userQuery = [ ...
            "I have octave band sound pressure levels, find the overall A-weighted level"; ...
            "fit a panel barrier and find the level after the reduction in dB(A)"];
    end
    if nargin < 2, context = ""; end
    userQuery = string(userQuery);

    % --- load the calculator database -----------------------------------
    here = fileparts(mfilename('fullpath'));
    csv  = fullfile(here, 'calculators.csv');
    if ~isfile(csv)
        error('findCalculator:noCSV', 'calculators.csv not found next to findCalculator.m');
    end
    T = readtable(csv, 'TextType', 'string', 'Delimiter', ',');
    tools = T.ToolName;
    descs = T.Keywords;

    % pre-tokenise the database and build IDF weights (used by both paths)
    descTokens = arrayfun(@(s) tokenize(s), descs, 'UniformOutput', false);
    idf = computeIDF(descTokens);

    useTFIDF = exist('tokenizedDocument','file') && exist('tfidf','file') && ...
               exist('bagOfWords','file') && exist('pdist2','file');

    % --- match each step ------------------------------------------------
    n = numel(userQuery);
    ctxTok = tokenize(context);
    best = strings(n,1);
    for s = 1:n
        stepTok = tokenize(userQuery(s));
        if useTFIDF
            qtext = strjoin(cellstr(stepTok), ' ');
            if isempty(stepTok), qtext = strjoin(cellstr(ctxTok), ' '); end
            idx = matchTFIDF(string(qtext), descs);
        else
            idx = matchKeywords(stepTok, ctxTok, descTokens, idf);
        end
        best(s) = tools(idx);
    end

    % --- concise pipeline output ----------------------------------------
    fprintf('--- Solution Pipeline ---\n');
    for s = 1:n
        fprintf('Step %d: Use %s\n', s, best(s));
    end
end

% ======================================================================
function idx = matchTFIDF(queryStep, descs)
    docs = [descs; queryStep];
    bag  = removeWords(bagOfWords(tokenizedDocument(lower(docs))), stopWords());
    M    = tfidf(bag);
    qv   = full(M(end, :));
    dv   = full(M(1:end-1, :));
    if ~any(qv)
        idx = 1; return;                    % nothing to go on
    end
    d = pdist2(qv, dv, 'cosine');
    d(isnan(d)) = 1;
    [~, idx] = min(d);
end

% ======================================================================
function idx = matchKeywords(stepTok, ctxTok, descTokens, idf)
    % Step tokens decide; context only breaks ties (base MATLAB, no toolboxes).
    stepScore = idfScore(stepTok, descTokens, idf);
    m = max(stepScore);
    if m == 0                                   % step has no useful words
        ctxScore = idfScore(ctxTok, descTokens, idf);
        [~, idx] = max(ctxScore); return;
    end
    ties = find(stepScore >= m - 1e-9);
    if numel(ties) == 1
        idx = ties(1);
    else                                        % break ties with the context
        ctxScore = idfScore(ctxTok, descTokens, idf);
        [~, j] = max(ctxScore(ties));
        idx = ties(j);
    end
end

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
function t = tokenize(str)
    t = split(lower(strtrim(str)));
    t = erase(t, [",", ".", ";", ":", "?", "!", "(", ")", "-", "/", ...
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
         "also","ear","operator"];
end
