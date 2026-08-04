function R = doublePanelTL(f, opts)
%DOUBLEPANELTL  Transmission loss of a double-leaf partition (Bies & Hansen).
%   R = ACOUSTICS.DOUBLEPANELTL(f, 'm1',m1, 'm2',m2, 'd',d) gives the normal-
%   incidence TL (dB) of TWO panels of surface mass m1, m2 (kg/m^2) separated
%   by an air gap d (m), with a sound-absorptive blanket in the cavity
%   (which suppresses cavity standing waves). f may be a vector (Hz).
%
%   The response has three regions set by two characteristic frequencies:
%       f0 = (1/2pi) sqrt[ (rho c^2 / d)(1/m1 + 1/m2) ]   mass-air-mass resonance
%       fl = 55/d   (~ c/(2 pi d))                         lower limiting freq
%
%       f < f0 :  the two leaves move together
%                 TL = 20*log10((m1+m2) f) - 42.4
%       f0 <= f < fl :
%                 TL = TL1 + TL2 + 20*log10(f d) - 29
%       f >= fl :
%                 TL = TL1 + TL2 + 6
%   where TLi = 20*log10(mi f) - 42.4 is each leaf's mass law.
%
%   Options: 'rho' (1.21), 'c' (343), 'constant' (42.4 dB mass-law term).
%   R has fields .f, .TL (dB, same size as f), .f0, .fl, .region (string per f)
%   and .steps.
%
%   Example (two 16 kg/m^2 panels 100 mm apart, blanket in cavity):
%       R = acoustics.doublePanelTL([100 300 1000], 'm1',16,'m2',16,'d',0.1);
%       R.TL      % [34.4  63.0  89.4] dB
    arguments
        f double {mustBePositive}
        opts.m1 (1,1) double {mustBePositive}
        opts.m2 (1,1) double {mustBePositive}
        opts.d  (1,1) double {mustBePositive}
        opts.rho (1,1) double {mustBePositive} = 1.21
        opts.c   (1,1) double {mustBePositive} = 343
        opts.constant (1,1) double = 42.4
    end
    m1 = opts.m1; m2 = opts.m2; d = opts.d; K = opts.constant;
    rhoc2 = opts.rho*opts.c^2;

    R.f0 = (1/(2*pi))*sqrt((rhoc2/d)*(1/m1 + 1/m2));
    R.fl = 55/d;

    f = f(:).';
    R.f = f;
    TL1 = 20*log10(m1*f) - K;
    TL2 = 20*log10(m2*f) - K;
    R.TL = zeros(size(f));
    R.region = strings(size(f));
    for i = 1:numel(f)
        if f(i) < R.f0
            R.TL(i) = 20*log10((m1+m2)*f(i)) - K;
            R.region(i) = "f<f0 (masses move together)";
        elseif f(i) < R.fl
            R.TL(i) = TL1(i) + TL2(i) + 20*log10(f(i)*d) - 29;
            R.region(i) = "f0<f<fl (mid: +20log(fd)-29)";
        else
            R.TL(i) = TL1(i) + TL2(i) + 6;
            R.region(i) = "f>fl (high: TL1+TL2+6)";
        end
    end

    lines = { ...
        sprintf('rho c^2 = %.6g Pa', rhoc2), ...
        sprintf('f0 = (1/2pi) sqrt[(rho c^2/d)(1/m1+1/m2)] = %.1f Hz', R.f0), ...
        sprintf('fl = 55/d = %.1f Hz', R.fl), ...
        'Leaf mass law: TLi = 20*log10(mi f) - 42.4', ''};
    for i = 1:numel(f)
        lines{end+1} = sprintf('f = %g Hz  [%s]', f(i), R.region(i)); %#ok<AGROW>
        lines{end+1} = sprintf('   TL1 = %.2f, TL2 = %.2f  ->  TL = %.1f dB', ...
            TL1(i), TL2(i), R.TL(i)); %#ok<AGROW>
    end
    R.steps = lines;
end
