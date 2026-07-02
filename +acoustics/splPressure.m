function R = splPressure(opts)
%SPLPRESSURE  Convert between sound pressure level and RMS pressure.
%   R = ACOUSTICS.SPLPRESSURE('Lp',value) computes RMS pressure from a
%   level, and R = ACOUSTICS.SPLPRESSURE('p',value) computes the level
%   from an RMS pressure. Supply exactly one.
%       Lp = 20*log10(p / p_ref),   p = p_ref * 10^(Lp/20),  p_ref = 2e-5 Pa
%   R has fields .Lp (dB), .p (Pa) and .steps.
%
%   Example:
%       acoustics.splPressure('p',1).Lp     % 93.98 dB   (1 Pa)
    arguments
        opts.Lp double = NaN
        opts.p  double {mustBePositiveOrNaN(opts.p)} = NaN
    end
    C = constants();
    hasLp = ~isnan(opts.Lp);
    hasP  = ~isnan(opts.p);
    if hasLp == hasP
        error('acoustics:splPressure:input', ...
            'Supply exactly one of Lp or p.');
    end
    if hasP
        R.p = opts.p;
        R.Lp = 20*log10(R.p/C.PREF);
        R.steps = { ...
            'Lp = 20*log10(p / p_ref)', ...
            sprintf('= 20*log10(%.4g / 2e-5) = 20*log10(%.4g)', R.p, R.p/C.PREF), ...
            sprintf('= %.2f dB', R.Lp)};
    else
        R.Lp = opts.Lp;
        R.p = C.PREF * 10^(R.Lp/20);
        R.steps = { ...
            'p = p_ref * 10^(Lp/20)', ...
            sprintf('= 2e-5 * 10^(%.4g/20) = 2e-5 * %.4g', R.Lp, 10^(R.Lp/20)), ...
            sprintf('= %.4g Pa', R.p)};
    end
end

function mustBePositiveOrNaN(x)
    if ~isnan(x) && ~(x > 0)
        error('acoustics:splPressure:pos', 'p must be > 0.');
    end
end
