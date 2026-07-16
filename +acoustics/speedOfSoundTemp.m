function R = speedOfSoundTemp(Tc, opts)
%SPEEDOFSOUNDTEMP  Speed of sound in a gas from temperature (or the inverse).
%   R = ACOUSTICS.SPEEDOFSOUNDTEMP(Tc) returns the speed of sound in air at
%   Tc degrees Celsius:
%       T0 = Tc + 273.2 (K),   c = sqrt(gamma*R*T0)
%
%   Leave Tc empty ([]) and supply 'c' to solve the temperature instead:
%       T0 = c^2/(gamma*R),   T = T0 - 273.2
%
%   Or supply 'd' (m) and 't' (s) to get the speed from a time-of-flight
%   measurement (c = d/t) and then solve the temperature from it:
%       acoustics.speedOfSoundTemp([], 'd', 8, 't', 0.020)   % 400 m/s, 125 C
%
%   Optional 'gamma' (default 1.4) and 'R' (default 287 J/kg/K) override the
%   gas properties. R has fields .Tc (deg C), .T0 (K), .c (m/s),
%   .cShortcut (20.06*sqrt(T0)) and .steps.
%
%   Example:
%       acoustics.speedOfSoundTemp(20).c              % 343.2 m/s
%       acoustics.speedOfSoundTemp([], 'c', 400).Tc   % 125 C
    arguments
        Tc double = []
        opts.gamma (1,1) double {mustBePositive} = 1.4
        opts.R     (1,1) double {mustBePositive} = 287
        opts.c double = []
        opts.d double = []
        opts.t double = []
    end
    g = opts.gamma; Rg = opts.R;
    steps = {};
    c = opts.c;

    % Time-of-flight overrides / supplies the speed.
    if ~isempty(opts.d) || ~isempty(opts.t)
        assert(~isempty(opts.d) && ~isempty(opts.t) && opts.d > 0 && opts.t > 0, ...
            'Provide both distance d and travel time t (> 0).');
        c = opts.d/opts.t;
        steps{end+1} = sprintf('c = d/t = %g/%g = %.2f m/s', opts.d, opts.t, c);
    end

    if ~isempty(c)                       % c -> temperature
        assert(c > 0, 'Speed c must be > 0.');
        R.c = c;
        R.T0 = c^2/(g*Rg);
        R.Tc = R.T0 - 273.2;
        R.cShortcut = 20.06*sqrt(R.T0);
        steps{end+1} = sprintf('T0 = c^2/(gamma*R) = %.2f^2/(%g*%g) = %.1f K', c, g, Rg, R.T0);
        steps{end+1} = sprintf('T = T0 - 273.2 = %.1f deg C', R.Tc);
        R.steps = steps;
    else                                 % temperature -> c
        assert(~isempty(Tc), 'Provide temperature Tc, speed c, or distance d and time t.');
        R.Tc = Tc;
        R.T0 = Tc + 273.2;
        R.c = sqrt(g*Rg*R.T0);
        R.cShortcut = 20.06*sqrt(R.T0);
        R.steps = { ...
            sprintf('T0 = Tc + 273.2 = %.1f K', R.T0), ...
            sprintf('c = sqrt(gamma*R*T0) = sqrt(%g*%g*%.1f) = %.2f m/s', g, Rg, R.T0, R.c), ...
            sprintf('(air shortcut 20.06*sqrt(T0) = %.2f m/s)', R.cShortcut)};
    end
end
