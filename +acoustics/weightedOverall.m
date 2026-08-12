function R = weightedOverall(freqs, levels, net)
%WEIGHTEDOVERALL  Overall weighted and linear level of a band spectrum.
%   R = ACOUSTICS.WEIGHTEDOVERALL(freqs, levels, net) applies the A/B/C/Z
%   weighting NET to octave or 1/3-octave band levels (dB) and energy-sums:
%       L_W = 10*log10( sum 10^((Li + Wi)/10) )
%       linear (unweighted) = 10*log10( sum 10^(Li/10) )
%   R has fields .weighted (dB), .linear (dB), .bandWeighted (vector),
%   .weights (vector) and .steps.
%
%   Example (77.5 dB(A) worked case):
%       f = [63 125 250 500 1000 2000 4000 8000];
%       L = [70 72 74 76 70.4 71 66 60];
%       acoustics.weightedOverall(f, L, 'A').weighted   % 77.50
    arguments
        freqs  (1,:) double {mustBePositive}
        levels (1,:) double
        net    (1,1) char {mustBeMember(net,{'A','B','C','Z'})}
    end
    if numel(freqs) ~= numel(levels)
        error('acoustics:weightedOverall:size', 'freqs and levels must match.');
    end
    R.weights = arrayfun(@(f) acoustics.weightingValue(f, net), freqs);
    R.bandWeighted = levels + R.weights;
    R.linear = 10*log10(sum(10.^(levels/10)));
    R.weighted = 10*log10(sum(10.^(R.bandWeighted/10)));
    tag = 'dB'; if net ~= 'Z', tag = sprintf('dB(%c)', net); end
    lines = {'L_W = 10*log10( sum 10^((Li+Wi)/10) )'};
    for i = 1:numel(freqs)
        lines{end+1} = sprintf('  %6g Hz: %g %+.1f = %.1f', ...
            freqs(i), levels(i), R.weights(i), R.bandWeighted(i)); %#ok<AGROW>
    end
    lines{end+1} = sprintf('  Overall %s = %.1f · linear = %.1f dB', tag, R.weighted, R.linear);
    R.steps = lines;
end
