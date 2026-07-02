function R = pipeModes(L, opts)
%PIPEMODES  Natural frequencies of a closed-open (quarter-wave) pipe.
%   R = ACOUSTICS.PIPEMODES(L) returns the first natural frequencies of a
%   pipe of length L (m) closed at one end and open at the other:
%       f_n = (2n-1) c / (4 L),   n = 1,2,3,...
%   Optional 'c' (default 343 m/s) and 'n' (default 4 modes). R has fields
%   .f (vector, Hz) and .steps.
    arguments
        L (1,1) double {mustBePositive}
        opts.c (1,1) double {mustBePositive} = 343
        opts.n (1,1) double {mustBePositive, mustBeInteger} = 4
    end
    n = 1:opts.n;
    R.f = (2*n - 1)*opts.c/(4*L);
    R.steps = arrayfun(@(k) sprintf('f%d = (2*%d-1)*c/(4L) = %.1f Hz', ...
        k, k, R.f(k)), n, 'UniformOutput', false);
    R.steps = [{'Closed-open pipe:  f_n = (2n-1) c / (4L)'}, R.steps];
end
