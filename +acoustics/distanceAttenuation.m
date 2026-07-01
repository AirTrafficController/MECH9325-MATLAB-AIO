function R = distanceAttenuation(L1, r1, r2)
%DISTANCEATTENUATION  Level at a new distance for point and line sources.
%   R = ACOUSTICS.DISTANCEATTENUATION(L1, r1, r2) propagates a level L1 (dB)
%   measured at r1 (m) out to r2 (m):
%       point (spherical, -6 dB/doubling):  L2 = L1 - 20*log10(r2/r1)
%       line  (cylindrical, -3 dB/doubling): L2 = L1 - 10*log10(r2/r1)
%   R has fields .point (dB), .line (dB) and .steps.
    arguments
        L1 (1,1) double
        r1 (1,1) double {mustBePositive}
        r2 (1,1) double {mustBePositive}
    end
    ratio = log10(r2/r1);
    R.point = L1 - 20*ratio;
    R.line  = L1 - 10*ratio;
    R.steps = { ...
        sprintf('log10(r2/r1) = log10(%g/%g) = %.4f', r2, r1, ratio), ...
        sprintf('Point: L2 = L1 - 20*log10(r2/r1) = %.4g - %.2f = %.2f dB', ...
            L1, 20*ratio, R.point), ...
        sprintf('Line:  L2 = L1 - 10*log10(r2/r1) = %.4g - %.2f = %.2f dB', ...
            L1, 10*ratio, R.line)};
end
