function tests = test_extraire_requete
%TEST_EXTRAIRE_REQUETE  Tests isolés de l'extraction des requêtes (évaluation).
%   Lancer seul : runtests('tests/test_extraire_requete.m')
tests = functiontests(localfunctions);
end

function setupOnce(tc) %#ok<INUSD>
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(racine, 'eval'), fullfile(racine, 'utils'));
end

function test_extrait_pris_dans_le_morceau(tc)
% Bonne durée, mono, et l'extrait est bien pris dans le morceau à t0.
Fe0 = 44100;
x = morceau_synthetique(20, Fe0, 4);
[y, t0] = extraire_requete([x x], Fe0, 5, RandStream('mt19937ar', 'Seed', 1));
verifyEqual(tc, numel(y), 5 * Fe0);
i0 = round(t0 * Fe0) + 1;
verifyEqual(tc, y, x(i0:i0 + 5*Fe0 - 1), 'AbsTol', 1e-12);
end

function test_reproductible(tc)
% Même graine, même extrait ; graines différentes, instants différents.
x = randn(20 * 8000, 1);
[~, a] = extraire_requete(x, 8000, 5, RandStream('mt19937ar', 'Seed', 3));
[~, b] = extraire_requete(x, 8000, 5, RandStream('mt19937ar', 'Seed', 3));
[~, c] = extraire_requete(x, 8000, 5, RandStream('mt19937ar', 'Seed', 4));
verifyEqual(tc, a, b);
verifyNotEqual(tc, a, c);
end

function test_morceau_trop_court(tc)
% Un morceau plus court que Tq est refusé.
verifyError(tc, @() extraire_requete(randn(8000, 1), 8000, 5), 'extraire_requete:court');
end
