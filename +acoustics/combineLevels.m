function R = combineLevels(levels)
%COMBINELEVELS  Energy (incoherent) sum of decibel levels.
%   R = ACOUSTICS.COMBINELEVELS(levels) combines a vector of levels (dB)
%   on an energy basis:  L_tot = 10*log10( sum 10^(Li/10) ).
%   R has fields:
%       .total     combined level (dB)
%       .pressure  equivalent RMS pressure (Pa), using p_ref = 2e-5
%       .steps     worked-step strings
%
%   Example:
%       acoustics.combineLevels([80 80 74]).total   % 83.44 dB
    arguments
        levels (1,:) double
    end
    C = constants();
    e = 10.^(levels/10);
    s = sum(e);
    R.total = 10*log10(s);
    R.pressure = C.PREF * 10^(R.total/20);
    terms = strjoin(arrayfun(@(x) sprintf('10^(%.4g/10)', x), levels, ...
        'UniformOutput', false), ' + ');
    R.steps = { ...
        'L_tot = 10*log10( sum 10^(Li/10) )', ...
        sprintf('= 10*log10( %s )', terms), ...
        sprintf('= 10*log10( %.5g ) = %.2f dB', s, R.total)};
end
