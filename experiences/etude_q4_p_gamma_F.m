%ETUDE_Q4_P_GAMMA_F  Q4 (p, tableau pic/paire, γf) et choix de F.
%   Prérequis : experiences/preparer_donnees.m (cache/).
%
%   1. p mesuré sur 100 extraits de 8 s (un par morceau de la base) pour un
%      bruit blanc à 10 dB (ajouté à 8 kHz) et un MP3 à 64 kbit/s (appliqué au
%      signal d'origine, retard du codeur retiré). Extraits alignés : p est la
%      proportion de pics propres retrouvés à la même position (m, k).
%      On mesure aussi p par bande (pour Q6) et la survie des clés p_cle,
%      à comparer à p² (une clé survit si ses deux pics survivent).
%   2. Tableau « 1 pic / 1 paire » du sujet avec nos valeurs.
%   3. γf = 1, 2, 4, 8 : M, appariements parasites attendus nq Nu / M,
%      TBD et TFD mesurés (bruit blanc 10 et 0 dB, Tq = 5 s, seuil recalibré).
%   4. F = 5, 10, 15 : TBD, TFD et taille de l'index (mêmes conditions).
%
%   Produit : resultats/q4_p.csv, q4_pic_paire.csv, q4_gamma.csv, q4_F.csv,
%             figures/p_par_bande (.pdf, .png)

clear; close all;
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'src'), fullfile(racine, 'utils'), ...
    fullfile(racine, 'eval'), fullfile(racine, 'eval', 'degradations'));
load(fullfile(racine, 'cache', 'base.mat'), 'base');
load(fullfile(racine, 'cache', 'signaux_base.mat'), 'signauxBase');
load(fullfile(racine, 'cache', 'signaux_hors.mat'), 'signauxHors');
P = parametres();
dossierRes = fullfile(racine, 'resultats');
rs = RandStream('mt19937ar', 'Seed', 4);
Tq = 8;

%% 1. p pour bruit blanc 10 dB et MP3 64 kbit/s
n = height(base);
noms = {'bruit blanc 10 dB', 'MP3 64 kbit/s'};
nPics = zeros(n, 1);  nCles = zeros(n, 1);
surv = zeros(n, 2);  survCles = zeros(n, 2);
survBande = zeros(P.Nb, 2);  nBande = zeros(P.Nb, 1);
tic;
for i = 1:n
    [x, fe] = audioread(base.chemin(i));
    y = extraire_requete(x, fe, Tq, rs);
    propre = pretraitement(y, P, fe);
    degr = {ajouter_bruit(propre, 10, 'blanc', rs), ...
            pretraitement(degrader_mp3(y, fe, 64, P), P, fe)};
    [Ep, picsP] = empreintes_signal(propre, P);
    nPics(i) = size(picsP, 1);
    nCles(i) = size(Ep, 1);
    for d = 1:2
        [Ed, picsD] = empreintes_signal(degr{d}, P);
        [~, pB, nB] = mesurer_p(picsP, picsD, P);
        surv(i, d) = sum(ismember(picsP, picsD, 'rows'));
        survCles(i, d) = sum(ismember(Ep, Ed, 'rows'));
        survBande(:, d) = survBande(:, d) + fillmissing(pB, 'constant', 0) .* nB;
        if d == 1, nBande = nBande + nB; end
    end
end
fprintf('Mesure de p sur %d extraits : %.0f s\n', n, toc);
p = sum(surv) / sum(nPics);
pCle = sum(survCles) / sum(nCles);
pBande = survBande ./ nBande;
rho = sum(nPics) / (n * Tq);
Tp = table(string(noms'), p', p'.^2, pCle', 'VariableNames', {'degradation', 'p', 'p2', 'p_cle'});
writetable(Tp, fullfile(dossierRes, 'q4_p.csv'));
disp(Tp);
fprintf('rho = %.1f pics/s, %.0f clés par requête de %d s en moyenne\n', rho, mean(nCles), Tq);
fprintf('p par bande (bruit / MP3) :\n');  disp([P.bandes(1:end-1)' P.bandes(2:end)' pBande]);

%% 2. Tableau « 1 pic / 1 paire » avec nos valeurs
lignes = {};
for d = 1:2
    nPic = rho * Tq;
    nPaire = mean(nCles);
    lignes(end+1, :) = {noms{d}, nPic, nPaire, p(d), p(d)^2, pCle(d), ...
        nPic * p(d), nPaire * p(d)^2, nPaire * pCle(d), P.K, P.M}; %#ok<SAGROW>
end
Tpp = cell2table(lignes, 'VariableNames', {'degradation', 'cles_requete_1pic', ...
    'cles_requete_paire', 'p', 'p2', 'p_cle_mesure', 'cles_correctes_1pic', ...
    'cles_correctes_paire_p2', 'cles_correctes_paire_mesure', 'M_1pic', 'M_paire'});
writetable(Tpp, fullfile(dossierRes, 'q4_pic_paire.csv'));
disp(Tpp);

%% 3. γf = 1, 2, 4, 8 et 4. F = 5, 10, 15 (bruit blanc 10 et 0 dB, Tq = 5 s)
TqV = 5;
% Deux niveaux de bruit : à 10 dB le TBD est proche de 100 % et départage
% mal les réglages ; à 0 dB les écarts ressortent.
lignesG = [];
for rsb = [10 0]
    for g = [1 2 4 8]
        Pg = parametres('gamma_f', g);
        rsN = RandStream('mt19937ar', 'Seed', 40);
        V = evaluer_variante(Pg, signauxBase, signauxHors, @(y) ajouter_bruit(y, rsb, 'blanc', rsN), TqV, 41);
        lignesG = [lignesG; rsb, g, Pg.M, V.nClesRequete, V.nEntrees, ...
            V.nClesRequete * V.nEntrees / Pg.M, V.s_thr, V.scoreMedian, V.TBD, V.TFD]; %#ok<AGROW>
        fprintf('RSB %d dB, gamma_f = %d : seuil %d, TBD %.1f %%\n', rsb, g, V.s_thr, 100 * V.TBD);
    end
end
Tg = array2table(lignesG, 'VariableNames', {'RSB', 'gamma_f', 'M', 'nq', 'Nu', ...
    'parasites_attendus', 's_thr', 'score_median', 'TBD', 'TFD'});
writetable(Tg, fullfile(dossierRes, 'q4_gamma.csv'));
disp(Tg);

lignesF = [];
for rsb = [10 0]
    for F = [5 10 15]
        Pf = parametres('F', F);
        rsN = RandStream('mt19937ar', 'Seed', 40);
        V = evaluer_variante(Pf, signauxBase, signauxHors, @(y) ajouter_bruit(y, rsb, 'blanc', rsN), TqV, 41);
        lignesF = [lignesF; rsb, F, V.nEntrees, V.nClesRequete, V.s_thr, V.scoreMedian, V.TBD, V.TFD]; %#ok<AGROW>
        fprintf('RSB %d dB, F = %d : seuil %d, TBD %.1f %%\n', rsb, F, V.s_thr, 100 * V.TBD);
    end
end
TF = array2table(lignesF, 'VariableNames', {'RSB', 'F', 'Nu', 'nq', 's_thr', 'score_median', 'TBD', 'TFD'});
writetable(TF, fullfile(dossierRes, 'q4_F.csv'));
disp(TF);

%% Figure : p par bande, bruit blanc 10 dB contre MP3 64 kbit/s (Q6)
fig = nouvelle_figure(14, 8);
b = bar(1:P.Nb, pBande, 'grouped');
b(1).FaceColor = [0.00 0.45 0.74];  b(2).FaceColor = [0.85 0.33 0.10];
etiq = arrayfun(@(j) sprintf('%.0f–%.0f', P.bandes(j), P.bandes(j+1)), 1:P.Nb, 'UniformOutput', false);
xticks(1:P.Nb);  xticklabels(etiq);  ylim([0 1]);  grid on;
xlabel('bande de fréquence (Hz)');  ylabel('p (proportion de pics conservés)');
legend(sprintf('bruit blanc 10 dB (p = %.2f)', p(1)), sprintf('MP3 64 kbit/s (p = %.2f)', p(2)), ...
    'Location', 'southoutside', 'NumColumns', 2);
title(sprintf('Survie des pics par bande (%d extraits de %d s)', n, Tq));
sauver_figure(fig, 'p_par_bande');
