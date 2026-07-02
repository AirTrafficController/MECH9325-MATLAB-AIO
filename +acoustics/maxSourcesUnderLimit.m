function R = maxSourcesUnderLimit(N1, Ltot, Lmax)
%MAXSOURCESUNDERLIMIT  Largest number of identical sources under a limit.
%   R = ACOUSTICS.MAXSOURCESUNDERLIMIT(N1, Ltot, Lmax) where N1 identical
%   sources currently produce Ltot (dB) and Lmax is the permitted level:
%       one source: L1 = Ltot - 10*log10(N1)
%       N <= N1 * 10^((Lmax - Ltot)/10)   (rounded down)
%   R has fields .perSource (dB), .Nexact, .N (integer), .levelAtN (dB),
%   .levelAtNplus1 (dB) and .steps.
    arguments
        N1   (1,1) double {mustBePositive}
        Ltot (1,1) double
        Lmax (1,1) double
    end
    R.perSource = Ltot - 10*log10(N1);
    R.Nexact = N1 * 10^((Lmax - Ltot)/10);
    R.N = floor(R.Nexact + 1e-9);
    if R.N < 1
        R.levelAtN = NaN; R.levelAtNplus1 = NaN;
        R.steps = {sprintf('Even one source (%.2f dB) exceeds the %.4g dB limit.', ...
            R.perSource, Lmax)};
        return;
    end
    R.levelAtN = Ltot + 10*log10(R.N/N1);
    R.levelAtNplus1 = Ltot + 10*log10((R.N+1)/N1);
    R.steps = { ...
        sprintf('One source: L1 = Ltot - 10*log10(N1) = %.4g - 10*log10(%g) = %.2f dB', ...
            Ltot, N1, R.perSource), ...
        'N <= N1 * 10^((Lmax - Ltot)/10)', ...
        sprintf('= %g * 10^((%.4g - %.4g)/10) = %.3f  -> round down = %d', ...
            N1, Lmax, Ltot, R.Nexact, R.N), ...
        sprintf('Level at %d = %.2f dB (<= %.4g) · at %d = %.2f dB (over)', ...
            R.N, R.levelAtN, Lmax, R.N+1, R.levelAtNplus1)};
end
