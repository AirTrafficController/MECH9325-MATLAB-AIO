function R = environmentalK2(S, A)
%ENVIRONMENTALK2  Environmental (room reflection) correction K2.
%   R = ACOUSTICS.ENVIRONMENTALK2(S, A) with measurement surface S (m^2) and
%   room absorption area A (m^2) returns:
%       K2 = 10*log10( 1 + 4*S/A )
%   R has fields .K2 (dB) and .steps.
    arguments
        S (1,1) double {mustBePositive}
        A (1,1) double {mustBePositive}
    end
    R.K2 = 10*log10(1 + 4*S/A);
    R.steps = { ...
        'K2 = 10*log10(1 + 4S/A)', ...
        sprintf('= 10*log10(1 + 4*%g/%g) = %.3f dB', S, A, R.K2)};
end
