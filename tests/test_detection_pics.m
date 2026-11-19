function tests = test_detection_pics
%TEST_DETECTION_PICS  Tests isolés de l'étape 3 (carte de constellation).
%   Lancer seul : runtests('tests/test_detection_pics.m')
tests = functiontests(localfunctions);
end

function setupOnce(tc)
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'src'), fullfile(racine, 'utils'));
tc.TestData.P = parametres();
tc.TestData.x = morceau_synthetique(20, tc.TestData.P.Fe, 7);
end

function test_sinusoide(tc)
% Une sinusoïde à 1 kHz donne des pics dans le canal de 1 kHz.
P = tc.TestData.P;
t = (0:5*P.Fe - 1)' / P.Fe;
pics = detection_pics(calcul_spectrogramme(sin(2*pi*1000*t), P), P);
kAttendu = round(1000 * P.Nfft / P.Fe) + 1;
verifyNotEmpty(tc, pics);
verifyTrue(tc, all(abs(pics(:, 2) - kAttendu) <= 1));
end

function test_invariance_gain(tc)
% Les positions des pics ne dépendent pas du volume.
P = tc.TestData.P;
x = tc.TestData.x;
ref = detection_pics(calcul_spectrogramme(x, P), P);
for a = [0.01 0.5 10]
    verifyEqual(tc, detection_pics(calcul_spectrogramme(a * x, P), P), ref);
end
end

function test_maxima_locaux(tc)
% Chaque pic est le maximum de son voisinage ±dm trames x ±dk canaux.
P = tc.TestData.P;
SdB = calcul_spectrogramme(tc.TestData.x, P);
pics = detection_pics(SdB, P);
[K, M] = size(SdB);
for i = 1:size(pics, 1)
    m = pics(i, 1);  k = pics(i, 2);
    V = SdB(max(1, k - P.dk):min(K, k + P.dk), max(1, m - P.dm):min(M, m + P.dm));
    verifyEqual(tc, SdB(k, m), max(V(:)));
end
end

function test_densite_et_bandes(tc)
% Densité bornée par le quota, et pics seulement entre f_min et f_max.
P = tc.TestData.P;
x = tc.TestData.x;
pics = detection_pics(calcul_spectrogramme(x, P), P);
rho = size(pics, 1) / (numel(x) / P.Fe);
verifyLessThanOrEqual(tc, rho, P.rho * 1.1);
verifyGreaterThan(tc, rho, P.rho / 3);
f = (pics(:, 2) - 1) * P.Fe / P.Nfft;
verifyTrue(tc, all(f >= P.f_min & f < P.f_max));
end

function test_silence(tc)
% Le silence (plateau de valeurs égales) ne donne aucun pic.
P = tc.TestData.P;
verifyEmpty(tc, detection_pics(calcul_spectrogramme(zeros(3*P.Fe, 1), P), P));
end
