function R = interfaceImpedance(z1, z2, opts)
%INTERFACEIMPEDANCE  Transmission/reflection at a normal-incidence interface.
%   R = ACOUSTICS.INTERFACEIMPEDANCE(z1, z2) for characteristic impedances
%   z1 (incident medium) and z2 (second medium) in rayls returns:
%       r       = z2/z1
%       alpha_t = 4r / (r+1)^2       (transmitted intensity/power fraction)
%       alpha_r = ((r-1)/(r+1))^2    (reflected intensity fraction)
%       TL      = -10*log10(alpha_t)
%       Tp      = 2 z2/(z1+z2)        (pressure amplitude transmission coeff)
%       Rp      = (z2-z1)/(z1+z2)     (pressure amplitude reflection coeff)
%
%   R = ACOUSTICS.INTERFACEIMPEDANCE(z1, z2, 'p0', p0) also uses the incident
%   pressure amplitude p0 (Pa) to give the transmitted wave in medium 2:
%       pTrans = Tp * p0             transmitted pressure amplitude (Pa)
%       uTrans = pTrans / z2         transmitted particle velocity amp (m/s)
%       pRefl  = Rp * p0             reflected pressure amplitude (Pa)
%
%   R has fields .ratio, .alphaT, .alphaR, .TL, .Tp, .Rp and (if p0 given)
%   .pTrans, .uTrans, .pRefl, plus .steps.
%
%   Example (939 Hz, 17 Pa in air onto water; z1=415, z2=1.48e6):
%       R = acoustics.interfaceImpedance(1.21*343, 1000*1480, 'p0', 17);
%       R.pTrans   % 33.99 Pa    R.uTrans % 2.297e-5 m/s (0.023 mm/s)
%       R.alphaT   % 0.00112
    arguments
        z1 (1,1) double {mustBePositive}
        z2 (1,1) double {mustBePositive}
        opts.p0 (1,1) double {mustBeNonnegative} = NaN
    end
    R.ratio = z2/z1;
    R.alphaT = 4*R.ratio/((R.ratio+1)^2);
    R.alphaR = ((R.ratio-1)/(R.ratio+1))^2;
    R.TL = -10*log10(R.alphaT);
    R.Tp = 2*z2/(z1+z2);
    R.Rp = (z2-z1)/(z1+z2);
    R.steps = { ...
        sprintf('r = z2/z1 = %.6g / %.6g = %.6g', z2, z1, R.ratio), ...
        sprintf('Tp = 2 z2/(z1+z2) = %.6g   (pressure transmission coeff)', R.Tp), ...
        sprintf('Rp = (z2-z1)/(z1+z2) = %.6g (pressure reflection coeff)', R.Rp), ...
        sprintf('alpha_t = 4r/(r+1)^2 = %.6g  (sound/power transmission coeff)', R.alphaT), ...
        sprintf('alpha_r = ((r-1)/(r+1))^2 = %.6g', R.alphaR), ...
        sprintf('TL = -10*log10(alpha_t) = %.2f dB', R.TL)};
    if ~isnan(opts.p0)
        R.pTrans = R.Tp * opts.p0;
        R.uTrans = R.pTrans / z2;
        R.pRefl  = R.Rp * opts.p0;
        R.steps = [R.steps, { ...
            sprintf('pTrans = Tp * p0 = %.6g * %.6g = %.6g Pa', R.Tp, opts.p0, R.pTrans), ...
            sprintf('uTrans = pTrans / z2 = %.6g / %.6g = %.4g m/s = %.4g mm/s', ...
                R.pTrans, z2, R.uTrans, R.uTrans*1000), ...
            sprintf('pRefl  = Rp * p0 = %.6g Pa', R.pRefl)}];
    end
end
