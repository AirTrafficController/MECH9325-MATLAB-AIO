function R = roomEquation(Lw, r, Rc, opts)
%ROOMEQUATION  SPL in a room from sound power (direct + reverberant field).
%   R = ACOUSTICS.ROOMEQUATION(Lw, r, Rc) returns the SPL at distance r (m)
%   from a source of power level Lw (dB) in a room of room constant Rc (m^2):
%       Lp = Lw + 10*log10( Q/(4*pi*r^2) + 4/R )
%   Optional 'Q' (default 1) sets the directivity. R has fields .Lp (dB),
%   .direct, .reverberant (the two bracket terms), .dominant and .steps.
    arguments
        Lw (1,1) double
        r  (1,1) double {mustBePositive}
        Rc (1,1) double {mustBePositive}
        opts.Q (1,1) double {mustBePositive} = 1
    end
    R.direct = opts.Q/(4*pi*r^2);
    R.reverberant = 4/Rc;
    R.Lp = Lw + 10*log10(R.direct + R.reverberant);
    if R.direct > R.reverberant
        R.dominant = 'direct field dominates';
    else
        R.dominant = 'reverberant field dominates';
    end
    R.steps = { ...
        'Lp = Lw + 10*log10( Q/(4*pi*r^2) + 4/R )', ...
        sprintf('= %.4g + 10*log10( %.4g + %.4g )', Lw, R.direct, R.reverberant), ...
        sprintf('= %.4g + 10*log10( %.4g ) = %.2f dB  (%s)', ...
            Lw, R.direct + R.reverberant, R.Lp, R.dominant)};
end
