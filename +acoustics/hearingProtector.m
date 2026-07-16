function R = hearingProtector(slc80, opts)
%HEARINGPROTECTOR  Protected A-weighted level via the SLC80 method.
%   R = ACOUSTICS.HEARINGPROTECTOR(slc80, 'Lceq', Lceq) returns the
%   A-weighted level reaching the ear under a hearing protector rated
%   slc80 (dB), per AS/NZS 1269.3:
%       Lprotected = Lceq - slc80
%   The rating is subtracted from the C-WEIGHTED level, never L_Aeq;
%   subtracting from L_Aeq double-counts the low frequencies (discounted
%   once by the A-curve and again by the protector) and overstates safety.
%
%   Alternatively pass octave-band levels to compute Lceq from the
%   C-weighting table:
%       R = ACOUSTICS.HEARINGPROTECTOR(27, 'bands', [250 99; 500 95])
%       Lceq = 10*log10( sum 10^((Li + Ci)/10) )
%
%   R has fields .Lceq, .slc80, .protected and .steps.
%
%   Example:
%       acoustics.hearingProtector(27, 'Lceq', 99.72).protected   % 72.72 dB(A)
    arguments
        slc80 (1,1) double
        opts.Lceq double = []
        opts.bands double = []          % [freq (Hz), level (dB)] rows
    end
    steps = {};
    if ~isempty(opts.bands)
        b = opts.bands;
        assert(size(b,2) == 2, 'bands must be an N-by-2 matrix of [freq, level].');
        e = 0; parts = cell(1, size(b,1));
        for i = 1:size(b,1)
            cw = acoustics.weightingValue(b(i,1), 'C');
            e = e + 10^((b(i,2) + cw)/10);
            parts{i} = sprintf('%gHz %.1f+(%.1f)=%.1f', b(i,1), b(i,2), cw, b(i,2)+cw);
        end
        Lceq = 10*log10(e);
        steps{end+1} = sprintf('Apply C-weighting: %s', strjoin(parts, '  '));
        steps{end+1} = sprintf('Lceq = 10*log10(sum 10^((Li+Ci)/10)) = %.2f dB(C)', Lceq);
    elseif ~isempty(opts.Lceq)
        Lceq = opts.Lceq;
    else
        error('acoustics:hearingProtector:noInput', 'Provide ''Lceq'' or ''bands''.');
    end
    R.Lceq = Lceq;
    R.slc80 = slc80;
    R.protected = Lceq - slc80;
    steps{end+1} = sprintf('Lprotected = Lceq - SLC80 = %.2f - %.2f = %.2f dB(A)', ...
        Lceq, slc80, R.protected);
    R.steps = steps;
end
