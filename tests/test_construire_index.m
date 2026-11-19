function tests = test_construire_index
%TEST_CONSTRUIRE_INDEX  Tests isolés de l'étape 5a (index inversé).
%   Lancer seul : runtests('tests/test_construire_index.m')
tests = functiontests(localfunctions);
end

function setupOnce(tc)
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'src'), fullfile(racine, 'utils'));
P = parametres();
tc.TestData.P = P;
tc.TestData.x = morceau_synthetique(20, P.Fe, 7);
tc.TestData.INDEX = construire_index({tc.TestData.x, flipud(tc.TestData.x)}, P);
end

function test_structure(tc)
% Entrées triées par clé ; ucle/debut/nb décrivent exactement les plages de chaque clé.
I = tc.TestData.INDEX;
verifyTrue(tc, issorted(I.cle));
verifyEqual(tc, I.ucle, unique(I.cle));
verifyEqual(tc, sum(I.nb), numel(I.cle));
verifyEqual(tc, I.cle(I.debut), I.ucle);
verifyEqual(tc, unique(I.id)', uint32([1 2]));
verifyEqual(tc, I.noms, {'morceau 1'; 'morceau 2'});
end

function test_toutes_les_entrees(tc)
% L'index rend toutes les entrées de chaque clé (comparaison avec une recherche exhaustive).
P = tc.TestData.P;
I = tc.TestData.INDEX;
E = generer_empreintes(detection_pics(calcul_spectrogramme(tc.TestData.x(1:5*P.Fe), P), P), P);
for c = uint32(E(1:20, 1))'
    [~, loc] = ismember(c, I.ucle);
    verifyEqual(tc, double(I.nb(loc)), sum(I.cle == c));
    verifyTrue(tc, all(I.cle(I.debut(loc) + (0:I.nb(loc) - 1)) == c));
end
end

function test_contenu_par_morceau(tc)
% Les entrées du morceau 1 sont exactement ses empreintes.
P = tc.TestData.P;
I = tc.TestData.INDEX;
E = empreintes_signal(tc.TestData.x, P);
sel = I.id == 1;
verifyEqual(tc, sortrows(double([I.cle(sel), I.m1(sel)])), sortrows(E));
end

function test_parametres_gardes(tc)
% L'index garde ses paramètres (identifier les réutilise) et ses noms.
I = construire_index({tc.TestData.x}, tc.TestData.P, {'A'});
verifyEqual(tc, I.P, tc.TestData.P);
verifyEqual(tc, I.noms, {'A'});
end
