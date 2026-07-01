function R = averageAbsorption(areas, alphas)
%AVERAGEABSORPTION  Area-weighted mean absorption coefficient.
%   R = ACOUSTICS.AVERAGEABSORPTION(areas, alphas) with equal-length vectors
%   of surface areas (m^2) and their absorption coefficients returns:
%       alpha_bar = sum(alpha_i * S_i) / sum(S_i)
%   R has fields .alphaBar, .totalArea (m^2), .totalAbsorption (m^2) and .steps.
    arguments
        areas  (1,:) double {mustBeNonnegative}
        alphas (1,:) double {mustBeNonnegative}
    end
    if numel(areas) ~= numel(alphas)
        error('acoustics:averageAbsorption:size', 'areas and alphas must match.');
    end
    num = sum(areas .* alphas);
    den = sum(areas);
    if den == 0
        error('acoustics:averageAbsorption:area', 'Total area is zero.');
    end
    R.alphaBar = num/den;
    R.totalArea = den;
    R.totalAbsorption = num;
    R.steps = { ...
        'alpha_bar = sum(alpha_i*S_i) / sum(S_i)', ...
        sprintf('= %.3f / %.1f = %.4f', num, den, R.alphaBar)};
end
