function tests = test_chaine
%TEST_CHAINE  Tests isolés des fonctions de la chaîne.
%   Lancer : runtests('tests')
tests = functiontests(localfunctions);
end

function setupOnce(tc)
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'src'), fullfile(racine, 'utils'));
tc.TestData.P = parametres();
tc.TestData.x = pretraitement(morceau_synthetique(20, 44100, 7), tc.TestData.P, 44100);
end

function test_pretraitement(tc)
% Sortie mono, colonne, à P.Fe ; un signal stéréo de 1 s donne P.Fe échantillons.
P = tc.TestData.P;
x = pretraitement(randn(44100, 2), P, 44100);
verifyTrue(tc, iscolumn(x));
verifyEqual(tc, numel(x), P.Fe);
end

function test_spectrogramme_dimensions(tc)
% K canaux et une trame toutes les H échantillons.
P = tc.TestData.P;
x = tc.TestData.x;
SdB = calcul_spectrogramme(x, P);
verifyEqual(tc, size(SdB, 1), P.K);
verifyEqual(tc, size(SdB, 2), floor((numel(x) - P.N) / P.H) + 1);
end

function test_sinusoide(tc)
% Une sinusoïde à 1 kHz donne des pics dans le canal de 1 kHz.
P = tc.TestData.P;
t = (0:5*P.Fe-1)' / P.Fe;
pics = detection_pics(calcul_spectrogramme(sin(2*pi*1000*t), P), P);
kAttendu = round(1000 * P.Nfft / P.Fe) + 1;
verifyNotEmpty(tc, pics);
verifyTrue(tc, all(abs(pics(:, 2) - kAttendu) <= 1));
end

function test_invariance_gain(tc)
% Propriété : les positions des pics ne dépendent pas du volume.
P = tc.TestData.P;
x = tc.TestData.x;
ref = detection_pics(calcul_spectrogramme(x, P), P);
for a = [0.01 0.5 10]
    verifyEqual(tc, detection_pics(calcul_spectrogramme(a * x, P), P), ref);
end
end

function test_decalage_entier(tc)
% Propriété (1) : un extrait commençant à m0*H est retrouvé avec δ = m0.
P = tc.TestData.P;
x = tc.TestData.x;
INDEX = construire_index({x}, P);
m0 = 40;
y = x(m0*P.H + 1 : m0*P.H + P.Tq*P.Fe);
R = identifier(y, INDEX, P);
verifyEqual(tc, R.id, 1);
verifyEqual(tc, R.delta, m0);
end

function test_index_toutes_entrees(tc)
% L'index rend toutes les entrées de chaque clé (comparaison avec une recherche exhaustive).
P = tc.TestData.P;
x = tc.TestData.x;
INDEX = construire_index({x, flipud(x)}, P);
E = generer_empreintes(detection_pics(calcul_spectrogramme(x(1:5*P.Fe), P), P), P);
c = uint32(E(1, 1));
attendu = sum(INDEX.cle == c);
[~, loc] = ismember(c, INDEX.ucle);
verifyEqual(tc, double(INDEX.nb(loc)), attendu);
verifyTrue(tc, all(INDEX.cle(INDEX.debut(loc) + (0:INDEX.nb(loc)-1)) == c));
end

function test_morceau_absent(tc)
% Un morceau absent de l'index doit donner « inconnu ».
P = tc.TestData.P;
INDEX = construire_index({tc.TestData.x}, P);
y = pretraitement(morceau_synthetique(P.Tq, 44100, 99), P, 44100);
R = identifier(y, INDEX, P);
verifyEqual(tc, R.id, 0);
end
