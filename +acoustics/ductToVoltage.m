function R = ductToVoltage(Lw, d_mm, sens_dB, opts)
%DUCTTOVOLTAGE  Microphone voltage from duct sound power (plane-wave).
%   R = ACOUSTICS.DUCTTOVOLTAGE(Lw, d_mm, sens_dB) for a circular duct of
%   diameter d_mm (mm) carrying sound power level Lw (dB) with a flush
%   microphone of sensitivity sens_dB (dB re 1 V/Pa):
%       W = W_ref*10^(Lw/10),  A = pi*d^2/4,  I = W/A
%       p_rms = sqrt(I*rho*c),  V = p_rms * 10^(sens/20)
%   Also reports the first higher-order-mode cut-on f_c = 1.8412*c/(pi*d).
%   Optional 'rho' (1.21 kg/m^3), 'c' (343 m/s), 'fmax' (Hz, for a validity
%   check). R has fields .W, .area, .I, .prms, .spl, .V, .fcuton and .steps.
    arguments
        Lw      (1,1) double
        d_mm    (1,1) double {mustBePositive}
        sens_dB (1,1) double
        opts.rho  (1,1) double {mustBePositive} = 1.21
        opts.c    (1,1) double {mustBePositive} = 343
        opts.fmax (1,1) double = 0
    end
    C = acoustics.constants();
    d = d_mm/1000;
    R.W = C.WREF*10^(Lw/10);
    R.area = pi*d^2/4;
    R.I = R.W/R.area;
    rc = opts.rho*opts.c;
    R.prms = sqrt(R.I*rc);
    R.spl = 20*log10(R.prms/C.PREF);
    sens = 10^(sens_dB/20);
    R.V = R.prms*sens;
    R.fcuton = 1.8412*opts.c/(pi*d);
    if opts.fmax > 0
        if opts.fmax < R.fcuton
            note = sprintf('Highest freq %.0f Hz < cut-on %.0f Hz -> plane waves only, valid.', ...
                opts.fmax, R.fcuton);
        else
            note = sprintf('Highest freq %.0f Hz >= cut-on %.0f Hz -> higher-order modes, approximate.', ...
                opts.fmax, R.fcuton);
        end
    else
        note = sprintf('First higher-order mode cuts on at %.0f Hz (plane-wave assumption valid below).', ...
            R.fcuton);
    end
    R.steps = { ...
        sprintf('W = W_ref*10^(Lw/10) = %.4g W', R.W), ...
        sprintf('A = pi*d^2/4 = %.4g m^2', R.area), ...
        sprintf('I = W/A = %.4g W/m^2', R.I), ...
        sprintf('p_rms = sqrt(I*rho*c) = %.4g Pa   (SPL = %.1f dB)', R.prms, R.spl), ...
        sprintf('V = p_rms*10^(S/20) = %.4g V  (%.4g mV)', R.V, R.V*1000), ...
        note};
end
