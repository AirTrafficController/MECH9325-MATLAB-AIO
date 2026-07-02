function R = subtractLevels(Ltot, Lremove)
%SUBTRACTLEVELS  Energy subtraction of one level from a total.
%   R = ACOUSTICS.SUBTRACTLEVELS(Ltot, Lremove) removes the contribution of
%   Lremove (e.g. background) from a measured total Ltot:
%       L_rem = 10*log10( 10^(Ltot/10) - 10^(Lremove/10) )
%   R has fields .remaining (dB) and .steps.
    arguments
        Ltot    (1,1) double
        Lremove (1,1) double
    end
    diff = 10^(Ltot/10) - 10^(Lremove/10);
    if diff <= 0
        error('acoustics:subtractLevels:order', ...
            'Total must exceed the level being removed.');
    end
    R.remaining = 10*log10(diff);
    R.steps = { ...
        'L_rem = 10*log10( 10^(Ltot/10) - 10^(Lremove/10) )', ...
        sprintf('= 10*log10( %.4g - %.4g ) = 10*log10( %.4g )', ...
            10^(Ltot/10), 10^(Lremove/10), diff), ...
        sprintf('= %.2f dB', R.remaining)};
end
