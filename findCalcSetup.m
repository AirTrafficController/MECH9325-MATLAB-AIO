function findCalcSetup(key, url, model)
%FINDCALCSETUP  Save the AI re-rank key/URL/model ONCE so they persist.
%   FINDCALCSETUP(key) saves your API key (and the Anthropic/Claude Haiku
%   defaults) to a private file in your MATLAB userpath. After this,
%   findCalculatorExtra / findCalculator('useLLM',true) pick the key up
%   automatically every session and after every getAIO - no more setenv.
%
%   FINDCALCSETUP(key, url)         also set the endpoint (default Anthropic)
%   FINDCALCSETUP(key, url, model)  also set the model.
%
%   The model accepts jokey tier aliases (or a real model id):
%       'shit'   -> claude-haiku-4-5   (cheapest, fast; the default)
%       'ok'     -> claude-sonnet-5    (mid)
%       'decent' -> claude-opus-5      (best, priciest)
%   Use an empty url to keep the Anthropic default, e.g.
%       findCalcSetup('sk-ant-...', '', 'ok')     % Sonnet
%
%   FINDCALCSETUP('clear') deletes the saved config.
%
%   Example (run ONCE, then never again):
%       findCalcSetup('sk-ant-...your fresh key...')          % default 'shit'/Haiku
%
%   SECURITY: this stores your API key in PLAINTEXT in a file on THIS
%   machine (userpath/findcalc_ai.mat). It is NOT in the toolkit folder and
%   is never committed - but keep the machine private, and run
%   findCalcSetup('clear') on a shared computer when you are done.
    up = userpath;
    if isempty(up)
        error('findCalcSetup:noUserpath', ...
            'MATLAB userpath is empty; set one with userpath(''C:\\path'') first.');
    end
    f = fullfile(up, 'findcalc_ai.mat');

    if nargin == 1 && (strcmpi(key,'clear') || strcmpi(key,'reset'))
        if isfile(f), delete(f); end
        setenv('FINDCALC_LLM_KEY',''); setenv('FINDCALC_LLM_URL','');
        fprintf('Cleared saved AI config (%s).\n', f);
        return;
    end
    if nargin < 1 || isempty(key)
        error('findCalcSetup:noKey', 'Provide your API key: findCalcSetup(''sk-ant-...'')');
    end
    if nargin < 2 || isempty(url),   url   = 'https://api.anthropic.com/v1/messages'; end
    if nargin < 3 || isempty(model), model = 'claude-haiku-4-5'; end
    model = modelAlias(model);

    cfg = struct('key', char(key), 'url', char(url), 'model', char(model));
    save(f, 'cfg');
    % also set for the current session so it works immediately
    setenv('FINDCALC_LLM_KEY',   cfg.key);
    setenv('FINDCALC_LLM_URL',   cfg.url);
    setenv('FINDCALC_LLM_MODEL', cfg.model);

    fprintf('Saved AI config to %s\n', f);
    fprintf('   URL   : %s\n', cfg.url);
    fprintf('   Model : %s\n', cfg.model);
    fprintf('It persists across MATLAB sessions and getAIO - no more setenv.\n');
    fprintf('SECURITY: your key is stored in plaintext on this machine; keep it\n');
    fprintf('private. On a shared PC run findCalcSetup(''clear'') when finished.\n');
end

% ======================================================================
function m = modelAlias(m)
%MODELALIAS  Map jokey tier aliases to real model ids; pass real ids through.
    switch lower(strtrim(char(m)))
        case {'shit','cheap','basic','haiku'},  m = 'claude-haiku-4-5';
        case {'ok','mid','sonnet'},             m = 'claude-sonnet-5';
        case {'decent','best','good','opus'},   m = 'claude-opus-5';
        otherwise,                              m = char(m);   % assume a real id
    end
end
