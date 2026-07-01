function R = soundPowerMeasured(Lp, S, opts)
%SOUNDPOWERMEASURED  Sound power level from a mean surface SPL.
%   R = ACOUSTICS.SOUNDPOWERMEASURED(Lp, S) with the mean measurement-surface
%   SPL Lp (dB) over an area S (m^2) returns the sound power level:
%       Lw = (Lp - K1 - K2) + 10*log10(S/S0),   S0 = 1 m^2
%   Optional 'K1' and 'K2' (default 0) apply the background and environmental
%   corrections. R has fields .Lw (dB) and .steps.
    arguments
        Lp (1,1) double
        S  (1,1) double {mustBePositive}
        opts.K1 (1,1) double = 0
        opts.K2 (1,1) double = 0
    end
    R.Lw = (Lp - opts.K1 - opts.K2) + 10*log10(S);
    R.steps = { ...
        'Lw = (Lp - K1 - K2) + 10*log10(S/S0),  S0 = 1 m^2', ...
        sprintf('= (%g - %g - %g) + 10*log10(%g) = %.2f dB', ...
            Lp, opts.K1, opts.K2, S, R.Lw)};
end
