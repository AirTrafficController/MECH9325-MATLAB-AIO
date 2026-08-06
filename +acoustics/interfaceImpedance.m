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
%   Give the incident wave amplitude EITHER as a peak pressure ('p0', Pa) OR
%   as a sound pressure level ('Lp', dB re 2e-5 Pa); with 'Lp' the incident
%   PEAK amplitude is p0 = sqrt(2)*2e-5*10^(Lp/20). Then:
%       pTrans     = Tp * p0          transmitted pressure amplitude (Pa)
%       pInterface = pTrans           total pressure at the interface (Pa)
%                                     (= incident+reflected, by continuity)
%       uTrans     = pTrans / z2      transmitted particle velocity amp (m/s)
%       pRefl      = Rp * p0          reflected pressure amplitude (Pa)
%
%   R has fields .ratio, .alphaT, .alphaR, .TL, .Tp, .Rp and (if p0/Lp given)
%   .pIncident, .pInterface, .pTrans, .uTrans, .pRefl, plus .steps.
%
%   Example (107 dB, 1000 Hz, air onto water; z1=415, z2=1.5e6):
%       R = acoustics.interfaceImpedance(1.21*343, 1000*1500, 'Lp', 107);
%       R.pIncident  % 6.33 Pa (peak)   R.pInterface % 12.66 Pa
%       R.uTrans     % 8.44e-6 m/s      R.alphaT     % 0.00111
    arguments
        z1 (1,1) double {mustBePositive}
        z2 (1,1) double {mustBePositive}
        opts.p0 (1,1) double {mustBeNonnegative} = NaN
        opts.Lp (1,1) double = NaN
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
    p0 = opts.p0;
    if ~isnan(opts.Lp)
        prms = 2e-5 * 10^(opts.Lp/20);
        p0 = sqrt(2) * prms;                 % incident PEAK amplitude
        R.steps = [R.steps, { ...
            sprintf('p_rms = 2e-5*10^(Lp/20) = 2e-5*10^(%.4g/20) = %.4g Pa', opts.Lp, prms), ...
            sprintf('(a) incident peak p0 = sqrt(2)*p_rms = %.4g Pa', p0)}];
    end
    if ~isnan(p0)
        R.pIncident  = p0;
        R.pTrans     = R.Tp * p0;
        R.pInterface = R.pTrans;             % total at interface = transmitted
        R.uTrans     = R.pTrans / z2;
        R.pRefl      = R.Rp * p0;
        R.steps = [R.steps, { ...
            sprintf('(b) total pressure at interface = Tp*p0 = %.6g Pa', R.pInterface), ...
            sprintf('(c) transmitted pressure in medium 2 = %.6g Pa  (= b, continuity)', R.pTrans), ...
            sprintf('(d) uTrans = pTrans/z2 = %.6g / %.6g = %.4g m/s', R.pTrans, z2, R.uTrans), ...
            sprintf('(e) sound transmission coeff alpha_t = %.4g', R.alphaT), ...
            sprintf('    reflected pressure pRefl = Rp*p0 = %.6g Pa', R.pRefl)}];
    end
end
