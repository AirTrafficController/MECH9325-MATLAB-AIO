function R = increaseFromSources(N1, L1, added)
%INCREASEFROMSOURCES  Level rise when more identical sources are added.
%   R = ACOUSTICS.INCREASEFROMSOURCES(N1, L1, added) returns the change and
%   new level when 'added' extra sources join N1 existing ones measured at
%   level L1:
%       N2 = N1 + added
%       dL = 10*log10(N2/N1),   L_new = L1 + dL
%   R has fields .N2, .delta (dB), .newLevel (dB) and .steps.
    arguments
        N1    (1,1) double {mustBePositive}
        L1    (1,1) double
        added (1,1) double
    end
    R.N2 = N1 + added;
    if ~(R.N2 > 0)
        error('acoustics:increaseFromSources:count', 'Resulting count must be positive.');
    end
    R.delta = 10*log10(R.N2/N1);
    R.newLevel = L1 + R.delta;
    R.steps = { ...
        sprintf('N2 = N1 + added = %g + %g = %g', N1, added, R.N2), ...
        sprintf('dL = 10*log10(N2/N1) = 10*log10(%g) = %.3f dB', R.N2/N1, R.delta), ...
        sprintf('L_new = L1 + dL = %.4g + %.3f = %.3f dB', L1, R.delta, R.newLevel)};
end
