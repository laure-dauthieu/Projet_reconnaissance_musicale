function tests = test_empreintes_signal
%TEST_EMPREINTES_SIGNAL  Tests isolés de la chaîne d'extraction commune (étapes 2 à 4).
%   Lancer seul : runtests('tests/test_empreintes_signal.m')
tests = functiontests(localfunctions);
end

function setupOnce(tc)
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'src'), fullfile(racine, 'utils'));
tc.TestData.P = parametres();
tc.TestData.x = morceau_synthetique(10, tc.TestData.P.Fe, 5);
end

function test_composition(tc)
% Même résultat que les trois étapes appelées l'une après l'autre.
P = tc.TestData.P;
x = tc.TestData.x;
[E, pics, SdB] = empreintes_signal(x, P);
verifyEqual(tc, SdB, calcul_spectrogramme(x, P));
verifyEqual(tc, pics, detection_pics(SdB, P));
verifyEqual(tc, E, generer_empreintes(pics, P));
end

function test_cles_dans_l_alphabet(tc)
% Toutes les clés sont des entiers de [0, M).
P = tc.TestData.P;
E = empreintes_signal(tc.TestData.x, P);
verifyNotEmpty(tc, E);
verifyTrue(tc, all(E(:, 1) >= 0 & E(:, 1) < P.M & E(:, 1) == round(E(:, 1))));
end
