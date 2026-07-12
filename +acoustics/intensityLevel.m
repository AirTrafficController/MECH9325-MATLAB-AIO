function R = intensityLevel(opts)
%INTENSITYLEVEL  Sound intensity level, optionally from RMS pressure.
%   R = ACOUSTICS.INTENSITYLEVEL('I',value) uses the intensity directly;
%   R = ACOUSTICS.INTENSITYLEVEL('p',value) first forms I = p^2/(rho c)
%   with rho c = 415 rayls. Supply exactly one of I or p.
%       LI = 10*log10(I / I_ref),   I_ref = 1e-12 W/m^2
%   R has fields .I (W/m^2), .LI (dB) and .steps.
%
%   Example:
%       acoustics.intensityLevel('p',1).LI
    arguments
        opts.I double {mustBePositiveOrNaN(opts.I)} = NaN
        opts.p double {mustBePositiveOrNaN(opts.p)} = NaN
    end
    C = acoustics.constants();
    hasI = ~isnan(opts.I);
    hasP = ~isnan(opts.p);
    if hasI == hasP
        error('acoustics:intensityLevel:input', 'Supply exactly one of I or p.');
    end
    steps = {};
    if hasP
        R.I = opts.p^2 / C.RHOC;
        steps{end+1} = sprintf('I = p_rms^2 / (rho c) = %.4g^2 / %g = %.4g W/m^2', ...
            opts.p, C.RHOC, R.I);
    else
        R.I = opts.I;
    end
    R.LI = 10*log10(R.I/C.IREF);
    steps{end+1} = sprintf('LI = 10*log10(I / I_ref) = 10*log10(%.4g / 1e-12) = %.2f dB', ...
        R.I, R.LI);
    R.steps = steps;
end

function mustBePositiveOrNaN(x)
    if ~isnan(x) && ~(x > 0)
        error('acoustics:intensityLevel:pos', 'Value must be > 0.');
    end
end
