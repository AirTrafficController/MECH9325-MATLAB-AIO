function R = lwLpDistance(r, opts)
%LWLPDISTANCE  Convert between sound power level and SPL at a distance.
%   R = ACOUSTICS.LWLPDISTANCE(r, 'Lw', value, 'type', t) gives Lp, and
%   R = ACOUSTICS.LWLPDISTANCE(r, 'Lp', value, 'type', t) gives Lw, for a
%   source at distance r (m). Supply exactly one of Lw/Lp.
%
%   'type' selects the radiation model (default "point_free"):
%       "point_free"   point, free field   Q=1
%       "point_ground" point, on ground     Q=2
%       "point_edge"   point, at an edge    Q=4
%       "point_corner" point, in a corner   Q=8
%       "line_free"    line, free field
%       "line_ground"  line, on ground
%   Point:  Lp = Lw - 20*log10(r) - 10*log10(4*pi/Q)
%   Line:   Lp = Lw - 10*log10(r) - k   (k = 8 free field, 5 on ground)
%   R has fields .Lw, .Lp, .coef, .k and .steps.
    arguments
        r (1,1) double {mustBePositive}
        opts.Lw double = NaN
        opts.Lp double = NaN
        opts.type (1,1) string {mustBeMember(opts.type, ...
            ["point_free","point_ground","point_edge","point_corner", ...
             "line_free","line_ground"])} = "point_free"
    end
    hasLw = ~isnan(opts.Lw);
    hasLp = ~isnan(opts.Lp);
    if hasLw == hasLp
        error('acoustics:lwLpDistance:input', 'Supply exactly one of Lw or Lp.');
    end
    switch opts.type
        case "point_free",   coef = 20; k = 10*log10(4*pi/1);
        case "point_ground", coef = 20; k = 10*log10(4*pi/2);
        case "point_edge",   coef = 20; k = 10*log10(4*pi/4);
        case "point_corner", coef = 20; k = 10*log10(4*pi/8);
        case "line_free",    coef = 10; k = 8;
        otherwise,           coef = 10; k = 5;   % line_ground
    end
    R.coef = coef; R.k = k;
    if hasLw
        R.Lw = opts.Lw;
        R.Lp = R.Lw - coef*log10(r) - k;
        R.steps = { ...
            sprintf('Lp = Lw - %g*log10(r) - %.2f', coef, k), ...
            sprintf('= %.4g - %g*log10(%g) - %.2f = %.2f dB', ...
                R.Lw, coef, r, k, R.Lp)};
    else
        R.Lp = opts.Lp;
        R.Lw = R.Lp + coef*log10(r) + k;
        R.steps = { ...
            sprintf('Lw = Lp + %g*log10(r) + %.2f', coef, k), ...
            sprintf('= %.4g + %g*log10(%g) + %.2f = %.2f dB', ...
                R.Lp, coef, r, k, R.Lw)};
    end
end
