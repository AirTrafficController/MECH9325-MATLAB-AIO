function findCalculator(userQuery)
%FINDCALCULATOR  Map a multi-part exam question to the calculators to use.
%   FINDCALCULATOR(userQuery) takes a string array where each element is one
%   step of a question and prints a step-by-step pipeline of the best-matching
%   tool for each step, read from calculators.csv (columns ToolName, Keywords).
%
%   Matching uses TF-IDF + cosine similarity (Text Analytics + Statistics
%   toolboxes) when they are installed, and automatically falls back to a
%   base-MATLAB keyword-overlap score when they are not - so it runs on any
%   MATLAB, including exam lab machines without the toolboxes.
%
%   Example:
%       userQuery = ["octave band SPLs find overall A-weighted level"; ...
%                    "fit a panel find the level after the reduction in dB(A)"];
%       findCalculator(userQuery)
%
%       --- Solution Pipeline ---
%       Step 1: Use Weighting: overall dB(A)
%       Step 2: Use Barrier added to spectrum

    if nargin < 1
        userQuery = [ ...
            "I have octave band sound pressure levels, find the overall A-weighted level"; ...
            "fit a panel barrier and find the level after the reduction in dB(A)"];
    end
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

    useTFIDF = exist('tokenizedDocument','file') && exist('tfidf','file') && ...
               exist('bagOfWords','file') && exist('pdist2','file');

    % --- match each step ------------------------------------------------
    n = numel(userQuery);
    best = strings(n,1);
    for s = 1:n
        if useTFIDF
            idx = matchTFIDF(userQuery(s), descs);
        else
            idx = matchKeywords(userQuery(s), descs);
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
    % Combine the query step with the database descriptions, TF-IDF, cosine.
    docs = [descs; queryStep];
    bag  = bagOfWords(tokenizedDocument(lower(docs)));
    M    = tfidf(bag);                      % (N+1) x V
    qv   = full(M(end, :));
    dv   = full(M(1:end-1, :));
    if ~any(qv)                             % no shared vocabulary
        idx = matchKeywords(queryStep, descs); return;
    end
    d = pdist2(qv, dv, 'cosine');           % cosine distance (0 = identical)
    d(isnan(d)) = 1;
    [~, idx] = min(d);
end

% ======================================================================
function idx = matchKeywords(queryStep, descs)
    % Base-MATLAB fallback: score by number of shared words.
    qt = tokenize(queryStep);
    scores = zeros(numel(descs), 1);
    for i = 1:numel(descs)
        kt = tokenize(descs(i));
        scores(i) = numel(intersect(qt, kt));
    end
    [~, idx] = max(scores);
end

function t = tokenize(str)
    t = split(lower(strtrim(str)));
    t = erase(t, [",", ".", ";", ":", "?", "(", ")", "-", "/"]);
    t = t(strlength(t) > 2);                % drop tiny stop-ish words
end
