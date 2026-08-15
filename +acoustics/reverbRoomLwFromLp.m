function R = reverbRoomLwFromLp(freqs, Lp, T60, V, opts)
%REVERBROOMLWFROMLP  Sound power level Lw from reverberation-room SPL (ISO 3741 style).
%   R = ACOUSTICS.REVERBROOMLWFROMLP(freqs, Lp, T60, V) returns per-band Lw
%   from band SPLs measured in a diffuse (reverberation) room using the
%   simplified relation:
%
%       A   = 0.161 * V ./ T60            (Sabine absorption area, m^2)
%       Lw  = Lp + 10*log10( A / 4 )
%           = Lp + 10*log10( V ./ T60 ) - 13.94
%
%   The constant is 10*log10(0.161/4) = -13.94 dB (rounded -14 dB in
%   many texts; the exact value is used here).
%
%   Inputs:
%       freqs (1xB)  octave-band centre frequencies (Hz)
%       Lp    (1xB)  band sound pressure levels (dB re 20 uPa)
%       T60   scalar or (1xB)  reverberation time (s)
%       V     scalar room volume (m^3)
%   Optional:
%       'net'  'A' | 'B' | 'C' | 'Z'  weighting for overall LwA (default 'A')
%
%   R fields:
%       .freqs, .Lp, .A, .Lw           per-band vectors
%       .LwWeighted                     Lw + weighting (dB, per net)
%       .LwOverall                      unweighted energy sum (dB)
%       .LwAOverall                     A-weighted energy sum (dB re net)
%       .constant                       10*log10(0.161/4) = -13.94
%       .steps                          working
    arguments
        freqs (1,:) double {mustBePositive}
        Lp    (1,:) double
        T60   (1,:) double {mustBePositive}
        V     (1,1) double {mustBePositive}
        opts.net (1,1) char {mustBeMember(opts.net,{'A','B','C','Z'})} = 'A'
    end
    B = numel(freqs);
    if numel(Lp) ~= B
        error('acoustics:reverbRoomLwFromLp:size', 'Lp must have one value per band.');
    end
    if isscalar(T60), T60 = repmat(T60, 1, B); end
    if numel(T60) ~= B
        error('acoustics:reverbRoomLwFromLp:t60', 'T60 must be scalar or one per band.');
    end

    K = 10*log10(0.161/4);
    A  = 0.161*V ./ T60;
    Lw = Lp + 10*log10(V ./ T60) + K;

    w  = arrayfun(@(f) acoustics.weightingValue(f, opts.net), freqs);
    LwWeighted = Lw + w;

    R.freqs = freqs;
    R.Lp    = Lp;
    R.A     = A;
    R.Lw    = Lw;
    R.LwWeighted = LwWeighted;
    R.LwOverall  = 10*log10(sum(10.^(Lw/10)));
    R.LwAOverall = 10*log10(sum(10.^(LwWeighted/10)));
    R.constant   = K;

    tag = 'dB'; if opts.net ~= 'Z', tag = sprintf('dB(%c)', opts.net); end
    R.steps = { ...
        'REVERBERATION ROOM: Lw from Lp (per octave band)', ...
        'A = 0.161*V/T60 · Lw = Lp + 10 log10(V/T60) + 10 log10(0.161/4)', ...
        sprintf('Constant 10 log10(0.161/4) = %.2f dB (often rounded to -14 dB)', K), ...
        sprintf('V = %g m^3', V), ...
        '', ...
        ['(a) A (m^2):        ' rowStr(freqs, A,  '%.3f')], ...
        ['(b) Lp (dB):        ' rowStr(freqs, Lp, '%.2f')], ...
        ['(c) Lw (dB):        ' rowStr(freqs, Lw, '%.2f')], ...
        ['(d) Lw + ' tag ':   ' rowStr(freqs, LwWeighted, '%.2f')], ...
        '', ...
        sprintf('(e) Overall Lw (unweighted) = %.1f dB', R.LwOverall), ...
        sprintf('(f) Overall Lw (%s)        = %.1f %s', tag, R.LwAOverall, tag)};
end

function s = rowStr(freqs, vals, fmt)
    parts = arrayfun(@(j) sprintf(['%g Hz ' fmt], freqs(j), vals(j)), ...
        1:numel(freqs), 'UniformOutput', false);
    s = strjoin(parts, '   ');
end
