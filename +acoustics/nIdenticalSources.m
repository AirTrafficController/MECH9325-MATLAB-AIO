function R = nIdenticalSources(L1, N)
%NIDENTICALSOURCES  Combined level of N identical incoherent sources.
%   R = ACOUSTICS.NIDENTICALSOURCES(L1, N) returns
%       L_tot = L1 + 10*log10(N)
%   R has fields .total (dB) and .steps.
    arguments
        L1 (1,1) double
        N  (1,1) double {mustBePositive}
    end
    R.total = L1 + 10*log10(N);
    R.steps = { ...
        'L_tot = L1 + 10*log10(N)', ...
        sprintf('= %.4g + 10*log10(%g) = %.4g + %.4g = %.2f dB', ...
            L1, N, L1, 10*log10(N), R.total)};
end
