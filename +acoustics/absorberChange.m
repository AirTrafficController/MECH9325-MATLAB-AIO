function R = absorberChange(V, T60, Sabs, alpha, opts)
%ABSORBERCHANGE  Reverberant-field level change from adding/removing absorber.
%   R = ACOUSTICS.ABSORBERCHANGE(V, T60, Sabs, alpha) computes the change in
%   reverberant SPL in a room of volume V (m^3) whose current reverberation
%   time is T60 (s) when a patch of absorber of area Sabs (m^2) and
%   coefficient alpha is added (default) or removed:
%       A1 = 0.161*V / T60          existing absorption
%       A_abs = Sabs * alpha        absorber contribution
%       A2 = A1 +/- A_abs           new absorption
%       dLp = 10*log10(A1 / A2)     level change (negative when adding)
%   Use 'mode',"remove" to remove absorber (A2 = A1 - A_abs). R has fields
%   .A1, .Aabs, .A2 (m^2), .deltaLp (dB) and .steps.
    arguments
        V     (1,1) double {mustBePositive}
        T60   (1,1) double {mustBePositive}
        Sabs  (1,1) double {mustBePositive}
        alpha (1,1) double {mustBeNonnegative}
        opts.mode (1,1) string {mustBeMember(opts.mode,["add","remove"])} = "add"
    end
    R.A1 = 0.161*V/T60;
    R.Aabs = Sabs*alpha;
    if opts.mode == "remove"
        R.A2 = R.A1 - R.Aabs; sign = '-';
    else
        R.A2 = R.A1 + R.Aabs; sign = '+';
    end
    if ~(R.A2 > 0)
        error('acoustics:absorberChange:A2', ...
            'Absorber exceeds room absorption (A2 <= 0).');
    end
    R.deltaLp = 10*log10(R.A1/R.A2);
    R.steps = { ...
        sprintf('A1 = 0.161*V/T60 = 0.161*%g/%g = %.3f m^2', V, T60, R.A1), ...
        sprintf('A_abs = Sabs*alpha = %g*%g = %.3f m^2', Sabs, alpha, R.Aabs), ...
        sprintf('A2 = A1 %s A_abs = %.3f m^2', sign, R.A2), ...
        sprintf('dLp = 10*log10(A1/A2) = 10*log10(%.3f/%.3f) = %+.2f dB', ...
            R.A1, R.A2, R.deltaLp)};
end
