function R = increaseFromSources(N1, L1, added, newLevel)
%INCREASEFROMSOURCES  Level rise from more identical sources (bidirectional).
%   R = ACOUSTICS.INCREASEFROMSOURCES(N1, L1, added) forward mode:
%       adds 'added' sources to N1 existing ones and returns the new level.
%       N2 = N1 + added,  dL = 10*log10(N2/N1),  L_new = L1 + dL
%
%   R = ACOUSTICS.INCREASEFROMSOURCES(N1, L1, [], newLevel) reverse mode:
%       given the observed new level L_new, solves for how many sources were
%       added:
%           N2 = N1 * 10^((L_new-L1)/10),  added = N2 - N1
%       Requires L_new > L1 (level must actually rise).
%
%   R fields: .N1, .N2, .added, .delta, .newLevel, .steps.
    arguments
        N1       (1,1) double {mustBePositive}
        L1       (1,1) double
        added    double = []
        newLevel double = []
    end
    haveAdded = ~isempty(added) && ~any(isnan(added));
    haveNew   = ~isempty(newLevel) && ~any(isnan(newLevel));
    if haveAdded == haveNew
        error('acoustics:increaseFromSources:mode', ...
            'Provide EITHER added (forward) OR newLevel (reverse).');
    end

    R.N1 = N1;
    if haveAdded
        R.added = added;
        R.N2 = N1 + added;
        if ~(R.N2 > 0)
            error('acoustics:increaseFromSources:count', 'Resulting count must be positive.');
        end
        R.delta = 10*log10(R.N2/N1);
        R.newLevel = L1 + R.delta;
        R.steps = { ...
            'FORWARD: N2 = N1 + added; dL = 10 log10(N2/N1); L_new = L1 + dL', ...
            sprintf('N2 = %g + %g = %g', N1, added, R.N2), ...
            sprintf('dL = 10 log10(%g/%g) = 10 log10(%.4f) = %.3f dB', R.N2, N1, R.N2/N1, R.delta), ...
            sprintf('L_new = %.4g + %.3f = %.3f dB', L1, R.delta, R.newLevel)};
    else
        R.newLevel = newLevel;
        R.delta = newLevel - L1;
        if R.delta <= 0
            error('acoustics:increaseFromSources:noRise', ...
                'newLevel (%g) must be greater than L1 (%g).', newLevel, L1);
        end
        ratio = 10^(R.delta/10);
        R.N2 = N1 * ratio;
        R.added = R.N2 - N1;
        R.steps = { ...
            'REVERSE: N2 = N1 * 10^((L_new - L1)/10); added = N2 - N1', ...
            sprintf('dL = L_new - L1 = %.4g - %.4g = %.3f dB', newLevel, L1, R.delta), ...
            sprintf('N2/N1 = 10^(%.3f/10) = %.4f', R.delta, ratio), ...
            sprintf('N2 = %g * %.4f = %.2f  ->  round to %g', N1, ratio, R.N2, round(R.N2)), ...
            sprintf('added = N2 - N1 = %.2f - %g = %.2f  ->  round to %g', ...
                R.N2, N1, R.added, round(R.added))};
    end
end
