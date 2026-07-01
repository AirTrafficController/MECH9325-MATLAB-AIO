function R = massLawTL(f, opts)
%MASSLAWTL  Transmission loss of a limp panel from the mass law.
%   R = ACOUSTICS.MASSLAWTL(f, 'M', m) at frequency f (Hz) for a panel of
%   surface mass m (kg/m^2):
%       TL = 20*log10(M*f) - 42.4
%   Instead of M you may give 'density' (kg/m^3) and 'thickness_mm' (mm),
%   from which M = density*thickness/1000 is formed. 'constant' overrides the
%   42.4 dB term. R has fields .M (kg/m^2), .TL (dB) and .steps.
%
%   Example (plywood 3 mm at 500 kg/m^3, 1 kHz):
%       acoustics.massLawTL(1000,'density',500,'thickness_mm',3).TL  % ~21 dB
    arguments
        f (1,1) double {mustBePositive}
        opts.M            double = NaN
        opts.density      double = NaN
        opts.thickness_mm double = NaN
        opts.constant (1,1) double = 42.4
    end
    M = opts.M;
    if isnan(M) && ~isnan(opts.density) && ~isnan(opts.thickness_mm)
        M = opts.density*opts.thickness_mm/1000;
    end
    if isnan(M) || ~(M > 0)
        error('acoustics:massLawTL:mass', ...
            'Provide surface mass M, or density and thickness_mm.');
    end
    R.M = M;
    R.TL = 20*log10(M*f) - opts.constant;
    R.steps = { ...
        sprintf('Surface mass M = %.3f kg/m^2', M), ...
        'TL = 20*log10(M*f) - 42.4', ...
        sprintf('= 20*log10(%.3f*%g) - 42.4 = %.2f - 42.4 = %.1f dB', ...
            M, f, 20*log10(M*f), R.TL)};
end
