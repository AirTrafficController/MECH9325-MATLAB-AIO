function R = oneOfNSources(Ltot, N)
%ONEOFNSOURCES  Level of a single source among N identical ones.
%   R = ACOUSTICS.ONEOFNSOURCES(Ltot, N) returns
%       L1 = Ltot - 10*log10(N)
%   R has fields .each (dB) and .steps.
    arguments
        Ltot (1,1) double
        N    (1,1) double {mustBePositive}
    end
    R.each = Ltot - 10*log10(N);
    R.steps = { ...
        'L1 = Ltot - 10*log10(N)', ...
        sprintf('= %.4g - 10*log10(%g) = %.4g - %.4g = %.2f dB', ...
            Ltot, N, Ltot, 10*log10(N), R.each)};
end
