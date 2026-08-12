function R = massLawTL(f, opts)
%MASSLAWTL  Transmission loss of a limp panel from the mass law.
%   R = ACOUSTICS.MASSLAWTL(f, 'M', m) at frequency f (Hz) for a panel of
%   surface mass m (kg/m^2):
%       TL = 20*log10(M*f) - 42.4
%
%   Layered / glued / laminated panels (bonded together with NO air gap act
%   as one leaf, so their surface masses ADD): pass M as a vector, e.g.
%       acoustics.massLawTL(100,'M',[10 10])   % two 10 kg/m^2 leaves -> M=20
%   Likewise 'density' and 'thickness_mm' may be vectors (one entry per
%   layer); the layer masses density.*thickness/1000 are summed.
%
%   'constant' overrides the 42.4 dB term (normal incidence). R has fields
%   .M (total kg/m^2), .layers (per-layer kg/m^2), .TL (dB) and .steps.
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
    if ~any(isnan(opts.M))
        layers = opts.M(:).';
    elseif ~any(isnan(opts.density)) && ~any(isnan(opts.thickness_mm))
        d = opts.density(:).'; th = opts.thickness_mm(:).';
        if numel(d) ~= numel(th)
            error('acoustics:massLawTL:layers', ...
                'density and thickness_mm must have the same number of layers.');
        end
        layers = d.*th/1000;
    else
        error('acoustics:massLawTL:mass', ...
            'Provide surface mass M, or density and thickness_mm (scalars or per-layer vectors).');
    end
    M = sum(layers);
    if ~(M > 0)
        error('acoustics:massLawTL:mass', 'Total surface mass must be > 0.');
    end
    R.layers = layers;
    R.M = M;
    R.TL = 20*log10(M*f) - opts.constant;
    R.steps = {};
    if numel(layers) > 1
        R.steps{end+1} = sprintf('Layers (glued, masses add): [%s] = %.3f kg/m^2', ...
            strjoin(arrayfun(@(x) sprintf('%.3g',x), layers, 'UniformOutput', false), ' + '), M);
    else
        R.steps{end+1} = sprintf('Surface mass M = %.3f kg/m^2', M);
    end
    R.steps{end+1} = sprintf('TL = 20*log10(M*f) - %.1f', opts.constant);
    R.steps{end+1} = sprintf('= 20*log10(%.3f*%g) - %.1f = %.2f - %.1f = %.1f dB', ...
        M, f, opts.constant, 20*log10(M*f), opts.constant, R.TL);
end
