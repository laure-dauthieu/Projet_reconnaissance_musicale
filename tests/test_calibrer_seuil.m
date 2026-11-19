function tests = test_calibrer_seuil
%TEST_CALIBRER_SEUIL  Tests isolés du réglage du seuil s_thr (évaluation, Q5).
%   Lancer seul : runtests('tests/test_calibrer_seuil.m')
tests = functiontests(localfunctions);
end

function setupOnce(tc) %#ok<INUSD>
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(racine, 'eval'));
end

function test_marge_par_defaut(tc)
% s_thr = ceil(1,5 x plus fort score négatif) : 23 -> 35, comme dans le rapport.
verifyEqual(tc, calibrer_seuil([4 9 23 17]), 35);
end

function test_marge_choisie(tc)
verifyEqual(tc, calibrer_seuil([10 20], 2), 40);
verifyEqual(tc, calibrer_seuil([10 21], 1), 21);
end

function test_au_dessus_de_toutes_les_negatives(tc)
% Aucune négative de calibration n'atteint le seuil.
s = randi(30, 50, 1);
verifyGreaterThan(tc, calibrer_seuil(s), max(s));
end
