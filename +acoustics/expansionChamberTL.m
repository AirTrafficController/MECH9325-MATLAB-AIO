function R = expansionChamberTL(S1, S2, L, f, opts)
%EXPANSIONCHAMBERTL  Transmission loss of a simple expansion chamber.
%   R = ACOUSTICS.EXPANSIONCHAMBERTL(S1, S2, L, f) for a chamber of area
%   S2 (m^2) and length L (m) between pipes of area S1 (m^2) at frequency
%   f (Hz):
%       m  = S2/S1,   kL = 2*pi*f/c * L
%       TL = 10*log10[ cos^2(kL) + 1/4 (m + 1/m)^2 sin^2(kL) ]
%   Optional 'c' (default 343 m/s). R has fields .m, .kL (rad), .TL (dB),
%   .lambda (m) and .steps.
    arguments
        S1 (1,1) double {mustBePositive}
        S2 (1,1) double {mustBePositive}
        L  (1,1) double {mustBePositive}
        f  (1,1) double {mustBePositive}
        opts.c (1,1) double {mustBePositive} = 343
    end
    R.m = S2/S1;
    R.kL = 2*pi*f/opts.c*L;
    R.TL = 10*log10(cos(R.kL)^2 + 0.25*(R.m + 1/R.m)^2*sin(R.kL)^2);
    R.lambda = opts.c/f;
    R.steps = { ...
        sprintf('m = S2/S1 = %.2f', R.m), ...
        sprintf('kL = 2*pi*f/c*L = %.3f rad', R.kL), ...
        'TL = 10*log10[ cos^2(kL) + 1/4 (m+1/m)^2 sin^2(kL) ]', ...
        sprintf('= %.2f dB   (lambda = %.3f m, lambda/4 = %.3f m)', R.TL, R.lambda, R.lambda/4)};
end
