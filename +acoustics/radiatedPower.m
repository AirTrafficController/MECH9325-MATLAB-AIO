function R = radiatedPower(I, r, opts)
%RADIATEDPOWER  Sound power radiated through a spherical/partial surface.
%   R = ACOUSTICS.RADIATEDPOWER(I, r) returns the power passing through a
%   full sphere of radius r for intensity I:  W = I * 4*pi*r^2.
%   R = ACOUSTICS.RADIATEDPOWER(I, r, 'Q', Q) divides the sphere by the
%   directivity factor Q (Q=1 free field, 2 ground, 4 edge, 8 corner):
%       W = I * 4*pi*r^2 / Q
%   R has fields .W (W), .Lw (dB re 1e-12 W), .area (m^2) and .steps.
    arguments
        I (1,1) double {mustBePositive}
        r (1,1) double {mustBePositive}
        opts.Q (1,1) double {mustBePositive} = 1
    end
    C = constants();
    R.area = 4*pi*r^2 / opts.Q;
    R.W = I * R.area;
    R.Lw = 10*log10(R.W/C.WREF);
    R.steps = { ...
        'W = I * 4*pi*r^2 / Q', ...
        sprintf('= %.4g * 4*pi*%g^2 / %g = %.4g W', I, r, opts.Q, R.W), ...
        sprintf('Lw = 10*log10(W / 1e-12) = %.2f dB', R.Lw)};
end
