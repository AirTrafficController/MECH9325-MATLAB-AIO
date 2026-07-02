function R = plantRoom(freqs, machineLw, alphaBase, alphaCoat, Scoat, S, opts)
%PLANTROOM  Reverberant-field level in a plant room, before/after coating.
%   R = ACOUSTICS.PLANTROOM(freqs, machineLw, alphaBase, alphaCoat, Scoat, S)
%   works per octave band to size a surface-absorption treatment.
%
%   Inputs (per octave band unless noted):
%       freqs       1xB octave centre frequencies (Hz)
%       machineLw   BxM matrix of machine sound power levels (dB); the M
%                   machines in each band are combined on an energy basis
%       alphaBase   1xB bare-surface absorption coefficient
%       alphaCoat   1xB absorption coefficient of the coated surface
%       Scoat       area of the surface being coated (m^2, scalar)
%       S           total room surface area (m^2, scalar)
%
%   For each band:
%       Lw   = 10*log10( sum 10^(Lw_machine/10) )     combined power level
%       W    = W_ref * 10^(Lw/10)
%       BEFORE:  alpha_bar = alphaBase
%       AFTER:   alpha_bar = [Scoat*alphaCoat + (S-Scoat)*alphaBase] / S
%       R_room = S*alpha_bar/(1-alpha_bar)
%       Lp     = Lw + 10*log10(4/R_room)              reverberant field
%   Overall A-weighted levels (default 'net','A') are formed by energy-summing
%   the per-band (Lp + weighting), before and after; the reduction is their
%   difference.
%
%   R has fields:
%       .freqs, .Lw (1xB), .W (1xB), .LwOverall
%       .alphaAfter (1xB), .Rbefore (1xB), .Rafter (1xB)
%       .LpBefore (1xB), .LpAfter (1xB)
%       .dBAbefore, .dBAafter, .reduction
%       .steps
    arguments
        freqs     (1,:) double {mustBePositive}
        machineLw (:,:) double
        alphaBase (1,:) double {mustBePositive}
        alphaCoat (1,:) double {mustBePositive}
        Scoat     (1,1) double {mustBePositive}
        S         (1,1) double {mustBePositive}
        opts.net  (1,1) char {mustBeMember(opts.net,{'A','B','C','Z'})} = 'A'
    end
    C = constants();
    B = numel(freqs);
    if size(machineLw,1) ~= B
        error('acoustics:plantRoom:rows', 'machineLw must have one row per band.');
    end
    if numel(alphaBase) ~= B || numel(alphaCoat) ~= B
        error('acoustics:plantRoom:size', 'alphaBase/alphaCoat must have one value per band.');
    end
    if Scoat > S
        error('acoustics:plantRoom:area', 'Coated area cannot exceed total surface.');
    end

    R.freqs = freqs;
    R.Lw = 10*log10(sum(10.^(machineLw/10), 2))';        % combine machines
    R.W = C.WREF * 10.^(R.Lw/10);
    R.LwOverall = 10*log10(sum(10.^(R.Lw/10)));

    R.alphaAfter = (Scoat*alphaCoat + (S-Scoat)*alphaBase) / S;
    R.Rbefore = S*alphaBase ./ (1 - alphaBase);
    R.Rafter  = S*R.alphaAfter ./ (1 - R.alphaAfter);
    R.LpBefore = R.Lw + 10*log10(4 ./ R.Rbefore);
    R.LpAfter  = R.Lw + 10*log10(4 ./ R.Rafter);

    w = arrayfun(@(f) weightingValue(f, opts.net), freqs);
    R.dBAbefore = 10*log10(sum(10.^((R.LpBefore + w)/10)));
    R.dBAafter  = 10*log10(sum(10.^((R.LpAfter  + w)/10)));
    R.reduction = R.dBAbefore - R.dBAafter;

    tag = 'dB'; if opts.net ~= 'Z', tag = sprintf('dB(%c)', opts.net); end
    lines = { ...
        'Per band: Lw = 10*log10( sum 10^(Lw_machine/10) ),  W = W_ref*10^(Lw/10)', ...
        'R = S*alpha_bar/(1-alpha_bar),  Lp = Lw + 10*log10(4/R)', ...
        'after: alpha_bar = [Scoat*alphaCoat + (S-Scoat)*alphaBase]/S', ''};
    for i = 1:B
        lines{end+1} = sprintf('  %6g Hz: Lw %.1f (W %.4g)  Lp %.1f -> %.1f dB', ...
            freqs(i), R.Lw(i), R.W(i), R.LpBefore(i), R.LpAfter(i)); %#ok<AGROW>
    end
    R.steps = [lines, { '', ...
        sprintf('Overall Lw = %.2f dB', R.LwOverall), ...
        sprintf('Overall before = %.1f %s · after = %.1f %s · reduction = %.1f %s', ...
            R.dBAbefore, tag, R.dBAafter, tag, R.reduction, tag)}];
end
