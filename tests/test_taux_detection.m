function tests = test_taux_detection
%TEST_TAUX_DETECTION  Tests isolés du calcul de TBD et TFD (évaluation).
%   Lancer seul : runtests('tests/test_taux_detection.m')
%   Les résultats d'identification sont écrits à la main : aucune autre étape n'est appelée.
tests = functiontests(localfunctions);
end

function setupOnce(tc) %#ok<INUSD>
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(racine, 'eval'));
end

function res = resultats()
% 4 positives (morceaux 1 à 4) et 2 négatives.
%   1 : bon morceau, score 100  -> bonne détection
%   2 : bon morceau, score 20   -> non-détection au seuil 35
%   3 : mauvais morceau, 50     -> confusion
%   4 : bon morceau, score 40   -> bonne détection
%   négatives : scores 10 et 60 -> la 2e est une fausse détection au seuil 35
id_vrai = [1; 2; 3; 4; 0; 0];
id_max  = [1; 2; 7; 4; 5; 6];
score   = [100; 20; 50; 40; 10; 60];
res = table(id_vrai, id_max, score);
end

function test_un_seuil(tc)
T = taux_detection(resultats(), 35);
verifyEqual(tc, T.TBD, 2/4);
verifyEqual(tc, T.confusion, 1/4);
verifyEqual(tc, T.non_detection, 1/4);
verifyEqual(tc, T.TFD, 1/2);
verifyEqual(tc, [T.N_pos, T.N_neg], [4, 2]);
end

function test_balayage_du_seuil(tc)
% Une ligne par seuil ; TBD et TFD décroissent quand le seuil monte.
T = taux_detection(resultats(), [0 15 35 70 200]);
verifyEqual(tc, height(T), 5);
verifyEqual(tc, T.TBD', [3 3 2 1 0] / 4);
verifyEqual(tc, T.TFD', [2 1 1 0 0] / 2);
verifyEqual(tc, T.TBD + T.confusion + T.non_detection, ones(5, 1));
end
