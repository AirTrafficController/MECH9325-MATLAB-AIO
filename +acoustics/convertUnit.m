function R = convertUnit(value, fromUnit, toUnit)
%CONVERTUNIT  Convert acoustic quantities between units and metric prefixes.
%   R = ACOUSTICS.CONVERTUNIT(value, fromUnit, toUnit) converts VALUE from one
%   unit to another (same physical dimension). R has fields .value, .from,
%   .to, .dimension and .steps.
%
%   Metric prefixes are parsed generically onto the base units
%   Pa, W, Hz, s, m, g, V, rayl:
%       f (1e-15) p (1e-12) n (1e-9) u/µ (1e-6) m (1e-3) c (1e-2) d (1e-1)
%       da (1e1) h (1e2) k (1e3) M (1e6) G (1e9) T (1e12)
%   e.g. uPa, kPa, MPa, hPa, nm, um, mm, km, mW, uW, pW, fW, kHz, MHz, ms, us.
%
%   Also recognised (non-prefixed):
%       pressure : bar mbar atm psi mmHg torr dyn/cm2
%       length   : in inch ft yd mile
%       time     : min hr h day
%       frequency: rad/s rpm
%       area     : m2 cm2 mm2 km2      volume: m3 L mL cm3 mm3
%       speed    : m/s km/h ft/s mph knot
%       mass     : kg t tonne          density: kg/m3 g/cm3 g/m3
%       intensity: W/m2 mW/m2 uW/m2 nW/m2 pW/m2
%       temperature: C K F  (affine)
%
%   Examples:
%       acoustics.convertUnit(2e-5, 'Pa', 'uPa').value     % 20   (p_ref)
%       acoustics.convertUnit(1e-12,'W','pW').value        % 1    (W_ref)
%       acoustics.convertUnit(1, 'atm', 'kPa').value       % 101.325
%       acoustics.convertUnit(1616.3,'rad/s','Hz').value   % 257.2
%       acoustics.convertUnit(20, 'C', 'K').value          % 293.15
    arguments
        value    (1,1) double
        fromUnit (1,1) string
        toUnit   (1,1) string
    end
    a = parseUnit(char(fromUnit));
    b = parseUnit(char(toUnit));

    if ~isempty(a.temp) || ~isempty(b.temp)
        if isempty(a.temp) || isempty(b.temp)
            error('acoustics:convertUnit:temp', 'Both units must be temperatures (C/K/F).');
        end
        K = toKelvin(value, a.temp);
        R.value = fromKelvin(K, b.temp);
        R.from = char(fromUnit); R.to = char(toUnit); R.dimension = 'temperature';
        R.steps = { sprintf('%g %s = %.6g K = %.6g %s', value, char(fromUnit), ...
            K, R.value, char(toUnit)) };
        return;
    end

    if ~strcmp(a.dim, b.dim)
        error('acoustics:convertUnit:dim', ...
            'Incompatible units: "%s" is %s but "%s" is %s.', ...
            char(fromUnit), a.dim, char(toUnit), b.dim);
    end
    base = value * a.factor;                 % value in the SI base unit
    R.value = base / b.factor;
    R.from = char(fromUnit); R.to = char(toUnit); R.dimension = a.dim;
    R.steps = { ...
        sprintf('%s: 1 %s = %.6g (SI base), 1 %s = %.6g (SI base)', ...
            a.dim, char(fromUnit), a.factor, char(toUnit), b.factor), ...
        sprintf('%g %s = %.6g (SI) = %.6g %s', value, char(fromUnit), base, R.value, char(toUnit))};
end

% ======================================================================
function s = parseUnit(u)
    u = strtrim(u);
    s.temp = '';
    switch u
        case {'C','degC'}, s.temp='C'; s.dim='temperature'; s.factor=1; return;
        case {'K','degK'}, s.temp='K'; s.dim='temperature'; s.factor=1; return;
        case {'F','degF'}, s.temp='F'; s.dim='temperature'; s.factor=1; return;
    end
    sp = specialMap();
    if isKey(sp, u)
        v = sp(u); s.dim = v{1}; s.factor = v{2}; return;
    end
    bm = baseMap(); pm = prefixMap();
    names = keys(bm);
    [~, ord] = sort(cellfun(@numel, names), 'descend');   % longest base first
    names = names(ord);
    for i = 1:numel(names)
        b = names{i};
        if numel(u) >= numel(b) && strcmp(u(end-numel(b)+1:end), b)
            pre = u(1:end-numel(b));
            if isempty(pre)
                pf = 1;
            elseif isKey(pm, pre)
                pf = pm(pre);
            else
                continue;                 % leading text is not a valid prefix
            end
            v = bm(b); s.dim = v{1}; s.factor = pf*v{2}; return;
        end
    end
    error('acoustics:convertUnit:unknown', 'Unknown unit: "%s".', u);
end

function m = prefixMap()
    m = containers.Map( ...
        {'f','p','n','u','µ','m','c','d','da','h','k','M','G','T'}, ...
        {1e-15,1e-12,1e-9,1e-6,1e-6,1e-3,1e-2,1e-1,1e1,1e2,1e3,1e6,1e9,1e12});
end

function m = baseMap()
    m = containers.Map( ...
        {'Pa','W','Hz','s','m','g','V','rayl'}, ...
        {{'pressure',1},{'power',1},{'frequency',1},{'time',1}, ...
         {'length',1},{'mass',1e-3},{'voltage',1},{'impedance',1}});
end

function m = specialMap()
    k = {'bar','mbar','atm','psi','mmHg','torr','dyn/cm2', ...
         'in','inch','ft','yd','mile', ...
         'min','hr','h','day', ...
         'rad/s','rpm', ...
         'm2','cm2','mm2','km2','m3','L','mL','cm3','mm3', ...
         'm/s','km/h','ft/s','mph','knot', ...
         'kg','t','tonne','kg/m3','g/cm3','g/m3', ...
         'W/m2','mW/m2','uW/m2','nW/m2','pW/m2'};
    v = {{'pressure',1e5},{'pressure',1e2},{'pressure',101325},{'pressure',6894.757293}, ...
         {'pressure',133.322},{'pressure',133.322},{'pressure',0.1}, ...
         {'length',0.0254},{'length',0.0254},{'length',0.3048},{'length',0.9144},{'length',1609.344}, ...
         {'time',60},{'time',3600},{'time',3600},{'time',86400}, ...
         {'frequency',1/(2*pi)},{'frequency',1/60}, ...
         {'area',1},{'area',1e-4},{'area',1e-6},{'area',1e6}, ...
         {'volume',1},{'volume',1e-3},{'volume',1e-6},{'volume',1e-6},{'volume',1e-9}, ...
         {'speed',1},{'speed',1/3.6},{'speed',0.3048},{'speed',0.44704},{'speed',0.514444}, ...
         {'mass',1},{'mass',1000},{'mass',1000}, ...
         {'density',1},{'density',1000},{'density',1e-3}, ...
         {'intensity',1},{'intensity',1e-3},{'intensity',1e-6},{'intensity',1e-9},{'intensity',1e-12}};
    m = containers.Map(k, v);
end

function K = toKelvin(v, t)
    switch t
        case 'C', K = v + 273.15;
        case 'F', K = (v - 32)*5/9 + 273.15;
        otherwise, K = v;                       % K
    end
end

function v = fromKelvin(K, t)
    switch t
        case 'C', v = K - 273.15;
        case 'F', v = (K - 273.15)*9/5 + 32;
        otherwise, v = K;                       % K
    end
end
