function R = particleMotion(P, f, opts)
%PARTICLEMOTION  Particle velocity, displacement and intensity of a wave.
%   R = ACOUSTICS.PARTICLEMOTION(P, f) for a plane wave of pressure
%   amplitude P (Pa) at frequency f (Hz), with rho c = 415 rayls by default:
%       u  = P / (rho c)                 particle velocity amplitude
%       xi = u / omega,  omega = 2*pi*f  displacement amplitude
%       I  = P^2 / (2 rho c)             intensity
%   Optional 'rhoc' overrides the impedance. R has fields .u, .xi, .I,
%   .omega and .steps.
    arguments
        P (1,1) double {mustBeNonnegative}
        f (1,1) double {mustBePositive}
        opts.rhoc (1,1) double {mustBePositive} = 415
    end
    R.omega = 2*pi*f;
    R.u = P/opts.rhoc;
    R.xi = R.u/R.omega;
    R.I = P^2/(2*opts.rhoc);
    R.steps = { ...
        sprintf('u = P/(rho c) = %g/%g = %.4g m/s', P, opts.rhoc, R.u), ...
        sprintf('xi = u/omega = u/(2*pi*f) = %.4g m', R.xi), ...
        sprintf('I = P^2/(2 rho c) = %.4g W/m^2', R.I)};
end
