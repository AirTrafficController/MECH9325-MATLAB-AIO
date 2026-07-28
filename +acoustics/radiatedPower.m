function R = radiatedPower(r, opts)
%RADIATEDPOWER  Sound power radiated by a point source (from I or pressure).
%   R = ACOUSTICS.RADIATEDPOWER(r, 'I', value) integrates a measured
%   intensity over the radiating surface at distance r (m):
%       S = 4*pi*r^2 / Q,   W = I * S
%   with directivity Q (1 free field / 2 hemisphere / 4 edge / 8 corner).
%
%   R = ACOUSTICS.RADIATEDPOWER(r, 'P', value) instead takes a PEAK pressure
%   amplitude P (Pa) and first forms the intensity:
%       p_rms = P / sqrt(2),   I = p_rms^2 / (rho c)
%   with rho c = 415 rayls by default ('rhoc' overrides).
%
%   Supply exactly one of I or P. R has fields .I (W/m^2), .area (m^2),
%   .W (W), .Lw (dB re 1e-12 W) and .steps.
%
%   Example (P = 25 Pa, r = 2 m, Q = 1):
%       R = acoustics.radiatedPower(2, 'P', 25);
%       R.I    % 0.753 W/m^2
%       R.W    % 37.85 W
    arguments
        r (1,1) double {mustBePositive}
        opts.I    double = NaN
        opts.P    double = NaN
        opts.Q    (1,1) double {mustBePositive} = 1
        opts.rhoc (1,1) double {mustBePositive} = 415
    end
    C = acoustics.constants();
    hasI = ~isnan(opts.I);
    hasP = ~isnan(opts.P);
    if hasI == hasP
        error('acoustics:radiatedPower:input', 'Supply exactly one of I or P.');
    end
    steps = {};
    if hasP
        prms = opts.P/sqrt(2);
        R.I = prms^2/opts.rhoc;
        steps = { ...
            sprintf('p_rms = P/sqrt(2) = %g/sqrt(2) = %.4g Pa', opts.P, prms), ...
            sprintf('I = p_rms^2/(rho c) = %.4g^2/%g = %.4g W/m^2', prms, opts.rhoc, R.I)};
    else
        R.I = opts.I;
    end
    R.area = 4*pi*r^2/opts.Q;
    R.W = R.I*R.area;
    R.Lw = 10*log10(R.W/C.WREF);
    R.steps = [steps, { ...
        sprintf('S = 4*pi*r^2/Q = 4*pi*%g^2/%g = %.4g m^2', r, opts.Q, R.area), ...
        sprintf('W = I*S = %.4g W', R.W), ...
        sprintf('Lw = 10*log10(W/1e-12) = %.2f dB', R.Lw)}];
end
