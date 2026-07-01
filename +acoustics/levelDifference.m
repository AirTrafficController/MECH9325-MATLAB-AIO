function R = levelDifference(before, after)
%LEVELDIFFERENCE  Level difference for TL / IL / NR.
%   R = ACOUSTICS.LEVELDIFFERENCE(before, after) returns the difference
%   between two levels (dB). The same subtraction underlies:
%       TL = Lw1 - Lw2          (transmission loss)
%       IL = L_before - L_after (insertion loss)
%       NR = L_in - L_out       (noise reduction)
%   R has fields .difference (dB) and .steps.
    arguments
        before (1,1) double
        after  (1,1) double
    end
    R.difference = before - after;
    R.steps = { ...
        sprintf('Difference = %g - %g = %.2f dB', before, after, R.difference), ...
        '(TL = Lw1 - Lw2 · IL = L_before - L_after · NR = L_in - L_out)'};
end
