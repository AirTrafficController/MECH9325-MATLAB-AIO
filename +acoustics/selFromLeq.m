function R = selFromLeq(opts)
%SELFROMLEQ  Convert between Leq over an event and its SEL.
%   R = ACOUSTICS.SELFROMLEQ('Leq',value,'T',seconds) gives SEL, and
%   R = ACOUSTICS.SELFROMLEQ('SEL',value,'T',seconds) gives Leq, using:
%       SEL = Leq + 10*log10(T / 1 s)
%   Supply the duration T (s) and exactly one of Leq/SEL. R has fields
%   .Leq (dB), .SEL (dB), .T and .steps.
    arguments
        opts.Leq double = NaN
        opts.SEL double = NaN
        opts.T   (1,1) double {mustBePositive} = 1
    end
    hasLeq = ~isnan(opts.Leq);
    hasSEL = ~isnan(opts.SEL);
    if hasLeq == hasSEL
        error('acoustics:selFromLeq:input', 'Supply exactly one of Leq or SEL.');
    end
    R.T = opts.T;
    if hasLeq
        R.Leq = opts.Leq;
        R.SEL = R.Leq + 10*log10(R.T);
        R.steps = { ...
            'SEL = Leq + 10*log10(T / 1 s)', ...
            sprintf('= %g + 10*log10(%g) = %g + %.3f = %.2f dB', ...
                R.Leq, R.T, R.Leq, 10*log10(R.T), R.SEL)};
    else
        R.SEL = opts.SEL;
        R.Leq = R.SEL - 10*log10(R.T);
        R.steps = { ...
            'Leq = SEL - 10*log10(T / 1 s)', ...
            sprintf('= %g - 10*log10(%g) = %.2f dB', R.SEL, R.T, R.Leq)};
    end
end
