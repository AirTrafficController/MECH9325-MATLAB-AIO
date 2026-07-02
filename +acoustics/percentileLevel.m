function R = percentileLevel(samples, N)
%PERCENTILELEVEL  Statistical level LN exceeded N% of the time.
%   R = ACOUSTICS.PERCENTILELEVEL(samples, N) returns LN, the level exceeded
%   for N% of the (equally sampled) time history in SAMPLES (dB). For
%   example N=10 gives L10 and N=90 gives L90.
%   R has fields .LN (dB) and .steps.
    arguments
        samples (1,:) double {mustBeNonempty}
        N       (1,1) double
    end
    if ~(N > 0 && N < 100)
        error('acoustics:percentileLevel:N', 'N must be between 0 and 100.');
    end
    s = sort(samples, 'descend');
    n = numel(s);
    idx = min(n, max(1, round(N/100*n)));
    R.LN = s(idx);
    R.steps = { ...
        sprintf('Sort %d samples descending; take the value at the N=%g%% rank.', n, N), ...
        sprintf('L%g = %.2f dB (exceeded %g%% of the time)', N, R.LN, N)};
end
