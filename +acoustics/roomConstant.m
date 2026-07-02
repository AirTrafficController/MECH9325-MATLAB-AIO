function R = roomConstant(alpha, S)
%ROOMCONSTANT  Room constant from average absorption and surface area.
%   R = ACOUSTICS.ROOMCONSTANT(alpha, S) returns
%       R = alpha*S / (1 - alpha)
%   for average absorption alpha (0 < alpha < 1) and total surface S (m^2).
%   R has fields .R (m^2) and .steps.
    arguments
        alpha (1,1) double
        S     (1,1) double {mustBePositive}
    end
    if ~(alpha > 0 && alpha < 1)
        error('acoustics:roomConstant:alpha', 'alpha must be between 0 and 1.');
    end
    R.R = alpha*S/(1 - alpha);
    R.steps = { ...
        'R = alpha*S / (1 - alpha)', ...
        sprintf('= %.4f*%g/(1-%.4f) = %.2f m^2', alpha, S, alpha, R.R)};
end
