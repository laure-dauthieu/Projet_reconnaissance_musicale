function tests = test_evaluer
%TEST_EVALUER  Tests isolés de l'évaluation d'un ensemble de requêtes.
%   Lancer seul : runtests('tests/test_evaluer.m')
tests = functiontests(localfunctions);
end

function setupOnce(tc)
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'src'), fullfile(racine, 'utils'), fullfile(racine, 'eval'));
P = parametres();
tc.TestData.P = P;
morceaux = arrayfun(@(g) morceau_synthetique(20, P.Fe, g), 1:3, 'UniformOutput', false);
tc.TestData.INDEX = construire_index(morceaux, P);
n = P.Tq * P.Fe;
tc.TestData.requetes = struct( ...
    'y', {morceaux{1}(1001:1000 + n), morceaux{3}(20001:20000 + n), morceau_synthetique(P.Tq, P.Fe, 50)}, ...
    'id_vrai', {1, 3, 0});
end

function test_une_ligne_par_requete(tc)
res = evaluer(tc.TestData.INDEX, tc.TestData.requetes, tc.TestData.P);
verifyEqual(tc, height(res), 3);
verifyEqual(tc, res.Properties.VariableNames, {'id_vrai', 'id_max', 'score', 'temps'});
verifyEqual(tc, res.id_vrai, [1; 3; 0]);
end

function test_coherent_avec_identifier(tc)
% Chaque ligne reprend le résultat d'identifier pour la même requête.
P = tc.TestData.P;
res = evaluer(tc.TestData.INDEX, tc.TestData.requetes, P);
for i = 1:3
    R = identifier(tc.TestData.requetes(i).y, tc.TestData.INDEX, P);
    verifyEqual(tc, [res.id_max(i), res.score(i)], [R.id_max, R.score]);
end
end

function test_taux(tc)
% Les deux positives sont reconnues, la négative est rejetée.
res = evaluer(tc.TestData.INDEX, tc.TestData.requetes);       % P de l'index
T = taux_detection(res, tc.TestData.P.s_thr);
verifyEqual(tc, [T.TBD, T.TFD], [1, 0]);
end
