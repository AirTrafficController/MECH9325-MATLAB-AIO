function R = ductBandPower(freqs, Lp, d, opts)
%DUCTBANDPOWER  Plane-wave sound power radiated from a long pipe/duct.
%   R = ACOUSTICS.DUCTBANDPOWER(freqs, Lp, d) for a long pipe (no reflected
%   waves) of internal diameter d (m), given the octave-band sound pressure
%   levels Lp (dB), computes per band:
%       (i)   p_rms = p_ref * 10^(Lp/20)              (Pa)
%       (ii)  I     = p_rms^2 / (rho c)               (W/m^2)
%       (iii) W     = I * A,   A = pi*d^2/4           (W)   [pipe cross-section]
%   and the totals:
%       (iv)  Lp_total = 10*log10( sum 10^(Lp/10) )   (dB)
%       (v)   Lw_total = 10*log10( sum W / W_ref )    (dB re 1e-12 W)
%
%   Uses the EXACT rho c = rho*c (defaults rho = 1.21 kg/m^3, c = 343 m/s;
%   override with 'rho' / 'c'). d is in metres (e.g. 0.086 for an 86 mm pipe).
%
%   R has fields .prms, .I, .W (1xB), .area, .LpTotal, .Wtotal, .LwTotal, .steps.
%
%   Example (86 mm pipe):
%       R = acoustics.ductBandPower([125 250 500 1000], [106 105 105 94], 0.086);
%       R.LwTotal   % 87.72 dB
    arguments
        freqs (1,:) double {mustBePositive}
        Lp    (1,:) double
        d     (1,1) double {mustBePositive}
        opts.rho (1,1) double {mustBePositive} = 1.21
        opts.c   (1,1) double {mustBePositive} = 343
    end
    if numel(freqs) ~= numel(Lp)
        error('acoustics:ductBandPower:size', 'freqs and Lp must match.');
    end
    C = acoustics.constants();
    rhoc = opts.rho*opts.c;
    R.area = pi*d^2/4;
    R.prms = C.PREF * 10.^(Lp/20);          % (i)
    R.I    = R.prms.^2 / rhoc;              % (ii)
    R.W    = R.I * R.area;                  % (iii)
    R.LpTotal = 10*log10(sum(10.^(Lp/10))); % (iv)
    R.Wtotal  = sum(R.W);
    R.LwTotal = 10*log10(R.Wtotal/C.WREF);  % (v)

    R.steps = { ...
        'LONG PIPE / DUCT, plane waves (no reflected waves)', ...
        sprintf('rho c = %.2f rayls · A = pi*d^2/4 = %.5g m^2', rhoc, R.area), ...
        'p_rms = p_ref*10^(Lp/20) · I = p_rms^2/(rho c) · W = I*A', ...
        '', ...
        ['(i)   p_rms (Pa):     ' rowStr(freqs, R.prms, '%.3f')], ...
        ['(ii)  I (W/m^2):      ' rowStr(freqs, R.I,    '%.4g')], ...
        ['(iii) W (W):          ' rowStr(freqs, R.W,    '%.4g')], ...
        '', ...
        sprintf('(iv) Total Lp = 10*log10(sum 10^(Lp/10))   = %.2f dB', R.LpTotal), ...
        sprintf('(v)  Total Lw = 10*log10(sum W / 1e-12)    = %.2f dB', R.LwTotal)};
end

function s = rowStr(freqs, vals, fmt)
    parts = arrayfun(@(j) sprintf(['%g Hz ' fmt], freqs(j), vals(j)), ...
        1:numel(freqs), 'UniformOutput', false);
    s = strjoin(parts, '   ');
end
