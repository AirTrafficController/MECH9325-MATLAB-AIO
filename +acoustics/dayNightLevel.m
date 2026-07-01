function R = dayNightLevel(Lday, Lnight)
%DAYNIGHTLEVEL  Community day-night average sound level Ldn.
%   R = ACOUSTICS.DAYNIGHTLEVEL(Lday, Lnight) with the 15 h daytime LAeq and
%   the 9 h night-time LAeq (dB(A)) applies the 10 dB night penalty:
%       Ldn = 10*log10( (1/24)[ 15*10^(Lday/10) + 9*10^((Lnight+10)/10) ] )
%   R has fields .Ldn (dB(A)) and .steps.
    arguments
        Lday   (1,1) double
        Lnight (1,1) double
    end
    ed = 15*10^(Lday/10);
    en = 9*10^((Lnight+10)/10);
    R.Ldn = 10*log10((ed + en)/24);
    R.steps = { ...
        'Ldn = 10*log10( (1/24)[ 15*10^(Lday/10) + 9*10^((Lnight+10)/10) ] )', ...
        sprintf('= 10*log10( (1/24)[ %.4g + %.4g ] )', ed, en), ...
        sprintf('= 10*log10( %.5g ) = %.2f dB(A)', (ed+en)/24, R.Ldn)};
end
