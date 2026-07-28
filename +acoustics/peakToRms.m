function R = peakToRms(P, components)
%PEAKTORMS  Peak-to-RMS pressure and quadrature combination of tones.
%   R = ACOUSTICS.PEAKTORMS(P) converts a peak pressure amplitude to RMS:
%       p_rms = P / sqrt(2)
%   R = ACOUSTICS.PEAKTORMS(P, components) also combines a vector of
%   component RMS pressures on a quadrature (energy) basis:
%       p_tot = sqrt( sum p_i^2 )
%   R has fields .prms (Pa), .splRms (dB), and when components are given
%   .ptot (Pa) and .splTot (dB), plus .steps.
    arguments
        P (1,1) double {mustBeNonnegative}
        components (1,:) double = []
    end
    C = acoustics.constants();
    R.prms = P/sqrt(2);
    R.splRms = 20*log10(R.prms/C.PREF);
    R.steps = { ...
        'p_rms = P / sqrt(2)', ...
        sprintf('= %g / sqrt(2) = %.4g Pa  ->  SPL = %.2f dB', P, R.prms, R.splRms)};
    if ~isempty(components)
        sumSq = sum(components.^2);
        R.ptot = sqrt(sumSq);
        R.splTot = 20*log10(R.ptot/C.PREF);
        terms = strjoin(arrayfun(@(x) sprintf('%.4g^2', x), components, ...
            'UniformOutput', false), ' + ');
        R.steps = [R.steps, { ...
            'p_tot = sqrt( sum p_i^2 )', ...
            sprintf('= sqrt( %s ) = sqrt(%.4g) = %.4g Pa', terms, sumSq, R.ptot), ...
            sprintf('SPL_tot = 20*log10(%.4g / 2e-5) = %.2f dB', R.ptot, R.splTot)}];
    end
end
