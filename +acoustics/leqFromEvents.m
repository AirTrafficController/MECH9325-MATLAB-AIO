function R = leqFromEvents(levels, eventTimes, counts, T)
%LEQFROMEVENTS  Leq over a period from repeated discrete events (pass-bys).
%   R = ACOUSTICS.LEQFROMEVENTS(levels, eventTimes, counts, T) with, per
%   event type, its level (dB), single-event duration (s), and number of
%   occurrences, over a reference period T (s):
%       Leq = 10*log10( (1/T) * sum Ni*ti*10^(Li/10) )
%   R has fields .Leq (dB), .energy, .T and .steps.
    arguments
        levels     (1,:) double
        eventTimes (1,:) double {mustBeNonnegative}
        counts     (1,:) double {mustBeNonnegative}
        T          (1,1) double {mustBePositive}
    end
    if ~isequal(numel(levels), numel(eventTimes), numel(counts))
        error('acoustics:leqFromEvents:size', 'Inputs must be the same length.');
    end
    R.energy = sum(counts .* eventTimes .* 10.^(levels/10));
    R.T = T;
    R.Leq = 10*log10(R.energy/T);
    R.steps = { ...
        'Leq = 10*log10( (1/T) * sum Ni*ti*10^(Li/10) )', ...
        sprintf('= 10*log10( (1/%.4g) * %.5g ) = %.3f dB', T, R.energy, R.Leq)};
end
