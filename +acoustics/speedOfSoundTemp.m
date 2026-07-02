function R = speedOfSoundTemp(Tc, opts)
%SPEEDOFSOUNDTEMP  Speed of sound in a gas from temperature.
%   R = ACOUSTICS.SPEEDOFSOUNDTEMP(Tc) returns the speed of sound in air at
%   Tc degrees Celsius:
%       T0 = Tc + 273.2 (K),   c = sqrt(gamma*R*T0)
%   Optional 'gamma' (default 1.4) and 'R' (default 287 J/kg/K) override the
%   gas properties. R has fields .T0 (K), .c (m/s), .cShortcut (20.06*sqrt(T0))
%   and .steps.
%
%   Example:
%       acoustics.speedOfSoundTemp(20).c    % 343.2 m/s
    arguments
        Tc (1,1) double
        opts.gamma (1,1) double {mustBePositive} = 1.4
        opts.R     (1,1) double {mustBePositive} = 287
    end
    R.T0 = Tc + 273.2;
    R.c = sqrt(opts.gamma * opts.R * R.T0);
    R.cShortcut = 20.06*sqrt(R.T0);
    R.steps = { ...
        sprintf('T0 = Tc + 273.2 = %.1f K', R.T0), ...
        sprintf('c = sqrt(gamma*R*T0) = sqrt(%g*%g*%.1f) = %.2f m/s', ...
            opts.gamma, opts.R, R.T0, R.c), ...
        sprintf('(air shortcut 20.06*sqrt(T0) = %.2f m/s)', R.cShortcut)};
end
