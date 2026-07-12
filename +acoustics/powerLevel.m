function R = powerLevel(opts)
%POWERLEVEL  Convert between sound power W and sound power level Lw.
%   R = ACOUSTICS.POWERLEVEL('W',value) gives Lw; R = ...('Lw',value) gives
%   W. Supply exactly one.
%       Lw = 10*log10(W / W_ref),   W = W_ref * 10^(Lw/10),  W_ref = 1e-12 W
%   R has fields .W (W), .Lw (dB) and .steps.
%
%   Example:
%       acoustics.powerLevel('W',0.5).Lw    % 116.99 dB
    arguments
        opts.W  double {mustBePositiveOrNaN(opts.W)} = NaN
        opts.Lw double = NaN
    end
    C = acoustics.constants();
    hasW  = ~isnan(opts.W);
    hasLw = ~isnan(opts.Lw);
    if hasW == hasLw
        error('acoustics:powerLevel:input', 'Supply exactly one of W or Lw.');
    end
    if hasW
        R.W = opts.W;
        R.Lw = 10*log10(R.W/C.WREF);
        R.steps = { ...
            'Lw = 10*log10(W / W_ref)', ...
            sprintf('= 10*log10(%.4g / 1e-12) = %.2f dB', R.W, R.Lw)};
    else
        R.Lw = opts.Lw;
        R.W = C.WREF * 10^(R.Lw/10);
        R.steps = { ...
            'W = W_ref * 10^(Lw/10)', ...
            sprintf('= 1e-12 * 10^(%.4g/10) = %.4g W', R.Lw, R.W)};
    end
end

function mustBePositiveOrNaN(x)
    if ~isnan(x) && ~(x > 0)
        error('acoustics:powerLevel:pos', 'W must be > 0.');
    end
end
