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

function testSpeedToTemperatureInverse(t)
    % c = 400 m/s -> ~125 C (inverse of the T->c relation)
    R = acoustics.speedOfSoundTemp([], 'c', 400);
    verifyEqual(t, R.Tc, 125.0, 'AbsTol', 0.5);
end

function testTemperatureFromTimeOfFlight(t)
    % 8 m in 20 ms -> c = 400 m/s, T ~ 125 C
    R = acoustics.speedOfSoundTemp([], 'd', 8, 't', 0.020);
    verifyEqual(t, R.c, 400, 'AbsTol', 1e-6);
    verifyEqual(t, R.Tc, 125.0, 'AbsTol', 0.5);
end

function testParticleThresholdDisplacement(t)
    % Just-audible 4 kHz tone (p_rms = 20 uPa) -> xi ~ 2.71 pm
    R = acoustics.particleMotion(sqrt(2)*2e-5, 4000);
    verifyEqual(t, R.xi, 2.71e-12, 'AbsTol', 0.05e-12);
    verifyEqual(t, R.spl, 0, 'AbsTol', 1e-9);   % threshold is 0 dB
end

function testParticle120HzPeak(t)
    % 120 Hz plane wave, 1.5 Pa peak, air
    R = acoustics.particleMotion(1.5, 120);
    verifyEqual(t, R.I,    2.711e-3, 'AbsTol', 1e-6);
    verifyEqual(t, R.u,    3.614e-3, 'AbsTol', 1e-6);
    verifyEqual(t, R.xi,   4.794e-6, 'AbsTol', 1e-9);
    verifyEqual(t, R.prms, 1.0607,   'AbsTol', 1e-4);
    verifyEqual(t, R.spl,  94.49,    'AbsTol', 0.01);
end

function testParticleFromRmsVelocitySPL(t)
    % u_rms = 0.11 m/s -> SPL in air and water
    Rair = acoustics.particleMotion([], 100, 'urms', 0.11, 'rhoc', 415, 'pref', 2e-5);
    verifyEqual(t, Rair.spl, 127.2, 'AbsTol', 0.1);
    Rwater = acoustics.particleMotion([], 100, 'urms', 0.11, 'rhoc', 1.5e6, 'pref', 1e-6);
    verifyEqual(t, Rwater.spl, 224.3, 'AbsTol', 0.1);
end

function testPipeModesUnchangedDefault(t)
    % Default open-closed pipe still gives (2n-1)c/4L
    R = acoustics.pipeModes(0.5);
    verifyEqual(t, R.f(1), 343/(4*0.5), 'AbsTol', 1e-6);
end

function testPipeOpenOpenModes(t)
    % 5 m open-open pipe -> f_n = n c / 2L, omega = 2 pi f
    R = acoustics.pipeModes(5, 'ends', "open-open", 'n', 3);
    verifyEqual(t, R.f,     [34.3 68.6 102.9],       'AbsTol', 0.05);
    verifyEqual(t, R.omega, 2*pi*[34.3 68.6 102.9],  'AbsTol', 0.5);
end

function testDuctBandPower(t)
    % 86 mm pipe, four octave bands -> total SPL 110.24 dB, total Lw 87.72 dB
    R = acoustics.ductBandPower([106 105 105 94], 86);
    verifyEqual(t, R.area, pi*0.086^2/4, 'AbsTol', 1e-9);
    verifyEqual(t, R.prms(1), 3.9905,   'AbsTol', 1e-3);
    verifyEqual(t, R.I(1),    3.837e-2, 'AbsTol', 1e-5);
    verifyEqual(t, R.W(1),    2.229e-4, 'AbsTol', 1e-7);
    verifyEqual(t, R.LpTotal, 110.24,   'AbsTol', 0.05);
    verifyEqual(t, R.LwTotal, 87.72,    'AbsTol', 0.05);
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
