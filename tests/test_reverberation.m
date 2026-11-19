function tests = test_reverberation
%TEST_REVERBERATION  Tests isolés de la réverbération synthétique (dégradation).
%   Lancer seul : runtests('tests/test_reverberation.m')
tests = functiontests(localfunctions);
end

function setupOnce(tc)
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(racine, 'eval', 'degradations'), fullfile(racine, 'utils'));
tc.TestData.Fe0 = 8000;
tc.TestData.y = morceau_synthetique(5, tc.TestData.Fe0, 3);
end

function test_longueur_puissance_duree(tc)
% Même longueur et même puissance ; la réponse dure T60.
y = tc.TestData.y;
Fe0 = tc.TestData.Fe0;
for T60 = [0.3 1]
    [yr, h] = reverberation(y, Fe0, T60, RandStream('mt19937ar', 'Seed', 1));
    verifyEqual(tc, numel(yr), numel(y));
    verifyEqual(tc, mean(yr.^2), mean(y.^2), 'RelTol', 1e-9);
    verifyEqual(tc, numel(h), round(T60 * Fe0));
end
end

function test_decroissance(tc)
% L'énergie de la réponse décroît : le dernier dixième est bien plus faible que le premier.
[~, h] = reverberation(tc.TestData.y, tc.TestData.Fe0, 1, RandStream('mt19937ar', 'Seed', 1));
n = numel(h);
verifyLessThan(tc, sum(h(end - n/10 + 1:end).^2), 1e-3 * sum(h(1:n/10).^2));
end
