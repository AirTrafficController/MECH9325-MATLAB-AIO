function R = reverbTestRoom(freqs, Lw, T60empty, T60furnished, V, S, opts)
%REVERBTESTROOM  Reverberant mean-square pressure in a test room.
%   R = ACOUSTICS.REVERBTESTROOM(freqs, Lw, T60empty, T60furnished, V, S)
%   evaluates the reverberant field for an empty and a furnished state using
%   the EXACT characteristic impedance (not the dB approximation):
%       A       = 0.161*V / T60           room absorption (m^2)
%       alpha   = A / S
%       R_room  = A / (1 - alpha)
%       W       = W_ref * 10^(Lw/10)
%       <p^2>   = 4 * rho c * W / R_room   reverberant mean-square pressure (Pa^2)
%       Lp      = 10*log10( <p^2> / p_ref^2 )
%
%   Inputs are per octave band (1xB vectors) except V, S:
%       freqs         octave centre frequencies (Hz)
%       Lw            band sound power levels (dB re 1e-12 W)
%       T60empty      reverberation time, empty room (s)
%       T60furnished  reverberation time, furnished room (s)
%       V, S          room volume (m^3) and total surface (m^2)
%   Optional: 'rhoc' (default 415 rayls), 'net' (default 'A').
%
%   R has fields:
%       .freqs, .Aempty, .Afurn (1xB)
%       .p2empty, .p2furn (1xB, Pa^2)
%       .LpEmpty, .LpFurn (1xB, dB)
%       .dBAempty, .dBAfurn, .reduction
%       .steps
    arguments
        freqs        (1,:) double {mustBePositive}
        Lw           (1,:) double
        T60empty     (1,:) double {mustBePositive}
        T60furnished (1,:) double {mustBePositive}
        V (1,1) double {mustBePositive}
        S (1,1) double {mustBePositive}
        opts.rhoc (1,1) double {mustBePositive} = 415
        opts.net  (1,1) char {mustBeMember(opts.net,{'A','B','C','Z'})} = 'A'
    end
    C = acoustics.constants();
    B = numel(freqs);
    if ~isequal(numel(Lw), numel(T60empty), numel(T60furnished), B)
        error('acoustics:reverbTestRoom:size', 'All band vectors must match freqs.');
    end
    W = C.WREF * 10.^(Lw/10);

    [R.Aempty, R.p2empty, R.LpEmpty] = state(T60empty, W, V, S, opts.rhoc, C.PREF);
    [R.Afurn,  R.p2furn,  R.LpFurn ] = state(T60furnished, W, V, S, opts.rhoc, C.PREF);

    R.freqs = freqs;
    w = arrayfun(@(f) acoustics.weightingValue(f, opts.net), freqs);
    R.dBAempty = 10*log10(sum(10.^((R.LpEmpty + w)/10)));
    R.dBAfurn  = 10*log10(sum(10.^((R.LpFurn  + w)/10)));
    R.reduction = R.dBAempty - R.dBAfurn;

    tag = 'dB'; if opts.net ~= 'Z', tag = sprintf('dB(%c)', opts.net); end
    lines = { ...
        'Per band: A = 0.161*V/T60, alpha = A/S, R = A/(1-alpha)', ...
        'W = W_ref*10^(Lw/10), <p^2> = 4*rho c*W/R, Lp = 10*log10(<p^2>/p_ref^2)', ''};
    for i = 1:B
        lines{end+1} = sprintf('  %6g Hz: A %.2f/%.2f  <p^2> %.4g/%.4g Pa^2  Lp %.1f/%.1f dB', ...
            freqs(i), R.Aempty(i), R.Afurn(i), R.p2empty(i), R.p2furn(i), ...
            R.LpEmpty(i), R.LpFurn(i)); %#ok<AGROW>
    end
    R.steps = [lines, { '', ...
        sprintf('Overall empty = %.1f %s · furnished = %.1f %s · reduction = %.1f %s', ...
            R.dBAempty, tag, R.dBAfurn, tag, R.reduction, tag)}];
end

function [A, p2, Lp] = state(T60, W, V, S, rhoc, pref)
    A = 0.161*V ./ T60;
    alpha = A / S;
    Rroom = A ./ (1 - alpha);
    p2 = 4*rhoc*W ./ Rroom;
    Lp = 10*log10(p2 / pref^2);
end
