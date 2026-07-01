function R = maxPermissibleTime(L, opts)
%MAXPERMISSIBLETIME  Maximum daily exposure time for a steady level.
%   R = ACOUSTICS.MAXPERMISSIBLETIME(L) for a steady level L (dB(A)) returns
%   the permitted exposure time using the OH&S exchange rule (defaults
%   Lc = 85 dB(A), q = 3 dB, Tc = 8 h):
%       T = Tc / 2^((L - Lc)/q)
%   R has fields .T (h), .exceeds (logical, L > Lc) and .steps.
    arguments
        L (1,1) double
        opts.Lc (1,1) double = 85
        opts.q  (1,1) double {mustBePositive} = 3
        opts.Tc (1,1) double {mustBePositive} = 8
    end
    R.T = opts.Tc/2^((L - opts.Lc)/opts.q);
    R.exceeds = L > opts.Lc;
    R.steps = { ...
        'T = Tc / 2^((L - Lc)/q)', ...
        sprintf('= %g / 2^((%g - %g)/%g) = %g / %.4g = %.4f h', ...
            opts.Tc, L, opts.Lc, opts.q, opts.Tc, 2^((L-opts.Lc)/opts.q), R.T)};
end
