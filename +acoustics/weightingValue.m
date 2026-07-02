function w = weightingValue(freq, net)
%WEIGHTINGVALUE  Relative response (dB) of a weighting network at a frequency.
%   w = ACOUSTICS.WEIGHTINGVALUE(freq, net) looks up the A/B/C weighting
%   value (dB) at the standard band centre FREQ (Hz). NET is one of
%   'A','B','C' or 'Z' (no weighting -> 0). Non-standard frequencies not
%   present in the table return 0.
%
%   See also ACOUSTICS.WEIGHTINGTABLE, ACOUSTICS.WEIGHTEDOVERALL.
    arguments
        freq (1,1) double {mustBePositive}
        net  (1,1) char {mustBeMember(net,{'A','B','C','Z'})}
    end
    if net == 'Z'
        w = 0; return;
    end
    T = weightingTable();
    col = struct('A',2,'B',3,'C',4);
    row = find(abs(T(:,1) - freq) < 1e-6, 1);
    if isempty(row)
        w = 0;
    else
        w = T(row, col.(net));
    end
end
