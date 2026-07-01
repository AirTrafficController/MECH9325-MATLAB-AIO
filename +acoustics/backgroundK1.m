function R = backgroundK1(Lsource, Lbackground)
%BACKGROUNDK1  Background-noise correction K1 for sound power measurement.
%   R = ACOUSTICS.BACKGROUNDK1(Lsource, Lbackground) with the mean SPL with
%   the source running and the mean background SPL (dB) returns:
%       dL = Lsource - Lbackground
%       K1 = -10*log10( 1 - 10^(-dL/10) )
%   Errors when dL <= 6 dB (measurement invalid). R has fields .dL (dB),
%   .K1 (dB), .negligible (logical, dL >= 15) and .steps.
    arguments
        Lsource     (1,1) double
        Lbackground (1,1) double
    end
    R.dL = Lsource - Lbackground;
    if R.dL < 6
        error('acoustics:backgroundK1:invalid', ...
            'dL = %.1f dB < 6 dB - background too high, measurement invalid.', R.dL);
    end
    R.K1 = -10*log10(1 - 10^(-R.dL/10));
    R.negligible = R.dL >= 15;
    note = '';
    if R.negligible, note = ' (>=15 dB -> negligible)'; end
    R.steps = { ...
        'K1 = -10*log10(1 - 10^(-dL/10))', ...
        sprintf('dL = %.1f dB', R.dL), ...
        sprintf('= -10*log10(1 - 10^(-%.1f/10)) = %.3f dB%s', R.dL, R.K1, note)};
end
