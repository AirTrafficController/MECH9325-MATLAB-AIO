function R = powerIntoMedium(SPL, d, opts)
%POWERINTOMEDIUM  Sound power carried into a medium through a pipe (from SPL).
%   R = ACOUSTICS.POWERINTOMEDIUM(SPL, d) for a pipe of internal diameter d (m)
%   whose end is coupled to a medium (default water) that is anechoically
%   terminated (a travelling wave, no reflections). A microphone at the
%   interface measures an RMS sound pressure level SPL (dB re 2e-5 Pa); the
%   acoustic pressure is continuous across the interface, so:
%       p_rms = p_ref * 10^(SPL/20)
%       I     = p_rms^2 / (rho c)        [travelling wave in the medium]
%       W     = I * A,   A = pi*d^2/4    [pipe cross-section]
%       Lw    = 10*log10(W / 1e-12)
%   Defaults are for water: 'rho' 1000 kg/m^3, 'c' 1480 m/s ('pref' 2e-5 Pa).
%
%   R has fields .prms (Pa), .rhoc, .area (m^2), .I (W/m^2), .W (W), .Lw (dB)
%   and .steps.
%
%   Example (80 mm pipe into a lake, 153 dB at the surface):
%       acoustics.powerIntoMedium(153, 0.080).W    % 2.71e-3 W
    arguments
        SPL (1,1) double
        d   (1,1) double {mustBePositive}
        opts.rho  (1,1) double {mustBePositive} = 1000
        opts.c    (1,1) double {mustBePositive} = 1480
        opts.pref (1,1) double {mustBePositive} = 2e-5
    end
    C = acoustics.constants();
    R.prms = opts.pref * 10^(SPL/20);
    R.rhoc = opts.rho*opts.c;
    R.area = pi*d^2/4;
    R.I = R.prms^2 / R.rhoc;
    R.W = R.I * R.area;
    R.Lw = 10*log10(R.W/C.WREF);
    R.steps = { ...
        'Anechoic medium (travelling wave), pressure continuous at interface', ...
        sprintf('p_rms = p_ref*10^(SPL/20) = 2e-5*10^(%.4g/20) = %.1f Pa', SPL, R.prms), ...
        sprintf('rho c = %.4g rayl · A = pi*d^2/4 = %.5g m^2', R.rhoc, R.area), ...
        sprintf('I = p_rms^2/(rho c) = %.4g W/m^2', R.I), ...
        sprintf('W = I*A = %.4g W  (%.3f mW)', R.W, R.W*1000), ...
        sprintf('Lw = 10*log10(W/1e-12) = %.1f dB', R.Lw)};
end
