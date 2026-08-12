function R = panelTL(freqs, F, deflection, L, W, thickness, density, opts)
%PANELTL  Transmission loss of a resonant single panel (mass + stiffness).
%   R = ACOUSTICS.PANELTL(freqs, F, deflection, L, W, thickness, density)
%   models a panel as an undamped mass-spring system and returns its natural
%   frequency and the sound transmission loss at each frequency in FREQS (Hz).
%
%   The stiffness comes from a static test (force F in N deflecting the centre
%   by DEFLECTION in m); the mass from the panel geometry and density:
%       A    = L*W                     panel area (m^2)
%       k    = F / deflection          total stiffness (N/m)
%       m''  = density * thickness     surface mass (kg/m^2)
%       s''  = k / A                   stiffness per unit area (N/m^3)
%       fn   = (1/2pi) sqrt(s''/m'')   natural frequency (Hz)
%   The TL uses the DOMINANT reactance in each region (the course method):
%       f <  fn  (stiffness-controlled):  TL = 20*log10( s'' / (2 rho c * w) )
%       f >= fn  (mass-controlled/mass law): TL = 20*log10( w*m'' / (2 rho c) )
%   with w = 2*pi*f. All lengths in metres. 'rhoc' defaults to 415 rayls.
%
%   R has fields .area, .k, .surfaceMass, .stiffnessPerArea, .fn, .TL (1xN),
%   .region (1xN string), .freqs and .steps.
%
%   Example (skylight glass panel, 197x98 mm, 14 mm, 1045 N -> 0.8 mm):
%       R = acoustics.panelTL([100 1000], 1045, 0.8e-3, 0.197, 0.098, 0.014, 2500);
%       R.fn      % 221.3 Hz
%       R.TL      % [42.3  48.5] dB
    arguments
        freqs      (1,:) double {mustBePositive}
        F          (1,1) double {mustBePositive}
        deflection (1,1) double {mustBePositive}
        L          (1,1) double {mustBePositive}
        W          (1,1) double {mustBePositive}
        thickness  (1,1) double {mustBePositive}
        density    (1,1) double {mustBePositive}
        opts.rhoc  (1,1) double {mustBePositive} = 415
    end
    R.area = L*W;
    R.k = F/deflection;
    R.surfaceMass = density*thickness;
    R.stiffnessPerArea = R.k/R.area;
    R.fn = sqrt(R.stiffnessPerArea/R.surfaceMass)/(2*pi);
    R.freqs = freqs;

    w = 2*pi*freqs;
    Xmass  = w*R.surfaceMass;                 % mass reactance
    Xstiff = R.stiffnessPerArea./w;           % stiffness reactance
    below  = freqs < R.fn;
    X = Xmass; X(below) = Xstiff(below);      % dominant reactance per region
    R.TL = 20*log10(X/(2*opts.rhoc));
    R.region = repmat("mass-controlled (mass law)", 1, numel(freqs));
    R.region(below) = "stiffness-controlled";

    lines = { ...
        'RESONANT SINGLE PANEL (mass + stiffness, no damping)', ...
        sprintf('A = L*W = %.5g m^2 · m" = rho*t = %.1f kg/m^2', R.area, R.surfaceMass), ...
        sprintf('k = F/deflection = %g/%g = %.4g N/m · s" = k/A = %.4g N/m^3', ...
            F, deflection, R.k, R.stiffnessPerArea), ...
        sprintf('(a) fn = (1/2pi) sqrt(s"/m") = %.1f Hz', R.fn), ...
        'Below fn: TL = 20*log10(s"/(2 rho c w));  above fn: TL = 20*log10(w m"/(2 rho c))'};
    for i = 1:numel(freqs)
        lines{end+1} = sprintf('    f = %g Hz  [%s]  ->  TL = %.1f dB', ...
            freqs(i), R.region(i), R.TL(i)); %#ok<AGROW>
    end
    R.steps = lines;
end
