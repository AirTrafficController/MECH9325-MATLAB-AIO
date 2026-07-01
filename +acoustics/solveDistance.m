function R = solveDistance(L1, L2, dr)
%SOLVEDISTANCE  Source distance from two levels a known increment apart.
%   R = ACOUSTICS.SOLVEDISTANCE(L1, L2, dr) where L1 (dB) is measured at an
%   unknown distance y and L2 (dB) a further dr (m) away, back-solves y:
%       point: y = dr / (10^(dL/20) - 1)
%       line:  y = dr / (10^(dL/10) - 1),   dL = L1 - L2
%   R has fields .point (m), .line (m), .dL (dB) and .steps.
    arguments
        L1 (1,1) double
        L2 (1,1) double
        dr (1,1) double {mustBePositive}
    end
    R.dL = L1 - L2;
    if ~(R.dL > 0)
        error('acoustics:solveDistance:order', 'Near level L1 must exceed far level L2.');
    end
    Rp = 10^(R.dL/20); Rl = 10^(R.dL/10);
    R.point = dr/(Rp - 1);
    R.line  = dr/(Rl - 1);
    R.steps = { ...
        sprintf('dL = L1 - L2 = %.4g - %.4g = %.4g dB', L1, L2, R.dL), ...
        sprintf('Point: y = dr/(10^(dL/20) - 1) = %g/(%.5g - 1) = %.3f m', dr, Rp, R.point), ...
        sprintf('Line:  y = dr/(10^(dL/10) - 1) = %g/(%.5g - 1) = %.3f m', dr, Rl, R.line)};
end
