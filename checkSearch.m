function ok = checkSearch()
%CHECKSEARCH  Regression-test the local search against a labelled question bank.
%   CHECKSEARCH() reads searchQuestions.csv (columns Question, ExpectedTool)
%   next to this file, runs the LOCAL findCalculator on each question, and
%   reports whether the expected tool is the #1 pick (PASS), only in the
%   top-3 (WEAK), or missing (FAIL). Prints a summary and lists every
%   non-PASS with the question so you can see what to fix.
%
%   ok = CHECKSEARCH() also returns true if every question PASSed.
%
%   HOW TO USE IT (the right way to grow the search):
%     1. Whenever you validate a new question -> tool, add ONE row to
%        searchQuestions.csv:  "the question text",Exact Tool Name
%        (quote the question; the tool name must match calculators.csv).
%     2. Run checkSearch after ANY keyword edit. If a change fixes your new
%        question but breaks an old one, you'll see it immediately - so you
%        can re-balance instead of silently regressing.
%   This turns "feed it questions" into cumulative, non-regressing tuning.
    here = fileparts(mfilename('fullpath'));
    csv  = fullfile(here, 'searchQuestions.csv');
    if ~isfile(csv)
        error('checkSearch:noCSV', 'searchQuestions.csv not found next to checkSearch.m');
    end
    T = readtable(csv, 'TextType', 'string', 'Delimiter', ',');
    nPass = 0; nWeak = 0; nFail = 0;
    for i = 1:height(T)
        q    = T.Question(i);
        want = strtrim(T.ExpectedTool(i));
        s = [];
        evalc('s = findCalculator(q);');        % run local search, suppress printout
        tools = strings(1,0);
        if ~isempty(s) && ~isempty(s(1).matches)
            tools = string({s(1).matches.tool});
        end
        if ~isempty(tools) && tools(1) == want
            nPass = nPass + 1;
        elseif any(tools == want)
            nWeak = nWeak + 1;
            fprintf('WEAK  want "%s"  but #1 = "%s"\n      Q: %s\n', want, tools(1), clip(q));
        else
            got = "(none)"; if ~isempty(tools), got = tools(1); end
            nFail = nFail + 1;
            fprintf('FAIL  want "%s"  got "%s"\n      Q: %s\n', want, got, clip(q));
        end
    end
    fprintf('\n%d/%d PASS   (%d weak, %d fail)\n', nPass, height(T), nWeak, nFail);
    ok = (nWeak == 0 && nFail == 0);
end

function s = clip(q)
    s = char(q);
    if numel(s) > 72, s = [s(1:71) char(8230)]; end
end
