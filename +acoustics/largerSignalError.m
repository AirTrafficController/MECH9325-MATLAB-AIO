function R = largerSignalError(ratio)
%LARGERSIGNALERROR  Error from ignoring the smaller of two signals.
%   R = ACOUSTICS.LARGERSIGNALERROR(ratio) takes ratio = p2/p1 (smaller /
%   larger, 0 <= ratio <= 1) and returns the fractional under-estimate made
%   by keeping only the larger signal:
%       p_tot = p1 * sqrt(1 + ratio^2)
%       error = 1/sqrt(1 + ratio^2) - 1
%   R has fields .ptotFactor (x p1), .errorPct (%) and .steps.
    arguments
        ratio (1,1) double {mustBeNonnegative}
    end
    if ratio > 1
        error('acoustics:largerSignalError:ratio', 'ratio (p2/p1) must be <= 1.');
    end
    R.ptotFactor = sqrt(1 + ratio^2);
    R.errorPct = (1/R.ptotFactor - 1)*100;
    R.steps = { ...
        sprintf('r = p2/p1 = %.4g', ratio), ...
        sprintf('p_tot = p1*sqrt(1 + r^2) = p1*sqrt(1 + %.4g) = %.5g*p1', ratio^2, R.ptotFactor), ...
        'Error = 1/sqrt(1 + r^2) - 1', ...
        sprintf('= 1/%.5g - 1 = %.2f %%', R.ptotFactor, R.errorPct)};
end
