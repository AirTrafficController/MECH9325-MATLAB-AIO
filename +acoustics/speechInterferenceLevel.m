function R = speechInterferenceLevel(bandLevels)
%SPEECHINTERFERENCELEVEL  Speech interference level (SIL / PSIL).
%   R = ACOUSTICS.SPEECHINTERFERENCELEVEL(bandLevels) returns the arithmetic
%   mean of the octave-band noise levels (dB) that interfere with speech:
%       SIL = mean( L_bands )
%   Classic SIL uses the 500, 1000, 2000 and 4000 Hz octave bands; the
%   preferred-octave PSIL uses 500, 1000 and 2000 Hz. Pass whichever set the
%   question specifies. R has fields .SIL (dB) and .steps.
%
%   Example (ship engine-room):
%       acoustics.speechInterferenceLevel([105 104 103 102.68]).SIL   % 103.67
    arguments
        bandLevels (1,:) double {mustBeNonempty}
    end
    R.SIL = mean(bandLevels);
    terms = strjoin(arrayfun(@(x) sprintf('%g', x), bandLevels, ...
        'UniformOutput', false), ' + ');
    R.steps = { ...
        'SIL = mean( octave-band levels )', ...
        sprintf('= (%s)/%d = %.2f dB', terms, numel(bandLevels), R.SIL)};
end
