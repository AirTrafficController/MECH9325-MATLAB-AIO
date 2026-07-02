function R = interfaceImpedance(z1, z2)
%INTERFACEIMPEDANCE  Transmission/reflection at an impedance interface.
%   R = ACOUSTICS.INTERFACEIMPEDANCE(z1, z2) for characteristic impedances
%   z1, z2 (rayls) returns the normal-incidence coefficients:
%       r       = z2/z1
%       alpha_t = 4r / (r+1)^2       (transmitted intensity fraction)
%       alpha_r = ((r-1)/(r+1))^2    (reflected intensity fraction)
%       TL      = -10*log10(alpha_t)
%   R has fields .ratio, .alphaT, .alphaR, .TL (dB) and .steps.
    arguments
        z1 (1,1) double {mustBePositive}
        z2 (1,1) double {mustBePositive}
    end
    R.ratio = z2/z1;
    R.alphaT = 4*R.ratio/((R.ratio+1)^2);
    R.alphaR = ((R.ratio-1)/(R.ratio+1))^2;
    R.TL = -10*log10(R.alphaT);
    R.steps = { ...
        sprintf('r = z2/z1 = %.4g', R.ratio), ...
        sprintf('alpha_t = 4r/(r+1)^2 = %.4g', R.alphaT), ...
        sprintf('alpha_r = ((r-1)/(r+1))^2 = %.4f', R.alphaR), ...
        sprintf('TL = -10*log10(alpha_t) = %.2f dB', R.TL)};
end
