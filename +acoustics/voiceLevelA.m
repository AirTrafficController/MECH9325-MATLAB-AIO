function R = voiceLevelA(SIL, r)
%VOICELEVELA  Required A-weighted voice level and communication verdict.
%   R = ACOUSTICS.VOICELEVELA(SIL, r) applies Unit 5 Eq 5.6 to find the
%   A-weighted voice level a talker must produce for just-reliable speech
%   communication over distance r (m) against a speech interference level
%   SIL (dB):
%       VL_A >= (4/3)*(SIL + 20*log10(r)) - 36
%   The result is compared with the Table 5.2 voice-effort levels
%   (dB(A)):  Normal 57, Raised 65, Very loud 74, Shouting 82,
%   Peak shouting 88.  If VL_A exceeds the 88 dB(A) peak-shouting limit,
%   communication is not possible. R has fields:
%       .VLA        required A-weighted voice level (dB(A))
%       .effort     the voice effort category required
%       .possible   logical, true when VL_A <= 88 dB(A)
%       .steps      worked-step strings
%
%   Example (ship engine-room, SIL = 103.67, r = 1 m):
%       v = acoustics.voiceLevelA(103.67, 1);
%       v.VLA        % 102.23 dB(A)
%       v.possible   % false (> 88 dB(A) peak shouting)
    arguments
        SIL (1,1) double
        r   (1,1) double {mustBePositive}
    end
    R.VLA = (4/3)*(SIL + 20*log10(r)) - 36;

    % Table 5.2 voice-effort levels (dB(A))
    thresholds = [57 65 74 82 88];
    names = {'Normal','Raised','Very loud','Shouting','Peak shouting'};
    idx = find(R.VLA <= thresholds, 1);
    if isempty(idx)
        R.effort = 'Beyond peak shouting';
        R.possible = false;
    else
        R.effort = names{idx};
        R.possible = true;
    end

    verdict = 'communication possible';
    if ~R.possible
        verdict = 'communication NOT possible (exceeds 88 dB(A) peak shouting)';
    end
    R.steps = { ...
        'VL_A = (4/3)*(SIL + 20*log10(r)) - 36   [Unit 5 Eq 5.6]', ...
        sprintf('= (4/3)*(%.2f + 20*log10(%g)) - 36', SIL, r), ...
        sprintf('= (4/3)*(%.2f) - 36 = %.2f dB(A)', SIL + 20*log10(r), R.VLA), ...
        sprintf('Required voice effort (Table 5.2): %s', R.effort), ...
        sprintf('Verdict: %s', verdict)};
end
