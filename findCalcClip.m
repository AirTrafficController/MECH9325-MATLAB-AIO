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
%   Answer/marks feedback and number-only rows (e.g. "102.255", "0 to 5",
%   "Marks for this submission", "Correct answer") are stripped first, so only
%   the real question lines are searched. Any extra arguments pass straight
%   through to FINDCALCULATOR, e.g.
%
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
    q = cleanClip(raw);
    if strlength(q) == 0
        fprintf(['Nothing usable on the clipboard.\n' ...
                 'Select the question text, press Ctrl+C, then run findCalcClip.\n']);
        if nargout, out = struct('query', {}, 'matches', {}); end
        return;
    end
    if nargout
        out = findCalculator(q, varargin{:});
    else
        findCalculator(q, varargin{:});
    end
end

function q = cleanClip(raw)
%CLEANCLIP  Keep only real question lines from pasted text: drop blank lines,
%   number/range/unit-only rows, and answer/marks feedback. A line survives
%   only if it contains a 3+ letter word AND is not a feedback line - which
%   removes "102.255", "0 to 5", "69", "dB" and the marking blurb while
%   keeping every "Determine ..." prompt and the scenario description.
    q = "";
    if isempty(raw), return; end
    lines = splitlines(string(raw));
    drop  = ["marks for this submission", "correct answer", "well done", "incorrect"];
    keep  = strings(0, 1);
    for i = 1:numel(lines)
        L = strtrim(lines(i));
        if strlength(L) == 0,                          continue; end   % blank
        if any(contains(lower(L), drop)),              continue; end   % feedback
        if isempty(regexp(L, '[A-Za-z]{3,}', 'once')), continue; end   % numbers/ranges/units
        keep(end+1, 1) = L; %#ok<AGROW>
    end
    q = strtrim(strjoin(keep, newline));
end
