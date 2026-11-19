function tests = test_pretraitement
%TEST_PRETRAITEMENT  Tests isolés de l'étape 1 (mono, rééchantillonnage à Fe).
%   Lancer seul : runtests('tests/test_pretraitement.m')
tests = functiontests(localfunctions);
end

function setupOnce(tc)
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'src'), fullfile(racine, 'utils'));
tc.TestData.P = parametres();
end

function test_stereo_vers_mono(tc)
% Sortie mono, colonne, à P.Fe : 1 s de stéréo à 44,1 kHz donne P.Fe échantillons.
P = tc.TestData.P;
x = pretraitement(randn(44100, 2), P, 44100);
verifyTrue(tc, iscolumn(x));
verifyEqual(tc, numel(x), P.Fe);
end

function test_deja_a_Fe(tc)
% Un signal déjà mono à P.Fe n'est pas modifié (ligne -> colonne seulement).
P = tc.TestData.P;
s = randn(1, P.Fe);
verifyEqual(tc, pretraitement(s, P, P.Fe), s(:));
end

function test_anti_repliement(tc)
% Une sinusoïde à 6 kHz (au-delà de Fe/2 = 4 kHz) est éliminée, pas repliée à 2 kHz.
P = tc.TestData.P;
Fe0 = 44100;
t = (0:Fe0 - 1)' / Fe0;
x = pretraitement(sin(2*pi*6000*t), P, Fe0);
verifyLessThan(tc, rms(x(1000:end-1000)), 0.01);
end

function test_lecture_fichier(tc)
% Lecture d'un fichier audio, avec les paramètres par défaut.
Fe0 = 22050;
s = 0.5 * sin(2*pi*440*(0:Fe0 - 1)' / Fe0);
f = [tempname '.wav'];
audiowrite(f, [s s], Fe0);
nettoyer = onCleanup(@() delete(f));
x = pretraitement(f);
verifyEqual(tc, numel(x), tc.TestData.P.Fe);
end

function test_Fe0_obligatoire(tc)
% Un signal sans sa fréquence d'origine est refusé.
verifyError(tc, @() pretraitement(randn(100, 1), tc.TestData.P), 'pretraitement:Fe0');
end
