function R = planeWaveLevel(u, opts)
%PLANEWAVELEVEL  Plane-wave particle velocity -> pressure -> sound pressure level.
%   R = ACOUSTICS.PLANEWAVELEVEL(u) takes the RMS particle velocity u (m/s) of a
%   plane progressive wave and returns the RMS pressure and the sound pressure
%   level, using p = rho*c*u and Lp = 20*log10(p/p_ref).
%
%   Options:
%       'rho'  medium density (kg/m^3), default 1.21 (air)
%       'c'    speed of sound (m/s),    default 343  (air)
%       'pref' reference pressure (Pa), default 2e-5 (20 uPa, air standard)
%   For WATER use rho=1000, c=1500 and pref=1e-6 (1 uPa, the underwater
%   acoustics reference).
%
%   R has fields .p (Pa), .Lp (dB), .rhoc (rayls) and .steps.
%
%   Examples (u = 0.11 m/s):
%       acoustics.planeWaveLevel(0.11).Lp                               % 127.17 dB (air)
%       acoustics.planeWaveLevel(0.11,'rho',1000,'c',1500,'pref',1e-6).Lp % 224.35 dB (water)
    arguments
        u (1,1) double {mustBeNonnegative}
        opts.rho  (1,1) double {mustBePositive} = 1.21
        opts.c    (1,1) double {mustBePositive} = 343
        opts.pref (1,1) double {mustBePositive} = 2e-5
    end
    R.rhoc = opts.rho * opts.c;
    R.p    = R.rhoc * u;
    R.Lp   = 20*log10(R.p / opts.pref);
    R.steps = { ...
        sprintf('rho c = %g * %g = %.5g rayls', opts.rho, opts.c, R.rhoc), ...
        sprintf('p = rho c * u = %.5g * %g = %.5g Pa', R.rhoc, u, R.p), ...
        sprintf('Lp = 20*log10(p / p_ref) = 20*log10(%.5g / %g)', R.p, opts.pref), ...
        sprintf('   = %.2f dB', R.Lp)};
end
