function R = pipeModes(L, opts)
%PIPEMODES  Natural (resonant) frequencies of an air column in a pipe.
%   R = ACOUSTICS.PIPEMODES(L) returns the first natural frequencies of a pipe
%   of length L (m). The end conditions set the formula ('ends' option):
%       "closed-open"    (quarter-wave)  f_n = (2n-1) c / (4L)   n = 1,2,3...
%       "open-open"      (half-wave)      f_n =  n c / (2L)
%       "closed-closed"  (half-wave)      f_n =  n c / (2L)
%   The default is "closed-open". Optional 'c' (343 m/s) and 'n' (3 modes).
%
%   R has fields:
%       .f      natural frequencies (Hz, 1xn)
%       .omega  angular frequencies (rad/s, 1xn)
%       .nodesFundamental  x-position(s) of the pressure node(s) of the
%                          fundamental mode (m): centre L/2 for closed-closed,
%                          the open end(s) otherwise
%       .steps
%
%   Example (2 m pipe closed at both ends):
%       R = acoustics.pipeModes(2, 'ends', "closed-closed");
%       R.omega            % [538.8 1077.6 1616.3] rad/s
%       R.nodesFundamental % 1  (pressure node at the centre)
    arguments
        L (1,1) double {mustBePositive}
        opts.c (1,1) double {mustBePositive} = 343
        opts.n (1,1) double {mustBePositive, mustBeInteger} = 3
        opts.ends (1,1) string ...
            {mustBeMember(opts.ends,["closed-open","open-open","closed-closed"])} = "closed-open"
    end
    n = 1:opts.n;
    switch opts.ends
        case "closed-open"
            R.f = (2*n - 1)*opts.c/(4*L);
            rel = 'f_n = (2n-1) c / (4L)';
            R.nodesFundamental = L;             % pressure node at the open end
        otherwise                                % open-open / closed-closed
            R.f = n*opts.c/(2*L);
            rel = 'f_n = n c / (2L)';
            if opts.ends == "closed-closed"
                R.nodesFundamental = L/2;        % pressure node at the centre
            else
                R.nodesFundamental = [0 L];      % pressure nodes at the open ends
            end
    end
    R.omega = 2*pi*R.f;

    lines = {sprintf('%s pipe:  %s  (omega = 2*pi*f)', opts.ends, rel)};
    for k = n
        lines{end+1} = sprintf('  f%d = %.2f Hz   omega%d = %.1f rad/s', ...
            k, R.f(k), k, R.omega(k)); %#ok<AGROW>
    end
    lines{end+1} = sprintf('Fundamental pressure node(s) at x = %s m', ...
        strjoin(arrayfun(@(x) sprintf('%.3g', x), R.nodesFundamental, ...
        'UniformOutput', false), ', '));
    R.steps = lines;
end
