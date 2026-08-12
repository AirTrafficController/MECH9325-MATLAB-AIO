function R = radiatedPower(r, opts)
%RADIATEDPOWER  Point-source radiation relations at a distance (both ways).
%   Give exactly ONE of the source quantities and get the full set at
%   distance r (m) for directivity Q (1 free field / 2 hemisphere / 4 edge /
%   8 corner):
%       R = ACOUSTICS.RADIATEDPOWER(r, 'W', value)  % sound POWER (W)  -> p,SPL,I,SIL
%       R = ACOUSTICS.RADIATEDPOWER(r, 'I', value)  % intensity (W/m^2)
%       R = ACOUSTICS.RADIATEDPOWER(r, 'P', value)  % PEAK pressure (Pa)
%
%   Relations (rho c = 415 rayls by default, 'rhoc' overrides):
%       S = 4*pi*r^2 / Q        (radiating area)
%       from P:  p_rms = P/sqrt(2),  I = p_rms^2/(rho c)
%       from W:  I = W / S
%       p_rms = sqrt(I*rho c),  W = I*S
%       SPL = 20*log10(p_rms/2e-5),  SIL = 10*log10(I/1e-12),  Lw = 10*log10(W/1e-12)
%
%   R has fields .I, .prms, .spl, .sil, .area, .W, .Lw and .steps.
%
%   Example (W = 1.04 W, r = 0.17 m, Q = 1):
%       R = acoustics.radiatedPower(0.17,'W',1.04);
%       R.prms  % 34.47 Pa      R.spl % 124.73 dB
%       R.I     % 2.864 W/m^2   R.sil % 124.57 dB
%   Example (P = 25 Pa, r = 2 m, Q = 1):
%       R = acoustics.radiatedPower(2,'P',25);  R.I % 0.753   R.W % 37.85
    arguments
        r (1,1) double {mustBePositive}
        opts.W    double = NaN
        opts.I    double = NaN
        opts.P    double = NaN
        opts.Q    (1,1) double {mustBePositive} = 1
        opts.rhoc (1,1) double {mustBePositive} = 415
    end
    C = acoustics.constants();
    given = [~isnan(opts.W), ~isnan(opts.I), ~isnan(opts.P)];
    if sum(given) ~= 1
        error('acoustics:radiatedPower:input', 'Supply exactly one of W, I or P.');
    end
    R.area = 4*pi*r^2/opts.Q;
    steps = { sprintf('S = 4*pi*r^2/Q = 4*pi*%g^2/%g = %.4g m^2', r, opts.Q, R.area) };
    if ~isnan(opts.P)
        prms = opts.P/sqrt(2);
        R.I  = prms^2/opts.rhoc;
        steps = [{ ...
            sprintf('p_rms = P/sqrt(2) = %g/sqrt(2) = %.4g Pa', opts.P, prms), ...
            sprintf('I = p_rms^2/(rho c) = %.4g^2/%g = %.4g W/m^2', prms, opts.rhoc, R.I)}, steps];
    elseif ~isnan(opts.W)
        R.I = opts.W/R.area;
        steps{end+1} = sprintf('I = W/S = %g/%.4g = %.4g W/m^2', opts.W, R.area, R.I);
    else
        R.I = opts.I;
    end
    R.prms = sqrt(R.I*opts.rhoc);
    R.W    = R.I*R.area;
    R.spl  = 20*log10(R.prms/C.PREF);
    R.sil  = 10*log10(R.I/C.IREF);
    R.Lw   = 10*log10(R.W/C.WREF);
    R.steps = [steps, { ...
        sprintf('p_rms = sqrt(I*rho c) = sqrt(%.4g*%g) = %.4g Pa', R.I, opts.rhoc, R.prms), ...
        sprintf('SPL = 20*log10(p_rms/2e-5) = %.2f dB', R.spl), ...
        sprintf('I   = %.4g W/m^2   SIL = 10*log10(I/1e-12) = %.2f dB', R.I, R.sil), ...
        sprintf('W = I*S = %.4g W   Lw = 10*log10(W/1e-12) = %.2f dB', R.W, R.Lw)}];
end
