function R = barrierInsertion(freqs, Lp, opts)
%BARRIERINSERTION  Effect of a mass-law barrier on an octave-band spectrum.
%   R = ACOUSTICS.BARRIERINSERTION(freqs, Lp, 'density', d, 'thickness_mm', t)
%   takes octave-band sound pressure levels Lp (dB) and a limp barrier (e.g. a
%   fitted panel or disc) and returns the A-weighted overall level before and
%   after the barrier is inserted, plus the reduction.
%
%   Per band the barrier adds its mass-law transmission loss:
%       m''    = density*thickness   (or pass 'M', surface mass kg/m^2)
%       TL     = 20*log10(m''*f) - 42.4
%       Lp_after = Lp - TL
%   The overall weighted levels use the standard A/B/C table (default 'net','A'):
%       (i)  overall before = 10*log10( sum 10^((Lp + Wi)/10) )
%       (ii) overall after  = 10*log10( sum 10^((Lp_after + Wi)/10) )
%
%   R has fields .TL, .LpAfter (1xB), .before, .after (dB), .reduction, .steps.
%
%   Example (tunnel + 25 mm foam disc, rho 320 kg/m^3):
%       R = acoustics.barrierInsertion([250 500 1000 2000], [104 109 106 110], ...
%               'density', 320, 'thickness_mm', 25);
%       R.before   % 113.3 dB(A)
%       R.after    % 78.8  dB(A)
    arguments
        freqs (1,:) double {mustBePositive}
        Lp    (1,:) double
        opts.M            double = NaN
        opts.density      double = NaN
        opts.thickness_mm double = NaN
        opts.net (1,1) char {mustBeMember(opts.net,{'A','B','C','Z'})} = 'A'
    end
    if numel(freqs) ~= numel(Lp)
        error('acoustics:barrierInsertion:size', 'freqs and Lp must match.');
    end
    m = opts.M;
    if isnan(m) && ~isnan(opts.density) && ~isnan(opts.thickness_mm)
        m = opts.density*opts.thickness_mm/1000;
    end
    if isnan(m) || ~(m > 0)
        error('acoustics:barrierInsertion:mass', ...
            'Provide surface mass M, or density and thickness_mm.');
    end
    R.TL = arrayfun(@(f) acoustics.massLawTL(f, 'M', m).TL, freqs);
    R.LpAfter = Lp - R.TL;
    R.before = acoustics.weightedOverall(freqs, Lp, opts.net).weighted;
    R.after  = acoustics.weightedOverall(freqs, R.LpAfter, opts.net).weighted;
    R.reduction = R.before - R.after;

    tag = 'dB'; if opts.net ~= 'Z', tag = sprintf('dB(%c)', opts.net); end
    rowStr = @(v,fmt) strjoin(arrayfun(@(j) sprintf(['%g Hz ' fmt], freqs(j), v(j)), ...
        1:numel(freqs), 'UniformOutput', false), '   ');
    R.steps = { ...
        sprintf('Barrier surface mass m" = %.1f kg/m^2 · TL = 20*log10(m"*f) - 42.4', m), ...
        ['   TL per band (dB):  ' rowStr(R.TL, '%.1f')], ...
        ['   Lp after (dB):     ' rowStr(R.LpAfter, '%.1f')], ...
        '', ...
        sprintf('(i)  overall before = %.1f %s', R.before, tag), ...
        sprintf('(ii) overall after  = %.1f %s   (reduction %.1f %s)', ...
            R.after, tag, R.reduction, tag)};
end
