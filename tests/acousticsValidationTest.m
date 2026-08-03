function tests = acousticsValidationTest()
%ACOUSTICSVALIDATIONTEST  Validate the +acoustics library against the
%   MECH9325 worked answers.
%
%   Run from the repository root with:
%       runtests('tests')
%   or
%       results = run(acousticsValidationTest);
%
%   Each test asserts one of the course's known worked results so the
%   toolkit can be trusted before use.
    tests = functiontests(localfunctions);
end

% ---- reference levels / powers / intensity ------------------------------

function testOnePascalIs94dB(t)
    % 1 Pa RMS -> 94 dB SPL (re 2e-5 Pa)
    R = acoustics.splPressure('p', 1);
    verifyEqual(t, R.Lp, 93.9794, 'AbsTol', 0.01);
    verifyEqual(t, round(R.Lp), 94);
end

function testHalfWattIs117dB(t)
    % 0.5 W -> 117 dB Lw (re 1e-12 W)
    R = acoustics.powerLevel('W', 0.5);
    verifyEqual(t, R.Lw, 116.9897, 'AbsTol', 0.01);
    verifyEqual(t, round(R.Lw), 117);
end

function testPowerLevelRoundTrip(t)
    R = acoustics.powerLevel('Lw', 117);
    R2 = acoustics.powerLevel('W', R.W);
    verifyEqual(t, R2.Lw, 117, 'AbsTol', 1e-9);
end

% ---- waves --------------------------------------------------------------

function testSpeedOfSoundAt20C(t)
    % c(20 C) = 343 m/s
    R = acoustics.speedOfSoundTemp(20);
    verifyEqual(t, R.c, 343.23, 'AbsTol', 0.05);
    verifyEqual(t, round(R.c), 343);
end

function testWaveSolvesLambda(t)
    R = acoustics.waveRelation('c', 343, 'f', 1000);
    verifyEqual(t, R.lambda, 0.343, 'AbsTol', 1e-6);
end

% ---- weighting: overall dB(A) = 77.5 ------------------------------------

function testAWeightedTotalIs77p5(t)
    % Octave-band spectrum whose A-weighted overall level is 77.5 dB(A).
    f = [63 125 250 500 1000 2000 4000 8000];
    L = [70  72  74  76  70.4 71   66   60];
    R = acoustics.weightedOverall(f, L, 'A');
    verifyEqual(t, R.weighted, 77.5, 'AbsTol', 0.05);
end

% ---- Leq: LAeq,24h = 70.55 ---------------------------------------------

function testLAeq24hIs70p55(t)
    % 74 dB(A) for 8 h, 69 for 8 h, 60 for 8 h, averaged over 24 h.
    levels    = [74 69 60];
    durations = [8 8 8] * 3600;          % seconds
    R = acoustics.leqFromLevels(levels, durations, 'T', 24*3600);
    verifyEqual(t, R.Leq, 70.55, 'AbsTol', 0.01);
end

function testLeqSELConsistency(t)
    % SEL = Leq + 10 log10(T)
    R = acoustics.leqFromLevels([90 90], [30 30], 'T', 60);
    verifyEqual(t, R.SEL, R.Leq + 10*log10(60), 'AbsTol', 1e-9);
end

% ---- loudness: 16 sones -------------------------------------------------

function testEightyPhonIs16Sones(t)
    R = acoustics.phonToSone(80);
    verifyEqual(t, R.sones, 16, 'AbsTol', 1e-9);
end

function testSonePhonRoundTrip(t)
    verifyEqual(t, acoustics.soneToPhon(16).phons, 80, 'AbsTol', 1e-9);
end

% ---- insulation: plywood mass-law TL = 21 dB @ 1 kHz --------------------

function testBarrierInsertionTunnel(t)
    % Tunnel spectrum + 25 mm foam disc (rho 320). Overall dB(A) before/after.
    R = acoustics.barrierInsertion([250 500 1000 2000], [104 109 106 110], ...
        'density', 320, 'thickness_mm', 25);
    verifyEqual(t, R.before, 113.3, 'AbsTol', 0.1);
    verifyEqual(t, R.after,  78.8, 'AbsTol', 0.1);
end

function testPanelTLskylight(t)
    % Resonant single panel (glass skylight). Formula-consistency check
    % (no official answer key): fn and TL from mass+stiffness model.
    R = acoustics.panelTL([100 1000], 945, 0.8e-3, 0.208, 0.095, 0.017, 2500);
    verifyEqual(t, R.fn, 188.76, 'AbsTol', 0.1);
    verifyEqual(t, R.surfaceMass, 42.5, 'AbsTol', 1e-9);   % rho*thickness
    verifyEqual(t, R.TL(1), 38.33, 'AbsTol', 0.1);         % 100 Hz (below fn)
    verifyEqual(t, R.TL(2), 49.84, 'AbsTol', 0.1);         % 1000 Hz (above fn)
end

function testPlywoodMassLawTLis21(t)
    % Plywood 3 mm at 500 kg/m^3 -> M = 1.5 kg/m^2, TL = 20log10(Mf)-42.4
    R = acoustics.massLawTL(1000, 'density', 500, 'thickness_mm', 3);
    verifyEqual(t, R.M, 1.5, 'AbsTol', 1e-9);
    verifyEqual(t, round(R.TL), 21);
    verifyEqual(t, R.TL, 21.12, 'AbsTol', 0.05);
end

% ---- speech: ship engine-room example -----------------------------------

function testShipEngineRoomSIL(t)
    % SIL = 103.67 dB from the four octave-band levels
    R = acoustics.speechInterferenceLevel([105 104 103 102.68]);
    verifyEqual(t, R.SIL, 103.67, 'AbsTol', 0.01);
end

function testShipEngineRoomVoiceLevel(t)
    % VL_A = (4/3)(SIL + 20log10 r) - 36 at r = 1 m -> 102.2 dB(A)
    R = acoustics.voiceLevelA(103.67, 1);
    verifyEqual(t, R.VLA, 102.2, 'AbsTol', 0.05);
end

function testShipEngineRoomCommunicationNotPossible(t)
    % VL_A > 88 dB(A) peak-shouting limit -> communication not possible
    R = acoustics.voiceLevelA(103.67, 1);
    verifyFalse(t, R.possible);
    verifyEqual(t, R.effort, 'Beyond peak shouting');
end

function testVoiceLevelPossibleCase(t)
    % A quiet interference level should be reachable with a normal voice.
    R = acoustics.voiceLevelA(52.5, 1);   % VL_A = (4/3)*52.5 - 36 = 34
    verifyTrue(t, R.possible);
    verifyEqual(t, R.effort, 'Normal');
end

% ---- a few structural checks on the wider library -----------------------

function testCombineThreeLevels(t)
    % 80 + 80 = 83.01; adding 74 -> 83.43
    verifyEqual(t, acoustics.combineLevels([80 80]).total, 83.0103, 'AbsTol', 0.01);
    verifyEqual(t, acoustics.combineLevels([80 80 74]).total, 83.5241, 'AbsTol', 0.01);
end

function testSabineSolvesEachTerm(t)
    base = acoustics.sabineT60('V', 200, 'S', 240, 'alpha', 0.15);
    % Feed T60 back and solve for alpha -> recover 0.15
    R = acoustics.sabineT60('V', 200, 'S', 240, 'T60', base.T60);
    verifyEqual(t, R.alpha, 0.15, 'AbsTol', 1e-9);
end

function testSubtractBackground(t)
    % 80 dB total minus 77 dB background -> 76.98 dB remaining
    R = acoustics.subtractLevels(80, 77);
    verifyEqual(t, R.remaining, 76.9794, 'AbsTol', 0.01);
end

function testDistancePointAndLine(t)
    % Doubling distance: point -6 dB, line -3 dB
    R = acoustics.distanceAttenuation(100, 1, 2);
    verifyEqual(t, R.point, 100 - 20*log10(2), 'AbsTol', 1e-9);
    verifyEqual(t, R.line,  100 - 10*log10(2), 'AbsTol', 1e-9);
end

function testRadiatedPowerFromIntensity(t)
    % I over a full sphere at r with Q=1
    R = acoustics.radiatedPower(2, 'I', 1e-6, 'Q', 1);
    verifyEqual(t, R.W, 1e-6*4*pi*4, 'RelTol', 1e-9);
end

function testRadiatedPowerFromPressure(t)
    % Web-app case: P = 25 Pa, r = 2 m, Q = 1 -> I = 0.753, W = 37.85 W
    R = acoustics.radiatedPower(2, 'P', 25, 'Q', 1);
    verifyEqual(t, R.I, 0.753, 'AbsTol', 0.001);
    verifyEqual(t, R.W, 37.85, 'AbsTol', 0.02);
end

function testHearingProtectorSLC80(t)
    % AS/NZS 1269 SLC80: protected LAeq = LCeq - SLC80.
    R = acoustics.hearingProtector(99.721, 27);
    verifyEqual(t, R.protectedLAeq, 72.721, 'AbsTol', 0.01);
end

function testPowerIntoMediumLake(t)
    % 80 mm pipe into a lake, 153 dB at surface, anechoic in water.
    R = acoustics.powerIntoMedium(153, 0.080, 'rho', 1000, 'c', 1480);
    verifyEqual(t, R.prms, 893.37, 'AbsTol', 0.5);
    verifyEqual(t, R.W, 2.711e-3, 'AbsTol', 1e-5);
end

function testDuctBandPowerSpeaker(t)
    % 86 mm pipe, long (plane waves). Octave-band Lp -> prms, I, W, totals.
    R = acoustics.ductBandPower([125 250 500 1000], [106 105 105 94], 0.086, ...
        'rho', 1.21, 'c', 343);
    verifyEqual(t, R.prms, [3.991 3.557 3.557 1.002], 'AbsTol', 0.002);
    verifyEqual(t, R.I,    [0.03837 0.03048 0.03048 0.002421], 'AbsTol', 0.0002);
    verifyEqual(t, R.W,    [2.229e-4 1.770e-4 1.770e-4 1.406e-5], 'AbsTol', 2e-7);
    verifyEqual(t, R.LpTotal, 110.24, 'AbsTol', 0.02);
    verifyEqual(t, R.LwTotal, 87.72, 'AbsTol', 0.02);
end

% ---- room calculators: formula-level checks -----------------------------
% (The exact web-app "plant room" and "reverberation test room" example
% datasets live in data.js; those regression tests are added once the input
% data is supplied. These hand-computable cases verify the implementations.)

function testPlantRoomSingleBand(t)
    % 1 band, 2 machines at 90 dB -> combined 93.01 dB; coat 50 of 200 m^2.
    R = acoustics.plantRoom(500, [90 90], 0.02, 0.8, 50, 200);
    verifyEqual(t, R.Lw(1), 93.0103, 'AbsTol', 0.01);      % combined power level
    verifyEqual(t, R.LpBefore(1), 92.9226, 'AbsTol', 0.01);
    verifyEqual(t, R.LpAfter(1), 81.6449, 'AbsTol', 0.01);
    verifyEqual(t, R.reduction, 11.2776, 'AbsTol', 0.01);  % single band -> weighting cancels
end

function testReverbTestRoomSingleBand(t)
    % Exact rho c: <p^2> = 4*rho c*W/R.  Lw = 100 dB, V = S = 200, T60 2 -> 1 s.
    R = acoustics.reverbTestRoom(1000, 100, 2, 1, 200, 200, 'rhoc', 415);
    verifyEqual(t, R.Aempty(1), 16.1, 'AbsTol', 0.001);
    verifyEqual(t, R.p2empty(1), 0.9481, 'AbsTol', 0.001);
    verifyEqual(t, R.LpEmpty(1), 93.7477, 'AbsTol', 0.01);
    verifyEqual(t, R.reduction, 3.4082, 'AbsTol', 0.01);
end

function testReverbTestRoomFurnitureExample(t)
    % Web-app worked example: V = 207 m^3, S = 220 m^2, rho c = 415.
    % Octave bands 250/500/1000 Hz; reference source Lw and empty/furnished T60.
    f    = [250   500   1000];
    Lw   = [81.4  82.0  88.2];
    Te   = [8.2   7.5   6.4];    % empty T60 (s)
    Tf   = [6.5   5.9   4.8];    % furnished T60 (s)
    R = acoustics.reverbTestRoom(f, Lw, Te, Tf, 207, 220, 'rhoc', 415);
    % (a) empty absorption area
    verifyEqual(t, R.Aempty, [4.064 4.444 5.207], 'AbsTol', 0.01);
    % (b) furnished absorption area
    verifyEqual(t, R.Afurn,  [5.127 5.649 6.943], 'AbsTol', 0.01);
    % (f) empty mean-square pressures (Pa^2)
    verifyEqual(t, R.p2empty, [0.0553 0.0580 0.2056], 'AbsTol', 0.001);
    % (g) furnished mean-square pressures (Pa^2)
    verifyEqual(t, R.p2furn,  [0.0436 0.0454 0.1530], 'AbsTol', 0.001);
    % (j),(k),(l) overall A-weighted levels and reduction
    verifyEqual(t, R.dBAempty, 87.8, 'AbsTol', 0.1);
    verifyEqual(t, R.dBAfurn,  86.5, 'AbsTol', 0.1);
    verifyEqual(t, R.reduction, 1.3, 'AbsTol', 0.1);
end
