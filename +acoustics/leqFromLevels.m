function R = leqFromLevels(levels, durations, opts)
%LEQFROMLEVELS  Equivalent continuous level from levels and durations.
%   R = ACOUSTICS.LEQFROMLEVELS(levels, durations) with level segments (dB)
%   and their durations (seconds) returns:
%       Leq = 10*log10( (1/T) * sum ti*10^(Li/10) )
%       SEL = 10*log10( sum ti*10^(Li/10) / 1 s ) = Leq + 10*log10(T/1s)
%   By default T is the sum of the durations; pass 'T',seconds to reference a
%   different averaging period (e.g. an 8 h shift or 24 h day). Durations may
%   be given in any consistent time unit, but SEL assumes seconds.
%   R has fields .Leq (dB), .SEL (dB), .T, .sumT, .energy and .steps.
%
%   Example (LAeq,24h = 70.55):
%       acoustics.leqFromLevels([74 69 60], [8 8 8]*3600, 'T', 24*3600).Leq
    arguments
        levels    (1,:) double
        durations (1,:) double {mustBeNonnegative}
        opts.T double = NaN
    end
    if numel(levels) ~= numel(durations)
        error('acoustics:leqFromLevels:size', 'levels and durations must match.');
    end
    R.energy = sum(durations .* 10.^(levels/10));
    R.sumT = sum(durations);
    if isnan(opts.T) || opts.T <= 0
        R.T = R.sumT;
    else
        R.T = opts.T;
    end
    R.Leq = 10*log10(R.energy/R.T);
    R.SEL = 10*log10(R.energy);
    R.steps = { ...
        'Leq = 10*log10( (1/T) * sum ti*10^(Li/10) )', ...
        sprintf('= 10*log10( (1/%.4g) * %.5g ) = %.3f dB', R.T, R.energy, R.Leq), ...
        'SEL = Leq + 10*log10(T/1s)', ...
        sprintf('= %.3f + 10*log10(%.4g) = %.2f dB', R.Leq, R.T, R.SEL)};
end
