function R = phonToSone(phon)
%PHONTOSONE  Convert loudness level (phons) to loudness (sones).
%   R = ACOUSTICS.PHONTOSONE(phon) returns
%       S = 2^((LL - 40)/10)
%   valid for LL >= 40 phon. R has fields .sones and .steps.
%
%   Example:
%       acoustics.phonToSone(80).sones     % 16 sones
    arguments
        phon (1,1) double
    end
    R.sones = 2^((phon - 40)/10);
    R.steps = { ...
        'S = 2^((LL - 40)/10)', ...
        sprintf('= 2^((%g - 40)/10) = %.3f sones', phon, R.sones)};
    if phon < 40
        R.steps{end+1} = 'Note: formula assumes LL >= 40 phon.';
    end
end
