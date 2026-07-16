function R = ductBandPower(Lp, d_mm, opts)
%DUCTBANDPOWER  Intensity and radiated power from band SPLs in a duct.
%   R = ACOUSTICS.DUCTBANDPOWER(Lp, d_mm) for a circular duct of diameter
%   d_mm (mm) carrying plane waves (no reflections), given a vector of band
%   sound pressure levels Lp (dB re 20 uPa):
%       A     = pi*d^2/4
%       p_rms = p_ref*10^(Lp/20)     (per band)
%       I     = p_rms^2/(rho c)      (per band)
%       W     = I*A                  (per band)
%   Totals:
%       LpTotal = 10*log10( sum 10^(Lp/10) )
%       LwTotal = 10*log10( sum(W) / W_ref )
%
%   This is the duct (plane-wave) counterpart to RADIATEDPOWER: power is
%   intensity times the cross-section, not a point source spreading into
%   4*pi*r^2. Optional 'rho' (1.21 kg/m^3) and 'c' (343 m/s). R has fields
%   .area, .prms, .I, .W (vectors), .LpTotal, .Wtotal, .LwTotal and .steps.
%
%   Example (86 mm pipe, four octave bands):
%       acoustics.ductBandPower([106 105 105 94], 86).LwTotal   % 87.72 dB
    arguments
        Lp double {mustBeVector}
        d_mm (1,1) double {mustBePositive}
        opts.rho (1,1) double {mustBePositive} = 1.21
        opts.c   (1,1) double {mustBePositive} = 343
    end
    C = constants();
    d = d_mm/1000;
    rc = opts.rho*opts.c;
    Lp = Lp(:).';                        % row vector
    R.area = pi*d^2/4;
    R.prms = C.PREF*10.^(Lp/20);
    R.I = R.prms.^2/rc;
    R.W = R.I*R.area;
    R.LpTotal = 10*log10(sum(10.^(Lp/10)));
    R.Wtotal = sum(R.W);
    R.LwTotal = 10*log10(R.Wtotal/C.WREF);

    steps = { ...
        sprintf('A = pi*d^2/4 = pi*(%.4g)^2/4 = %.4g m^2', d, R.area), ...
        sprintf('rho c = %.4g*%.4g = %.4g rayls', opts.rho, opts.c, rc)};
    for i = 1:numel(Lp)
        steps{end+1} = sprintf(['Lp=%.1f dB: p_rms = p_ref*10^(Lp/20) = %.4g Pa, ', ...
            'I = p_rms^2/rho c = %.4g W/m^2, W = I*A = %.4g W'], ...
            Lp(i), R.prms(i), R.I(i), R.W(i)); %#ok<AGROW>
    end
    steps{end+1} = sprintf('Lp_total = 10*log10(sum 10^(Lp/10)) = %.2f dB', R.LpTotal);
    steps{end+1} = sprintf('sum W = %.4g W -> Lw_total = 10*log10(sumW/W_ref) = %.2f dB', ...
        R.Wtotal, R.LwTotal);
    R.steps = steps;
end
