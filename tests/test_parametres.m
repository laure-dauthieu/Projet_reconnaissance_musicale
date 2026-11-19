function tests = test_parametres
%TEST_PARAMETRES  Tests isolés de parametres (réglages et grandeurs dérivées).
%   Lancer seul : runtests('tests/test_parametres.m')
tests = functiontests(localfunctions);
end

function setupOnce(tc) %#ok<INUSD>
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine);
end

function test_valeurs_du_sujet(tc)
% Valeurs de départ du sujet (§8) et grandeurs dérivées.
P = parametres();
verifyEqual(tc, [P.Fe, P.N, P.H, P.Nfft, P.K], [8000, 1024, 512, 1024, 513]);
verifyEqual(tc, [P.dm_min, P.dm_max, P.Nt], [2, 31, 30]);
verifyEqual(tc, P.M, 513^2 * 30);                 % ≈ 7,9e6 clés pour gamma_f = 1
verifyEqual(tc, numel(P.bandes), P.Nb + 1);
verifyEqual(tc, P.bandes([1 end]), [P.f_min, P.f_max], 'AbsTol', 1e-9);
end

function test_remplacement_et_derivees(tc)
% Une valeur remplacée recalcule les grandeurs qui en dépendent.
P = parametres('N', 2048, 'gamma_f', 4);
verifyEqual(tc, P.H, 1024);
verifyEqual(tc, P.K, 1025);
verifyEqual(tc, P.Nf, ceil(1025 / 4));
verifyEqual(tc, P.M, P.Nf^2 * P.Nt);
end

function test_erreurs(tc)
% Nom inconnu ou arguments impairs : erreur explicite.
verifyError(tc, @() parametres('inconnu', 1), 'parametres:inconnu');
verifyError(tc, @() parametres('F'), 'parametres:arguments');
end
