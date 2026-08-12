function R = doublePanelTL(f, opts)
%DOUBLEPANELTL  TL of panels in series (composite barrier): TL = sum of TLi.
%   Two (or more) panels in series pass a fraction alpha_i of the incident
%   intensity each, so the overall transmission coefficient is the PRODUCT
%       alpha_t = alpha_1 * alpha_2 * ...
%   and the transmission loss is the SUM of the individual panel TLs
%       TL = -10 log10(alpha_t) = TL_1 + TL_2 + ...
%   (This is the workshop/lecture model for a composite double panel.)
%
%   R = ACOUSTICS.DOUBLEPANELTL(f, 'masses', [m1 m2 ...]) gives each panel's
%   normal-incidence mass-law TL, TLi = 20*log10(mi*f) - 42.4, then sums them.
%   f may be a vector (Hz). Alternatively give 'TL', [TL1 TL2 ...] to sum
%   TLs you already have (f is then ignored for the panel TLs).
%
%   Options: 'constant' (42.4 dB mass-law term). R has fields .f, .TL (dB,
%   per frequency), .TLpanels (per-panel TL at each f), .alphaT and .steps.
%
%   Example (two 16 kg/m^2 timber panels, composite barrier):
%       R = acoustics.doublePanelTL([100 300 1000], 'masses', [16 16]);
%       R.TL      % [43.4  62.4  83.4] dB
    arguments
        f double = NaN
        opts.masses double = []
        opts.TL     double = []
        opts.constant (1,1) double = 42.4
    end
    K = opts.constant;

    if ~isempty(opts.TL)                     % TLs supplied directly
        tl = opts.TL(:).';
        R.f = NaN;
        R.TLpanels = tl;
        R.TL = sum(tl);
        R.alphaT = prod(10.^(-tl/10));
        R.steps = { ...
            sprintf('Panels in series: alpha_t = prod(alpha_i), TL = sum(TL_i)'), ...
            sprintf('TL = %s = %.1f dB', ...
                strjoin(arrayfun(@(x) sprintf('%.2f',x), tl, 'UniformOutput',false),' + '), R.TL), ...
            sprintf('alpha_t = %.4g', R.alphaT)};
        return;
    end

    if isempty(opts.masses) || any(isnan(f))
        error('acoustics:doublePanelTL:input', ...
            'Provide masses (and frequency f), or TL values directly.');
    end
    m = opts.masses(:).';
    f = f(:).';
    R.f = f;
    R.TLpanels = zeros(numel(f), numel(m));
    R.TL = zeros(size(f));
    R.alphaT = zeros(size(f));
    lines = {'Panels in series: alpha_t = prod(alpha_i)  ->  TL = sum(TL_i)', ...
             'Each panel (mass law): TLi = 20*log10(mi*f) - 42.4', ''};
    for i = 1:numel(f)
        tli = 20*log10(m*f(i)) - K;
        R.TLpanels(i,:) = tli;
        R.TL(i) = sum(tli);
        R.alphaT(i) = prod(10.^(-tli/10));
        lines{end+1} = sprintf('f = %g Hz:  TL = %s = %.1f dB', f(i), ...
            strjoin(arrayfun(@(x) sprintf('%.2f',x), tli, 'UniformOutput',false),' + '), ...
            R.TL(i)); %#ok<AGROW>
    end
    R.steps = lines;
end
