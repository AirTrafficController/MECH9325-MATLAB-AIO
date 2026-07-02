function R = tlFromCoefficient(alphaT)
%TLFROMCOEFFICIENT  Transmission loss from a transmission coefficient.
%   R = ACOUSTICS.TLFROMCOEFFICIENT(alphaT) returns
%       TL = -10*log10(alpha_t)
%   for 0 < alpha_t <= 1. R has fields .TL (dB) and .steps.
    arguments
        alphaT (1,1) double
    end
    if ~(alphaT > 0 && alphaT <= 1)
        error('acoustics:tlFromCoefficient:range', 'alpha_t must be in (0, 1].');
    end
    R.TL = -10*log10(alphaT);
    R.steps = { ...
        'TL = -10*log10(alpha_t)', ...
        sprintf('= -10*log10(%g) = %.2f dB', alphaT, R.TL)};
end
