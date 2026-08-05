function R = speedOfSoundTemp(Tc, opts)
%SPEEDOFSOUNDTEMP  Speed of sound in a gas and temperature (either direction).
%   FORWARD - speed from temperature:
%       R = ACOUSTICS.SPEEDOFSOUNDTEMP(Tc)      % Tc in degrees Celsius
%           T0 = Tc + 273.2 (K),  c = sqrt(gamma*R*T0)
%
%   INVERSE - temperature from speed:
%       R = ACOUSTICS.SPEEDOFSOUNDTEMP('c', c)              % measured speed (m/s)
%       R = ACOUSTICS.SPEEDOFSOUNDTEMP('distance',d,'time',t)  % c = d/t
%           T0 = c^2/(gamma*R),   Tc = T0 - 273.2
%   e.g. an impulse crossing d = 8 m between two probe microphones in t = 20 ms
%   gives c = 400 m/s and Tc ~ 125 C.
%
%   Optional 'gamma' (1.4) and 'R' (287 J/kg/K) override the gas properties.
%   R has fields .Tc (C), .T0 (K), .c (m/s), .cShortcut (20.06*sqrt(T0)) and
%   .steps.
%
%   Examples:
%       acoustics.speedOfSoundTemp(20).c                     % 343.2 m/s
%       acoustics.speedOfSoundTemp('distance',8,'time',0.02).Tc  % ~125 C
    arguments
        Tc double = NaN
        opts.c        (1,1) double = NaN
        opts.distance (1,1) double = NaN
        opts.time     (1,1) double = NaN
        opts.gamma    (1,1) double {mustBePositive} = 1.4
        opts.R        (1,1) double {mustBePositive} = 287
    end
    g = opts.gamma; Rgas = opts.R;

    % Work out the measured speed, if any was supplied.
    c = opts.c;
    dtStep = {};
    if isnan(c) && ~isnan(opts.distance) && ~isnan(opts.time)
        if opts.time <= 0
            error('acoustics:speedOfSoundTemp:time', 'time must be > 0.');
        end
        c = opts.distance/opts.time;
        dtStep = { sprintf('c = distance/time = %g/%g = %.2f m/s', ...
            opts.distance, opts.time, c) };
    end

    if ~isnan(Tc)
        % ---- forward: temperature -> speed ----
        R.Tc = Tc;
        R.T0 = Tc + 273.2;
        R.c  = sqrt(g*Rgas*R.T0);
        R.cShortcut = 20.06*sqrt(R.T0);
        R.steps = { ...
            sprintf('T0 = Tc + 273.2 = %.1f K', R.T0), ...
            sprintf('c = sqrt(gamma*R*T0) = sqrt(%g*%g*%.1f) = %.2f m/s', ...
                g, Rgas, R.T0, R.c), ...
            sprintf('(air shortcut 20.06*sqrt(T0) = %.2f m/s)', R.cShortcut)};
    elseif ~isnan(c)
        % ---- inverse: speed -> temperature ----
        R.c  = c;
        R.T0 = c^2/(g*Rgas);
        R.Tc = R.T0 - 273.2;
        R.cShortcut = 20.06*sqrt(R.T0);
        R.steps = [ dtStep, { ...
            sprintf('T0 = c^2/(gamma*R) = %.2f^2/(%g*%g) = %.2f K', c, g, Rgas, R.T0), ...
            sprintf('Tc = T0 - 273.2 = %.1f degC', R.Tc) } ];
    else
        error('acoustics:speedOfSoundTemp:input', ...
            'Give Tc (temperature), or c, or distance and time.');
    end
end
