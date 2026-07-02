function R = bandWorkbench(thirds, levels, net)
%BANDWORKBENCH  Combine 1/3-octave levels into octaves and an overall level.
%   R = ACOUSTICS.BANDWORKBENCH(thirds, levels, net) takes 1/3-octave centre
%   frequencies and their SPLs (dB) and, grouping successive triplets,
%   returns octave-band SPLs, the overall SPL and the overall weighted level:
%       octave SPL = 10*log10( sum 10^(L_third/10) ) over its 3 thirds
%       overall    = 10*log10( sum 10^(L_oct/10) )
%       weighted   = 10*log10( sum 10^((L_oct + W_oct)/10) )
%   R has fields .octaveFreq, .octaveSPL (vectors), .overall (dB),
%   .weighted (dB) and .steps.
    arguments
        thirds (1,:) double {mustBePositive}
        levels (1,:) double
        net    (1,1) char {mustBeMember(net,{'A','B','C','Z'})}
    end
    if numel(thirds) ~= numel(levels)
        error('acoustics:bandWorkbench:size', 'thirds and levels must match.');
    end
    octF = []; octL = []; lines = {'(a) Octave band SPLs:'};
    for i = 1:3:numel(thirds)-2
        trio = levels(i:i+2);
        spl = 10*log10(sum(10.^(trio/10)));
        octF(end+1) = thirds(i+1); octL(end+1) = spl; %#ok<AGROW>
        combo = strjoin(arrayfun(@(x) sprintf('%g', x), trio, ...
            'UniformOutput', false), '+');
        lines{end+1} = sprintf('   %6g Hz : %s -> %.2f dB', thirds(i+1), combo, spl); %#ok<AGROW>
    end
    R.octaveFreq = octF; R.octaveSPL = octL;
    R.overall = 10*log10(sum(10.^(octL/10)));
    w = arrayfun(@(f) weightingValue(f, net), octF);
    R.weighted = 10*log10(sum(10.^((octL + w)/10)));
    tag = 'dB'; if net ~= 'Z', tag = sprintf('dB(%c)', net); end
    R.steps = [lines, { ...
        sprintf('(b) Overall SPL      = %.2f dB', R.overall), ...
        sprintf('(b) Overall weighted = %.2f %s', R.weighted, tag)}];
end
