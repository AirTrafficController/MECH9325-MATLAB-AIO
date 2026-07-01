function R = panelResonance(K, M)
%PANELRESONANCE  Fundamental resonance frequency of a mass-spring panel.
%   R = ACOUSTICS.PANELRESONANCE(K, M) with stiffness per unit area
%   K (N/m^3) and surface mass M (kg/m^2) returns:
%       fn = (1/2pi) * sqrt(K/M)
%   R has fields .fn (Hz) and .steps.
    arguments
        K (1,1) double {mustBePositive}
        M (1,1) double {mustBePositive}
    end
    R.fn = sqrt(K/M)/(2*pi);
    R.steps = { ...
        'fn = (1/2pi)*sqrt(K/M)', ...
        sprintf('= (1/2pi)*sqrt(%g/%g) = %.2f Hz', K, M, R.fn)};
end
