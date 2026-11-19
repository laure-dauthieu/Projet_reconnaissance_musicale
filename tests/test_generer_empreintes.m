function tests = test_generer_empreintes
%TEST_GENERER_EMPREINTES  Tests isolés de l'étape 4 (paires de pics -> clés).
%   Lancer seul : runtests('tests/test_generer_empreintes.m')
%   Les pics sont écrits à la main : ce test ne dépend d'aucune autre étape.
tests = functiontests(localfunctions);
end

function setupOnce(tc)
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'src'));
tc.TestData.P = parametres();
end

function test_formule_de_la_cle(tc)
% Une seule paire : u = (Qf(k1)*Nf + Qf(k2))*Nt + (Δm - dm_min), m1 rangé à part.
P = tc.TestData.P;
pics = [10 100; 15 120];
E = generer_empreintes(pics, P);
q = @(k) floor((k - 1) / P.gamma_f);
verifyEqual(tc, E, [(q(100)*P.Nf + q(120))*P.Nt + (5 - P.dm_min), 10]);
end

function test_zone_cible(tc)
% Cibles exclues : trop proches (Δm < dm_min), trop loin (Δm > dm_max), |Δk| > dk_max.
P = tc.TestData.P;
pics = sortrows([10 100; 10 + P.dm_min - 1 110; 10 + P.dm_max + 1 110; 20 100 + P.dk_max + 1], [1 2]);
E = generer_empreintes(pics, P);
verifyFalse(tc, any(E(:, 2) == 10));          % l'ancre de la trame 10 n'a aucune cible valable
end

function test_F_cibles_au_plus(tc)
% Une ancre suivie de 30 cibles valables n'en garde que F.
P = tc.TestData.P;
pics = [1 200; (2 + (1:30))', repmat(205, 30, 1)];
E = generer_empreintes(pics, P);
verifyEqual(tc, sum(E(:, 2) == 1), P.F);
end

function test_invariance_translation(tc)
% Décaler tous les pics de d trames donne les mêmes clés, et m1 décalé de d.
P = tc.TestData.P;
rs = RandStream('mt19937ar', 'Seed', 2);
pics = sortrows([randi(rs, 200, 300, 1), randi(rs, [30 480], 300, 1)], [1 2]);
pics = unique(pics, 'rows');
E1 = generer_empreintes(pics, P);
E2 = generer_empreintes(pics + [37 0], P);
verifyEqual(tc, E2(:, 1), E1(:, 1));
verifyEqual(tc, E2(:, 2), E1(:, 2) + 37);
end

function test_gamma_f(tc)
% Avec gamma_f = 4, deux pics des canaux 101 et 102 (même classe) donnent la même clé.
P = parametres('gamma_f', 4);
E1 = generer_empreintes([10 101; 15 120], P);
E2 = generer_empreintes([10 102; 15 120], P);
verifyEqual(tc, E1(:, 1), E2(:, 1));
end
