function R = soundPowerFromSurfaces(levels, areas)
%SOUNDPOWERFROMSURFACES  Sound power level from partial measurement surfaces.
%   R = ACOUSTICS.SOUNDPOWERFROMSURFACES(levels, areas) determines the sound
%   power level of a source from the sound pressure levels measured on the
%   partial areas of an enveloping surface (e.g. an imaginary cuboid around a
%   machine):
%       Lw = 10*log10( sum S_i * 10^(Li/10) )      [S0 = 1 m^2]
%          = meanLp + 10*log10(S)
%   where meanLp = 10*log10( (1/S) sum S_i 10^(Li/10) ) is the area-weighted
%   mean SPL and S = sum S_i the total surface area.
%
%   LEVELS are the per-surface SPLs (dB); use A-weighted levels to get the
%   A-weighted Lw. AREAS are the per-surface areas (m^2); pass a scalar if all
%   partial areas are equal.
%
%   R has fields .totalArea (m^2), .meanLp (dB), .Lw (dB) and .steps.
%
%   Example (six 2 m^2 faces, A-weighted SPLs):
%       acoustics.soundPowerFromSurfaces([89 87 80 95 90 87], 2).Lw   % 100.8
    arguments
        levels (1,:) double
        areas  (1,:) double {mustBePositive}
    end
    if isscalar(areas)
        areas = repmat(areas, 1, numel(levels));
    end
    if numel(areas) ~= numel(levels)
        error('acoustics:soundPowerFromSurfaces:size', ...
            'Give one area per level (or a single area for all).');
    end
    e = areas .* 10.^(levels/10);
    R.totalArea = sum(areas);
    R.meanLp = 10*log10(sum(e)/R.totalArea);
    R.Lw = 10*log10(sum(e));
    R.steps = { ...
        'Lw = 10*log10( sum S_i*10^(Li/10) ) = meanLp + 10*log10(S),  S0 = 1 m^2', ...
        sprintf('S = sum S_i = %.4g m^2', R.totalArea), ...
        sprintf('meanLp = 10*log10( (1/S) sum S_i*10^(Li/10) ) = %.2f dB', R.meanLp), ...
        sprintf('Lw = %.2f + 10*log10(%.4g) = %.2f dB', R.meanLp, R.totalArea, R.Lw)};
end
