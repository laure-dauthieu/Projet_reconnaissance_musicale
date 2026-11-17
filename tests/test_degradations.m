function tests = test_degradations
%TEST_DEGRADATIONS  Tests isolés des requêtes et des dégradations.
%   Lancer : runtests('tests')
tests = functiontests(localfunctions);
end

function setupOnce(tc)
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'src'), fullfile(racine, 'utils'), ...
    fullfile(racine, 'eval'), fullfile(racine, 'eval', 'degradations'));
tc.TestData.P = parametres();
tc.TestData.Fe0 = 44100;
tc.TestData.y = morceau_synthetique(5, tc.TestData.Fe0, 3);
end

function test_extraire_requete(tc)
% Bonne durée, mono, et l'extrait est bien pris dans le morceau à t0.
Fe0 = tc.TestData.Fe0;
x = morceau_synthetique(20, Fe0, 4);
[y, t0] = extraire_requete([x x], Fe0, 5, RandStream('mt19937ar', 'Seed', 1));
verifyEqual(tc, numel(y), 5 * Fe0);
i0 = round(t0 * Fe0) + 1;
verifyEqual(tc, y, x(i0:i0 + 5*Fe0 - 1), 'AbsTol', 1e-12);
end

function test_rsb_blanc(tc)
% Le RSB obtenu est celui demandé.
y = tc.TestData.y;
for rsb = [20 10 0]
    yb = ajouter_bruit(y, rsb, 'blanc', RandStream('mt19937ar', 'Seed', 1));
    mesure = 10*log10(mean(y.^2) / mean((yb - y).^2));
    verifyEqual(tc, mesure, rsb, 'AbsTol', 1e-9);
end
end

function test_rsb_bruit_reel(tc)
% Même chose avec un bruit fourni plus court que l'extrait (il est répété).
y = tc.TestData.y;
b = randn(1000, 1);
yb = ajouter_bruit(y, 5, b, RandStream('mt19937ar', 'Seed', 1));
verifyEqual(tc, 10*log10(mean(y.^2) / mean((yb - y).^2)), 5, 'AbsTol', 1e-9);
end

function test_mp3_aligne(tc)
% Le MP3 garde la longueur et reste aligné sur l'original (retard retiré).
y = tc.TestData.y;
ym = degrader_mp3(y, tc.TestData.Fe0, 128, tc.TestData.P);
verifyEqual(tc, numel(ym), numel(y));
[c, lags] = xcorr(ym, y, 200);
[~, i] = max(c);
verifyEqual(tc, lags(i), 0);
end

function test_passe_bande(tc)
% 1 kHz passe, 100 Hz est fortement atténué.
Fe0 = tc.TestData.Fe0;
t = (0:Fe0-1)' / Fe0;
gain = @(f) rms(filtre_passe_bande(sin(2*pi*f*t), Fe0)) / rms(sin(2*pi*f*t));
verifyGreaterThan(tc, gain(1000), 0.9);
verifyLessThan(tc, gain(100), 0.05);
end

function test_reverberation(tc)
% Même longueur et même puissance ; la réponse dure T60.
y = tc.TestData.y;
[yr, h] = reverberation(y, tc.TestData.Fe0, 0.3, RandStream('mt19937ar', 'Seed', 1));
verifyEqual(tc, numel(yr), numel(y));
verifyEqual(tc, mean(yr.^2), mean(y.^2), 'RelTol', 1e-9);
verifyEqual(tc, numel(h), round(0.3 * tc.TestData.Fe0));
end
