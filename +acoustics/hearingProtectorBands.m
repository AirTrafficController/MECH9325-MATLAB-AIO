function R = hearingProtectorBands(freq, Lp, meanAtt, stdAtt, opts)
%HEARINGPROTECTORBANDS  A-weighted level at the ear, octave-band mean+/-SD method.
%   R = ACOUSTICS.HEARINGPROTECTORBANDS(freq, Lp, meanAtt, stdAtt) estimates
%   the A-weighted sound pressure level under a hearing protector from octave
%   band data (all inputs same-length vectors):
%       freq     octave band centre frequencies (Hz)
%       Lp       octave band sound pressure levels (dB)
%       meanAtt  mean protector attenuation per band (dB)
%       stdAtt   standard deviation of the attenuation per band (dB)
%   Per band the assumed attenuation is  meanAtt - k*stdAtt  (least/worst-case
%   protection for k>0, i.e. the "maximum" ear level), so
%       L_ear      = Lp - (meanAtt - k*stdAtt)
%       L_ear,A    = L_ear + A-weighting(freq)
%       LA         = 10*log10( sum 10^(L_ear,A/10) )
%   Option 'k' sets the SD multiplier (default 1): k=0 mean only, k=1
%   (mean-1SD, Bies & Hansen), k=2 (mean-2SD). 'net' picks the weighting
%   network ('A' default, 'Z' for unweighted).
%
%   R has fields .LA (protected, weighted), .LAunprot (no protector, same
%   network), .reduction (dB), .perBand (a table: freq Lp assumedAtt L_ear
%   L_ear_weighted) and .steps.
%
%   Example (NAL EML-45 muffs, k=1 -> LA = 93.0 dB(A)):
%       f =[125 250 500 1000 2000 4000 8000];
%       Lp=[102 103 104 95 91 98 98];
%       m =[5.3 8.5 15.9 26 25.4 35.7 27.2];
%       s =[4.6 2.4 4.6 4.3 5.5 4.1 5.5];
%       acoustics.hearingProtectorBands(f,Lp,m,s).LA
    arguments
        freq    (1,:) double {mustBePositive}
        Lp      (1,:) double
        meanAtt (1,:) double
        stdAtt  (1,:) double
        opts.k   (1,1) double = 1
        opts.net (1,1) char {mustBeMember(opts.net,{'A','B','C','Z'})} = 'A'
    end
    n = numel(freq);
    if ~all([numel(Lp) numel(meanAtt) numel(stdAtt)] == n)
        error('acoustics:hearingProtectorBands:size', ...
            'freq, Lp, meanAtt and stdAtt must be the same length.');
    end
    assumed = meanAtt - opts.k*stdAtt;      % least protection -> highest ear level
    Lear    = Lp - assumed;                 % under the protector, per band
    wt      = arrayfun(@(f) acoustics.weightingValue(f, opts.net), freq);
    LearW   = Lear + wt;                    % weighted, under protector
    LpW     = Lp   + wt;                    % weighted, no protector
    R.LA        = 10*log10(sum(10.^(LearW/10)));
    R.LAunprot  = 10*log10(sum(10.^(LpW/10)));
    R.reduction = R.LAunprot - R.LA;
    R.perBand   = [freq(:), Lp(:), assumed(:), Lear(:), LearW(:)];
    kstr = sprintf('mean - %g*SD', opts.k);
    if opts.k == 0, kstr = 'mean'; end
    R.steps = { ...
        sprintf('Assumed attenuation per band = %s', kstr), ...
        sprintf('L_ear = Lp - (mean - %g*SD),  then %s-weight and energy-sum', opts.k, opts.net), ...
        sprintf('L%c (under protector) = %.2f dB', opts.net, R.LA), ...
        sprintf('L%c (no protector)    = %.2f dB   -> reduction %.2f dB', ...
            opts.net, R.LAunprot, R.reduction)};
end
