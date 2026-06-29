classdef AcousticsApp < handle
    %ACOUSTICSAPP  Search-driven acoustics & noise calculator (MATLAB port).
    %   A programmatic App Designer style GUI mirroring the MECH9325 web app:
    %   a search box filters a list of calculators on the left; the selected
    %   calculator's form appears on the right. Run with:  AcousticsApp
    %
    %   Covers the full quiz material: decibel arithmetic (levels, combine,
    %   subtract), plane waves, distance attenuation, room acoustics, sound
    %   power measurement, duct->voltage, A/B/C weighting, band workbench,
    %   Leq (levels/events/time-varying), occupational noise dose, loudness,
    %   speech interference (PSIL), community noise (Ldn), statistical levels
    %   & SEL, sound insulation (transmission loss) and mufflers.
    %
    %   Every calculator prints the full working (formulae + substituted
    %   numbers) so it doubles as a hand-calculation checker.
    %
    %   No toolboxes required (base MATLAB R2018b+ for uifigure +
    %   uigridlayout).

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
        OCTMAIN          % octave centres 63 Hz - 8 kHz
        OCTFULL          % octave centres 31.5 Hz - 16 kHz
    end

    properties (Constant)
        PREF = 2e-5;     % reference sound pressure, Pa
        WREF = 1e-12;    % reference sound power, W
        IREF = 1e-12;    % reference sound intensity, W/m^2
        RHOC = 415;      % characteristic impedance of air, rayls
        CAIR = 343;      % speed of sound in air at 20 C, m/s
    end

    methods
        function app = AcousticsApp()
            app.WTAB = acousticsData();
            app.THIRD = app.WTAB(:,1);
            app.OCTMAIN = [63 125 250 500 1000 2000 4000 8000]';
            app.OCTFULL = [31.5 63 125 250 500 1000 2000 4000 8000 16000]';
            app.buildUI();
            app.defineCalcs();
            app.refreshList('');
        end

        % ---------- top-level UI ----------
        function buildUI(app)
            app.Fig = uifigure('Name','Acoustics & Noise Control Toolkit', ...
                'Position',[100 100 1040 660]);
            g = uigridlayout(app.Fig,[2 2]);
            g.RowHeight = {40,'1x'};
            g.ColumnWidth = {300,'1x'};

            % search box (spans top)
            s = uieditfield(g,'text','Placeholder', ...
                'Search calculators - SPL, dB(A), Leq, RT60, dose, TL, sones, mass law...', ...
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

            % right: content panel (scrollable so tall forms fit)
            app.Content = uipanel(g,'BorderType','none','Scrollable','on');
            app.Content.Layout.Row = 2; app.Content.Layout.Column = 2;
        end

        function defineCalcs(app)
            c = {};
            % name, tags, fn
            c(end+1,:) = {'Levels: SPL <-> pressure','spl lp sound pressure level pascal pa rms reference 20 micropascal decibel convert', @app.buildSPL};
            c(end+1,:) = {'Levels: Sound power level Lw','lw sound power watt level reference convert', @app.buildLwConv};
            c(end+1,:) = {'Levels: Sound intensity level LI','li intensity i=p2/rhoc pressure level reference convert', @app.buildLI};
            c(end+1,:) = {'Levels: Peak <-> RMS & combine tones','peak rms amplitude p/sqrt2 combine quadrature pressures tones total', @app.buildRMS};
            c(end+1,:) = {'Levels: PSD -> RMS pressure','psd power spectral density pa2/hz integrate band trapezoid mean square spectrum', @app.buildPSD};

            c(end+1,:) = {'Combine: add sound levels','combine add sum total incoherent energy decibel sources', @app.buildCombine};
            c(end+1,:) = {'Combine: N identical sources','n identical sources machines 10log10 total combine', @app.buildNIdentical};
            c(end+1,:) = {'Combine: increase from more sources','increase more sources louder dogs added delta level', @app.buildIncrease};
            c(end+1,:) = {'Combine: error using larger signal only','error larger signal smaller ignore neglect ratio quadrature percent', @app.buildLargerError};
            c(end+1,:) = {'Combine: max sources under a limit','max maximum sources machines limit night permitted how many under', @app.buildMaxSources};

            c(end+1,:) = {'Subtract: remove background / source','subtract remove background source minus energy difference', @app.buildSubtract};
            c(end+1,:) = {'Subtract: one of N identical sources','one of n identical subtract source decibel', @app.buildOneOfN};

            c(end+1,:) = {'Waves: c = f x lambda','wave wavelength lambda frequency speed sound c=fl period omega wavenumber k', @app.buildWave};
            c(end+1,:) = {'Waves: speed of sound from temperature','speed sound temperature gas constant gamma celsius kelvin', @app.buildSOS};
            c(end+1,:) = {'Waves: particle velocity & displacement','particle velocity displacement xi intensity pressure amplitude rho c', @app.buildParticle};
            c(end+1,:) = {'Waves: octave band edges & pipe modes','octave band edges centre bandwidth percentage pipe natural frequency modes resonance', @app.buildBandEdges};

            c(end+1,:) = {'Distance: attenuation L2 at new distance','distance attenuation spreading point line source 6 3 db doubling traffic', @app.buildDistance};
            c(end+1,:) = {'Distance: solve distance from two levels','distance solve unknown two levels back out near far rifle increment', @app.buildInvDistance};
            c(end+1,:) = {'Distance: Lw <-> Lp (free field / ground)','lw lp sound power spl free field ground directivity q point line reverse', @app.buildLwLp};

            c(end+1,:) = {'Room: Sabine reverberation time','room reverberation rt60 t60 sabine absorption volume surface alpha', @app.buildRT};
            c(end+1,:) = {'Room: average absorption coefficient','average absorption coefficient alpha area surface room', @app.buildAvgAbs};
            c(end+1,:) = {'Room: room constant R','room constant r absorption alpha surface', @app.buildRoomConst};
            c(end+1,:) = {'Room: room equation Lp from Lw','room equation lp lw direct reverberant field directivity q distance', @app.buildRoomEq};
            c(end+1,:) = {'Room: reverberant change (add/remove panels)','reverberant change add remove panels absorber suspended office treatment band', @app.buildReverb};

            c(end+1,:) = {'Power: background correction K1','sound power k1 background correction mean spl', @app.buildK1};
            c(end+1,:) = {'Power: environmental correction K2','sound power k2 environmental correction absorption surface', @app.buildK2};
            c(end+1,:) = {'Power: sound power level (measured)','sound power level lw measured k1 k2 surface hemisphere', @app.buildLwMeas};
            c(end+1,:) = {'Power: Lw from free-field band SPLs','sound power lw free field band spl unweight a-weighted hemisphere sphere drill', @app.buildPowerBands};

            c(end+1,:) = {'Duct: sound power -> mic voltage','duct pipe microphone voltage sensitivity plane wave intensity rms cut-on', @app.buildDuct};

            c(end+1,:) = {'A / B / C Weighting & overall level','weighting a b c dba dbc octave third overall spectrum network', @app.buildWeighting};
            c(end+1,:) = {'Band Workbench (1/3-oct -> octave)','band workbench third octave overall a-weighted spl triplet nine bands', @app.buildBand};

            c(end+1,:) = {'Leq from levels & durations','leq equivalent continuous duration sel exposure energy average', @app.buildLeq};
            c(end+1,:) = {'Leq from discrete events (pass-bys)','leq events train vehicle pass by count discrete energy', @app.buildEvents};
            c(end+1,:) = {'Leq time-varying level & percentile LN','leq time varying ramp formula integral percentile ln l10 l90 exceeded', @app.buildTimeVarying};

            c(end+1,:) = {'Noise Dose & max time','noise dose ohs 85 db exchange permissible time worker shift criterion', @app.buildDose};
            c(end+1,:) = {'Max permissible time (steady level)','max permissible time steady level exchange rate criterion ohs', @app.buildMaxTime};

            c(end+1,:) = {'Loudness: phons -> sones','loudness phon sone equal loudness contour convert subjective', @app.buildPh2S};
            c(end+1,:) = {'Loudness: sones -> phons','loudness sone phon convert log2', @app.buildS2Ph};

            c(end+1,:) = {'Speech: PSIL & voice effort','speech psil sil interference voice effort communication 500 1000 2000 distance', @app.buildPSIL};

            c(end+1,:) = {'Community: day-night level Ldn','community noise day night ldn penalty residential environmental', @app.buildLdn};

            c(end+1,:) = {'Stats: SEL <-> Leq','sel sound exposure level single event leq 1 second', @app.buildSEL};
            c(end+1,:) = {'Stats: sort values into terms','statistical sort percentile l1 l99 sel leq ordering max min', @app.buildSort};

            c(end+1,:) = {'Insulation: mass law TL','insulation transmission loss tl mass law partition wall surface mass density thickness', @app.buildMassLaw};
            c(end+1,:) = {'Insulation: interface impedance & coeffs','interface impedance ratio reflection transmission coefficient alpha tl', @app.buildInterface};
            c(end+1,:) = {'Insulation: TL from coefficient','transmission loss tl coefficient alpha t', @app.buildTLcoef};
            c(end+1,:) = {'Insulation: panel resonance frequency','panel resonance natural frequency stiffness mass', @app.buildPanelRes};

            c(end+1,:) = {'Muffler: sudden area change','muffler silencer area change transmission loss reactive', @app.buildAreaChange};
            c(end+1,:) = {'Muffler: simple expansion chamber','muffler silencer expansion chamber transmission loss reactive quarter wave', @app.buildExpChamber};
            c(end+1,:) = {'Muffler: TL / IL / NR (level difference)','muffler transmission insertion loss noise reduction tl il nr difference', @app.buildLevelDiff};

            c(end+1,:) = {'Reference: A / B / C weighting table','table reference a b c weighting values chart lookup data', @app.buildRefTable};

            app.Calcs = struct('name',c(:,1),'tags',c(:,2),'fn',c(:,3));
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

        % ================= shared form helpers =================
        function gl = form(app, nrows)
            gl = uigridlayout(app.Content,[nrows 2]);
            gl.ColumnWidth = {220,'1x'};
            gl.RowHeight = repmat({32},1,nrows);
            gl.RowHeight{end} = '1x';
        end
        function out = resultBox(~, gl, row)
            out = uitextarea(gl,'Editable','off','FontName','monospaced');
            out.Layout.Row = row; out.Layout.Column = [1 2];
        end
        function h = numField(~, gl, row, label, val)
            l = uilabel(gl,'Text',label); l.Layout.Row = row; l.Layout.Column = 1;
            h = uieditfield(gl,'numeric','Value',val); h.Layout.Row = row; h.Layout.Column = 2;
        end
        function h = txtField(~, gl, row, label, val)
            l = uilabel(gl,'Text',label); l.Layout.Row = row; l.Layout.Column = 1;
            h = uieditfield(gl,'text','Value',val); h.Layout.Row = row; h.Layout.Column = 2;
        end
        function h = ddField(~, gl, row, label, items)
            l = uilabel(gl,'Text',label); l.Layout.Row = row; l.Layout.Column = 1;
            h = uidropdown(gl,'Items',items); h.Layout.Row = row; h.Layout.Column = 2;
        end
        function b = goButton(~, gl, row, cb)
            b = uibutton(gl,'Text','Compute','ButtonPushedFcn',cb);
            b.Layout.Row = row; b.Layout.Column = [1 2];
        end
        function note(~, gl, row, txt)
            l = uilabel(gl,'Text',txt,'FontColor',[.5 .5 .5],'WordWrap','on');
            l.Layout.Row = row; l.Layout.Column = [1 2];
        end

        % ================= LEVELS =================
        function buildSPL(app)
            gl = app.form(5);
            app.W.lp = app.txtField(gl,1,'Sound pressure level Lp (dB)','94');
            app.W.p  = app.txtField(gl,2,'or RMS pressure p (Pa)','');
            app.note(gl,3,'Lp = 20*log10(p / 2e-5)   ·   p = 2e-5 * 10^(Lp/20). Fill one, blank the other.');
            app.goButton(gl,4,@(o,e) app.runSPL());
            app.W.out = app.resultBox(gl,5);
        end
        function runSPL(app)
            if ~isempty(strtrim(app.W.p.Value))
                p = app.pnum(app.W.p);
                if ~(p > 0), app.W.out.Value = {'Pressure must be > 0.'}; return; end
                Lp = 20*log10(p/app.PREF); app.W.lp.Value = sprintf('%.2f',Lp);
                app.W.out.Value = { sprintf('Lp = %.2f dB', Lp), '', 'WORKING', ...
                    'Lp = 20*log10(p / p_ref)', ...
                    sprintf('= 20*log10(%.4g / 2e-5) = 20*log10(%.4g)', p, p/app.PREF), ...
                    sprintf('= %.2f dB', Lp) };
            else
                Lp = app.pnum(app.W.lp); p = app.PREF*10^(Lp/20); app.W.p.Value = sprintf('%.4g',p);
                app.W.out.Value = { sprintf('p_rms = %.4g Pa', p), '', 'WORKING', ...
                    'p = p_ref * 10^(Lp/20)', ...
                    sprintf('= 2e-5 * 10^(%.4g/20) = 2e-5 * %.4g', Lp, 10^(Lp/20)), ...
                    sprintf('= %.4g Pa', p) };
            end
        end

        function buildLwConv(app)
            gl = app.form(5);
            app.W.W  = app.txtField(gl,1,'Sound power W (W)','0.5');
            app.W.Lw = app.txtField(gl,2,'or Lw (dB re 1e-12 W)','');
            app.note(gl,3,'Lw = 10*log10(W / 1e-12). Fill one, blank the other.');
            app.goButton(gl,4,@(o,e) app.runLwConv());
            app.W.out = app.resultBox(gl,5);
        end
        function runLwConv(app)
            if ~isempty(strtrim(app.W.Lw.Value))
                L = app.pnum(app.W.Lw); Wp = app.WREF*10^(L/10); app.W.W.Value = sprintf('%.4g',Wp);
                app.W.out.Value = { sprintf('W = %.4g W', Wp), '', 'WORKING', ...
                    sprintf('W = W_ref * 10^(Lw/10) = 1e-12 * 10^(%.4g/10) = %.4g W', L, Wp) };
            else
                Wp = app.pnum(app.W.W);
                if ~(Wp > 0), app.W.out.Value = {'Power must be > 0.'}; return; end
                L = 10*log10(Wp/app.WREF); app.W.Lw.Value = sprintf('%.2f',L);
                app.W.out.Value = { sprintf('Lw = %.2f dB', L), '', 'WORKING', ...
                    'Lw = 10*log10(W / W_ref)', ...
                    sprintf('= 10*log10(%.4g / 1e-12) = %.2f dB', Wp, L) };
            end
        end

        function buildLI(app)
            gl = app.form(5);
            app.W.I = app.txtField(gl,1,'Intensity I (W/m^2)','');
            app.W.p = app.txtField(gl,2,'or RMS pressure p (Pa)  [I=p^2/rhoc]','1');
            app.note(gl,3,'LI = 10*log10(I / 1e-12)   ·   I = p_rms^2 / (rho c),  rho c = 415.');
            app.goButton(gl,4,@(o,e) app.runLI());
            app.W.out = app.resultBox(gl,5);
        end
        function runLI(app)
            steps = {};
            if ~isempty(strtrim(app.W.p.Value))
                p = app.pnum(app.W.p); I = p^2/app.RHOC;
                steps{end+1} = sprintf('I = p_rms^2 / (rho c) = %.4g^2 / %g = %.4g W/m^2', p, app.RHOC, I);
            else
                I = app.pnum(app.W.I);
            end
            if ~(I > 0), app.W.out.Value = {'Enter intensity or pressure.'}; return; end
            LI = 10*log10(I/app.IREF);
            steps{end+1} = sprintf('LI = 10*log10(I / I_ref) = 10*log10(%.4g / 1e-12) = %.2f dB', I, LI);
            app.W.out.Value = [{ sprintf('I = %.4g W/m^2', I), sprintf('LI = %.2f dB', LI), '', 'WORKING' }, steps];
        end

        function buildRMS(app)
            gl = uigridlayout(app.Content,[7 2]);
            gl.RowHeight = {32,32,20,'1x',32,32,140}; gl.ColumnWidth = {220,'1x'};
            app.W.P = app.numField(gl,1,'Peak pressure amplitude P (Pa)',2);
            app.note(gl,2,'p_rms = P/sqrt(2).   Combine component RMS pressures: p_tot = sqrt(sum p_i^2).');
            l = uilabel(gl,'Text','Component RMS pressures (Pa), one per line:');
            l.Layout.Row = 3; l.Layout.Column = [1 2];
            app.W.list = uitextarea(gl,'Value',{'1.0','2.0','0.5'});
            app.W.list.Layout.Row = 4; app.W.list.Layout.Column = [1 2];
            app.goButton(gl,5,@(o,e) app.runRMS());
            app.W.out = app.resultBox(gl,7);
        end
        function runRMS(app)
            P = app.W.P.Value; prms = P/sqrt(2);
            out = { sprintf('p_rms (from peak) = %.4g Pa  ->  SPL = %.2f dB', prms, 20*log10(prms/app.PREF)) };
            ps = app.parseCol(app.W.list.Value);
            if ~isempty(ps)
                sumSq = sum(ps.^2); tot = sqrt(sumSq);
                terms = strjoin(arrayfun(@(x) sprintf('%.4g^2',x), ps, 'UniformOutput',false), ' + ');
                out = [out, { sprintf('p_tot (combined) = %.4g Pa  ->  SPL = %.2f dB', tot, 20*log10(tot/app.PREF)), ...
                    '', 'WORKING', 'p_tot = sqrt( sum p_i^2 )', ...
                    sprintf('= sqrt( %s ) = sqrt(%.4g) = %.4g Pa', terms, sumSq, tot) }];
            end
            app.W.out.Value = out;
        end

        function buildPSD(app)
            gl = app.form(7);
            app.W.f1 = app.numField(gl,1,'Lower freq f1 (Hz)',973);
            app.W.f2 = app.numField(gl,2,'Upper freq f2 (Hz)',4584);
            app.W.s1 = app.numField(gl,3,'PSD at f1, S1 (Pa^2/Hz)',0.0015);
            app.W.s2 = app.numField(gl,4,'PSD at f2, S2 (Pa^2/Hz)',1.5e-4);
            app.note(gl,5,'p_rms^2 = integral S df = 1/2 (S1+S2)(f2-f1)   ·   SPL = 20*log10(p_rms/2e-5)');
            app.goButton(gl,6,@(o,e) app.runPSD());
            app.W.out = app.resultBox(gl,7);
        end
        function runPSD(app)
            f1=app.W.f1.Value; f2=app.W.f2.Value; s1=app.W.s1.Value; s2=app.W.s2.Value;
            if ~(f2 > f1), app.W.out.Value = {'Upper frequency must exceed lower frequency.'}; return; end
            if s1<0 || s2<0, app.W.out.Value = {'PSD values must be >= 0.'}; return; end
            bw=f2-f1; ms=(s1+s2)/2*bw; prms=sqrt(ms); spl=20*log10(prms/app.PREF);
            app.W.out.Value = { sprintf('Mean-square p^2 = %.4g Pa^2', ms), ...
                sprintf('p_rms = %.4g Pa', prms), sprintf('SPL = %.2f dB', spl), ...
                '', 'WORKING', ...
                sprintf('p_rms^2 = 1/2 (S1+S2)(f2-f1) = 1/2 (%.4g + %.4g)(%.4g)', s1, s2, bw), ...
                sprintf('= %.4g Pa^2', ms), ...
                sprintf('p_rms = sqrt(%.4g) = %.4g Pa', ms, prms), ...
                sprintf('SPL = 20*log10(%.4g / 2e-5) = %.2f dB', prms, spl) };
        end

        % ================= COMBINE =================
        function buildCombine(app)
            gl = uigridlayout(app.Content,[4 1]);
            gl.RowHeight = {20,'1x',32,140};
            uilabel(gl,'Text','One level (dB) per line:');
            app.W.txt = uitextarea(gl,'Value',{'80','80','74'});
            uibutton(gl,'Text','Combine','ButtonPushedFcn',@(o,e) app.runCombine());
            app.W.out = uitextarea(gl,'Editable','off','FontName','monospaced');
        end
        function runCombine(app)
            L = app.parseCol(app.W.txt.Value);
            if isempty(L), app.W.out.Value = {'Enter at least one level.'}; return; end
            e = 10.^(L/10); s = sum(e); tot = 10*log10(s); p = app.PREF*10^(tot/20);
            terms = strjoin(arrayfun(@(x) sprintf('10^(%.4g/10)',x), L, 'UniformOutput',false), ' + ');
            app.W.out.Value = { sprintf('Combined level = %.2f dB', tot), ...
                sprintf('RMS pressure   = %.4g Pa', p), '', 'WORKING', ...
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
                sprintf('= %.4g + 10*log10(%g) = %.4g + %.4g = %.2f dB', L1, N, L1, 10*log10(N), tot) };
        end

        function buildIncrease(app)
            gl = app.form(5);
            app.W.n1  = app.numField(gl,1,'Initial number N1',47);
            app.W.L1  = app.numField(gl,2,'Measured level L1 (dB)',66);
            app.W.add = app.numField(gl,3,'Sources added',7);
            app.goButton(gl,4,@(o,e) app.runIncrease());
            app.W.out = app.resultBox(gl,5);
        end
        function runIncrease(app)
            n1=app.W.n1.Value; L1=app.W.L1.Value; add=app.W.add.Value; n2=n1+add;
            if ~(n1>0) || ~(n2>0), app.W.out.Value = {'Counts must be positive.'}; return; end
            dL=10*log10(n2/n1); nl=L1+dL;
            app.W.out.Value = { sprintf('Increase dL = %.3f dB', dL), sprintf('New level = %.3f dB', nl), ...
                '', 'WORKING', sprintf('N2 = N1 + added = %g + %g = %g', n1, add, n2), ...
                sprintf('dL = 10*log10(N2/N1) = 10*log10(%g) = %.3f dB', n2/n1, dL), ...
                sprintf('L_new = L1 + dL = %.4g + %.3f = %.3f dB', L1, dL, nl) };
        end

        function buildLargerError(app)
            gl = app.form(5);
            app.W.p1 = app.numField(gl,1,'Larger RMS p1',1);
            app.W.p2 = app.numField(gl,2,'Smaller RMS p2',0.11);
            app.W.r  = app.txtField(gl,3,'or ratio p2/p1 (overrides)','');
            app.goButton(gl,4,@(o,e) app.runLargerError());
            app.W.out = app.resultBox(gl,5);
        end
        function runLargerError(app)
            if ~isempty(strtrim(app.W.r.Value))
                r = app.pnum(app.W.r);
                if ~(r>=0), app.W.out.Value = {'Ratio must be >= 0.'}; return; end
            else
                p1=app.W.p1.Value; p2=app.W.p2.Value;
                if ~(p1>0)||~(p2>=0), app.W.out.Value = {'Enter positive p1 and non-negative p2 (or a ratio).'}; return; end
                r = p2/p1;
            end
            if r>1, app.W.out.Value = {'Ratio should be <= 1 (p2 is the smaller signal).'}; return; end
            ptot=sqrt(1+r*r); err=(1/ptot-1)*100;
            app.W.out.Value = { sprintf('Total RMS = %.5g x p1', ptot), ...
                sprintf('Error using only p1 = %.2f %% (under-estimate)', err), ...
                '', 'WORKING', sprintf('r = p2/p1 = %.4g', r), ...
                sprintf('p_tot = p1*sqrt(1 + r^2) = p1*sqrt(1 + %.4g) = %.5g*p1', r*r, ptot), ...
                'Error = 1/sqrt(1 + r^2) - 1', ...
                sprintf('= 1/%.5g - 1 = %.2f %%', ptot, err) };
        end

        function buildMaxSources(app)
            gl = app.form(5);
            app.W.N1  = app.numField(gl,1,'Current number N1',8);
            app.W.Lt  = app.numField(gl,2,'Measured total Ltot (dB)',54);
            app.W.Lm  = app.numField(gl,3,'Limit Lmax (dB)',50);
            app.goButton(gl,4,@(o,e) app.runMaxSources());
            app.W.out = app.resultBox(gl,5);
        end
        function runMaxSources(app)
            N1=app.W.N1.Value; L1=app.W.Lt.Value; Lmax=app.W.Lm.Value;
            if ~(N1>=1), app.W.out.Value = {'N1 must be >= 1.'}; return; end
            per=L1-10*log10(N1); Nexact=N1*10^((Lmax-L1)/10); N=floor(Nexact+1e-9);
            if N<1, app.W.out.Value = {sprintf('Even one source (%.2f dB) exceeds the %.4g dB limit.',per,Lmax)}; return; end
            Ln=L1+10*log10(N/N1); Ln1=L1+10*log10((N+1)/N1);
            app.W.out.Value = { sprintf('Max sources within limit = %d', N), ...
                sprintf('Level at %d = %.2f dB (<= %.4g, ok) · at %d = %.2f dB (over)', N, Ln, Lmax, N+1, Ln1), ...
                '', 'WORKING', ...
                sprintf('One source: L1 = Ltot - 10*log10(N1) = %.4g - 10*log10(%g) = %.2f dB', L1, N1, per), ...
                'N <= N1 * 10^((Lmax - Ltot)/10)', ...
                sprintf('= %g * 10^((%.4g - %.4g)/10) = %.3f  -> round down = %d', N1, Lmax, L1, Nexact, N) };
        end

        % ================= SUBTRACT =================
        function buildSubtract(app)
            gl = app.form(4);
            app.W.tot = app.numField(gl,1,'Total level Ltot (dB)',80);
            app.W.bg  = app.numField(gl,2,'Level to remove Lbg (dB)',77);
            app.goButton(gl,3,@(o,e) app.runSubtract());
            app.W.out = app.resultBox(gl,4);
        end
        function runSubtract(app)
            tot=app.W.tot.Value; bg=app.W.bg.Value; diff=10^(tot/10)-10^(bg/10);
            if diff<=0, app.W.out.Value = {'Total must exceed the level being removed.'}; return; end
            rem=10*log10(diff);
            app.W.out.Value = { sprintf('Remaining level = %.2f dB', rem), '', 'WORKING', ...
                'L_rem = 10*log10( 10^(Ltot/10) - 10^(Lbg/10) )', ...
                sprintf('= 10*log10( %.4g - %.4g ) = 10*log10( %.4g )', 10^(tot/10), 10^(bg/10), diff), ...
                sprintf('= %.2f dB', rem) };
        end

        function buildOneOfN(app)
            gl = app.form(4);
            app.W.tot = app.numField(gl,1,'Combined level Ltot (dB)',80);
            app.W.N   = app.numField(gl,2,'Number of sources N',2);
            app.goButton(gl,3,@(o,e) app.runOneOfN());
            app.W.out = app.resultBox(gl,4);
        end
        function runOneOfN(app)
            tot=app.W.tot.Value; N=app.W.N.Value;
            if ~(N>=1), app.W.out.Value = {'N must be >= 1.'}; return; end
            one=tot-10*log10(N);
            app.W.out.Value = { sprintf('Each source = %.2f dB', one), '', 'WORKING', ...
                'L1 = Ltot - 10*log10(N)', ...
                sprintf('= %.4g - 10*log10(%g) = %.4g - %.4g = %.2f dB', tot, N, tot, 10*log10(N), one) };
        end

        % ================= WAVES =================
        function buildWave(app)
            gl = app.form(5);
            app.W.c   = app.txtField(gl,1,'Speed c (m/s)','343');
            app.W.f   = app.txtField(gl,2,'Frequency f (Hz)','1000');
            app.W.lam = app.txtField(gl,3,'Wavelength lambda (m)','');
            app.goButton(gl,4,@(o,e) app.runWave());
            app.W.out = app.resultBox(gl,5);
        end
        function runWave(app)
            c=app.pnum(app.W.c); f=app.pnum(app.W.f); lam=app.pnum(app.W.lam);
            known = ~isnan(c) + ~isnan(f) + ~isnan(lam);
            if known < 2, app.W.out.Value = {'Enter at least two of c, f, lambda.'}; return; end
            if isnan(c), c=f*lam; elseif isnan(f), f=c/lam; elseif isnan(lam), lam=c/f; end
            app.W.c.Value=sprintf('%.3f',c); app.W.f.Value=sprintf('%.3f',f); app.W.lam.Value=sprintf('%.4f',lam);
            w=2*pi*f; k=2*pi/lam;
            app.W.out.Value = { sprintf('c = %.2f m/s · f = %.2f Hz · lambda = %.4f m', c, f, lam), ...
                sprintf('T = 1/f = %.4g s', 1/f), sprintf('omega = 2*pi*f = %.1f rad/s', w), ...
                sprintf('k = 2*pi/lambda = %.3f rad/m', k) };
        end

        function buildSOS(app)
            gl = app.form(5);
            app.W.T = app.numField(gl,1,'Temperature (deg C)',20);
            app.W.R = app.numField(gl,2,'Gas constant R (J/kg/K)',287);
            app.W.g = app.numField(gl,3,'gamma',1.4);
            app.goButton(gl,4,@(o,e) app.runSOS());
            app.W.out = app.resultBox(gl,5);
        end
        function runSOS(app)
            Tc=app.W.T.Value; R=app.W.R.Value; g=app.W.g.Value; T0=Tc+273.2; c=sqrt(g*R*T0);
            app.W.out.Value = { sprintf('T0 = %.1f K', T0), ...
                sprintf('c = sqrt(gamma*R*T0) = sqrt(%g*%g*%.1f) = %.2f m/s', g, R, T0, c), ...
                sprintf('Air shortcut 20.06*sqrt(T0) = %.2f m/s', 20.06*sqrt(T0)) };
        end

        function buildParticle(app)
            gl = app.form(5);
            app.W.P  = app.numField(gl,1,'Pressure amplitude P (Pa)',2);
            app.W.f  = app.numField(gl,2,'Frequency f (Hz)',1000);
            app.W.rc = app.numField(gl,3,'rho c (rayls)',415);
            app.goButton(gl,4,@(o,e) app.runParticle());
            app.W.out = app.resultBox(gl,5);
        end
        function runParticle(app)
            P=app.W.P.Value; f=app.W.f.Value; rc=app.W.rc.Value;
            w=2*pi*f; u=P/rc; xi=u/w; I=P^2/(2*rc);
            app.W.out.Value = { sprintf('Particle velocity u = P/rhoc = %.4g m/s', u), ...
                sprintf('Displacement xi = u/omega = %.4g m', xi), ...
                sprintf('Intensity I = P^2/(2 rhoc) = %.4g W/m^2', I) };
        end

        function buildBandEdges(app)
            gl = uigridlayout(app.Content,[7 2]);
            gl.RowHeight = {32,32,32,'1x',32,32,'1x'}; gl.ColumnWidth = {220,'1x'};
            app.W.fc = app.numField(gl,1,'Octave band centre fc (Hz)',1000);
            app.W.ty = app.ddField(gl,2,'Band type',{'Octave','1/3 Octave'});
            b1 = uibutton(gl,'Text','Band edges','ButtonPushedFcn',@(o,e) app.runBandEdges());
            b1.Layout.Row = 3; b1.Layout.Column = [1 2];
            app.W.out = app.resultBox(gl,4);
            app.W.pipeL = app.numField(gl,5,'Pipe length L (m), closed one end',0.5);
            app.W.pipeC = app.numField(gl,6,'Speed c (m/s)',343);
            b2 = uibutton(gl,'Text','Natural frequencies  fn=(2n-1)c/4L','ButtonPushedFcn',@(o,e) app.runPipe());
            b2.Layout.Row = 7; b2.Layout.Column = [1 2];
        end
        function runBandEdges(app)
            fc=app.W.fc.Value;
            if ~(fc>0), app.W.out.Value = {'Centre frequency must be > 0.'}; return; end
            third = strcmp(app.W.ty.Value,'1/3 Octave');
            if third, k=2^(1/6); ks='2^(1/6)'; nm='one-third octave'; ref='23.1';
            else, k=sqrt(2); ks='sqrt(2)'; nm='octave'; ref='70.7'; end
            lower=fc/k; upper=fc*k; bw=upper-lower; pct=bw/fc*100;
            app.W.out.Value = { sprintf('Lower = %.1f Hz · Upper = %.1f Hz', lower, upper), ...
                sprintf('Bandwidth = %.1f Hz · %% bandwidth = %.1f %%', bw, pct), ...
                '', 'WORKING', sprintf('f_lower = fc/%s, f_upper = fc*%s', ks, ks), ...
                sprintf('BW = %.1f - %.1f = %.1f Hz', upper, lower, bw), ...
                sprintf('%%BW = BW/fc*100 = %.1f %% (constant -> %s ~ %s %%)', pct, nm, ref) };
        end
        function runPipe(app)
            L=app.W.pipeL.Value; c=app.W.pipeC.Value;
            if ~(L>0), app.W.out.Value = {'Length must be > 0.'}; return; end
            s = {'Natural frequencies (closed-open pipe):'};
            for n=1:4, s{end+1} = sprintf('  f%d = (2*%d-1)*c/(4L) = %.1f Hz', n, n, (2*n-1)*c/(4*L)); end %#ok<AGROW>
            app.W.out.Value = s;
        end

        % ================= DISTANCE =================
        function buildDistance(app)
            gl = app.form(6);
            app.W.L1 = app.numField(gl,1,'Known level L1 (dB)',78);
            app.W.r1 = app.numField(gl,2,'At distance r1 (m)',6.5);
            app.W.r2 = app.numField(gl,3,'New distance r2 (m)',65);
            app.W.ex = app.txtField(gl,4,'+ extra source at r1 (dB, optional)','');
            app.goButton(gl,5,@(o,e) app.runDistance());
            app.W.out = app.resultBox(gl,6);
        end
        function runDistance(app)
            L1=app.W.L1.Value; r1=app.W.r1.Value; r2=app.W.r2.Value;
            if r1<=0||r2<=0, app.W.out.Value = {'Distances must be > 0.'}; return; end
            steps = {};
            if ~isempty(strtrim(app.W.ex.Value))
                extra = app.pnum(app.W.ex);
                if isnan(extra), app.W.out.Value = {'Extra source level must be a number (or blank).'}; return; end
                L1c = app.dBsum([L1 extra]);
                steps{end+1} = sprintf('Combine at r1: L1 = 10*log10(10^(%.4g/10)+10^(%.4g/10)) = %.2f dB', L1, extra, L1c);
                L1 = L1c;
            end
            ratio=log10(r2/r1); pt=L1-20*ratio; ln=L1-10*ratio;
            steps = [steps, { ...
                sprintf('log10(r2/r1) = log10(%g/%g) = %.4f', r2, r1, ratio), ...
                sprintf('Point: L2 = L1 - 20*log10(r2/r1) = %.4g - %.2f = %.2f dB', L1, 20*ratio, pt), ...
                sprintf('Line:  L2 = L1 - 10*log10(r2/r1) = %.4g - %.2f = %.2f dB', L1, 10*ratio, ln) }];
            app.W.out.Value = [{ sprintf('Point (spherical, -6 dB/doubling): L2 = %.2f dB', pt), ...
                sprintf('Line  (cylindrical, -3 dB/doubling): L2 = %.2f dB', ln), '', 'WORKING' }, steps];
        end

        function buildInvDistance(app)
            gl = app.form(5);
            app.W.L1 = app.numField(gl,1,'Near level L1 (dB)',128);
            app.W.L2 = app.numField(gl,2,'Far level L2 (dB)',98);
            app.W.dr = app.numField(gl,3,'Extra distance dr (m)',25.2);
            app.goButton(gl,4,@(o,e) app.runInvDistance());
            app.W.out = app.resultBox(gl,5);
        end
        function runInvDistance(app)
            L1=app.W.L1.Value; L2=app.W.L2.Value; dr=app.W.dr.Value;
            if ~(dr>0), app.W.out.Value = {'Extra distance dr must be > 0.'}; return; end
            dL=L1-L2;
            if ~(dL>0), app.W.out.Value = {'Near level L1 must exceed far level L2.'}; return; end
            Rp=10^(dL/20); Rl=10^(dL/10); yp=dr/(Rp-1); yl=dr/(Rl-1);
            app.W.out.Value = { sprintf('Point source (-6 dB/doubling): near distance y = %.3f m', yp), ...
                sprintf('Line  source (-3 dB/doubling): near distance y = %.3f m', yl), ...
                '', 'WORKING', sprintf('dL = L1 - L2 = %.4g - %.4g = %.4g dB', L1, L2, dL), ...
                sprintf('Point: y = dr/(10^(dL/20) - 1) = %g/(%.5g - 1) = %.3f m', dr, Rp, yp), ...
                sprintf('Line:  y = dr/(10^(dL/10) - 1) = %g/(%.5g - 1) = %.3f m', dr, Rl, yl) };
        end

        function buildLwLp(app)
            gl = app.form(6);
            app.W.Lw = app.txtField(gl,1,'Lw (dB)  [blank to solve]','');
            app.W.Lp = app.txtField(gl,2,'Lp (dB)  [blank to solve]','88');
            app.W.r  = app.numField(gl,3,'Distance r (m)',1.7);
            app.W.ty = app.ddField(gl,4,'Source type', { ...
                'Point, free field  Q=1', 'Point, on ground  Q=2', ...
                'Point, edge  Q=4', 'Point, corner  Q=8', ...
                'Line, free field', 'Line, on ground'});
            app.goButton(gl,5,@(o,e) app.runLwLp());
            app.W.out = app.resultBox(gl,6);
        end
        function runLwLp(app)
            hasLw = ~isempty(strtrim(app.W.Lw.Value));
            hasLp = ~isempty(strtrim(app.W.Lp.Value));
            r = app.W.r.Value;
            if ~(r>0), app.W.out.Value = {'Distance must be > 0.'}; return; end
            if hasLw==hasLp, app.W.out.Value = {'Fill exactly one of Lw / Lp, blank the other.'}; return; end
            kp = @(Q) 10*log10(4*pi/Q);
            switch app.W.ty.Value
                case 'Point, free field  Q=1', coef=20; k=kp(1);
                case 'Point, on ground  Q=2', coef=20; k=kp(2);
                case 'Point, edge  Q=4',      coef=20; k=kp(4);
                case 'Point, corner  Q=8',    coef=20; k=kp(8);
                case 'Line, free field',      coef=10; k=8;
                otherwise,                    coef=10; k=5;
            end
            if hasLw
                Lw=app.pnum(app.W.Lw); out=Lw-coef*log10(r)-k; app.W.Lp.Value=sprintf('%.2f',out);
                app.W.out.Value = { sprintf('Lp = %.2f dB', out), '', 'WORKING', ...
                    sprintf('Lp = Lw - %g*log10(r) - %.2f', coef, k), ...
                    sprintf('= %.4g - %g*log10(%g) - %.2f = %.4g - %.3f - %.2f = %.2f dB', ...
                        Lw, coef, r, k, Lw, coef*log10(r), k, out) };
            else
                Lp=app.pnum(app.W.Lp); out=Lp+coef*log10(r)+k; app.W.Lw.Value=sprintf('%.2f',out);
                app.W.out.Value = { sprintf('Lw = %.2f dB', out), '', 'WORKING', ...
                    sprintf('Lw = Lp + %g*log10(r) + %.2f', coef, k), ...
                    sprintf('= %.4g + %g*log10(%g) + %.2f = %.4g + %.3f + %.2f = %.2f dB', ...
                        Lp, coef, r, k, Lp, coef*log10(r), k, out) };
            end
        end

        % ================= ROOM =================
        function buildRT(app)
            gl = app.form(6);
            app.W.V = app.txtField(gl,1,'Volume V (m^3)','200');
            app.W.S = app.txtField(gl,2,'Total surface S (m^2)','240');
            app.W.a = app.txtField(gl,3,'Average absorption alpha','0.15');
            app.W.T = app.txtField(gl,4,'T60 (s)','');
            app.goButton(gl,5,@(o,e) app.runRT());
            app.W.out = app.resultBox(gl,6);
        end
        function runRT(app)
            V=app.pnum(app.W.V); S=app.pnum(app.W.S); a=app.pnum(app.W.a); T=app.pnum(app.W.T);
            miss = isnan(V)+isnan(S)+isnan(a)+isnan(T);
            if miss~=1, app.W.out.Value = {'Fill exactly three values; leave one blank.'}; return; end
            if isnan(T), T=0.161*V/(a*S);
            elseif isnan(a), a=0.161*V/(T*S);
            elseif isnan(S), S=0.161*V/(T*a);
            else, V=T*a*S/0.161; end
            app.W.V.Value=sprintf('%.2f',V); app.W.S.Value=sprintf('%.2f',S);
            app.W.a.Value=sprintf('%.4f',a); app.W.T.Value=sprintf('%.3f',T);
            app.W.out.Value = { sprintf('T60 = %.3f s · alpha = %.4f · A = alpha*S = %.2f m^2', T, a, a*S), ...
                '', 'WORKING', 'T60 = 0.161*V / (alpha*S)', ...
                sprintf('= 0.161*%.4g / (%.4f*%.4g) = %.3f / %.3f = %.3f s', V, a, S, 0.161*V, a*S, T) };
        end

        function buildAvgAbs(app)
            gl = uigridlayout(app.Content,[4 1]);
            gl.RowHeight = {20,'1x',32,120};
            uilabel(gl,'Text','One surface per line:  area, alpha');
            app.W.txt = uitextarea(gl,'Value',{'60, 0.3','120, 0.05','60, 0.1'});
            uibutton(gl,'Text','Compute alpha-bar','ButtonPushedFcn',@(o,e) app.runAvgAbs());
            app.W.out = uitextarea(gl,'Editable','off','FontName','monospaced');
        end
        function runAvgAbs(app)
            rows = app.parseRows(app.W.txt.Value, 2);
            if isempty(rows), app.W.out.Value = {'Each row needs: area, alpha.'}; return; end
            num=sum(rows(:,1).*rows(:,2)); den=sum(rows(:,1));
            if den==0, app.W.out.Value = {'Total area is zero.'}; return; end
            app.W.out.Value = { sprintf('alpha-bar = %.4f', num/den), '', 'WORKING', ...
                'alpha-bar = sum(alpha_i*S_i) / sum(S_i)', ...
                sprintf('= %.2f / %.1f = %.4f', num, den, num/den) };
        end

        function buildRoomConst(app)
            gl = app.form(4);
            app.W.a = app.numField(gl,1,'Average absorption alpha',0.15);
            app.W.S = app.numField(gl,2,'Total surface S (m^2)',240);
            app.goButton(gl,3,@(o,e) app.runRoomConst());
            app.W.out = app.resultBox(gl,4);
        end
        function runRoomConst(app)
            a=app.W.a.Value; S=app.W.S.Value;
            if ~(a>0&&a<1), app.W.out.Value = {'alpha must be between 0 and 1.'}; return; end
            R=a*S/(1-a);
            app.W.out.Value = { sprintf('Room constant R = %.2f m^2', R), '', 'WORKING', ...
                sprintf('R = alpha*S/(1-alpha) = %.4f*%g/(1-%.4f) = %.2f m^2', a, S, a, R) };
        end

        function buildRoomEq(app)
            gl = app.form(6);
            app.W.Lw = app.numField(gl,1,'Lw (dB)',100);
            app.W.r  = app.numField(gl,2,'Distance r (m)',3);
            app.W.R  = app.numField(gl,3,'Room constant R (m^2)',42);
            app.W.Q  = app.ddField(gl,4,'Directivity Q',{'1 - free','2 - wall','4 - edge','8 - corner'});
            app.goButton(gl,5,@(o,e) app.runRoomEq());
            app.W.out = app.resultBox(gl,6);
        end
        function runRoomEq(app)
            Lw=app.W.Lw.Value; r=app.W.r.Value; R=app.W.R.Value; Q=str2double(app.W.Q.Value(1));
            if ~(r>0)||~(R>0), app.W.out.Value = {'r and R must be > 0.'}; return; end
            direct=Q/(4*pi*r*r); rev=4/R; Lp=Lw+10*log10(direct+rev);
            if direct>rev, dom='direct field dominates'; else, dom='reverberant field dominates'; end
            app.W.out.Value = { sprintf('Lp = %.2f dB  (%s)', Lp, dom), '', 'WORKING', ...
                'Lp = Lw + 10*log10( Q/(4*pi*r^2) + 4/R )', ...
                sprintf('= %.4g + 10*log10( %.4g + %.4g )', Lw, direct, rev), ...
                sprintf('= %.4g + 10*log10( %.4g ) = %.2f dB', Lw, direct+rev, Lp) };
        end

        function buildReverb(app)
            gl = uigridlayout(app.Content,[6 2]);
            gl.RowHeight = {32,32,'1x',32,32,150}; gl.ColumnWidth = {180,'1x'};
            app.W.mode = app.ddField(gl,1,'Change',{'Remove absorber (level rises)','Add absorber (level falls)'});
            app.W.net  = app.ddField(gl,2,'Overall weighting',{'A','B','C','Z (none)'});
            f = app.OCTFULL;
            app.W.tbl = uitable(gl,'ColumnName',{'Freq (Hz)','Lp (dB)','T60 (s)','alpha'}, ...
                'ColumnEditable',[false true true true], ...
                'Data',[num2cell(f), repmat({[]},numel(f),3)]);
            app.W.tbl.Layout.Row = 3; app.W.tbl.Layout.Column = [1 2];
            sub = uigridlayout(gl,[1 4]); sub.Layout.Row = 4; sub.Layout.Column = [1 2];
            sub.Padding = [0 0 0 0]; sub.ColumnWidth = {110,'1x',150,'1x'};
            uilabel(sub,'Text','Room V (m^3)');
            app.W.V = uieditfield(sub,'numeric','Value',408);
            uilabel(sub,'Text','Absorber S_abs (m^2)');
            app.W.Sabs = uieditfield(sub,'numeric','Value',48);
            b = uibutton(gl,'Text','Compute','ButtonPushedFcn',@(o,e) app.runReverb());
            b.Layout.Row = 5; b.Layout.Column = [1 2];
            app.W.out = uitextarea(gl,'Editable','off','FontName','monospaced');
            app.W.out.Layout.Row = 6; app.W.out.Layout.Column = [1 2];
        end
        function runReverb(app)
            net = app.W.net.Value(1); remove = startsWith(app.W.mode.Value,'Remove');
            V=app.W.V.Value; Sabs=app.W.Sabs.Value;
            if ~(V>0), app.W.out.Value = {'Room volume V must be > 0.'}; return; end
            if ~(Sabs>0), app.W.out.Value = {'Absorber area S_abs must be > 0.'}; return; end
            d=app.W.tbl.Data; rows=[];
            for i=1:size(d,1)
                Lp=d{i,2}; T=d{i,3}; al=d{i,4};
                if isempty(Lp)||(isnumeric(Lp)&&isnan(Lp)), continue; end
                if isempty(T)||isempty(al), app.W.out.Value = {sprintf('Band %g Hz needs T60 and alpha as well as Lp.', d{i,1})}; return; end
                if ~(T>0), app.W.out.Value = {sprintf('T60 at %g Hz must be > 0.', d{i,1})}; return; end
                A1=0.161*V/T; Aabs=Sabs*al;
                if remove, A2=A1-Aabs; else, A2=A1+Aabs; end
                if ~(A2>0), app.W.out.Value = {sprintf('Band %g Hz: absorber exceeds room absorption (A2<=0).', d{i,1})}; return; end
                dL=10*log10(A1/A2);
                rows(end+1,:)=[d{i,1}, Lp, dL, Lp+dL, app.weight(d{i,1},net)]; %#ok<AGROW>
            end
            if isempty(rows), app.W.out.Value = {'Enter at least one band Lp.'}; return; end
            tag='dB'; if net~='Z', tag=sprintf('dB(%c)',net); end
            before=app.dBsum(rows(:,2)+rows(:,5)); after=app.dBsum(rows(:,4)+rows(:,5)); change=after-before;
            lines = {'Per-band new Lp:'};
            for i=1:size(rows,1)
                lines{end+1} = sprintf('  %6g Hz: Lp %g  dLp %+.2f  -> %.2f', rows(i,1), rows(i,2), rows(i,3), rows(i,4)); %#ok<AGROW>
            end
            lines = [lines, { '', sprintf('(a) Current  = %.1f %s', before, tag), ...
                sprintf('(b) After    = %.1f %s', after, tag), ...
                sprintf('(c) Change   = %+.1f %s', change, tag), '', 'WORKING', ...
                'A1 = 0.161*V/T60 · A_abs = S_abs*alpha · A2 = A1 -/+ A_abs', ...
                'dLp = 10*log10(A1/A2) · new Lp = Lp + dLp', ...
                'overall = 10*log10( sum 10^((Lp+W)/10) )' }];
            app.W.out.Value = lines;
        end

        % ================= SOUND POWER =================
        function buildK1(app)
            gl = app.form(4);
            app.W.st = app.numField(gl,1,'Mean SPL, source on (dB)',80);
            app.W.b  = app.numField(gl,2,'Mean SPL, background (dB)',71);
            app.goButton(gl,3,@(o,e) app.runK1());
            app.W.out = app.resultBox(gl,4);
        end
        function runK1(app)
            st=app.W.st.Value; b=app.W.b.Value; dL=st-b;
            if dL<=0, app.W.out.Value = {'Source level must exceed background.'}; return; end
            if dL<6
                app.W.out.Value = {sprintf('dL = %.1f dB < 6 dB - measurement invalid (background too high).', dL)}; return;
            end
            K1=-10*log10(1-10^(-dL/10));
            extra=''; if dL>=15, extra=' (>=15 dB -> negligible)'; end
            app.W.out.Value = { sprintf('dL = %.1f dB · K1 = %.3f dB%s', dL, K1, extra), '', 'WORKING', ...
                'K1 = -10*log10(1 - 10^(-dL/10))', ...
                sprintf('= -10*log10(1 - 10^(-%.1f/10)) = %.3f dB', dL, K1) };
        end

        function buildK2(app)
            gl = app.form(4);
            app.W.S = app.numField(gl,1,'Measurement surface S (m^2)',6.28);
            app.W.A = app.numField(gl,2,'Room absorption area A (m^2)',50);
            app.goButton(gl,3,@(o,e) app.runK2());
            app.W.out = app.resultBox(gl,4);
        end
        function runK2(app)
            S=app.W.S.Value; A=app.W.A.Value;
            if ~(A>0), app.W.out.Value = {'Absorption area must be > 0.'}; return; end
            K2=10*log10(1+4*S/A);
            app.W.out.Value = { sprintf('K2 = %.3f dB', K2), '', 'WORKING', ...
                sprintf('K2 = 10*log10(1 + 4S/A) = 10*log10(1 + 4*%g/%g) = %.3f dB', S, A, K2) };
        end

        function buildLwMeas(app)
            gl = app.form(6);
            app.W.lp = app.numField(gl,1,'Mean source SPL (dB)',80);
            app.W.k1 = app.numField(gl,2,'K1 (dB)',0.6);
            app.W.k2 = app.numField(gl,3,'K2 (dB)',0.4);
            app.W.S  = app.numField(gl,4,'Measurement surface S (m^2)',6.28);
            app.goButton(gl,5,@(o,e) app.runLwMeas());
            app.W.out = app.resultBox(gl,6);
        end
        function runLwMeas(app)
            lp=app.W.lp.Value; k1=app.W.k1.Value; k2=app.W.k2.Value; S=app.W.S.Value;
            if ~(S>0), app.W.out.Value = {'Surface area must be > 0.'}; return; end
            Lw=(lp-k1-k2)+10*log10(S);
            app.W.out.Value = { sprintf('Lw = %.2f dB', Lw), '', 'WORKING', ...
                'Lw = (Lp - K1 - K2) + 10*log10(S/S0),  S0 = 1 m^2', ...
                sprintf('= (%g - %g - %g) + 10*log10(%g) = %.2f dB', lp, k1, k2, S, Lw) };
        end

        function buildPowerBands(app)
            gl = uigridlayout(app.Content,[7 2]);
            gl.RowHeight = {32,32,'1x',32,32,32,150}; gl.ColumnWidth = {180,'1x'};
            app.W.net = app.ddField(gl,1,'Band levels are',{'A-weighted','B-weighted','C-weighted','Linear (Z)'});
            app.W.sp  = app.ddField(gl,2,'Band spacing', ...
                {'Octave (63-8k)','Octave (31.5-16k)','1/3 Octave'});
            app.W.sp.Value = 'Octave (31.5-16k)';
            app.W.sp.ValueChangedFcn = @(o,e) app.fillPowerTable();
            app.W.tbl = uitable(gl,'ColumnName',{'Freq (Hz)','Level (dB)'},'ColumnEditable',[false true]);
            app.W.tbl.Layout.Row = 3; app.W.tbl.Layout.Column = [1 2];
            app.W.surf = app.ddField(gl,4,'Surface',{'Hemisphere (2*pi*r^2)','Sphere (4*pi*r^2)','Custom area'});
            sub = uigridlayout(gl,[1 4]); sub.Layout.Row=5; sub.Layout.Column=[1 2]; sub.Padding=[0 0 0 0];
            uilabel(sub,'Text','r (m) / d (m) / S:');
            app.W.r = uieditfield(sub,'text','Value','0.43','Placeholder','radius');
            app.W.d = uieditfield(sub,'text','Value','','Placeholder','diameter');
            app.W.Scust = uieditfield(sub,'text','Value','','Placeholder','custom S');
            b = uibutton(gl,'Text','Compute Lw','ButtonPushedFcn',@(o,e) app.runPowerBands());
            b.Layout.Row = 6; b.Layout.Column = [1 2];
            app.W.out = uitextarea(gl,'Editable','off','FontName','monospaced');
            app.W.out.Layout.Row = 7; app.W.out.Layout.Column = [1 2];
            app.fillPowerTable();
        end
        function fillPowerTable(app)
            f = app.spacingFreqs(app.W.sp.Value);
            app.W.tbl.Data = [num2cell(f), repmat({[]},numel(f),1)];
        end
        function runPowerBands(app)
            net = app.netChar(app.W.net.Value);
            d=app.W.tbl.Data; rows=[];
            for i=1:size(d,1)
                v=d{i,2};
                if ~isempty(v)&&~isnan(v)
                    f=d{i,1}; w=app.weight(f,net); rows(end+1,:)=[f, v, v-w]; %#ok<AGROW>
                end
            end
            if isempty(rows), app.W.out.Value = {'Enter at least one band level.'}; return; end
            switch app.W.surf.Value
                case 'Custom area'
                    S=str2double(app.W.Scust.Value);
                    if ~(S>0), app.W.out.Value = {'Enter a custom area S > 0.'}; return; end
                    surfName='custom surface';
                otherwise
                    r=str2double(app.W.r.Value); dd=str2double(app.W.d.Value);
                    if ~(r>0)&&dd>0, r=dd/2; end
                    if ~(r>0), app.W.out.Value = {'Enter a radius or diameter > 0 (or custom area).'}; return; end
                    if startsWith(app.W.surf.Value,'Sphere'), S=4*pi*r*r; surfName='sphere (S=4*pi*r^2)';
                    else, S=2*pi*r*r; surfName='hemisphere (S=2*pi*r^2)'; end
            end
            Lp=app.dBsum(rows(:,3)); p2=app.PREF^2*10^(Lp/10); I=p2/app.RHOC; Wp=I*S; Lw=10*log10(Wp/app.WREF);
            lines = {'Un-weighted band levels:'};
            for i=1:size(rows,1)
                lines{end+1} = sprintf('  %6g Hz: %g  -> %.1f', rows(i,1), rows(i,2), rows(i,3)); %#ok<AGROW>
            end
            lines = [lines, { '', sprintf('Lw = %.1f dB re 1e-12 W', Lw), '', 'WORKING', ...
                sprintf('Overall SPL Lp = 10*log10( sum 10^(L_lin/10) ) = %.2f dB', Lp), ...
                sprintf('p2_rms = p_ref^2 * 10^(Lp/10) = %.4g Pa^2', p2), ...
                sprintf('I = p2/(rho c) = %.4g W/m^2', I), ...
                sprintf('%s: S = %.4g m^2', surfName, S), ...
                sprintf('W = I*S = %.4g W', Wp), ...
                sprintf('Lw = 10*log10(W/1e-12) = %.1f dB', Lw) }];
            app.W.out.Value = lines;
        end

        % ================= DUCT =================
        function buildDuct(app)
            gl = app.form(8);
            app.W.Lw   = app.numField(gl,1,'Sound power level Lw (dB)',93);
            app.W.d    = app.numField(gl,2,'Pipe diameter d (mm)',114);
            app.W.sens = app.numField(gl,3,'Mic sensitivity (dB re 1 V/Pa)',-68);
            app.W.rho  = app.numField(gl,4,'Air density rho (kg/m^3)',1.21);
            app.W.c    = app.numField(gl,5,'Sound speed c (m/s)',343);
            app.W.fmax = app.txtField(gl,6,'Highest frequency (Hz, optional)','1500');
            app.goButton(gl,7,@(o,e) app.runDuct());
            app.W.out = app.resultBox(gl,8);
        end
        function runDuct(app)
            Lw=app.W.Lw.Value; d=app.W.d.Value/1000; Sdb=app.W.sens.Value; rho=app.W.rho.Value; c=app.W.c.Value;
            fmax=app.pnum(app.W.fmax); if isnan(fmax), fmax=0; end
            if ~(d>0), app.W.out.Value = {'Pipe diameter must be > 0.'}; return; end
            if ~(rho>0&&c>0), app.W.out.Value = {'Density and sound speed must be > 0.'}; return; end
            Wp=app.WREF*10^(Lw/10); A=pi*d*d/4; I=Wp/A; rc=rho*c; p=sqrt(I*rc);
            Lp=20*log10(p/app.PREF); sens=10^(Sdb/20); V=p*sens; fc=1.8412*c/(pi*d);
            if fmax>0
                if fmax<fc, modeNote=sprintf('Highest freq %.0f Hz < cut-on %.0f Hz -> plane waves only, valid.', fmax, fc);
                else, modeNote=sprintf('Highest freq %.0f Hz >= cut-on %.0f Hz -> higher-order modes, result approximate.', fmax, fc); end
            else
                modeNote=sprintf('First higher-order mode cuts on at %.0f Hz (plane-wave assumption valid below).', fc);
            end
            app.W.out.Value = { sprintf('RMS voltage = %.4g V  (%.4g mV)', V, V*1000), '', 'WORKING', ...
                sprintf('W = W_ref*10^(Lw/10) = %.4g W', Wp), ...
                sprintf('A = pi*d^2/4 = %.4g m^2', A), ...
                sprintf('I = W/A = %.4g W/m^2', I), ...
                sprintf('p_rms = sqrt(I*rho*c) = sqrt(%.4g) = %.4g Pa', I*rc, p), ...
                sprintf('(SPL Lp = 20*log10(p/p_ref) = %.1f dB)', Lp), ...
                sprintf('mic sensitivity = 10^(S/20) = %.4g V/Pa', sens), ...
                sprintf('V = p_rms*10^(S/20) = %.4g V', V), '', modeNote };
        end

        % ================= WEIGHTING =================
        function buildWeighting(app)
            gl = uigridlayout(app.Content,[5 2]);
            gl.RowHeight = {32,32,'1x',32,140}; gl.ColumnWidth = {140,'1x'};
            app.W.net = app.ddField(gl,1,'Weighting',{'A','B','C','Z (none)'});
            app.W.sp  = app.ddField(gl,2,'Band spacing',{'Octave (63-8k)','Octave (31.5-16k)','1/3 Octave'});
            app.W.sp.ValueChangedFcn = @(o,e) app.fillWeightTable();
            app.W.tbl = uitable(gl,'ColumnName',{'Freq (Hz)','Level (dB)'},'ColumnEditable',[false true]);
            app.W.tbl.Layout.Row = 3; app.W.tbl.Layout.Column = [1 2];
            b = uibutton(gl,'Text','Calculate overall level','ButtonPushedFcn',@(o,e) app.runWeighting());
            b.Layout.Row = 4; b.Layout.Column = [1 2];
            app.W.out = uitextarea(gl,'Editable','off','FontName','monospaced');
            app.W.out.Layout.Row = 5; app.W.out.Layout.Column = [1 2];
            app.fillWeightTable();
        end
        function fillWeightTable(app)
            f = app.spacingFreqs(app.W.sp.Value);
            app.W.tbl.Data = [num2cell(f), repmat({[]},numel(f),1)];
        end
        function runWeighting(app)
            d=app.W.tbl.Data; net=app.W.net.Value(1); f=[]; L=[];
            for i=1:size(d,1)
                v=d{i,2};
                if ~isempty(v)&&~isnan(v), f(end+1)=d{i,1}; L(end+1)=v; end %#ok<AGROW>
            end
            if isempty(L), app.W.out.Value = {'Enter at least one band level.'}; return; end
            w=arrayfun(@(x) app.weight(x,net), f); Lw=L+w;
            lin=app.dBsum(L); wtd=app.dBsum(Lw);
            tag='dB'; if net~='Z', tag=sprintf('dB(%c)',net); end
            lines = { sprintf('Overall %s = %.1f', tag, wtd), ...
                sprintf('Linear (unweighted) total = %.1f dB', lin), '', 'WORKING', ...
                'L_W = 10*log10( sum 10^((Li+Wi)/10) )' };
            for i=1:numel(f)
                lines{end+1} = sprintf('  %6g Hz: %g %+.1f = %.1f', f(i), L(i), w(i), Lw(i)); %#ok<AGROW>
            end
            lines{end+1} = sprintf('  => %.1f %s', wtd, tag);
            app.W.out.Value = lines;
        end

        % ================= BAND WORKBENCH =================
        function buildBand(app)
            gl = uigridlayout(app.Content,[4 2]);
            gl.RowHeight = {32,'1x',32,150}; gl.ColumnWidth = {140,'1x'};
            app.W.net = app.ddField(gl,1,'Weighting',{'A','B','C','Z (none)'});
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
            d=app.W.tbl.Data; net=app.W.net.Value(1);
            lev=containers.Map('KeyType','double','ValueType','double');
            for i=1:size(d,1)
                v=d{i,2};
                if ~isempty(v)&&~isnan(v), lev(d{i,1})=v; end
            end
            if lev.Count==0, app.W.out.Value = {'Enter at least one 1/3-octave level.'}; return; end
            T=app.THIRD; lines={'(a) Octave band SPLs:'}; octSPL=[]; octCtr=[];
            for i=1:3:numel(T)-2
                trio=T(i:i+2); have=trio(arrayfun(@(f) isKey(lev,f), trio));
                if isempty(have), continue; end
                vals=arrayfun(@(f) lev(f), have); spl=app.dBsum(vals);
                octSPL(end+1)=spl; octCtr(end+1)=T(i+1); %#ok<AGROW>
                combo=strjoin(arrayfun(@(x) sprintf('%g',x), vals, 'UniformOutput',false), '+');
                lines{end+1}=sprintf('   %6g Hz : %s -> %.2f dB', T(i+1), combo, spl); %#ok<AGROW>
            end
            overall=app.dBsum(octSPL);
            w=arrayfun(@(cc) app.weight(cc,net), octCtr); wtd=app.dBsum(octSPL+w);
            tag='dB'; if net~='Z', tag=sprintf('dB(%c)',net); end
            lines=[lines, { '', sprintf('(b) Overall SPL      = %.2f dB', overall), ...
                sprintf('(b) Overall weighted = %.2f %s', wtd, tag), '', 'WORKING', ...
                'octave SPL = 10*log10( sum 10^(L_third/10) ) over its 3 thirds', ...
                'Overall    = 10*log10( sum 10^(L_oct/10) )', ...
                'Weighted   = 10*log10( sum 10^((L_oct+W_oct)/10) )' }];
            app.W.out.Value = lines;
        end

        % ================= LEQ =================
        function buildLeq(app)
            gl = uigridlayout(app.Content,[6 2]);
            gl.RowHeight = {20,'1x',32,32,32,120}; gl.ColumnWidth = {180,'1x'};
            l = uilabel(gl,'Text','Level dB(A) and Duration per row (units allowed, e.g. 15 min, 2 h):');
            l.Layout.Row = 1; l.Layout.Column = [1 2];
            app.W.tbl = uitable(gl,'ColumnName',{'Level dB(A)','Duration'}, ...
                'ColumnEditable',[true true], 'Data',{96,'15 min';91,'2 h';99,'6 min';86,'2.5 h'});
            app.W.tbl.Layout.Row = 2; app.W.tbl.Layout.Column = [1 2];
            addb = uibutton(gl,'Text','+ Add row','ButtonPushedFcn',@(o,e) app.addRow(app.W.tbl,{[],''}));
            addb.Layout.Row = 3; addb.Layout.Column = 1;
            b = uibutton(gl,'Text','Compute Leq','ButtonPushedFcn',@(o,e) app.runLeq());
            b.Layout.Row = 3; b.Layout.Column = 2;
            app.W.unit = app.ddField(gl,4,'Default unit (bare numbers)',{'hours','minutes','seconds'});
            app.W.T = app.txtField(gl,5,'Reference T (blank = sum t)','');
            app.W.out = uitextarea(gl,'Editable','off','FontName','monospaced');
            app.W.out.Layout.Row = 6; app.W.out.Layout.Column = [1 2];
        end
        function runLeq(app)
            def = app.unitChar(app.W.unit.Value);
            [L,t] = app.readLevelTime(app.W.tbl, def);
            if isempty(L), app.W.out.Value = {'Enter level, duration rows (e.g. 96, 15 min).'}; return; end
            energy=sum(t.*10.^(L/10)); sumT=sum(t);
            T=app.parseTime(app.W.T.Value, def); if isnan(T)||T<=0, T=sumT; end
            leq=10*log10(energy/T); sel=10*log10(energy);
            app.W.out.Value = { sprintf('Leq = %.3f dB   (sum t = %s, T = %s)', leq, app.fmtSeconds(sumT), app.fmtSeconds(T)), ...
                sprintf('SEL (L_AE, over 1 s) = %.2f dB', sel), '', 'WORKING', ...
                'Leq = 10*log10( (1/T) * sum ti*10^(Li/10) )   [SI seconds]', ...
                sprintf('= 10*log10( (1/%.4g) * %.5g ) = %.3f dB', T, energy, leq), ...
                'SEL = 10*log10( sum ti*10^(Li/10) / 1s ) = Leq + 10*log10(T/1s)', ...
                sprintf('= %.3f + 10*log10(%.4g) = %.2f dB', leq, T, sel) };
        end

        function buildEvents(app)
            gl = uigridlayout(app.Content,[6 2]);
            gl.RowHeight = {20,'1x',32,32,32,120}; gl.ColumnWidth = {180,'1x'};
            l = uilabel(gl,'Text','Level dB(A), single-event duration, number of events per row:');
            l.Layout.Row = 1; l.Layout.Column = [1 2];
            app.W.tbl = uitable(gl,'ColumnName',{'Level dB(A)','Event time','No. events'}, ...
                'ColumnEditable',[true true true], 'Data',{86,'12 s',120;79,'18 s',200;78,'24 s',80});
            app.W.tbl.Layout.Row = 2; app.W.tbl.Layout.Column = [1 2];
            addb = uibutton(gl,'Text','+ Add row','ButtonPushedFcn',@(o,e) app.addRow(app.W.tbl,{[],'',[]}));
            addb.Layout.Row = 3; addb.Layout.Column = 1;
            b = uibutton(gl,'Text','Compute Leq','ButtonPushedFcn',@(o,e) app.runEvents());
            b.Layout.Row = 3; b.Layout.Column = 2;
            app.W.unit = app.ddField(gl,4,'Default unit (bare numbers)',{'seconds','minutes','hours'});
            app.W.T = app.txtField(gl,5,'Reference period T','24 h');
            app.W.out = uitextarea(gl,'Editable','off','FontName','monospaced');
            app.W.out.Layout.Row = 6; app.W.out.Layout.Column = [1 2];
        end
        function runEvents(app)
            def = app.unitChar(app.W.unit.Value);
            T = app.parseTime(app.W.T.Value, def);
            if ~(T>0), app.W.out.Value = {'Reference period T must be > 0.'}; return; end
            d=app.W.tbl.Data; energy=0; ok=false;
            for i=1:size(d,1)
                L=d{i,1}; tsec=app.parseTime(d{i,2},def); n=d{i,3};
                if isempty(L)||(isnumeric(L)&&isnan(L))||isnan(tsec)||isempty(n)||(isnumeric(n)&&isnan(n)), continue; end
                energy=energy+n*tsec*10^(L/10); ok=true;
            end
            if ~ok, app.W.out.Value = {'Each row needs: level, event duration, number of events.'}; return; end
            leq=10*log10(energy/T);
            app.W.out.Value = { sprintf('Leq,T = %.3f dB   (T = %s)', leq, app.fmtSeconds(T)), '', 'WORKING', ...
                'Leq = 10*log10( (1/T) * sum Ni*ti*10^(Li/10) )   [SI seconds]', ...
                sprintf('= 10*log10( (1/%.4g) * %.5g ) = %.3f dB', T, energy, leq) };
        end

        function buildTimeVarying(app)
            gl = uigridlayout(app.Content,[7 2]);
            gl.RowHeight = {44,'1x',32,32,32,120,'1x'}; gl.ColumnWidth = {180,'1x'};
            l = uilabel(gl,'WordWrap','on','Text', ...
                ['Segments, one per line:   const:  t1, t2, const, L     ramp:  t1, t2, ramp, a, b, c   ' ...
                 '(L = 10*log10(a*t+b) + c)']);
            l.Layout.Row = 1; l.Layout.Column = [1 2];
            app.W.seg = uitextarea(gl,'Value',{'0, 1, ramp, 9, 1, 80','1, 5, const, 80'});
            app.W.seg.Layout.Row = 2; app.W.seg.Layout.Column = [1 2];
            app.W.N = app.numField(gl,3,'Percentile N for LN (%)',10);
            app.W.T = app.txtField(gl,4,'Reference T (blank = full span)','');
            b = uibutton(gl,'Text','Compute Leq & LN','ButtonPushedFcn',@(o,e) app.runTimeVarying());
            b.Layout.Row = 5; b.Layout.Column = [1 2];
            app.W.out = uitextarea(gl,'Editable','off','FontName','monospaced');
            app.W.out.Layout.Row = 6; app.W.out.Layout.Column = [1 2];
            app.W.ax = uiaxes(gl); app.W.ax.Layout.Row = 7; app.W.ax.Layout.Column = [1 2];
            xlabel(app.W.ax,'Time'); ylabel(app.W.ax,'Level (dB)');
        end
        function runTimeVarying(app)
            [segs, err] = app.parseSegments(app.W.seg.Value);
            if ~isempty(err), app.W.out.Value = {err}; cla(app.W.ax); return; end
            tStart=min([segs.t1]); tEnd=max([segs.t2]);
            T=str2double(strtrim(app.W.T.Value)); if ~(T>0), T=tEnd-tStart; end
            E=0; for i=1:numel(segs), E=E+app.segEnergy(segs(i)); end
            leq=10*log10(E/T);
            N=app.W.N.Value; LN=NaN;
            if N>0 && N<100
                np=100000; tt=tStart+((0:np-1)+0.5)/np*(tEnd-tStart); arr=zeros(1,np);
                for i=1:np
                    s=app.segAt(segs,tt(i)); arr(i)=app.segLevel(s,tt(i));
                end
                arr=sort(arr); LN=arr(max(1,floor((1-N/100)*(np-1))+1));
            end
            lines = { sprintf('Leq = %.2f dB(A)', leq) };
            if ~isnan(LN)
                lines{end+1} = sprintf('L%g%% = %.2f dB(A)  (exceeded %g%% of the %.4g period)', N, LN, N, T);
            end
            lines = [lines, { '', 'WORKING', 'Leq = 10*log10( (1/T) * sum integral 10^(L(t)/10) dt )' }];
            for i=1:numel(segs)
                s=segs(i);
                if strcmp(s.type,'const')
                    lines{end+1} = sprintf('[%g-%g] const %g dB -> int = %.4g', s.t1, s.t2, s.L, app.segEnergy(s)); %#ok<AGROW>
                else
                    lines{end+1} = sprintf('[%g-%g] ramp 10*log10(%g t+%g)+%g -> int = %.4g', s.t1, s.t2, s.a, s.b, s.c, app.segEnergy(s)); %#ok<AGROW>
                end
            end
            lines{end+1} = sprintf('sum int = %.5g · T = %g · Leq = %.2f dB(A)', E, T, leq);
            app.W.out.Value = lines;
            % plot
            cla(app.W.ax); hold(app.W.ax,'on');
            for i=1:numel(segs)
                s=segs(i);
                if strcmp(s.type,'const'), tp=[s.t1 s.t2]; Lp=[s.L s.L];
                else, tp=linspace(s.t1,s.t2,48); Lp=arrayfun(@(x) app.segLevel(s,x), tp); end
                plot(app.W.ax, tp, Lp, '-', 'Color',[0.17 0.83 0.75], 'LineWidth',2);
            end
            if ~isnan(LN)
                plot(app.W.ax, [tStart tEnd], [LN LN], '--', 'Color',[0.96 0.62 0.04], 'LineWidth',1.3);
                text(app.W.ax, tEnd, LN, sprintf(' L%g%%=%.1f',N,LN), ...
                    'Color',[0.96 0.62 0.04], 'HorizontalAlignment','right', 'VerticalAlignment','bottom');
            end
            hold(app.W.ax,'off');
        end

        % ================= NOISE DOSE =================
        function buildDose(app)
            gl = uigridlayout(app.Content,[7 2]);
            gl.RowHeight = {20,'1x',32,32,32,32,150}; gl.ColumnWidth = {180,'1x'};
            l = uilabel(gl,'Text','Level dB(A) and Duration per row (units allowed, e.g. 15 min):');
            l.Layout.Row = 1; l.Layout.Column = [1 2];
            app.W.tbl = uitable(gl,'ColumnName',{'Level dB(A)','Duration'}, ...
                'ColumnEditable',[true true],'Data',{96,'15 min';91,'2 h';99,'6 min';86,'2.5 h'});
            app.W.tbl.Layout.Row=2; app.W.tbl.Layout.Column=[1 2];
            addb = uibutton(gl,'Text','+ Add row','ButtonPushedFcn',@(o,e) app.addRow(app.W.tbl,{[],''}));
            addb.Layout.Row = 3; addb.Layout.Column = 1;
            b = uibutton(gl,'Text','Assess','ButtonPushedFcn',@(o,e) app.runDose());
            b.Layout.Row=3; b.Layout.Column=2;
            sub = uigridlayout(gl,[1 4]); sub.Layout.Row=4; sub.Layout.Column=[1 2]; sub.Padding=[0 0 0 0];
            app.W.unit = uidropdown(sub,'Items',{'hours','minutes','seconds'});
            app.W.Lc = uieditfield(sub,'numeric','Value',85);
            app.W.q  = uieditfield(sub,'numeric','Value',3);
            app.W.Tc = uieditfield(sub,'numeric','Value',8);
            app.note(gl,5,'fields: default unit · Lc (dB(A)) · q (dB) · Tc (h).  Ti = Tc/2^((Li-Lc)/q), Dose = sum ti/Ti.');
            app.W.out = uitextarea(gl,'Editable','off','FontName','monospaced');
            app.W.out.Layout.Row=7; app.W.out.Layout.Column=[1 2];
        end
        function runDose(app)
            def = app.unitChar(app.W.unit.Value);
            [L,tsec] = app.readLevelTime(app.W.tbl, def);
            if isempty(L), app.W.out.Value = {'Enter level, duration rows.'}; return; end
            t = tsec/3600;  % hours
            Lc=app.W.Lc.Value; q=app.W.q.Value; Tc=app.W.Tc.Value;
            energy=sum(t.*10.^(L/10)); sumT=sum(t);
            Ti=Tc./2.^((L-Lc)/q); dose=sum(t./Ti);
            leqT=10*log10(energy/sumT); leq8=10*log10(energy/Tc);
            Tmax=Tc/2^((leqT-Lc)/q); exceed=leq8>Lc;
            app.W.out.Value = { ...
                sprintf('L_Aeq,T  (over %.3g h) = %.3f dB(A)', sumT, leqT), ...
                sprintf('L_Aeq,%gh             = %.3f dB(A)', Tc, leq8), ...
                sprintf('Noise dose            = %.1f %%  (100%% = limit)', dose*100), ...
                sprintf('Exceeds %g dB(A)?      %s', Lc, ternary(exceed,'YES','No')), ...
                sprintf('Max permissible time  = %.3f h (%s)', Tmax, fmtHM(Tmax)), ...
                '', 'WORKING', ...
                sprintf('L_Aeq,T = 10*log10( (1/%.3g) * sum ti*10^(Li/10) ) = %.3f dB(A)', sumT, leqT), ...
                sprintf('L_Aeq,%gh = L_Aeq,T + 10*log10(T/Tc) = %.3f', Tc, leq8), ...
                'Allowed time Ti = Tc / 2^((Li-Lc)/q)', ...
                sprintf('Dose = sum ti/Ti = %.4f = %.1f %%', dose, dose*100), ...
                sprintf('Tmax = Tc / 2^((L_Aeq,T-Lc)/q) = %.3f h', Tmax) };
        end

        function buildMaxTime(app)
            gl = app.form(6);
            app.W.L  = app.numField(gl,1,'Noise level L (dB(A))',89);
            app.W.Lc = app.numField(gl,2,'Criterion Lc (dB(A))',85);
            app.W.q  = app.numField(gl,3,'Exchange rate q (dB)',3);
            app.W.Tc = app.numField(gl,4,'Criterion time Tc (h)',8);
            app.goButton(gl,5,@(o,e) app.runMaxTime());
            app.W.out = app.resultBox(gl,6);
        end
        function runMaxTime(app)
            L=app.W.L.Value; Lc=app.W.Lc.Value; q=app.W.q.Value; Tc=app.W.Tc.Value;
            if ~(q>0)||~(Tc>0), app.W.out.Value = {'q and Tc must be > 0.'}; return; end
            T=Tc/2^((L-Lc)/q); exceed=L>Lc;
            app.W.out.Value = { sprintf('T = %.3f h  (%s) - level %s the %g dB(A) criterion.', ...
                    T, fmtHM(T), ternary(exceed,'exceeds','is within'), Lc), ...
                '', 'WORKING', 'T = Tc / 2^((L - Lc)/q)', ...
                sprintf('= %g / 2^((%g - %g)/%g) = %g / %.4g = %.4f h', Tc, L, Lc, q, Tc, 2^((L-Lc)/q), T) };
        end

        % ================= LOUDNESS =================
        function buildPh2S(app)
            gl = app.form(4);
            app.W.p = app.numField(gl,1,'Loudness level LL (phons)',80);
            app.goButton(gl,2,@(o,e) app.runPh2S());
            app.W.out = app.resultBox(gl,4);
        end
        function runPh2S(app)
            p=app.W.p.Value; s=2^((p-40)/10);
            extra={}; if p<40, extra={'Note: formula assumes LL >= 40 phon.'}; end
            app.W.out.Value = [{ sprintf('Loudness = %.3f sones', s) }, extra, ...
                { '', 'WORKING', 'S = 2^((LL - 40)/10)', sprintf('= 2^((%g - 40)/10) = %.3f sones', p, s) }];
        end

        function buildS2Ph(app)
            gl = app.form(4);
            app.W.s = app.numField(gl,1,'Loudness S (sones)',16);
            app.goButton(gl,2,@(o,e) app.runS2Ph());
            app.W.out = app.resultBox(gl,4);
        end
        function runS2Ph(app)
            s=app.W.s.Value;
            if ~(s>0), app.W.out.Value = {'Sones must be > 0.'}; return; end
            p=40+10*log2(s);
            app.W.out.Value = { sprintf('Loudness level = %.2f phons', p), '', 'WORKING', ...
                'LL = 40 + 10*log2(S)', sprintf('= 40 + 10*log2(%g) = %.2f phons', s, p) };
        end

        % ================= SPEECH (PSIL) =================
        function buildPSIL(app)
            gl = app.form(6);
            app.W.a = app.numField(gl,1,'L at 500 Hz (dB)',76);
            app.W.b = app.txtField(gl,2,'L at 1000 Hz (blank = same)','');
            app.W.c = app.txtField(gl,3,'L at 2000 Hz (blank = same)','');
            app.W.dist = app.numField(gl,4,'Talker-listener distance (m)',1.5);
            app.goButton(gl,5,@(o,e) app.runPSIL());
            app.W.out = app.resultBox(gl,6);
        end
        function runPSIL(app)
            a=app.W.a.Value;
            b=app.pnum(app.W.b); if isnan(b), b=a; end
            c=app.pnum(app.W.c); if isnan(c), c=a; end
            dist=app.W.dist.Value; psil=(a+b+c)/3;
            adj=psil+20*log10(max(dist,0.05)/1.0);
            if adj<45, effort='Normal to Raised';
            elseif adj<55, effort='Raised to Very Loud';
            elseif adj<65, effort='Very Loud to Shouting';
            elseif adj<75, effort='Shouting';
            else, effort='Communication impossible'; end
            app.W.out.Value = { sprintf('PSIL = %.2f dB · at %g m voice effort: %s', psil, dist, effort), ...
                '', 'WORKING', 'PSIL = (L500 + L1000 + L2000)/3', ...
                sprintf('= (%g + %g + %g)/3 = %.2f dB', a, b, c, psil) };
        end

        % ================= COMMUNITY =================
        function buildLdn(app)
            gl = app.form(4);
            app.W.day   = app.numField(gl,1,'Daytime LAeq,day (15 h, dB(A))',65);
            app.W.night = app.numField(gl,2,'Night-time LAeq,night (9 h, dB(A))',55);
            app.goButton(gl,3,@(o,e) app.runLdn());
            app.W.out = app.resultBox(gl,4);
        end
        function runLdn(app)
            dv=app.W.day.Value; nv=app.W.night.Value;
            ed=15*10^(dv/10); en=9*10^((nv+10)/10); ldn=10*log10((ed+en)/24);
            app.W.out.Value = { sprintf('Ldn = %.2f dB(A)', ldn), '', 'WORKING', ...
                'Ldn = 10*log10( (1/24)[ 15*10^(Lday/10) + 9*10^((Lnight+10)/10) ] )', ...
                sprintf('= 10*log10( (1/24)[ %.4g + %.4g ] )', ed, en), ...
                sprintf('= 10*log10( %.5g ) = %.2f dB(A)', (ed+en)/24, ldn) };
        end

        % ================= STATS / SEL =================
        function buildSEL(app)
            gl = app.form(4);
            app.W.leq = app.numField(gl,1,'Leq over the event (dB)',84.4);
            app.W.T   = app.numField(gl,2,'Event duration T (s)',60);
            app.goButton(gl,3,@(o,e) app.runSEL());
            app.W.out = app.resultBox(gl,4);
        end
        function runSEL(app)
            leq=app.W.leq.Value; T=app.W.T.Value;
            if ~(T>0), app.W.out.Value = {'T must be > 0.'}; return; end
            sel=leq+10*log10(T);
            app.W.out.Value = { sprintf('SEL = %.2f dB', sel), '', 'WORKING', ...
                'SEL = Leq + 10*log10(T / 1 s)', ...
                sprintf('= %g + 10*log10(%g) = %g + %.3f = %.2f dB', leq, T, leq, 10*log10(T), sel) };
        end

        function buildSort(app)
            gl = uigridlayout(app.Content,[4 1]);
            gl.RowHeight = {20,'1x',32,120};
            uilabel(gl,'Text','One measured value (dB) per line (assigned biggest->smallest):');
            app.W.txt = uitextarea(gl,'Value',{'93.5','31.5','84.4','102.5'});
            uibutton(gl,'Text','Assign SEL, L1, Leq, L99','ButtonPushedFcn',@(o,e) app.runSort());
            app.W.out = uitextarea(gl,'Editable','off','FontName','monospaced');
        end
        function runSort(app)
            v = sort(app.parseCol(app.W.txt.Value),'descend');
            if numel(v)<4, app.W.out.Value = {'Enter four values (one per line).'}; return; end
            app.W.out.Value = { 'Assigned by magnitude:', ...
                sprintf('  SEL (largest)  = %g dB', v(1)), ...
                sprintf('  L1             = %g dB', v(2)), ...
                sprintf('  Leq            = %g dB', v(3)), ...
                sprintf('  L99 (smallest) = %g dB', v(4)) };
        end

        % ================= INSULATION / TL =================
        function buildMassLaw(app)
            gl = app.form(6);
            app.W.M   = app.txtField(gl,1,'Surface mass M (kg/m^2)','');
            app.W.rho = app.txtField(gl,2,'or density (kg/m^3)','2500');
            app.W.t   = app.txtField(gl,3,'x thickness t (mm)','3');
            app.W.f   = app.numField(gl,4,'Frequency f (Hz)',1000);
            app.goButton(gl,5,@(o,e) app.runMassLaw());
            app.W.out = app.resultBox(gl,6);
        end
        function runMassLaw(app)
            M=app.pnum(app.W.M);
            if isnan(M)
                rho=app.pnum(app.W.rho); t=app.pnum(app.W.t);
                if ~isnan(rho)&&~isnan(t), M=rho*t/1000; end
            end
            f=app.W.f.Value;
            if ~(M>0), app.W.out.Value = {'Enter surface mass, or density and thickness.'}; return; end
            TL=20*log10(M*f)-42.4;
            app.W.out.Value = { sprintf('Surface mass M = %.3f kg/m^2', M), ...
                sprintf('TL = %.1f dB at %g Hz', TL, f), '', 'WORKING', ...
                'TL = 20*log10(M*f) - 42.4', ...
                sprintf('= 20*log10(%.3f*%g) - 42.4 = %.2f - 42.4 = %.1f dB', M, f, 20*log10(M*f), TL) };
        end

        function buildInterface(app)
            gl = app.form(4);
            app.W.z1 = app.numField(gl,1,'Medium 1 rho c (rayls)',415);
            app.W.z2 = app.numField(gl,2,'Medium 2 rho c (rayls)',1480000);
            app.goButton(gl,3,@(o,e) app.runInterface());
            app.W.out = app.resultBox(gl,4);
        end
        function runInterface(app)
            z1=app.W.z1.Value; z2=app.W.z2.Value; r=z2/z1;
            at=4*r/((r+1)^2); ar=((r-1)/(r+1))^2; TL=-10*log10(at);
            app.W.out.Value = { sprintf('Impedance ratio r = z2/z1 = %.4g', r), ...
                sprintf('alpha_t = %.4g · alpha_r = %.4f', at, ar), ...
                sprintf('TL = -10*log10(alpha_t) = %.2f dB', TL) };
        end

        function buildTLcoef(app)
            gl = app.form(4);
            app.W.a = app.numField(gl,1,'Transmission coefficient alpha_t',0.001);
            app.goButton(gl,2,@(o,e) app.runTLcoef());
            app.W.out = app.resultBox(gl,4);
        end
        function runTLcoef(app)
            a=app.W.a.Value;
            if ~(a>0&&a<=1), app.W.out.Value = {'alpha must be between 0 and 1.'}; return; end
            app.W.out.Value = { sprintf('TL = -10*log10(alpha_t) = -10*log10(%g) = %.2f dB', a, -10*log10(a)) };
        end

        function buildPanelRes(app)
            gl = app.form(4);
            app.W.K = app.numField(gl,1,'Stiffness per area K (N/m^3)',1e6);
            app.W.M = app.numField(gl,2,'Surface mass M (kg/m^2)',10);
            app.goButton(gl,3,@(o,e) app.runPanelRes());
            app.W.out = app.resultBox(gl,4);
        end
        function runPanelRes(app)
            K=app.W.K.Value; M=app.W.M.Value;
            if ~(K>0&&M>0), app.W.out.Value = {'K and M must be > 0.'}; return; end
            fn=sqrt(K/M)/(2*pi);
            app.W.out.Value = { sprintf('fn = (1/2pi)*sqrt(K/M) = (1/2pi)*sqrt(%g/%g) = %.2f Hz', K, M, fn) };
        end

        % ================= MUFFLERS =================
        function buildAreaChange(app)
            gl = app.form(5);
            app.W.s1 = app.numField(gl,1,'Pipe area S1 (m^2)',0.01);
            app.W.s2 = app.numField(gl,2,'Chamber/exit area S2 (m^2)',0.1);
            app.goButton(gl,3,@(o,e) app.runAreaChange());
            app.W.out = app.resultBox(gl,5);
        end
        function runAreaChange(app)
            s1=app.W.s1.Value; s2=app.W.s2.Value;
            if ~(s1>0&&s2>0), app.W.out.Value = {'Areas must be > 0.'}; return; end
            Tt=4*s1*s2/((s1+s2)^2); TL=-10*log10(Tt);
            app.W.out.Value = { sprintf('Tt = %.4g · TL = %.2f dB', Tt, TL), '', 'WORKING', ...
                'Tt = 4*S1*S2 / (S1+S2)^2', ...
                sprintf('= %.4g / %.4g = %.4g', 4*s1*s2, (s1+s2)^2, Tt), ...
                sprintf('TL = -10*log10(Tt) = %.2f dB', TL) };
        end

        function buildExpChamber(app)
            gl = app.form(7);
            app.W.s1 = app.numField(gl,1,'Pipe area S1 (m^2)',0.01);
            app.W.s2 = app.numField(gl,2,'Chamber area S2 (m^2)',0.1);
            app.W.L  = app.numField(gl,3,'Chamber length L (m)',0.3);
            app.W.f  = app.numField(gl,4,'Frequency f (Hz)',250);
            app.W.c  = app.numField(gl,5,'Speed c (m/s)',343);
            app.goButton(gl,6,@(o,e) app.runExpChamber());
            app.W.out = app.resultBox(gl,7);
        end
        function runExpChamber(app)
            s1=app.W.s1.Value; s2=app.W.s2.Value; L=app.W.L.Value; f=app.W.f.Value; c=app.W.c.Value;
            if ~(s1>0&&s2>0), app.W.out.Value = {'Areas must be > 0.'}; return; end
            m=s2/s1; kL=2*pi*f/c*L;
            TL=10*log10(cos(kL)^2+0.25*(m+1/m)^2*sin(kL)^2); lam=c/f;
            app.W.out.Value = { sprintf('kL = %.3f rad · TL = %.2f dB', kL, TL), ...
                sprintf('m = S2/S1 = %.2f · lambda = %.3f m · lambda/4 = %.3f m (peak length)', m, lam, lam/4), ...
                '', 'WORKING', 'TL = 10*log10[ cos^2(kL) + 1/4 (m+1/m)^2 sin^2(kL) ]' };
        end

        function buildLevelDiff(app)
            gl = app.form(4);
            app.W.a = app.numField(gl,1,'Upstream / without-treatment (dB)',100);
            app.W.b = app.numField(gl,2,'Downstream / with-treatment (dB)',78);
            app.goButton(gl,3,@(o,e) app.runLevelDiff());
            app.W.out = app.resultBox(gl,4);
        end
        function runLevelDiff(app)
            a=app.W.a.Value; b=app.W.b.Value;
            app.W.out.Value = { sprintf('Difference = %.2f dB', a-b), ...
                '(TL = Lw1 - Lw2 · IL = L_before - L_after · NR = L_in - L_out)' };
        end

        % ================= REFERENCE TABLE =================
        function buildRefTable(app)
            gl = uigridlayout(app.Content,[2 1]);
            gl.RowHeight = {20,'1x'};
            uilabel(gl,'Text','A / B / C weighting relative response (dB), IEC 61672 family:');
            t = uitable(gl,'ColumnName',{'Freq (Hz)','A (dB)','B (dB)','C (dB)'}, ...
                'Data',app.WTAB,'ColumnEditable',[false false false false]);
            t.Layout.Row = 2;
        end

        % ================= small utilities =================
        function addRow(~, tbl, template)
            tbl.Data(end+1,:) = template;
        end
        function v = pnum(~, h)
            v = str2double(strtrim(h.Value));
        end
        function [L,t] = readLevelTime(app, tbl, defUnit)
            d=tbl.Data; L=[]; t=[];
            for i=1:size(d,1)
                a=d{i,1};
                if isempty(a)||(isnumeric(a)&&isnan(a)), continue; end
                sec=app.parseTime(d{i,2}, defUnit);
                if isnan(sec), continue; end
                L(end+1)=a; t(end+1)=sec; %#ok<AGROW>
            end
        end
        function sec = parseTime(~, val, defUnit)
            if isnumeric(val), s=num2str(val); else, s=strtrim(char(val)); end
            if isempty(s), sec=NaN; return; end
            tok=regexp(s,'^([0-9.eE+\-]+)\s*([a-zA-Z]*)$','tokens','once');
            if isempty(tok), sec=NaN; return; end
            v=str2double(tok{1}); if isnan(v), sec=NaN; return; end
            u=lower(tok{2}); if isempty(u), u=defUnit; end
            switch u
                case {'s','sec','secs','second','seconds'}, f=1;
                case {'m','min','mins','minute','minutes'}, f=60;
                case {'h','hr','hrs','hour','hours'},       f=3600;
                otherwise, sec=NaN; return;
            end
            sec=v*f;
        end
        function u = unitChar(~, label)
            switch label
                case 'minutes', u='min';
                case 'seconds', u='s';
                otherwise,      u='h';
            end
        end
        function s = fmtSeconds(~, sec)
            if sec>=3600, s=sprintf('%.3g h',sec/3600);
            elseif sec>=60, s=sprintf('%.3g min',sec/60);
            else, s=sprintf('%.3g s',sec); end
        end
        function f = spacingFreqs(app, label)
            switch label
                case 'Octave (63-8k)',    f=app.OCTMAIN;
                case 'Octave (31.5-16k)', f=app.OCTFULL;
                otherwise,                f=app.THIRD;
            end
        end
        function net = netChar(~, label)
            net = label(1);  % 'A','B','C', or 'L' for Linear -> treat as Z
            if net=='L', net='Z'; end
        end
        function v = parseCol(~, c)
            if ischar(c), c = cellstr(c); end
            v = str2double(c); v = v(~isnan(v)); v = v(:)';
        end
        function rows = parseRows(~, c, ncols)
            if ischar(c), c = cellstr(c); end
            rows = [];
            for i=1:numel(c)
                ln = strtrim(c{i}); if isempty(ln), continue; end
                nums = str2double(regexp(ln,'[,\s]+','split'));
                nums = nums(~isnan(nums));
                if numel(nums) >= ncols, rows(end+1,:) = nums(1:ncols); end %#ok<AGROW>
            end
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
        % ---- time-varying segment helpers ----
        function [segs, err] = parseSegments(~, lines)
            if ischar(lines), lines = cellstr(lines); end
            segs = struct('t1',{},'t2',{},'type',{},'L',{},'a',{},'b',{},'c',{}); err='';
            for i=1:numel(lines)
                ln = strtrim(lines{i}); if isempty(ln), continue; end
                p = strtrim(strsplit(ln,','));
                if numel(p)<3
                    err=sprintf('Bad segment "%s" - need t1, t2, type, ...', ln); return;
                end
                t1=str2double(p{1}); t2=str2double(p{2});
                if isnan(t1) || isnan(t2) || t2<=t1
                    err=sprintf('Bad segment "%s" - need t1 < t2.', ln); return;
                end
                type=lower(p{3});
                s=struct('t1',t1,'t2',t2,'type',type,'L',NaN,'a',NaN,'b',NaN,'c',NaN);
                if strcmp(type,'const')
                    if numel(p)<4, err=sprintf('Constant segment "%s" needs level L.', ln); return; end
                    s.L=str2double(p{4});
                    if isnan(s.L), err=sprintf('Constant segment "%s" needs level L.', ln); return; end
                elseif strcmp(type,'ramp')
                    if numel(p)<6, err=sprintf('Ramp segment "%s" needs a, b, c.', ln); return; end
                    s.a=str2double(p{4}); s.b=str2double(p{5}); s.c=str2double(p{6});
                    if any(isnan([s.a s.b s.c])), err=sprintf('Ramp segment "%s" needs a, b, c.', ln); return; end
                    if s.a*t1+s.b<=0 || s.a*t2+s.b<=0
                        err=sprintf('Ramp "%s": a*t+b must stay > 0.', ln); return;
                    end
                else
                    err=sprintf('Segment "%s": type must be const or ramp.', ln); return;
                end
                segs(end+1)=s; %#ok<AGROW>
            end
            if isempty(segs), err='Enter at least one segment.'; end
        end
        function L = segLevel(~, s, t)
            if strcmp(s.type,'const'), L=s.L; else, L=10*log10(s.a*t+s.b)+s.c; end
        end
        function E = segEnergy(~, s)
            if strcmp(s.type,'const')
                E=(s.t2-s.t1)*10^(s.L/10);
            else
                E=10^(s.c/10)*(s.a*(s.t2^2-s.t1^2)/2 + s.b*(s.t2-s.t1));
            end
        end
        function s = segAt(~, segs, t)
            idx = find(t>=[segs.t1] & t<=[segs.t2], 1);
            if isempty(idx), idx=numel(segs); end
            s = segs(idx);
        end
    end
end

% ===== local functions (file-scope helpers) =====
function s = ternary(cond,a,b)
    if cond, s=a; else, s=b; end
end
function s = fmtHM(hours)
    if ~isfinite(hours), s='inf'; return; end
    secs = round(hours*3600);
    h = floor(secs/3600); secs = secs-h*3600; m = floor(secs/60); secs = secs-m*60;
    parts = {};
    if h>0, parts{end+1}=sprintf('%d h',h); end
    if m>0, parts{end+1}=sprintf('%d min',m); end
    if secs>0 && h==0, parts{end+1}=sprintf('%d s',secs); end
    if isempty(parts), s='0 min'; else, s=strjoin(parts,' '); end
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
