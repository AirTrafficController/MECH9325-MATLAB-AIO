function R = noiseDose(levels, durations, opts)
%NOISEDOSE  Occupational noise dose, LAeq and maximum permissible time.
%   R = ACOUSTICS.NOISEDOSE(levels, durations) with exposure levels (dB(A))
%   and their durations (SECONDS) evaluates a shift against the OH&S
%   criterion (defaults: Lc = 85 dB(A), exchange rate q = 3 dB, criterion
%   time Tc = 8 h):
%       allowed time Ti = Tc / 2^((Li-Lc)/q)
%       Dose = sum ti/Ti              (100% = the limit; ti, Tc in hours)
%       L_Aeq,T  = 10*log10( (1/T)  sum ti*10^(Li/10) )
%       L_Aeq,Tc = 10*log10( (1/Tc) sum ti*10^(Li/10) )
%       Tmax = Tc / 2^((L_Aeq,T - Lc)/q)
%   R has fields .LAeqT, .LAeqTc (dB(A)), .dose (fraction), .dosePct,
%   .Tmax (h), .exceeds (logical) and .steps.
    arguments
        levels    (1,:) double
        durations (1,:) double {mustBeNonnegative}
        opts.Lc (1,1) double = 85
        opts.q  (1,1) double {mustBePositive} = 3
        opts.Tc (1,1) double {mustBePositive} = 8
    end
    if numel(levels) ~= numel(durations)
        error('acoustics:noiseDose:size', 'levels and durations must match.');
    end
    t = durations/3600;   % hours
    energy = sum(t .* 10.^(levels/10));
    sumT = sum(t);
    Ti = opts.Tc ./ 2.^((levels - opts.Lc)/opts.q);
    R.dose = sum(t ./ Ti);
    R.dosePct = R.dose*100;
    R.LAeqT = 10*log10(energy/sumT);
    R.LAeqTc = 10*log10(energy/opts.Tc);
    R.Tmax = opts.Tc/2^((R.LAeqT - opts.Lc)/opts.q);
    R.exceeds = R.LAeqTc > opts.Lc;
    R.steps = { ...
        sprintf('L_Aeq,T = 10*log10( (1/%.3g h) * sum ti*10^(Li/10) ) = %.3f dB(A)', sumT, R.LAeqT), ...
        sprintf('L_Aeq,%gh = L_Aeq,T + 10*log10(T/Tc) = %.3f dB(A)', opts.Tc, R.LAeqTc), ...
        'Allowed time Ti = Tc / 2^((Li-Lc)/q)', ...
        sprintf('Dose = sum ti/Ti = %.4f = %.1f %%', R.dose, R.dosePct), ...
        sprintf('Tmax = Tc / 2^((L_Aeq,T-Lc)/q) = %.3f h', R.Tmax)};
end
