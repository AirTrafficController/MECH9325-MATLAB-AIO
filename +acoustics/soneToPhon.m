function R = soneToPhon(sones)
%SONETOPHON  Convert loudness (sones) to loudness level (phons).
%   R = ACOUSTICS.SONETOPHON(sones) returns
%       LL = 40 + 10*log2(S)
%   R has fields .phons and .steps.
%
%   Example:
%       acoustics.soneToPhon(16).phons     % 80 phon
    arguments
        sones (1,1) double {mustBePositive}
    end
    R.phons = 40 + 10*log2(sones);
    R.steps = { ...
        'LL = 40 + 10*log2(S)', ...
        sprintf('= 40 + 10*log2(%g) = %.2f phons', sones, R.phons)};
end
