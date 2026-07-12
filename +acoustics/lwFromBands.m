function R = lwFromBands(freqs, levels, S, opts)
%LWFROMBANDS  Free-field sound power level from measured band SPLs.
%   R = ACOUSTICS.LWFROMBANDS(freqs, levels, S) un-weights the band levels
%   (default 'net',"A"), energy-sums them to an overall linear SPL, converts
%   to intensity and integrates over the measurement surface S (m^2):
%       L_lin,i = Li - W_i                (remove weighting)
%       Lp      = 10*log10( sum 10^(L_lin,i/10) )
%       I       = p_ref^2 * 10^(Lp/10) / (rho c)
%       W       = I * S,   Lw = 10*log10(W / W_ref)
%   'net' is the weighting applied to the input levels ('A','B','C','Z').
%   R has fields .Lp (dB), .I (W/m^2), .W (W), .Lw (dB) and .steps.
    arguments
        freqs  (1,:) double {mustBePositive}
        levels (1,:) double
        S      (1,1) double {mustBePositive}
        opts.net (1,1) char {mustBeMember(opts.net,{'A','B','C','Z'})} = 'A'
    end
    if numel(freqs) ~= numel(levels)
        error('acoustics:lwFromBands:size', 'freqs and levels must match.');
    end
    C = acoustics.constants();
    w = arrayfun(@(f) acoustics.weightingValue(f, opts.net), freqs);
    lin = levels - w;
    R.Lp = 10*log10(sum(10.^(lin/10)));
    p2 = C.PREF^2 * 10^(R.Lp/10);
    R.I = p2/C.RHOC;
    R.W = R.I * S;
    R.Lw = 10*log10(R.W/C.WREF);
    R.steps = { ...
        sprintf('Un-weight bands (remove %c), overall Lp = 10*log10( sum 10^(L_lin/10) ) = %.2f dB', ...
            opts.net, R.Lp), ...
        sprintf('p2_rms = p_ref^2 * 10^(Lp/10) = %.4g Pa^2', p2), ...
        sprintf('I = p2/(rho c) = %.4g W/m^2', R.I), ...
        sprintf('W = I*S = %.4g W', R.W), ...
        sprintf('Lw = 10*log10(W/1e-12) = %.1f dB', R.Lw)};
end
