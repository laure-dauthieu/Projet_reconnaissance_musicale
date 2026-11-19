function tests = test_ajouter_bruit
%TEST_AJOUTER_BRUIT  Tests isolés du bruit additif à RSB imposé (dégradation).
%   Lancer seul : runtests('tests/test_ajouter_bruit.m')
tests = functiontests(localfunctions);
end

function setupOnce(tc)
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(racine, 'eval', 'degradations'), fullfile(racine, 'utils'));
tc.TestData.y = morceau_synthetique(5, 8000, 3);
end

function test_rsb_blanc(tc)
% Le RSB obtenu est celui demandé, Px étant mesuré sur l'extrait (équation (8)).
y = tc.TestData.y;
for rsb = [20 10 0]
    yb = ajouter_bruit(y, rsb, 'blanc', RandStream('mt19937ar', 'Seed', 1));
    verifyEqual(tc, 10*log10(mean(y.^2) / mean((yb - y).^2)), rsb, 'AbsTol', 1e-9);
end
end

function test_rsb_bruit_reel(tc)
% Même chose avec un bruit fourni plus court que l'extrait (il est répété).
y = tc.TestData.y;
yb = ajouter_bruit(y, 5, randn(1000, 1), RandStream('mt19937ar', 'Seed', 1));
verifyEqual(tc, 10*log10(mean(y.^2) / mean((yb - y).^2)), 5, 'AbsTol', 1e-9);
end

function test_longueur(tc)
y = tc.TestData.y;
verifyEqual(tc, size(ajouter_bruit(y, 10)), size(y));
end
