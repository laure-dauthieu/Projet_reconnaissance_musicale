function tests = test_calcul_spectrogramme
%TEST_CALCUL_SPECTROGRAMME  Tests isolés de l'étape 2 (TFCT en dB).
%   Lancer seul : runtests('tests/test_calcul_spectrogramme.m')
tests = functiontests(localfunctions);
end

function setupOnce(tc)
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'src'), fullfile(racine, 'utils'));
tc.TestData.P = parametres();
tc.TestData.x = morceau_synthetique(10, tc.TestData.P.Fe, 7);
end

function test_dimensions(tc)
% K canaux et une trame toutes les H échantillons.
P = tc.TestData.P;
x = tc.TestData.x;
[SdB, f, t] = calcul_spectrogramme(x, P);
verifyEqual(tc, size(SdB, 1), P.K);
verifyEqual(tc, size(SdB, 2), floor((numel(x) - P.N) / P.H) + 1);
verifyEqual(tc, f(2) - f(1), P.Fe / P.Nfft, 'AbsTol', 1e-9);
verifyEqual(tc, t(2) - t(1), P.H / P.Fe, 'AbsTol', 1e-9);
end

function test_sinusoide(tc)
% Une sinusoïde à 1 kHz a son maximum dans le canal de 1 kHz, à chaque trame.
P = tc.TestData.P;
t = (0:2*P.Fe - 1)' / P.Fe;
SdB = calcul_spectrogramme(sin(2*pi*1000*t), P);
[~, k] = max(SdB, [], 1);
verifyEqual(tc, unique(k), round(1000 * P.Nfft / P.Fe) + 1);
end

function test_translation(tc)
% Propriété (1) : un décalage de m0*H échantillons translate le spectrogramme de m0 trames.
P = tc.TestData.P;
x = tc.TestData.x;
m0 = 7;
Sx = calcul_spectrogramme(x, P);
Sy = calcul_spectrogramme(x(m0*P.H + 1:end), P);
n = size(Sy, 2);
verifyEqual(tc, Sy, Sx(:, m0 + (1:n)), 'AbsTol', 1e-9);
end

function test_gain(tc)
% Un gain alpha ajoute 20 log10(alpha) dB partout (hors plancher eps).
P = tc.TestData.P;
x = tc.TestData.x;
S1 = calcul_spectrogramme(x, P);
S2 = calcul_spectrogramme(3 * x, P);
fort = S1 > max(S1(:)) - 60;
verifyEqual(tc, S2(fort) - S1(fort), repmat(20*log10(3), nnz(fort), 1), 'AbsTol', 1e-6);
end

function test_parametres_par_defaut(tc)
% Sans P, les paramètres de départ sont utilisés.
verifyEqual(tc, calcul_spectrogramme(tc.TestData.x), calcul_spectrogramme(tc.TestData.x, tc.TestData.P));
end
