function R = mufflerAreaChange(S1, S2)
%MUFFLERAREACHANGE  Transmission loss of a sudden cross-section change.
%   R = ACOUSTICS.MUFFLERAREACHANGE(S1, S2) for a pipe of area S1 (m^2)
%   opening into an area S2 (m^2):
%       Tt = 4*S1*S2 / (S1+S2)^2       (transmitted power fraction)
%       TL = -10*log10(Tt)
%   R has fields .Tt, .TL (dB) and .steps.
    arguments
        S1 (1,1) double {mustBePositive}
        S2 (1,1) double {mustBePositive}
    end
    R.Tt = 4*S1*S2/((S1+S2)^2);
    R.TL = -10*log10(R.Tt);
    R.steps = { ...
        'Tt = 4*S1*S2 / (S1+S2)^2', ...
        sprintf('= %.4g / %.4g = %.4g', 4*S1*S2, (S1+S2)^2, R.Tt), ...
        sprintf('TL = -10*log10(Tt) = %.2f dB', R.TL)};
end
