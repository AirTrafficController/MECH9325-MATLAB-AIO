function R = octaveBandEdges(fc, opts)
%OCTAVEBANDEDGES  Lower/upper edges and bandwidth of an octave-type band.
%   R = ACOUSTICS.OCTAVEBANDEDGES(fc) for an octave band centred at fc (Hz):
%       f_lower = fc/sqrt(2),  f_upper = fc*sqrt(2)
%   R = ACOUSTICS.OCTAVEBANDEDGES(fc,'type','third') uses a 1/3-octave band
%   with ratio 2^(1/6). R has fields .lower, .upper (Hz), .bandwidth (Hz),
%   .percent (% of fc) and .steps.
    arguments
        fc (1,1) double {mustBePositive}
        opts.type (1,1) string {mustBeMember(opts.type,["octave","third"])} = "octave"
    end
    if opts.type == "third"
        k = 2^(1/6); ks = '2^(1/6)'; nm = 'one-third octave'; ref = '23.1';
    else
        k = sqrt(2); ks = 'sqrt(2)'; nm = 'octave'; ref = '70.7';
    end
    R.lower = fc/k;
    R.upper = fc*k;
    R.bandwidth = R.upper - R.lower;
    R.percent = R.bandwidth/fc*100;
    R.steps = { ...
        sprintf('f_lower = fc/%s = %.1f Hz', ks, R.lower), ...
        sprintf('f_upper = fc*%s = %.1f Hz', ks, R.upper), ...
        sprintf('BW = %.1f - %.1f = %.1f Hz', R.upper, R.lower, R.bandwidth), ...
        sprintf('%%BW = BW/fc*100 = %.1f %% (constant -> %s ~ %s %%)', R.percent, nm, ref)};
end
