function tests = test_identifier
%TEST_IDENTIFIER  Tests isolés de l'étape 5b (alignement temporel et décision).
%   Lancer seul : runtests('tests/test_identifier.m')
tests = functiontests(localfunctions);
end

function setupOnce(tc)
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'src'), fullfile(racine, 'utils'));
P = parametres();
tc.TestData.P = P;
tc.TestData.morceaux = arrayfun(@(g) morceau_synthetique(20, P.Fe, g), 1:3, 'UniformOutput', false);
tc.TestData.INDEX = construire_index(tc.TestData.morceaux, P);
end

function test_decalage_entier(tc)
% Propriété (1) : un extrait commençant à m0*H est retrouvé avec δ = m0.
P = tc.TestData.P;
x = tc.TestData.morceaux{2};
m0 = 40;
R = identifier(x(m0*P.H + 1 : m0*P.H + P.Tq*P.Fe), tc.TestData.INDEX, P);
verifyEqual(tc, R.id, 2);
verifyEqual(tc, R.delta, m0);
end

function test_decalage_quelconque(tc)
% Un début qui ne tombe pas sur la grille des trames : bon morceau, δ à une trame près.
P = tc.TestData.P;
x = tc.TestData.morceaux{3};
debut = 33333;
R = identifier(x(debut:debut + P.Tq*P.Fe - 1), tc.TestData.INDEX, P);
verifyEqual(tc, R.id, 3);
verifyLessThanOrEqual(tc, abs(R.delta - (debut - 1) / P.H), 1);
end

function test_morceau_absent(tc)
% Un morceau absent de l'index donne « inconnu », mais id_max et score restent renseignés.
P = tc.TestData.P;
R = identifier(morceau_synthetique(P.Tq, P.Fe, 99), tc.TestData.INDEX, P);
verifyEqual(tc, R.id, 0);
verifyLessThan(tc, R.score, P.s_thr);
verifyTrue(tc, R.id_max >= 1 && R.id_max <= 3);
end

function test_seuil(tc)
% Le même score est accepté ou rejeté selon s_thr.
P = tc.TestData.P;
x = tc.TestData.morceaux{1};
y = x(1:P.Tq*P.Fe);
R = identifier(y, tc.TestData.INDEX, P);
Rhaut = identifier(y, tc.TestData.INDEX, parametres('s_thr', R.score + 1));
verifyEqual(tc, R.id, 1);
verifyEqual(tc, Rhaut.id, 0);
end

function test_sorties(tc)
% Score = maximum des scores ; les appariements du meilleur ont δ = R.delta dans R.score cas.
P = tc.TestData.P;
x = tc.TestData.morceaux{2};
R = identifier(x(5000:5000 + P.Tq*P.Fe - 1), tc.TestData.INDEX);   % P de l'index
verifyEqual(tc, numel(R.scores), 3);
verifyEqual(tc, R.score, max(R.scores));
verifyEqual(tc, sum(R.app(:, 1) == R.id_max & R.app(:, 2) == R.delta), R.score);
end
