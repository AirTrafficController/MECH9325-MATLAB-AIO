function R = waveRelation(opts)
%WAVERELATION  Solve c = f*lambda for whichever term is missing.
%   R = ACOUSTICS.WAVERELATION('c',..,'f',..) etc. Supply exactly two of
%   c (m/s), f (Hz), lambda (m); the third is solved from c = f*lambda.
%   R also reports period T, angular frequency omega and wavenumber k.
%   R has fields .c, .f, .lambda, .T, .omega, .k and .steps.
%
%   Example:
%       acoustics.waveRelation('c',343,'f',1000).lambda   % 0.343 m
    arguments
        opts.c      double = NaN
        opts.f      double = NaN
        opts.lambda double = NaN
    end
    c = opts.c; f = opts.f; lam = opts.lambda;
    known = ~isnan(c) + ~isnan(f) + ~isnan(lam);
    if known < 2
        error('acoustics:waveRelation:input', ...
            'Supply at least two of c, f, lambda.');
    end
    if isnan(c),   c = f*lam;
    elseif isnan(f),   f = c/lam;
    elseif isnan(lam), lam = c/f;
    end
    R.c = c; R.f = f; R.lambda = lam;
    R.T = 1/f; R.omega = 2*pi*f; R.k = 2*pi/lam;
    R.steps = { ...
        sprintf('c = f*lambda  ->  c = %.3f m/s, f = %.3f Hz, lambda = %.4f m', c, f, lam), ...
        sprintf('T = 1/f = %.4g s', R.T), ...
        sprintf('omega = 2*pi*f = %.1f rad/s', R.omega), ...
        sprintf('k = 2*pi/lambda = %.3f rad/m', R.k)};
end
