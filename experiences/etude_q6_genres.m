%ETUDE_Q6_GENRES  Q6 : taux de bonne détection par genre musical.
%   Prérequis : experiences/campagne_evaluation.m (resultats/campagne.mat)
%               et experiences/preparer_donnees.m (cache/).
%
%   À partir des requêtes de la campagne (25 requêtes positives par genre en
%   moyenne), on calcule le TBD de chaque genre pour quelques conditions
%   difficiles, au seuil retenu. Pour expliquer les écarts, on mesure aussi
%   par genre :
%     - le score médian du bon morceau sans dégradation (Tq = 5 s) ;
%     - la densité de pics « brute » ρ_brut (sans quota) des morceaux de la
%       base : elle mesure combien la musique offre de maxima nets.
%
%   Produit : resultats/q6_genres.csv, figures/tbd_par_genre (.pdf, .png)

clear; close all;
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'src'), fullfile(racine, 'utils'), fullfile(racine, 'eval'));
load(fullfile(racine, 'resultats', 'campagne.mat'), 'C', 'resultats', 's_thr');
load(fullfile(racine, 'cache', 'base.mat'), 'base');
load(fullfile(racine, 'cache', 'signaux_base.mat'), 'signauxBase');

choix = {'sans dégradation', 3; 'bruit blanc 5 dB', 5; 'bruit blanc 0 dB', 5; ...
    'réverbération T60 = 1 s', 5};
genres = unique(base.genre);
nG = numel(genres);

%% TBD par genre et par condition
TBD = zeros(nG, size(choix, 1));
nPos = zeros(nG, 1);
for c = 1:size(choix, 1)
    r = resultats{strcmp({C.nom}, choix{c, 1}) & [C.Tq] == choix{c, 2}};
    pos = r.id_vrai > 0;
    for g = 1:nG
        sel = pos & r.genre == genres(g);
        nPos(g) = sum(sel);
        TBD(g, c) = mean(r.id_max(sel) == r.id_vrai(sel) & r.score(sel) >= s_thr);
    end
end

%% Indicateurs par genre
r = resultats{strcmp({C.nom}, 'sans dégradation') & [C.Tq] == 5};
scoreMedian = zeros(nG, 1);
for g = 1:nG
    sel = r.id_vrai > 0 & r.genre == genres(g);
    scoreMedian(g) = median(r.score(sel));
end
% Part de l'énergie (200–4000 Hz) au-dessus de 894 Hz (bandes 4 à 6) : un
% bruit blanc a la même densité à toutes les fréquences, donc le RSB local
% des bandes hautes dépend de l'énergie que la musique y met.
Pbrut = parametres('rho', Inf);
rhoBrut = zeros(height(base), 1);
partAigus = zeros(height(base), 1);
for i = 1:height(base)
    x = signauxBase{i};
    [SdB, f] = calcul_spectrogramme(x, Pbrut);
    rhoBrut(i) = size(detection_pics(SdB, Pbrut), 1) / (numel(x) / Pbrut.Fe);
    E = sum(10.^(SdB / 10), 2);
    utile = f >= Pbrut.f_min & f < Pbrut.f_max;
    partAigus(i) = sum(E(utile & f >= Pbrut.bandes(4))) / sum(E(utile));
end
parGenre = @(v) arrayfun(@(g) median(v(base.genre == genres(g))), (1:nG)');

T = table(genres, nPos, scoreMedian, parGenre(rhoBrut), 100 * parGenre(partAigus), ...
    100 * TBD(:, 1), 100 * TBD(:, 2), 100 * TBD(:, 3), 100 * TBD(:, 4), 'VariableNames', ...
    {'genre', 'N_pos', 'score_median_propre_Tq5', 'rho_brut_median', 'energie_au_dessus_900Hz_pct', ...
    'TBD_propre_Tq3', 'TBD_bruit5dB_Tq5', 'TBD_bruit0dB_Tq5', 'TBD_reverb1s_Tq5'});
T = sortrows(T, 'TBD_bruit0dB_Tq5', 'descend');
writetable(T, fullfile(racine, 'resultats', 'q6_genres.csv'));
disp(T);
c = corrcoef(T.energie_au_dessus_900Hz_pct, T.TBD_bruit0dB_Tq5);  c = c(1, 2);
fprintf('Corrélation (8 genres) entre part d''énergie > 900 Hz et TBD à 0 dB : %.2f\n', c);

%% Figure : genres triés par TBD à 0 dB
[~, o] = sort(TBD(:, 3), 'descend');
pal = [0.00 0.45 0.74; 0.85 0.33 0.10; 0.13 0.55 0.13; 0.49 0.18 0.56];
fig = nouvelle_figure(9.4, 6.6);       % taille d'impression (demi-largeur du rapport)
b = bar(100 * TBD(o, :), 'grouped');
for c = 1:numel(b), b(c).FaceColor = pal(c, :); end
xticks(1:nG);  xticklabels(genres(o));  xtickangle(35);  ylim([0 105]);  grid on;
ylabel('TBD (%)');
legend(cellfun(@(n, t) sprintf('%s, T_q = %d s', n, t), choix(:, 1), choix(:, 2), 'UniformOutput', false), ...
    'Location', 'southoutside', 'NumColumns', 2, 'FontSize', 7);
sauver_figure(fig, 'tbd_par_genre');
