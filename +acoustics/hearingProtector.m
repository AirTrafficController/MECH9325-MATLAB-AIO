function R = hearingProtector(LCeq, SLC80)
%HEARINGPROTECTOR  Protected A-weighted level using the SLC80 method.
%   R = ACOUSTICS.HEARINGPROTECTOR(LCeq, SLC80) estimates the A-weighted level
%   under a hearing protector (ear muff/plug) using the AS/NZS 1269 Sound Level
%   Conversion method:
%       LAeq' = LCeq - SLC80
%   where LCeq is the C-weighted equivalent noise level (dB(C)) and SLC80 is
%   the protector's Sound Level Conversion rating (dB). Note the SLC80 is
%   subtracted from the C-weighted level, not the A-weighted one.
%
%   (Tip: LCeq comes from C-weighting the octave bands and energy-averaging
%   over time. When the C-weighting is ~0 dB in the important bands, LCeq
%   equals the linear Leq.)
%
%   R has fields .protectedLAeq (dB(A)) and .steps.
%
%   Example (Leq,8h = LCeq = 99.72 dB, muffs SLC80 = 27 dB):
%       acoustics.hearingProtector(99.721, 27).protectedLAeq    % 72.72 dB(A)
    arguments
        LCeq  (1,1) double
        SLC80 (1,1) double {mustBeNonnegative}
    end
    R.protectedLAeq = LCeq - SLC80;
    R.steps = { ...
        'Protected level (AS/NZS 1269, SLC80 method):', ...
        'LAeq'' = LCeq - SLC80   (SLC80 subtracted from the C-weighted level)', ...
        sprintf('= %.2f - %.2f = %.2f dB(A)', LCeq, SLC80, R.protectedLAeq)};
end
