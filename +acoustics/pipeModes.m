function R = pipeModes(L, opts)
%PIPEMODES  Natural frequencies of a pipe (any end condition).
%   R = ACOUSTICS.PIPEMODES(L) returns the first natural frequencies of a
%   pipe of length L (m). The 'ends' option selects the boundary condition:
%       "open-closed"    (default)  f_n = (2n-1) c / (4L),  n = 1,2,3,...
%       "open-open"                 f_n =    n   c / (2L)
%       "closed-closed"             f_n =    n   c / (2L)
%   Optional 'c' (default 343 m/s) and 'n' (default 4 modes). R has fields
%   .f (vector, Hz), .omega (vector, rad/s) and .steps. End effects neglected.
%
%   Example (5 m pipe open at both ends):
%       acoustics.pipeModes(5, 'ends', "open-open", 'n', 3).omega
%       % [215.5  431.0  646.5] rad/s
    arguments
        L (1,1) double {mustBePositive}
        opts.c (1,1) double {mustBePositive} = 343
        opts.n (1,1) double {mustBePositive, mustBeInteger} = 4
        opts.ends (1,1) string ...
            {mustBeMember(opts.ends, ["open-closed","open-open","closed-closed"])} = "open-closed"
    end
    n = 1:opts.n;
    if opts.ends == "open-closed"
        R.f = (2*n - 1)*opts.c/(4*L);
        header = 'Open-closed pipe:  f_n = (2n-1) c / (4L)';
        expr = @(k) sprintf('f%d = (2*%d-1)*c/(4L) = %.1f Hz  (w = %.1f rad/s)', ...
            k, k, R.f(k), 2*pi*R.f(k));
    else
        R.f = n*opts.c/(2*L);
        if opts.ends == "open-open"
            header = 'Open-open pipe:  f_n = n c / (2L)';
        else
            header = 'Closed-closed pipe:  f_n = n c / (2L)';
        end
        expr = @(k) sprintf('f%d = %d*c/(2L) = %.1f Hz  (w = %.1f rad/s)', ...
            k, k, R.f(k), 2*pi*R.f(k));
    end
    R.omega = 2*pi*R.f;
    R.steps = [{header}, arrayfun(expr, n, 'UniformOutput', false)];
end
