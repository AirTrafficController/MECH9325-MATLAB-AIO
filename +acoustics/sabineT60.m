function R = sabineT60(opts)
%SABINET60  Sabine reverberation time, solving for any one unknown.
%   R = ACOUSTICS.SABINET60('V',..,'S',..,'alpha',..,'T60',..) solves the
%   Sabine equation for whichever ONE of the four is left out (NaN/omitted):
%       T60 = 0.161 * V / (alpha * S)
%   Supply exactly three of V (m^3), S (m^2), alpha, T60 (s). R has fields
%   .V, .S, .alpha, .T60, .A (= alpha*S) and .steps.
%
%   Example:
%       acoustics.sabineT60('V',200,'S',240,'alpha',0.15).T60
    arguments
        opts.V     double = NaN
        opts.S     double = NaN
        opts.alpha double = NaN
        opts.T60   double = NaN
    end
    V = opts.V; S = opts.S; a = opts.alpha; T = opts.T60;
    miss = isnan(V) + isnan(S) + isnan(a) + isnan(T);
    if miss ~= 1
        error('acoustics:sabineT60:input', ...
            'Supply exactly three of V, S, alpha, T60 (leave one out).');
    end
    if isnan(T),     T = 0.161*V/(a*S);
    elseif isnan(a), a = 0.161*V/(T*S);
    elseif isnan(S), S = 0.161*V/(T*a);
    else,            V = T*a*S/0.161;
    end
    R.V = V; R.S = S; R.alpha = a; R.T60 = T; R.A = a*S;
    R.steps = { ...
        'T60 = 0.161*V / (alpha*S)', ...
        sprintf('= 0.161*%.4g / (%.4f*%.4g) = %.3f / %.3f = %.3f s', ...
            V, a, S, 0.161*V, a*S, T), ...
        sprintf('Absorption A = alpha*S = %.2f m^2', R.A)};
end
