function R = particleMotion(P, f, opts)
%PARTICLEMOTION  Particle velocity, displacement, intensity and SPL of a wave.
%   R = ACOUSTICS.PARTICLEMOTION(P, f) for a plane wave of peak pressure
%   amplitude P (Pa) at frequency f (Hz), with rho c = 415 rayls by default:
%       u    = P / (rho c)                 particle velocity amplitude (peak)
%       urms = u / sqrt(2)                 rms particle velocity
%       xi   = u / omega,  omega = 2*pi*f  displacement amplitude
%       I    = P^2 / (2 rho c)             intensity
%       prms = P / sqrt(2)                 rms pressure
%       spl  = 20*log10(prms/pref)         sound pressure level
%
%   Leave P empty ([]) and supply 'urms' to drive it from the rms particle
%   velocity instead (P = sqrt(2)*rho c*urms):
%       acoustics.particleMotion([], 100, 'urms', 0.11, 'rhoc', 415)
%
%   Optional 'rhoc' overrides the impedance (air 415, water 1.5e6 rayls) and
%   'pref' the SPL reference (air 2e-5 Pa, water 1e-6 Pa). R has fields .P,
%   .u, .urms, .xi, .I, .prms, .spl, .omega and .steps.
%
%   Example (just-audible 4 kHz tone, p_rms = 20 uPa):
%       acoustics.particleMotion(sqrt(2)*2e-5, 4000).xi   % ~2.7e-12 m
    arguments
        P double
        f (1,1) double {mustBePositive}
        opts.rhoc (1,1) double {mustBePositive} = 415
        opts.urms double = []
        opts.pref (1,1) double {mustBePositive} = 2e-5
    end
    if isempty(P)
        assert(~isempty(opts.urms) && opts.urms >= 0, ...
            'Provide peak pressure P or rms particle velocity urms (>= 0).');
        P = sqrt(2)*opts.rhoc*opts.urms;     % peak pressure from rms velocity
    else
        assert(P >= 0, 'Pressure P must be >= 0.');
    end
    R.P = P;
    R.omega = 2*pi*f;
    R.u = P/opts.rhoc;
    R.urms = R.u/sqrt(2);
    R.xi = R.u/R.omega;
    R.I = P^2/(2*opts.rhoc);
    R.prms = P/sqrt(2);
    R.spl = 20*log10(R.prms/opts.pref);
    R.steps = { ...
        sprintf('u = P/(rho c) = %g/%g = %.4g m/s (peak)', P, opts.rhoc, R.u), ...
        sprintf('urms = u/sqrt(2) = %.4g m/s', R.urms), ...
        sprintf('xi = u/omega = u/(2*pi*f) = %.4g m', R.xi), ...
        sprintf('I = P^2/(2 rho c) = %.4g W/m^2', R.I), ...
        sprintf('prms = P/sqrt(2) = %.4g Pa', R.prms), ...
        sprintf('SPL = 20*log10(prms/pref) = 20*log10(%.4g/%.4g) = %.2f dB', ...
            R.prms, opts.pref, R.spl)};
end
