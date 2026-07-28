function R = psdToRms(f1, f2, S1, S2)
%PSDTORMS  RMS pressure and SPL from a power spectral density band.
%   R = ACOUSTICS.PSDTORMS(f1, f2, S1, S2) integrates a straight-line PSD
%   segment (Pa^2/Hz) between f1 and f2 (Hz) using the trapezoidal rule:
%       p_rms^2 = 1/2 (S1 + S2)(f2 - f1)
%       SPL     = 20*log10(p_rms / p_ref)
%   R has fields .meanSquare (Pa^2), .prms (Pa), .spl (dB) and .steps.
    arguments
        f1 (1,1) double {mustBeNonnegative}
        f2 (1,1) double {mustBeNonnegative}
        S1 (1,1) double {mustBeNonnegative}
        S2 (1,1) double {mustBeNonnegative}
    end
    if ~(f2 > f1)
        error('acoustics:psdToRms:band', 'Upper frequency must exceed lower frequency.');
    end
    C = acoustics.constants();
    bw = f2 - f1;
    R.meanSquare = (S1 + S2)/2 * bw;
    R.prms = sqrt(R.meanSquare);
    R.spl = 20*log10(R.prms/C.PREF);
    R.steps = { ...
        sprintf('p_rms^2 = 1/2 (S1+S2)(f2-f1) = 1/2 (%.4g + %.4g)(%.4g)', S1, S2, bw), ...
        sprintf('= %.4g Pa^2', R.meanSquare), ...
        sprintf('p_rms = sqrt(%.4g) = %.4g Pa', R.meanSquare, R.prms), ...
        sprintf('SPL = 20*log10(%.4g / 2e-5) = %.2f dB', R.prms, R.spl)};
end
