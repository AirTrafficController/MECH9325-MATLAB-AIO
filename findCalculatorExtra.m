function varargout = findCalculatorExtra(userQuery, context)
%FINDCALCULATOREXTRA  findCalculator with the online AI re-rank switched on.
%   Shorthand for findCalculator(userQuery, 'useLLM', true) - so you can type
%
%       findCalculatorExtra("... your question ...")
%
%   instead of the longer findCalculator("...", 'useLLM', true).
%
%   The AI part needs FINDCALC_LLM_KEY / FINDCALC_LLM_URL set (see
%   findCalculator's help). If they are not set, or you are offline, it just
%   falls back to the local ranking - identical to plain findCalculator.
%
%   Accepts the same inputs and returns the same struct as findCalculator:
%       findCalculatorExtra(query)
%       findCalculatorExtra(query, context)
%       s = findCalculatorExtra(query)          % also returns the struct
    if nargin < 1
        userQuery = "";   % let findCalculator use its own default
    end
    if nargin < 2
        context = "";
    end
    if nargout
        [varargout{1:nargout}] = findCalculator(userQuery, context, 'useLLM', true);
    else
        findCalculator(userQuery, context, 'useLLM', true);
    end
end
