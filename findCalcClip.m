function out = findCalcClip(varargin)
%FINDCALCCLIP  Search from the clipboard - copy a whole question, then run this.
%   Copy an exam question to the clipboard (select it, Ctrl+C) - tables,
%   'quotes', blank lines and all - then simply type:
%
%       findCalcClip
%
%   It reads the clipboard and runs FINDCALCULATOR on it, so you never paste
%   the question into a  findCalculator("...")  call. That matters because a
%   pasted multi-line question with embedded quotes and line breaks cannot be
%   typed as a "..." argument in the command window - MATLAB runs each line as
%   you paste it and the quotes corrupt the command. Reading the clipboard
%   sidesteps that completely.
%
%   Only the ACTUAL sub-questions are searched. Lines that start with a
%   command/question word (Determine, Find, Calculate, ... What, Which, How)
%   or end with "?" become the parts; the scenario, data tables, blank rows,
%   number-only rows, empty answer fields ("Leq,100s =") and marks/feedback
%   are dropped - so a 5-part question gives 5 parts, not one per line. If no
%   such question line is found, the whole cleaned text is handed to
%   FINDCALCULATOR to split on "(i) (ii)" markers as usual.
%
%   Any extra arguments pass straight through to FINDCALCULATOR, e.g.
%       findCalcClip('useLLM', true)     % optional online re-rank (not exam-safe)
%
%   S = FINDCALCCLIP(...) also returns the FINDCALCULATOR struct array.
%
%   See also FINDCALCULATOR.
    try
        raw = clipboard('paste');
    catch
        raw = '';                                   % no desktop/Java clipboard
    end
    parts = cleanClip(raw);
    if isempty(parts) || all(strlength(parts) == 0)
        fprintf(['Nothing usable on the clipboard.\n' ...
                 'Select the question text, press Ctrl+C, then run findCalcClip.\n']);
        if nargout, out = struct('query', {}, 'matches', {}); end
        return;
    end
    if nargout
        out = findCalculator(parts, "", varargin{:});
    else
        findCalculator(parts, "", varargin{:});
    end
end

function parts = cleanClip(raw)
%CLEANCLIP  Turn pasted text into the list of real sub-questions to search.
%   Drops noise (scenario tables, number/unit-only rows, empty answer fields
%   like "RMS voltage =" or a lone "Volts", and marks/feedback). Then:
%    * if any line starts with a command/question word (Determine, Find, ...)
%      or ends with "?", those lines ARE the sub-questions (multi-part case);
%    * otherwise the whole thing is ONE question - the kept lines are joined
%      with spaces into a single query, so a one-paragraph question stays one
%      part instead of splitting on its line breaks.
    parts = strings(1, 0);
    if isempty(raw), return; end
    lines = splitlines(string(raw));
    drop  = ["marks for this submission", "correct answer", "well done", "incorrect"];
    units = ["v","volt","volts","db","dba","dbc","pa","upa","hz","khz","w","mw", ...
             "watt","watts","sec","second","seconds","mm","mv"];
    kept  = strings(0, 1);
    for i = 1:numel(lines)
        L = strtrim(lines(i));
        if strlength(L) == 0,                          continue; end   % blank
        if any(contains(lower(L), drop)),              continue; end   % feedback
        if isempty(regexp(L, '[A-Za-z]{3,}', 'once')), continue; end   % numbers/ranges/short
        if endsWith(L, "="),                           continue; end   % empty answer field "X ="
        if any(lower(regexprep(L,'[^A-Za-z]','')) == units), continue; end % lone unit line "Volts"
        kept(end+1, 1) = L; %#ok<AGROW>
    end
    if isempty(kept), return; end

    % A line is a sub-question if its FIRST word is a command/question word,
    % or it ends with "?". First-word matching (rather than a regex) is used
    % because it is unambiguous and robust across MATLAB versions.
    qWords = ["determine","find","calculate","compute","estimate","evaluate", ...
              "obtain","show","state","explain","what","which","how","why","hence"];
    isQ = false(numel(kept), 1);
    for i = 1:numel(kept)
        w1 = extractBefore(kept(i) + " ", " ");        % first token (+" " guards 1-word lines)
        w1 = lower(regexprep(w1, '[^A-Za-z]', ''));    % letters only: "(i)" -> "i", "Determine," -> determine
        isQ(i) = any(w1 == qWords) || endsWith(kept(i), '?');
    end
    if any(isQ)
        parts = reshape(kept(isQ), 1, []);             % multi-part: the sub-question lines
    else
        parts = strtrim(strjoin(kept, " "));           % single question: one query (no line-split)
    end
end
