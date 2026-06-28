classdef AcousticsApp < handle
    %ACOUSTICSAPP  Search-driven acoustics & noise calculator (MATLAB port).
    %   A programmatic App Designer style GUI mirroring the MECH9325 web app:
    %   a search box filters a list of calculators on the left; the selected
    %   calculator's form appears on the right. Run with:  AcousticsApp
    %
    %   Calculators: Levels, Combine, N identical, A/B/C Weighting,
    %   Band Workbench (1/3-octave -> octave -> overall), Leq (+SEL),
    %   Noise Dose, Distance.
    %
    %   No toolboxes required (base MATLAB R2016b+ for uifigure).

    properties
        Fig
        SearchField
        ListBox
        InfoLabel
        Content          % right-hand uipanel that hosts the active calculator
        Calcs            % struct array: name, tags, fn (builder handle)
        W                % struct of handles for the active calculator
        WTAB             % A/B/C weighting table  [freq A B C]
        THIRD            % 1/3-octave centre frequencies
    end

    methods
        function app = AcousticsApp()
            app.WTAB = acousticsData();
            app.THIRD = app.WTAB(:,1);
            app.buildUI();
            app.defineCalcs();
            app.refreshList('');
        end

        % ---------- top-level UI ----------
        function buildUI(app)
            app.Fig = uifigure('Name','Acoustics & Noise Toolkit', ...
                'Position',[100 100 980 620]);
            g = uigridlayout(app.Fig,[2 2]);
            g.RowHeight = {40,'1x'};
            g.ColumnWidth = {260,'1x'};

            % search box (spans top)
            s = uieditfield(g,'text','Placeholder', ...
                'Search calculators — SPL, dBA, Leq, octave, dose, distance…', ...
                'ValueChangingFcn',@(o,e) app.refreshList(e.Value));
            s.Layout.Row = 1; s.Layout.Column = [1 2];
            app.SearchField = s;

            % left: list of calculators + match info
            lg = uigridlayout(g,[2 1]); lg.Layout.Row = 2; lg.Layout.Column = 1;
            lg.RowHeight = {'1x',20}; lg.Padding = [0 0 0 0];
            app.ListBox = uilistbox(lg,'ValueChangedFcn',@(o,e) app.onSelect());
            app.ListBox.Layout.Row = 1;
            app.InfoLabel = uilabel(lg,'Text','','FontColor',[.4 .4 .4]);
            app.InfoLabel.Layout.Row = 2;

            % right: content panel
            app.Content = uipanel(g,'BorderType','none');
            app.Content.Layout.Row = 2; app.Content.Layout.Column = 2;
        end

        function defineCalcs(app)
            names = {'Levels: SPL / pressure / power', ...
                     'Combine sound levels', ...
                     'N identical sources', ...
                     'A / B / C Weighting', ...
                     'Band Workbench (1/3-oct -> octave)', ...
                     'Leq from levels & durations', ...
                     'Noise Dose & max time', ...
                     'Distance attenuation'};
            tags = {'spl pressure pascal sound power level lw intensity reference convert', ...
                    'combine add sum energy incoherent total decibel', ...
                    'n identical sources machines 10log10 total', ...
                    'weighting a b c dba dbc octave third overall spectrum', ...
                    'band workbench third octave overall a-weighted spl 9 bands', ...
                    'leq equivalent continuous duration sel exposure energy average', ...
                    'noise dose ohs 85 db exchange permissible time worker shift', ...
                    'distance attenuation point line spreading 6 3 db doubling traffic'};
            fns = {@app.buildLevels, @app.buildCombine, @app.buildNIdentical, ...
                   @app.buildWeighting, @app.buildBand, @app.buildLeq, ...
                   @app.buildDose, @app.buildDistance};
            app.Calcs = struct('name',names,'tags',tags,'fn',fns);
        end

        function refreshList(app, query)
            q = lower(strtrim(query));
            names = {app.Calcs.name};
            if isempty(q)
                keep = true(size(names));
            else
                hay = lower(strcat({app.Calcs.name}, {' '}, {app.Calcs.tags}));
                keep = cellfun(@(h) contains(h, q), hay);
            end
            shown = names(keep);
            if isempty(shown)
                app.ListBox.Items = {};
                app.InfoLabel.Text = 'no match';
                delete(app.Content.Children);
                return;
            end
            app.ListBox.Items = shown;
            if ~ismember(app.ListBox.Value, shown)
                app.ListBox.Value = shown{1};
            end
            if numel(shown) > 1
                app.InfoLabel.Text = sprintf('%d matches', numel(shown));
            else
                app.InfoLabel.Text = '1 match';
            end
            app.onSelect();
        end

        function onSelect(app)
            name = app.ListBox.Value;
            idx = find(strcmp({app.Calcs.name}, name), 1);
            if isempty(idx), return; end
            delete(app.Content.Children);
            app.W = struct();
            app.Calcs(idx).fn();
        end

        % ---------- shared form helpers ----------
        function gl = form(app, nrows)
            gl = uigridlayout(app.Content,[nrows 2]);
            gl.ColumnWidth = {180,'1x'};
            gl.RowHeight = repmat({32},1,nrows);
            gl.RowHeight{end} = '1x';
        end

        function out = resultBox(app, gl, row)
            out = uitextarea(gl,'Editable','off','FontName','monospaced');
            out.Layout.Row = row; out.Layout.Column = [1 2];
        end

        function h = numField(~, gl, row, label, val)
            l = uilabel(gl,'Text',label); l.Layout.Row = row; l.Layout.Column = 1;
            h = uieditfield(gl,'numeric','Value',val); h.Layout.Row = row; h.Layout.Column = 2;
        end

        function b = goButton(~, gl, row, cb)
            b = uibutton(gl,'Text','Compute','ButtonPushedFcn',cb);
            b.Layout.Row = row; b.Layout.Column = [1 2];
        end

        % ---------- calculators ----------
        function buildLevels(app)
            gl = app.form(4);
            app.W.lp = app.numField(gl,1,'Sound pressure level Lp (dB)',94);
            l = uilabel(gl,'Text','p = 2e-5*10^(Lp/20) Pa  ·  I = p^2/(rho c)','FontColor',[.5 .5 .5]);
            l.Layout.Row = 2; l.Layout.Column = [1 2];
            app.goButton(gl,3,@(o,e) app.runLevels());
            app.W.out = app.resultBox(gl,4);
        end
        function runLevels(app)
            Lp = app.W.lp.Value; p = 2e-5*10^(Lp/20); I = p^2/415;
            app.W.out.Value = { ...
                sprintf('RMS pressure p = %.4g Pa', p), ...
                sprintf('Intensity I    = %.4g W/m^2  (rho c = 415)', I), ...
                '', 'WORKING', ...
                sprintf('p = 2e-5 * 10^(Lp/20) = 2e-5 * 10^(%.4g/20) = %.4g Pa', Lp, p), ...
                sprintf('I = p^2/(rho*c)       = %.4g^2 / 415 = %.4g W/m^2', p, I) };
        end

        function buildCombine(app)
            gl = uigridlayout(app.Content,[4 1]);
            gl.RowHeight = {20,'1x',32,120};
            uilabel(gl,'Text','One level (dB) per line:');
            app.W.txt = uitextarea(gl,'Value',{'80','80','74'});
            uibutton(gl,'Text','Combine','ButtonPushedFcn',@(o,e) app.runCombine());
            app.W.out = uitextarea(gl,'Editable','off','FontName','monospaced');
        end
        function runCombine(app)
            L = app.parseCol(app.W.txt.Value);
            if isempty(L), app.W.out.Value = {'Enter at least one level.'}; return; end
            e = 10.^(L/10); s = sum(e); tot = 10*log10(s); p = 2e-5*10^(tot/20);
            terms = strjoin(arrayfun(@(x) sprintf('10^(%.4g/10)',x), L, ...
                'UniformOutput',false), ' + ');
            app.W.out.Value = { ...
                sprintf('Combined level = %.2f dB', tot), ...
                sprintf('RMS pressure   = %.4g Pa', p), ...
                '', 'WORKING', ...
                'L_tot = 10*log10( sum 10^(Li/10) )', ...
                sprintf('= 10*log10( %s )', terms), ...
                sprintf('= 10*log10( %.5g ) = %.2f dB', s, tot) };
        end

        function buildNIdentical(app)
            gl = app.form(4);
            app.W.L1 = app.numField(gl,1,'Level of one source L1 (dB)',77);
            app.W.N  = app.numField(gl,2,'Number of identical sources N',2);
            app.goButton(gl,3,@(o,e) app.runNIdentical());
            app.W.out = app.resultBox(gl,4);
        end
        function runNIdentical(app)
            L1 = app.W.L1.Value; N = app.W.N.Value;
            if N < 1, app.W.out.Value = {'N must be >= 1.'}; return; end
            tot = L1 + 10*log10(N);
            app.W.out.Value = { sprintf('Total of %g sources = %.2f dB', N, tot), ...
                '', 'WORKING', 'L_tot = L1 + 10*log10(N)', ...
                sprintf('= %.4g + 10*log10(%g)', L1, N), ...
                sprintf('= %.4g + %.4g = %.2f dB', L1, 10*log10(N), tot) };
        end

        function buildWeighting(app)
            gl = uigridlayout(app.Content,[5 2]);
            gl.RowHeight = {32,32,'1x',32,140}; gl.ColumnWidth = {140,'1x'};
            l1 = uilabel(gl,'Text','Spacing'); l1.Layout.Row = 1; l1.Layout.Column = 1;
            app.W.spacing = uidropdown(gl,'Items',{'Octave','1/3 Octave'}, ...
                'ValueChangedFcn',@(o,e) app.fillWeightTable());
            app.W.spacing.Layout.Row = 1; app.W.spacing.Layout.Column = 2;
            l2 = uilabel(gl,'Text','Network'); l2.Layout.Row = 2; l2.Layout.Column = 1;
            app.W.net = uidropdown(gl,'Items',{'A','B','C','Z (none)'});
            app.W.net.Layout.Row = 2; app.W.net.Layout.Column = 2;
            app.W.tbl = uitable(gl,'ColumnName',{'Freq (Hz)','Level (dB)'}, ...
                'ColumnEditable',[false true]);
            app.W.tbl.Layout.Row = 3; app.W.tbl.Layout.Column = [1 2];
            b = uibutton(gl,'Text','Calculate overall level','ButtonPushedFcn',@(o,e) app.runWeighting());
            b.Layout.Row = 4; b.Layout.Column = [1 2];
            app.W.out = uitextarea(gl,'Editable','off','FontName','monospaced');
            app.W.out.Layout.Row = 5; app.W.out.Layout.Column = [1 2];
            app.fillWeightTable();
        end
        function fillWeightTable(app)
            if strcmp(app.W.spacing.Value,'Octave')
                f = [63 125 250 500 1000 2000 4000 8000]';
            else
                f = app.THIRD;
            end
            app.W.tbl.Data = [num2cell(f), repmat({[]},numel(f),1)];
        end
        function runWeighting(app)
            d = app.W.tbl.Data; net = app.W.net.Value(1);
            f = []; L = [];
            for i = 1:size(d,1)
                v = d{i,2};
                if ~isempty(v) && ~isnan(v), f(end+1)=d{i,1}; L(end+1)=v; end %#ok<AGROW>
            end
            if isempty(L), app.W.out.Value = {'Enter at least one band level.'}; return; end
            w = arrayfun(@(x) app.weight(x,net), f);
            Lw = L + w;
            lin = app.dBsum(L); wtd = app.dBsum(Lw);
            tag = 'dB'; if net~='Z', tag = sprintf('dB(%c)',net); end
            lines = { sprintf('Overall %s = %.1f', tag, wtd), ...
                sprintf('Linear (unweighted) total = %.1f dB', lin), ...
                '', 'WORKING', 'L_W = 10*log10( sum 10^((Li+Wi)/10) )' };
            for i = 1:numel(f)
                lines{end+1} = sprintf('  %6g Hz: %g %+.1f = %.1f', f(i), L(i), w(i), Lw(i)); %#ok<AGROW>
            end
            lines{end+1} = sprintf('  => %.1f %s', wtd, tag);
            app.W.out.Value = lines;
        end

        function buildBand(app)
            gl = uigridlayout(app.Content,[4 2]);
            gl.RowHeight = {32,'1x',32,150}; gl.ColumnWidth = {140,'1x'};
            l = uilabel(gl,'Text','Weighting'); l.Layout.Row = 1; l.Layout.Column = 1;
            app.W.net = uidropdown(gl,'Items',{'A','B','C','Z (none)'});
            app.W.net.Layout.Row = 1; app.W.net.Layout.Column = 2;
            app.W.tbl = uitable(gl,'ColumnName',{'1/3-oct (Hz)','Level (dB)'}, ...
                'ColumnEditable',[false true], ...
                'Data',[num2cell(app.THIRD), repmat({[]},numel(app.THIRD),1)]);
            app.W.tbl.Layout.Row = 2; app.W.tbl.Layout.Column = [1 2];
            b = uibutton(gl,'Text','Analyse','ButtonPushedFcn',@(o,e) app.runBand());
            b.Layout.Row = 3; b.Layout.Column = [1 2];
            app.W.out = uitextarea(gl,'Editable','off','FontName','monospaced');
            app.W.out.Layout.Row = 4; app.W.out.Layout.Column = [1 2];
        end
        function runBand(app)
            d = app.W.tbl.Data; net = app.W.net.Value(1);
            lev = containers.Map('KeyType','double','ValueType','double');
            for i = 1:size(d,1)
                v = d{i,2};
                if ~isempty(v) && ~isnan(v), lev(d{i,1}) = v; end
            end
            if lev.Count == 0, app.W.out.Value = {'Enter at least one 1/3-octave level.'}; return; end
            T = app.THIRD; lines = {'(a) Octave band SPLs:'}; octSPL = []; octCtr = [];
            for i = 1:3:numel(T)-2
                trio = T(i:i+2); have = trio(arrayfun(@(f) isKey(lev,f), trio));
                if isempty(have), continue; end
                vals = arrayfun(@(f) lev(f), have);
                spl = app.dBsum(vals);
                octSPL(end+1) = spl; octCtr(end+1) = T(i+1); %#ok<AGROW>
                combo = strjoin(arrayfun(@(x) sprintf('%g',x), vals, 'UniformOutput',false), '+');
                lines{end+1} = sprintf('   %6g Hz : %s -> %.2f dB', T(i+1), combo, spl); %#ok<AGROW>
            end
            overall = app.dBsum(octSPL);
            w = arrayfun(@(c) app.weight(c,net), octCtr);
            wtd = app.dBsum(octSPL + w);
            tag = 'dB'; if net~='Z', tag = sprintf('dB(%c)',net); end
            lines{end+1} = '';
            lines{end+1} = sprintf('(b) Overall SPL      = %.2f dB', overall);
            lines{end+1} = sprintf('(b) Overall weighted = %.2f %s', wtd, tag);
            lines{end+1} = '';
            lines{end+1} = 'WORKING';
            lines{end+1} = 'octave SPL = 10*log10( sum 10^(L_third/10) ) over its 3 thirds';
            lines{end+1} = 'Overall    = 10*log10( sum 10^(L_oct/10) )';
            lines{end+1} = 'Weighted   = 10*log10( sum 10^((L_oct+W_oct)/10) )';
            app.W.out.Value = lines;
        end

        function buildLeq(app)
            gl = uigridlayout(app.Content,[5 2]);
            gl.RowHeight = {20,'1x',32,32,120}; gl.ColumnWidth = {140,'1x'};
            l = uilabel(gl,'Text','Level dB(A) and Duration (seconds) per row:');
            l.Layout.Row = 1; l.Layout.Column = [1 2];
            app.W.tbl = uitable(gl,'ColumnName',{'Level dB(A)','Duration (s)'}, ...
                'ColumnEditable',[true true], 'Data',{96,900;91,7200;99,360});
            app.W.tbl.Layout.Row = 2; app.W.tbl.Layout.Column = [1 2];
            addb = uibutton(gl,'Text','+ Add row','ButtonPushedFcn',@(o,e) app.addRow(app.W.tbl));
            addb.Layout.Row = 3; addb.Layout.Column = 1;
            lt = uilabel(gl,'Text','Reference T (s, 0 = use sum)'); lt.Layout.Row = 4; lt.Layout.Column = 1;
            app.W.T = uieditfield(gl,'numeric','Value',0); app.W.T.Layout.Row=4; app.W.T.Layout.Column=2;
            b = uibutton(gl,'Text','Compute Leq','ButtonPushedFcn',@(o,e) app.runLeq());
            b.Layout.Row = 3; b.Layout.Column = 2;
            app.W.out = uitextarea(gl,'Editable','off','FontName','monospaced');
            app.W.out.Layout.Row = 5; app.W.out.Layout.Column = [1 2];
        end
        function runLeq(app)
            [L,t] = app.readPairs(app.W.tbl);
            if isempty(L), app.W.out.Value = {'Enter level,duration rows.'}; return; end
            energy = sum(t .* 10.^(L/10)); sumT = sum(t);
            T = app.W.T.Value; if T <= 0, T = sumT; end
            leq = 10*log10(energy/T); sel = 10*log10(energy);   % energy in s*ratio -> /1s
            app.W.out.Value = { ...
                sprintf('Leq = %.3f dB   (sum t = %.4g s, T = %.4g s)', leq, sumT, T), ...
                sprintf('SEL (L_AE, over 1 s) = %.2f dB', sel), ...
                '', 'WORKING', ...
                'Leq = 10*log10( (1/T) * sum ti*10^(Li/10) )', ...
                sprintf('= 10*log10( (1/%.4g) * %.5g ) = %.3f dB', T, energy, leq), ...
                'SEL = 10*log10( sum ti*10^(Li/10) / 1s ) = Leq + 10*log10(T/1s)', ...
                sprintf('= %.3f + 10*log10(%.4g) = %.2f dB', leq, T, sel) };
        end

        function buildDose(app)
            gl = uigridlayout(app.Content,[7 2]);
            gl.RowHeight = {20,'1x',32,32,32,32,140}; gl.ColumnWidth = {160,'1x'};
            l = uilabel(gl,'Text','Level dB(A) and Duration (HOURS) per row:');
            l.Layout.Row = 1; l.Layout.Column = [1 2];
            app.W.tbl = uitable(gl,'ColumnName',{'Level dB(A)','Duration (h)'}, ...
                'ColumnEditable',[true true],'Data',{95,0.35;89,0.65});
            app.W.tbl.Layout.Row=2; app.W.tbl.Layout.Column=[1 2];
            addb = uibutton(gl,'Text','+ Add row','ButtonPushedFcn',@(o,e) app.addRow(app.W.tbl));
            addb.Layout.Row = 3; addb.Layout.Column = 1;
            b = uibutton(gl,'Text','Assess','ButtonPushedFcn',@(o,e) app.runDose());
            b.Layout.Row=3; b.Layout.Column=2;
            app.W.Lc = app.numField(gl,4,'Criterion Lc (dB(A))',85);
            app.W.q  = app.numField(gl,5,'Exchange rate q (dB)',3);
            app.W.Tc = app.numField(gl,6,'Criterion time Tc (h)',8);
            app.W.out = uitextarea(gl,'Editable','off','FontName','monospaced');
            app.W.out.Layout.Row=7; app.W.out.Layout.Column=[1 2];
        end
        function runDose(app)
            [L,t] = app.readPairs(app.W.tbl);
            if isempty(L), app.W.out.Value={'Enter level,duration rows.'}; return; end
            Lc = app.W.Lc.Value; q = app.W.q.Value; Tc = app.W.Tc.Value;
            energy = sum(t.*10.^(L/10)); sumT = sum(t);
            leqT  = 10*log10(energy/sumT);
            leq8  = 10*log10(energy/Tc);
            Ti = Tc ./ 2.^((L-Lc)/q); dose = sum(t./Ti);
            Tmax = Tc / 2^((leqT-Lc)/q);
            app.W.out.Value = { ...
                sprintf('L_Aeq,T  (over %.3g h) = %.3f dB(A)', sumT, leqT), ...
                sprintf('L_Aeq,%gh             = %.3f dB(A)', Tc, leq8), ...
                sprintf('Noise dose            = %.1f %%  (100%% = limit)', dose*100), ...
                sprintf('Exceeds %g dB(A)?      %s', Lc, ternary(leqT>Lc,'YES','No')), ...
                sprintf('Max permissible time  = %.3f h (%s)', Tmax, hm(Tmax)), ...
                '', 'WORKING', ...
                sprintf('L_Aeq,T = 10*log10( (1/%.3g) * sum ti*10^(Li/10) ) = %.3f dB(A)', sumT, leqT), ...
                sprintf('L_Aeq,%gh = L_Aeq,T + 10*log10(T/Tc) = %.3f + 10*log10(%.3g/%g) = %.3f', Tc, leqT, sumT, Tc, leq8), ...
                'Allowed time Ti = Tc / 2^((Li-Lc)/q)', ...
                sprintf('Dose = sum ti/Ti = %.4f = %.1f %%', dose, dose*100), ...
                sprintf('Tmax = Tc / 2^((L_Aeq,T-Lc)/q) = %g / 2^((%.2f-%g)/%g) = %.3f h', Tc, leqT, Lc, q, Tmax) };
        end

        function buildDistance(app)
            gl = app.form(5);
            app.W.L1 = app.numField(gl,1,'Known level L1 (dB)',78);
            app.W.r1 = app.numField(gl,2,'At distance r1 (m)',6.5);
            app.W.r2 = app.numField(gl,3,'New distance r2 (m)',65);
            app.goButton(gl,4,@(o,e) app.runDistance());
            app.W.out = app.resultBox(gl,5);
        end
        function runDistance(app)
            L1=app.W.L1.Value; r1=app.W.r1.Value; r2=app.W.r2.Value;
            if r1<=0 || r2<=0, app.W.out.Value={'Distances must be > 0.'}; return; end
            ratio = log10(r2/r1);
            app.W.out.Value = { ...
                sprintf('Point (spherical, -6 dB/doubling): L2 = %.2f dB', L1-20*ratio), ...
                sprintf('Line  (cylindrical, -3 dB/doubling): L2 = %.2f dB', L1-10*ratio), ...
                '', 'WORKING', ...
                sprintf('log10(r2/r1) = log10(%g/%g) = %.4f', r2, r1, ratio), ...
                sprintf('Point: L2 = L1 - 20*log10(r2/r1) = %.4g - %.2f = %.2f dB', L1, 20*ratio, L1-20*ratio), ...
                sprintf('Line:  L2 = L1 - 10*log10(r2/r1) = %.4g - %.2f = %.2f dB', L1, 10*ratio, L1-10*ratio) };
        end

        % ---------- small utilities ----------
        function addRow(~, tbl)
            tbl.Data(end+1,:) = {[],[]};
        end
        function [L,t] = readPairs(~, tbl)
            d = tbl.Data; L=[]; t=[];
            for i=1:size(d,1)
                a=d{i,1}; b=d{i,2};
                if ~isempty(a)&&~isnan(a)&&~isempty(b)&&~isnan(b), L(end+1)=a; t(end+1)=b; end %#ok<AGROW>
            end
        end
        function v = parseCol(~, c)
            if ischar(c), c = cellstr(c); end
            v = str2double(c); v = v(~isnan(v)); v = v(:)';
        end
        function L = dBsum(~, levels)
            L = 10*log10(sum(10.^(levels(:)/10)));
        end
        function w = weight(app, freq, net)
            if net=='Z', w=0; return; end
            col = struct('A',2,'B',3,'C',4); col = col.(net);
            row = find(app.WTAB(:,1)==freq,1);
            if isempty(row), w=0; else, w=app.WTAB(row,col); end
        end
    end
end

% ===== local functions (file-scope helpers) =====
function s = ternary(cond,a,b)
    if cond, s=a; else, s=b; end
end
function s = hm(hours)
    secs = round(hours*3600);
    h = floor(secs/3600); secs = secs-h*3600; m = floor(secs/60);
    if h>0 && m>0, s=sprintf('%d h %d min',h,m);
    elseif h>0,    s=sprintf('%d h',h);
    else,          s=sprintf('%d min',m); end
end
function T = acousticsData()
    % [freq, A, B, C] relative response (dB), IEC 61672 family.
    T = [ 25 -44.7 -20.4 -4.4;  31.5 -39.4 -17.1 -3.0;  40 -34.6 -14.2 -2.0;
          50 -30.2 -11.6 -1.3;  63 -26.2 -9.3 -0.8;     80 -22.5 -7.4 -0.5;
          100 -19.1 -5.6 -0.3;  125 -16.1 -4.2 -0.2;    160 -13.4 -3.0 -0.1;
          200 -10.9 -2.0 0.0;   250 -8.6 -1.3 0.0;      315 -6.6 -0.8 0.0;
          400 -4.8 -0.5 0.0;    500 -3.2 -0.3 0.0;      630 -1.9 -0.1 0.0;
          800 -0.8 0.0 0.0;     1000 0.0 0.0 0.0;       1250 0.6 0.0 0.0;
          1600 1.0 0.0 -0.1;    2000 1.2 -0.1 -0.2;     2500 1.3 -0.2 -0.3;
          3150 1.2 -0.4 -0.5;   4000 1.0 -0.7 -0.8;     5000 0.5 -1.2 -1.3;
          6300 -0.1 -1.9 -2.0;  8000 -1.1 -2.9 -3.0;    10000 -2.5 -4.3 -4.4;
          12500 -4.3 -6.1 -6.2; 16000 -6.6 -8.4 -8.5;   20000 -9.3 -11.1 -11.2 ];
end
