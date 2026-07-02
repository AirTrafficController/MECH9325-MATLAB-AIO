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
    %   The numerical work is delegated to the +acoustics function library
    %   (one .m file per formula), so every result shown here can also be
    %   reproduced from the command line, e.g.  acoustics.splPressure('p',1).
    %   The +acoustics package folder must be on the MATLAB path (it sits
    %   next to this file, so running from the repo root is enough).
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
            app.WTAB = acoustics.weightingTable();
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
            c(end+1,:) = {'Levels: Radiated power (point source)','radiated power intensity pressure w=i*s 4 pi r2 q directivity free field hemisphere point source lw', @app.buildRadiated};

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
            c(end+1,:) = {'Room: plant room (surface treatment)','plant room machine motor coat ceiling absorption alpha reverberant field surface treatment reduction dba band', @app.buildPlant};
            c(end+1,:) = {'Room: reverberation test room (mean-square p)','reverberation test room t60 mean square pressure empty furnished absorption exact rhoc reduction dba band', @app.buildRevRoom};

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
                R = acoustics.splPressure('p',p); app.W.lp.Value = sprintf('%.2f',R.Lp);
            else
                R = acoustics.splPressure('Lp',app.pnum(app.W.lp));
                app.W.p.Value = sprintf('%.4g',R.p);
            end
            app.W.out.Value = [{ sprintf('Lp = %.2f dB · p_rms = %.4g Pa', R.Lp, R.p), ...
                '', 'WORKING' }, R.steps];
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
                R = acoustics.powerLevel('Lw',app.pnum(app.W.Lw));
                app.W.W.Value = sprintf('%.4g',R.W);
            else
                Wp = app.pnum(app.W.W);
                if ~(Wp > 0), app.W.out.Value = {'Power must be > 0.'}; return; end
                R = acoustics.powerLevel('W',Wp); app.W.Lw.Value = sprintf('%.2f',R.Lw);
            end
            app.W.out.Value = [{ sprintf('Lw = %.2f dB · W = %.4g W', R.Lw, R.W), ...
                '', 'WORKING' }, R.steps];
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
            if ~isempty(strtrim(app.W.p.Value))
                p = app.pnum(app.W.p);
                if ~(p > 0), app.W.out.Value = {'Pressure must be > 0.'}; return; end
                R = acoustics.intensityLevel('p',p);
            else
                I = app.pnum(app.W.I);
                if ~(I > 0), app.W.out.Value = {'Enter intensity or pressure.'}; return; end
                R = acoustics.intensityLevel('I',I);
            end
            app.W.out.Value = [{ sprintf('I = %.4g W/m^2 · LI = %.2f dB', R.I, R.LI), ...
                '', 'WORKING' }, R.steps];
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
            ps = app.parseCol(app.W.list.Value);
            R = acoustics.peakToRms(app.W.P.Value, ps);
            lines = { sprintf('p_rms (from peak) = %.4g Pa  ->  SPL = %.2f dB', R.prms, R.splRms) };
            if ~isempty(ps)
                lines{end+1} = sprintf('p_tot (combined) = %.4g Pa  ->  SPL = %.2f dB', ...
                    R.ptot, R.splTot);
            end
            app.W.out.Value = [lines, {'', 'WORKING'}, R.steps];
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
            R = acoustics.psdToRms(f1, f2, s1, s2);
            app.W.out.Value = [{ sprintf('Mean-square p^2 = %.4g Pa^2 · p_rms = %.4g Pa · SPL = %.2f dB', ...
                R.meanSquare, R.prms, R.spl), '', 'WORKING' }, R.steps];
        end

        function buildRadiated(app)
            gl = app.form(7);
            app.W.src = app.ddField(gl,1,'Input', ...
                {'Peak pressure P (Pa)','Intensity I (W/m^2)'});
            app.W.val = app.numField(gl,2,'Value (P in Pa, or I in W/m^2)',25);
            app.W.r   = app.numField(gl,3,'Distance r (m)',2);
            app.W.Q   = app.ddField(gl,4,'Directivity Q', ...
                {'1 - free field','2 - hemisphere','4 - edge','8 - corner'});
            app.note(gl,5,'S = 4*pi*r^2/Q · from P: p_rms=P/sqrt2, I=p_rms^2/rhoc · W = I*S · Lw = 10*log10(W/1e-12)');
            app.goButton(gl,6,@(o,e) app.runRadiated());
            app.W.out = app.resultBox(gl,7);
        end
        function runRadiated(app)
            r=app.W.r.Value; Q=str2double(app.W.Q.Value(1)); v=app.W.val.Value;
            if ~(r>0), app.W.out.Value = {'Distance r must be > 0.'}; return; end
            if ~(v>0), app.W.out.Value = {'Input value must be > 0.'}; return; end
            if startsWith(app.W.src.Value,'Peak')
                R = acoustics.radiatedPower(r,'P',v,'Q',Q);
            else
                R = acoustics.radiatedPower(r,'I',v,'Q',Q);
            end
            app.W.out.Value = [{ sprintf('I = %.4g W/m^2 · W = %.4g W · Lw = %.2f dB', ...
                R.I, R.W, R.Lw), '', 'WORKING' }, R.steps];
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
            R = acoustics.combineLevels(L);
            app.W.out.Value = [{ sprintf('Combined level = %.2f dB · RMS pressure = %.4g Pa', ...
                R.total, R.pressure), '', 'WORKING' }, R.steps];
        end

        function buildNIdentical(app)
            gl = app.form(4);
            app.W.L1 = app.numField(gl,1,'Level of one source L1 (dB)',77);
            app.W.N  = app.numField(gl,2,'Number of identical sources N',2);
            app.goButton(gl,3,@(o,e) app.runNIdentical());
            app.W.out = app.resultBox(gl,4);
        end
        function runNIdentical(app)
            N = app.W.N.Value;
            if N < 1, app.W.out.Value = {'N must be >= 1.'}; return; end
            R = acoustics.nIdenticalSources(app.W.L1.Value, N);
            app.W.out.Value = [{ sprintf('Total of %g sources = %.2f dB', N, R.total), ...
                '', 'WORKING' }, R.steps];
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
            n1=app.W.n1.Value; add=app.W.add.Value;
            if ~(n1>0) || ~(n1+add>0), app.W.out.Value = {'Counts must be positive.'}; return; end
            R = acoustics.increaseFromSources(n1, app.W.L1.Value, add);
            app.W.out.Value = [{ sprintf('Increase dL = %.3f dB · New level = %.3f dB', ...
                R.delta, R.newLevel), '', 'WORKING' }, R.steps];
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
            R = acoustics.largerSignalError(r);
            app.W.out.Value = [{ sprintf('Total RMS = %.5g x p1', R.ptotFactor), ...
                sprintf('Error using only p1 = %.2f %% (under-estimate)', R.errorPct), ...
                '', 'WORKING' }, R.steps];
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
            N1=app.W.N1.Value;
            if ~(N1>=1), app.W.out.Value = {'N1 must be >= 1.'}; return; end
            R = acoustics.maxSourcesUnderLimit(N1, app.W.Lt.Value, app.W.Lm.Value);
            if R.N<1, app.W.out.Value = R.steps; return; end
            app.W.out.Value = [{ sprintf('Max sources within limit = %d', R.N), ...
                '', 'WORKING' }, R.steps];
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
            tot=app.W.tot.Value; bg=app.W.bg.Value;
            if 10^(tot/10)-10^(bg/10) <= 0
                app.W.out.Value = {'Total must exceed the level being removed.'}; return;
            end
            R = acoustics.subtractLevels(tot, bg);
            app.W.out.Value = [{ sprintf('Remaining level = %.2f dB', R.remaining), ...
                '', 'WORKING' }, R.steps];
        end

        function buildOneOfN(app)
            gl = app.form(4);
            app.W.tot = app.numField(gl,1,'Combined level Ltot (dB)',80);
            app.W.N   = app.numField(gl,2,'Number of sources N',2);
            app.goButton(gl,3,@(o,e) app.runOneOfN());
            app.W.out = app.resultBox(gl,4);
        end
        function runOneOfN(app)
            N=app.W.N.Value;
            if ~(N>=1), app.W.out.Value = {'N must be >= 1.'}; return; end
            R = acoustics.oneOfNSources(app.W.tot.Value, N);
            app.W.out.Value = [{ sprintf('Each source = %.2f dB', R.each), '', 'WORKING' }, R.steps];
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
            if (~isnan(c))+(~isnan(f))+(~isnan(lam)) < 2
                app.W.out.Value = {'Enter at least two of c, f, lambda.'}; return;
            end
            R = acoustics.waveRelation('c',c,'f',f,'lambda',lam);
            app.W.c.Value=sprintf('%.3f',R.c); app.W.f.Value=sprintf('%.3f',R.f);
            app.W.lam.Value=sprintf('%.4f',R.lambda);
            app.W.out.Value = [{ sprintf('c = %.2f m/s · f = %.2f Hz · lambda = %.4f m', ...
                R.c, R.f, R.lambda), '', 'WORKING' }, R.steps];
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
            R = acoustics.speedOfSoundTemp(app.W.T.Value, ...
                'gamma',app.W.g.Value, 'R',app.W.R.Value);
            app.W.out.Value = [{ sprintf('c = %.2f m/s  (T0 = %.1f K)', R.c, R.T0), ...
                '', 'WORKING' }, R.steps];
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
            R = acoustics.particleMotion(app.W.P.Value, app.W.f.Value, 'rhoc',app.W.rc.Value);
            app.W.out.Value = [{ sprintf('u = %.4g m/s · xi = %.4g m · I = %.4g W/m^2', ...
                R.u, R.xi, R.I), '', 'WORKING' }, R.steps];
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
            ty='octave'; if strcmp(app.W.ty.Value,'1/3 Octave'), ty='third'; end
            R = acoustics.octaveBandEdges(fc,'type',ty);
            app.W.out.Value = [{ sprintf('Lower = %.1f Hz · Upper = %.1f Hz · BW = %.1f Hz (%.1f %%)', ...
                R.lower, R.upper, R.bandwidth, R.percent), '', 'WORKING' }, R.steps];
        end
        function runPipe(app)
            L=app.W.pipeL.Value; c=app.W.pipeC.Value;
            if ~(L>0), app.W.out.Value = {'Length must be > 0.'}; return; end
            R = acoustics.pipeModes(L,'c',c,'n',4);
            app.W.out.Value = R.steps;
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
            pre = {};
            if ~isempty(strtrim(app.W.ex.Value))
                extra = app.pnum(app.W.ex);
                if isnan(extra), app.W.out.Value = {'Extra source level must be a number (or blank).'}; return; end
                cc = acoustics.combineLevels([L1 extra]);
                pre = { sprintf('Combine at r1: L1 = %.2f dB', cc.total) };
                L1 = cc.total;
            end
            R = acoustics.distanceAttenuation(L1, r1, r2);
            app.W.out.Value = [{ sprintf('Point (spherical, -6 dB/doubling): L2 = %.2f dB', R.point), ...
                sprintf('Line  (cylindrical, -3 dB/doubling): L2 = %.2f dB', R.line), '', 'WORKING' }, ...
                pre, R.steps];
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
            if ~(L1-L2>0), app.W.out.Value = {'Near level L1 must exceed far level L2.'}; return; end
            R = acoustics.solveDistance(L1, L2, dr);
            app.W.out.Value = [{ ...
                sprintf('Point source (-6 dB/doubling): near distance y = %.3f m', R.point), ...
                sprintf('Line  source (-3 dB/doubling): near distance y = %.3f m', R.line), ...
                '', 'WORKING' }, R.steps];
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
            switch app.W.ty.Value
                case 'Point, free field  Q=1', ty='point_free';
                case 'Point, on ground  Q=2', ty='point_ground';
                case 'Point, edge  Q=4',      ty='point_edge';
                case 'Point, corner  Q=8',    ty='point_corner';
                case 'Line, free field',      ty='line_free';
                otherwise,                    ty='line_ground';
            end
            if hasLw
                R = acoustics.lwLpDistance(r,'Lw',app.pnum(app.W.Lw),'type',ty);
                app.W.Lp.Value=sprintf('%.2f',R.Lp); head=sprintf('Lp = %.2f dB', R.Lp);
            else
                R = acoustics.lwLpDistance(r,'Lp',app.pnum(app.W.Lp),'type',ty);
                app.W.Lw.Value=sprintf('%.2f',R.Lw); head=sprintf('Lw = %.2f dB', R.Lw);
            end
            app.W.out.Value = [{ head, '', 'WORKING' }, R.steps];
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
            if isnan(V)+isnan(S)+isnan(a)+isnan(T) ~= 1
                app.W.out.Value = {'Fill exactly three values; leave one blank.'}; return;
            end
            R = acoustics.sabineT60('V',V,'S',S,'alpha',a,'T60',T);
            app.W.V.Value=sprintf('%.2f',R.V); app.W.S.Value=sprintf('%.2f',R.S);
            app.W.a.Value=sprintf('%.4f',R.alpha); app.W.T.Value=sprintf('%.3f',R.T60);
            app.W.out.Value = [{ sprintf('T60 = %.3f s · alpha = %.4f · A = alpha*S = %.2f m^2', ...
                R.T60, R.alpha, R.A), '', 'WORKING' }, R.steps];
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
            R = acoustics.averageAbsorption(rows(:,1)', rows(:,2)');
            app.W.out.Value = [{ sprintf('alpha-bar = %.4f', R.alphaBar), '', 'WORKING' }, R.steps];
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
            R = acoustics.roomConstant(a,S);
            app.W.out.Value = [{ sprintf('Room constant R = %.2f m^2', R.R), '', 'WORKING' }, R.steps];
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
            Lw=app.W.Lw.Value; r=app.W.r.Value; Rc=app.W.R.Value; Q=str2double(app.W.Q.Value(1));
            if ~(r>0)||~(Rc>0), app.W.out.Value = {'r and R must be > 0.'}; return; end
            R = acoustics.roomEquation(Lw,r,Rc,'Q',Q);
            app.W.out.Value = [{ sprintf('Lp = %.2f dB  (%s)', R.Lp, R.dominant), ...
                '', 'WORKING' }, R.steps];
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
                try
                    cr = acoustics.absorberChange(V, T, Sabs, al, ...
                        'mode', ternary(remove,"remove","add"));
                catch
                    app.W.out.Value = {sprintf('Band %g Hz: absorber exceeds room absorption (A2<=0).', d{i,1})}; return;
                end
                dL=cr.deltaLp;
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

        function buildPlant(app)
            gl = uigridlayout(app.Content,[5 2]);
            gl.RowHeight = {32,'1x',44,32,150}; gl.ColumnWidth = {200,'1x'};
            sub = uigridlayout(gl,[1 8]); sub.Layout.Row=1; sub.Layout.Column=[1 2];
            sub.Padding=[0 0 0 0]; sub.ColumnWidth={90,'1x','1x','1x',130,'1x'};
            uilabel(sub,'Text','Room L,W,H (m)');
            app.W.L=uieditfield(sub,'numeric','Value',11.6);
            app.W.Wd=uieditfield(sub,'numeric','Value',5.0);
            app.W.H=uieditfield(sub,'numeric','Value',5.0);
            uilabel(sub,'Text','Coated area Scoat (m^2)');
            app.W.Scoat=uieditfield(sub,'numeric','Value',58);
            f=[63 125 250 500 1000 2000 4000 8000]';
            app.W.tbl=uitable(gl,'ColumnName',{'Freq (Hz)','Lw combined (dB)','alpha base','alpha coat'}, ...
                'ColumnEditable',[false true true true], ...
                'Data',[num2cell(f), repmat({[]},numel(f),3)]);
            app.W.tbl.Layout.Row=2; app.W.tbl.Layout.Column=[1 2];
            app.note(gl,3,'Per band enter the combined machine Lw and the bare/coated alpha. S = 2(LW+LH+WH). R = S*alpha/(1-alpha), Lp = Lw + 10*log10(4/R). After: alpha_bar = [Scoat*alphaCoat + (S-Scoat)*alphaBase]/S.');
            b=uibutton(gl,'Text','Compute','ButtonPushedFcn',@(o,e) app.runPlant());
            b.Layout.Row=4; b.Layout.Column=[1 2];
            app.W.out=uitextarea(gl,'Editable','off','FontName','monospaced');
            app.W.out.Layout.Row=5; app.W.out.Layout.Column=[1 2];
        end
        function runPlant(app)
            L=app.W.L.Value; Wd=app.W.Wd.Value; H=app.W.H.Value; Scoat=app.W.Scoat.Value;
            if ~(L>0&&Wd>0&&H>0), app.W.out.Value={'Room dimensions must be > 0.'}; return; end
            S=2*(L*Wd+L*H+Wd*H);
            d=app.W.tbl.Data; f=[]; Lw=[]; ab=[]; ac=[];
            for i=1:size(d,1)
                lw=d{i,2}; a1=d{i,3}; a2=d{i,4};
                if isempty(lw)||(isnumeric(lw)&&isnan(lw)), continue; end
                if isempty(a1)||isempty(a2), app.W.out.Value={sprintf('Band %g Hz needs Lw, alpha base and alpha coat.',d{i,1})}; return; end
                f(end+1)=d{i,1}; Lw(end+1)=lw; ab(end+1)=a1; ac(end+1)=a2; %#ok<AGROW>
            end
            if isempty(f), app.W.out.Value={'Enter at least one band (Lw, alpha base, alpha coat).'}; return; end
            try
                R=acoustics.plantRoom(f, Lw', ab, ac, Scoat, S);
            catch me
                app.W.out.Value={me.message}; return;
            end
            app.W.out.Value=[{ sprintf('S = %.1f m^2 · overall Lw = %.2f dB', S, R.LwOverall), ...
                sprintf('Before = %.1f dB(A) · After = %.1f dB(A) · Reduction = %.1f dB(A)', ...
                    R.dBAbefore, R.dBAafter, R.reduction), '', 'WORKING' }, R.steps];
        end

        function buildRevRoom(app)
            gl = uigridlayout(app.Content,[5 2]);
            gl.RowHeight = {32,'1x',44,32,150}; gl.ColumnWidth = {200,'1x'};
            sub = uigridlayout(gl,[1 6]); sub.Layout.Row=1; sub.Layout.Column=[1 2];
            sub.Padding=[0 0 0 0]; sub.ColumnWidth={70,'1x',70,'1x',110,'1x'};
            uilabel(sub,'Text','V (m^3)'); app.W.V=uieditfield(sub,'numeric','Value',207);
            uilabel(sub,'Text','S (m^2)'); app.W.S=uieditfield(sub,'numeric','Value',220);
            uilabel(sub,'Text','rho c (rayls)'); app.W.rc=uieditfield(sub,'numeric','Value',415);
            f=[250 500 1000]';
            app.W.tbl=uitable(gl,'ColumnName',{'Freq (Hz)','Lw (dB)','T60 empty (s)','T60 furnished (s)'}, ...
                'ColumnEditable',[false true true true], ...
                'Data',[num2cell(f), repmat({[]},numel(f),3)]);
            app.W.tbl.Layout.Row=2; app.W.tbl.Layout.Column=[1 2];
            app.note(gl,3,'A=0.161V/T60, alpha=A/S, R=A/(1-alpha), W=1e-12*10^(Lw/10), <p^2>=4*rho c*W/R (exact rho c), Lp=10*log10(<p^2>/p_ref^2).');
            b=uibutton(gl,'Text','Compute','ButtonPushedFcn',@(o,e) app.runRevRoom());
            b.Layout.Row=4; b.Layout.Column=[1 2];
            app.W.out=uitextarea(gl,'Editable','off','FontName','monospaced');
            app.W.out.Layout.Row=5; app.W.out.Layout.Column=[1 2];
        end
        function runRevRoom(app)
            V=app.W.V.Value; S=app.W.S.Value; rc=app.W.rc.Value;
            if ~(V>0&&S>0&&rc>0), app.W.out.Value={'V, S and rho c must be > 0.'}; return; end
            d=app.W.tbl.Data; f=[]; Lw=[]; te=[]; tf=[];
            for i=1:size(d,1)
                lw=d{i,2}; e=d{i,3}; fu=d{i,4};
                if isempty(lw)||(isnumeric(lw)&&isnan(lw)), continue; end
                if isempty(e)||isempty(fu), app.W.out.Value={sprintf('Band %g Hz needs Lw and both T60 values.',d{i,1})}; return; end
                f(end+1)=d{i,1}; Lw(end+1)=lw; te(end+1)=e; tf(end+1)=fu; %#ok<AGROW>
            end
            if isempty(f), app.W.out.Value={'Enter at least one band (Lw, T60 empty, T60 furnished).'}; return; end
            try
                R=acoustics.reverbTestRoom(f, Lw, te, tf, V, S, 'rhoc', rc);
            catch me
                app.W.out.Value={me.message}; return;
            end
            app.W.out.Value=[{ sprintf('Empty = %.1f dB(A) · Furnished = %.1f dB(A) · Reduction = %.1f dB(A)', ...
                R.dBAempty, R.dBAfurn, R.reduction), '', 'WORKING' }, R.steps];
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
            if dL<6
                app.W.out.Value = {sprintf('dL = %.1f dB < 6 dB - measurement invalid (background too high).', dL)}; return;
            end
            R = acoustics.backgroundK1(st,b);
            app.W.out.Value = [{ sprintf('dL = %.1f dB · K1 = %.3f dB', R.dL, R.K1), ...
                '', 'WORKING' }, R.steps];
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
            R = acoustics.environmentalK2(S,A);
            app.W.out.Value = [{ sprintf('K2 = %.3f dB', R.K2), '', 'WORKING' }, R.steps];
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
            S=app.W.S.Value;
            if ~(S>0), app.W.out.Value = {'Surface area must be > 0.'}; return; end
            R = acoustics.soundPowerMeasured(app.W.lp.Value, S, ...
                'K1',app.W.k1.Value, 'K2',app.W.k2.Value);
            app.W.out.Value = [{ sprintf('Lw = %.2f dB', R.Lw), '', 'WORKING' }, R.steps];
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
            d=app.W.tbl.Data; f=[]; L=[];
            for i=1:size(d,1)
                v=d{i,2};
                if ~isempty(v)&&~isnan(v), f(end+1)=d{i,1}; L(end+1)=v; end %#ok<AGROW>
            end
            if isempty(L), app.W.out.Value = {'Enter at least one band level.'}; return; end
            switch app.W.surf.Value
                case 'Custom area'
                    S=str2double(app.W.Scust.Value);
                    if ~(S>0), app.W.out.Value = {'Enter a custom area S > 0.'}; return; end
                otherwise
                    r=str2double(app.W.r.Value); dd=str2double(app.W.d.Value);
                    if ~(r>0)&&dd>0, r=dd/2; end
                    if ~(r>0), app.W.out.Value = {'Enter a radius or diameter > 0 (or custom area).'}; return; end
                    if startsWith(app.W.surf.Value,'Sphere'), S=4*pi*r*r; else, S=2*pi*r*r; end
            end
            R = acoustics.lwFromBands(f, L, S, 'net', net);
            app.W.out.Value = [{ sprintf('Lw = %.1f dB re 1e-12 W', R.Lw), '', 'WORKING' }, R.steps];
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
            Lw=app.W.Lw.Value; d=app.W.d.Value; Sdb=app.W.sens.Value; rho=app.W.rho.Value; c=app.W.c.Value;
            fmax=app.pnum(app.W.fmax); if isnan(fmax), fmax=0; end
            if ~(d>0), app.W.out.Value = {'Pipe diameter must be > 0.'}; return; end
            if ~(rho>0&&c>0), app.W.out.Value = {'Density and sound speed must be > 0.'}; return; end
            R = acoustics.ductToVoltage(Lw, d, Sdb, 'rho',rho, 'c',c, 'fmax',fmax);
            app.W.out.Value = [{ sprintf('RMS voltage = %.4g V  (%.4g mV)', R.V, R.V*1000), ...
                '', 'WORKING' }, R.steps];
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
            R = acoustics.weightedOverall(f, L, net);
            tag='dB'; if net~='Z', tag=sprintf('dB(%c)',net); end
            app.W.out.Value = [{ sprintf('Overall %s = %.1f', tag, R.weighted), ...
                sprintf('Linear (unweighted) total = %.1f dB', R.linear), '', 'WORKING' }, R.steps];
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
            T = app.parseTime(app.W.T.Value, def);
            R = acoustics.leqFromLevels(L, t, 'T', T);
            app.W.out.Value = [{ ...
                sprintf('Leq = %.3f dB   (sum t = %s, T = %s)', R.Leq, ...
                    app.fmtSeconds(R.sumT), app.fmtSeconds(R.T)), ...
                sprintf('SEL (L_AE, over 1 s) = %.2f dB', R.SEL), '', 'WORKING' }, R.steps];
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
            d=app.W.tbl.Data; L=[]; tt=[]; n=[];
            for i=1:size(d,1)
                a=d{i,1}; tsec=app.parseTime(d{i,2},def); cnt=d{i,3};
                if isempty(a)||(isnumeric(a)&&isnan(a))||isnan(tsec)||isempty(cnt)||(isnumeric(cnt)&&isnan(cnt)), continue; end
                L(end+1)=a; tt(end+1)=tsec; n(end+1)=cnt; %#ok<AGROW>
            end
            if isempty(L), app.W.out.Value = {'Each row needs: level, event duration, number of events.'}; return; end
            R = acoustics.leqFromEvents(L, tt, n, T);
            app.W.out.Value = [{ sprintf('Leq,T = %.3f dB   (T = %s)', R.Leq, app.fmtSeconds(T)), ...
                '', 'WORKING' }, R.steps];
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
                LN = acoustics.percentileLevel(arr, N).LN;
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
            Lc=app.W.Lc.Value; q=app.W.q.Value; Tc=app.W.Tc.Value;
            R = acoustics.noiseDose(L, tsec, 'Lc',Lc, 'q',q, 'Tc',Tc);
            app.W.out.Value = [{ ...
                sprintf('L_Aeq,T = %.3f dB(A)   ·   L_Aeq,%gh = %.3f dB(A)', R.LAeqT, Tc, R.LAeqTc), ...
                sprintf('Noise dose = %.1f %%  (100%% = limit)', R.dosePct), ...
                sprintf('Exceeds %g dB(A)? %s   ·   Max permissible time = %.3f h (%s)', ...
                    Lc, ternary(R.exceeds,'YES','No'), R.Tmax, fmtHM(R.Tmax)), ...
                '', 'WORKING' }, R.steps];
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
            R = acoustics.maxPermissibleTime(L,'Lc',Lc,'q',q,'Tc',Tc);
            app.W.out.Value = [{ sprintf('T = %.3f h  (%s) - level %s the %g dB(A) criterion.', ...
                R.T, fmtHM(R.T), ternary(R.exceeds,'exceeds','is within'), Lc), ...
                '', 'WORKING' }, R.steps];
        end

        % ================= LOUDNESS =================
        function buildPh2S(app)
            gl = app.form(4);
            app.W.p = app.numField(gl,1,'Loudness level LL (phons)',80);
            app.goButton(gl,2,@(o,e) app.runPh2S());
            app.W.out = app.resultBox(gl,4);
        end
        function runPh2S(app)
            R = acoustics.phonToSone(app.W.p.Value);
            app.W.out.Value = [{ sprintf('Loudness = %.3f sones', R.sones), ...
                '', 'WORKING' }, R.steps];
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
            R = acoustics.soneToPhon(s);
            app.W.out.Value = [{ sprintf('Loudness level = %.2f phons', R.phons), ...
                '', 'WORKING' }, R.steps];
        end

        % ================= SPEECH (SIL / voice level) =================
        function buildPSIL(app)
            gl = app.form(7);
            app.W.a = app.numField(gl,1,'L at 500 Hz (dB)',105);
            app.W.b = app.numField(gl,2,'L at 1000 Hz (dB)',104);
            app.W.c = app.numField(gl,3,'L at 2000 Hz (dB)',103);
            app.W.d = app.txtField(gl,4,'L at 4000 Hz (dB, optional)','102.68');
            app.W.dist = app.numField(gl,5,'Talker-listener distance r (m)',1);
            app.goButton(gl,6,@(o,e) app.runPSIL());
            app.W.out = app.resultBox(gl,7);
        end
        function runPSIL(app)
            bands = [app.W.a.Value app.W.b.Value app.W.c.Value];
            d4 = app.pnum(app.W.d); if ~isnan(d4), bands(end+1)=d4; end
            r = app.W.dist.Value;
            if ~(r>0), app.W.out.Value = {'Distance r must be > 0.'}; return; end
            sil = acoustics.speechInterferenceLevel(bands);
            vl  = acoustics.voiceLevelA(sil.SIL, r);
            headline = sprintf('SIL = %.2f dB · VL_A = %.2f dB(A) · %s', ...
                sil.SIL, vl.VLA, ternary(vl.possible,'communication possible', ...
                'communication NOT possible'));
            app.W.out.Value = [{headline, '', 'WORKING'}, sil.steps, {''}, vl.steps];
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
            R = acoustics.dayNightLevel(app.W.day.Value, app.W.night.Value);
            app.W.out.Value = [{ sprintf('Ldn = %.2f dB(A)', R.Ldn), '', 'WORKING' }, R.steps];
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
            T=app.W.T.Value;
            if ~(T>0), app.W.out.Value = {'T must be > 0.'}; return; end
            R = acoustics.selFromLeq('Leq',app.W.leq.Value,'T',T);
            app.W.out.Value = [{ sprintf('SEL = %.2f dB', R.SEL), '', 'WORKING' }, R.steps];
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
            f=app.W.f.Value; M=app.pnum(app.W.M);
            try
                if ~isnan(M)
                    R = acoustics.massLawTL(f,'M',M);
                else
                    R = acoustics.massLawTL(f,'density',app.pnum(app.W.rho), ...
                        'thickness_mm',app.pnum(app.W.t));
                end
            catch
                app.W.out.Value = {'Enter surface mass, or density and thickness.'}; return;
            end
            app.W.out.Value = [{ sprintf('Surface mass M = %.3f kg/m^2 · TL = %.1f dB at %g Hz', ...
                R.M, R.TL, f), '', 'WORKING' }, R.steps];
        end

        function buildInterface(app)
            gl = app.form(4);
            app.W.z1 = app.numField(gl,1,'Medium 1 rho c (rayls)',415);
            app.W.z2 = app.numField(gl,2,'Medium 2 rho c (rayls)',1480000);
            app.goButton(gl,3,@(o,e) app.runInterface());
            app.W.out = app.resultBox(gl,4);
        end
        function runInterface(app)
            R = acoustics.interfaceImpedance(app.W.z1.Value, app.W.z2.Value);
            app.W.out.Value = [{ ...
                sprintf('r = z2/z1 = %.4g · alpha_t = %.4g · alpha_r = %.4f · TL = %.2f dB', ...
                    R.ratio, R.alphaT, R.alphaR, R.TL), '', 'WORKING' }, R.steps];
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
            R = acoustics.tlFromCoefficient(a);
            app.W.out.Value = [{ sprintf('TL = %.2f dB', R.TL), '', 'WORKING' }, R.steps];
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
            R = acoustics.panelResonance(K,M);
            app.W.out.Value = [{ sprintf('fn = %.2f Hz', R.fn), '', 'WORKING' }, R.steps];
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
            R = acoustics.mufflerAreaChange(s1,s2);
            app.W.out.Value = [{ sprintf('Tt = %.4g · TL = %.2f dB', R.Tt, R.TL), ...
                '', 'WORKING' }, R.steps];
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
            R = acoustics.expansionChamberTL(s1,s2,L,f,'c',c);
            app.W.out.Value = [{ sprintf('kL = %.3f rad · TL = %.2f dB', R.kL, R.TL), ...
                '', 'WORKING' }, R.steps];
        end

        function buildLevelDiff(app)
            gl = app.form(4);
            app.W.a = app.numField(gl,1,'Upstream / without-treatment (dB)',100);
            app.W.b = app.numField(gl,2,'Downstream / with-treatment (dB)',78);
            app.goButton(gl,3,@(o,e) app.runLevelDiff());
            app.W.out = app.resultBox(gl,4);
        end
        function runLevelDiff(app)
            R = acoustics.levelDifference(app.W.a.Value, app.W.b.Value);
            app.W.out.Value = [{ sprintf('Difference = %.2f dB', R.difference) }, R.steps];
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
