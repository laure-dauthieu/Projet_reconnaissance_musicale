function tests = test_degrader_mp3
%TEST_DEGRADER_MP3  Tests isolés du codage MP3 (dégradation).
%   Lancer seul : runtests('tests/test_degrader_mp3.m')
%   Nécessite ffmpeg (chemin dans P.ffmpeg) : sans lui, les tests sont ignorés
%   (« Incomplete ») au lieu d'échouer.
tests = functiontests(localfunctions);
end

function setupOnce(tc)
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'eval', 'degradations'), fullfile(racine, 'utils'));
tc.TestData.P = parametres();
tc.TestData.Fe0 = 44100;
tc.TestData.y = morceau_synthetique(5, tc.TestData.Fe0, 3);
statut = system(sprintf('"%s" -version', tc.TestData.P.ffmpeg));
assumeEqual(tc, statut, 0, 'ffmpeg est introuvable : test du MP3 ignoré.');
end

function test_longueur_et_alignement(tc)
% Le MP3 garde la longueur et reste aligné sur l'original (retard du codeur retiré).
y = tc.TestData.y;
ym = degrader_mp3(y, tc.TestData.Fe0, 128, tc.TestData.P);
verifyEqual(tc, numel(ym), numel(y));
[c, lags] = xcorr(ym, y, 200);
[~, i] = max(c);
verifyEqual(tc, lags(i), 0);
end

function test_debit(tc)
% Plus le débit est bas, plus l'erreur de codage est grande.
y = tc.TestData.y;
err = @(d) mean((degrader_mp3(y, tc.TestData.Fe0, d, tc.TestData.P) - y).^2);
verifyGreaterThan(tc, err(32), err(128));
end
