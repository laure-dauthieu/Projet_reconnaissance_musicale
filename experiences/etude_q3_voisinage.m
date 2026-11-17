%ETUDE_Q3_VOISINAGE  Q3 : densité ρ et survie p en fonction du voisinage.
%   Prérequis : experiences/preparer_donnees.m (cache/signaux_base.mat).
%
%   Pour chaque voisinage ±dm trames x ±dk canaux, sans quota de pics
%   (P.rho = Inf : seuls le voisinage et le seuil local décident), on mesure
%   sur 100 extraits de 8 s (un par morceau de la base) :
%     ρ = nombre de pics par seconde sur l'extrait propre ;
%     p = proportion de ces pics retrouvés à la même position après ajout
%         d'un bruit blanc à 10 dB (ajouté à 8 kHz, extrait aligné).
%   Le critère ρ p² est proportionnel au nombre de clés correctes retrouvées
%   (s ≈ F ρ Tq p²). On mesure aussi le réglage retenu, avec quota.
%
%   Produit : resultats/q3_voisinage.csv, figures/p_en_fonction_de_rho (.pdf, .png)

clear; close all;
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'src'), fullfile(racine, 'utils'), ...
    fullfile(racine, 'eval'), fullfile(racine, 'eval', 'degradations'));
load(fullfile(racine, 'cache', 'signaux_base.mat'), 'signauxBase');
P0 = parametres();
rs = RandStream('mt19937ar', 'Seed', 3);
Tq = 8;
RSB = 10;

%% Extraits propres et bruités (les mêmes pour tous les réglages)
n = numel(signauxBase);
propre = cell(n, 1);  bruite = cell(n, 1);
nq = Tq * P0.Fe;
for i = 1:n
    x = signauxBase{i};
    d = randi(rs, numel(x) - nq + 1);
    propre{i} = x(d:d + nq - 1);
    bruite{i} = ajouter_bruit(propre{i}, RSB, 'blanc', rs);
end

%% Balayage du voisinage (sans quota) puis réglage retenu (avec quota)
dks = [1 2 3 5 8 12];
dms = [1 3 5];
lignes = [];
for dm = dms
    for dk = dks
        lignes = [lignes; mesurer(parametres('dk', dk, 'dm', dm, 'rho', Inf), propre, bruite, Tq)]; %#ok<AGROW>
    end
end
retenu = mesurer(P0, propre, bruite, Tq);
T = array2table([lignes; retenu], 'VariableNames', {'dk', 'dm', 'quota', 'rho', 'p', 'rho_p2'});
writetable(T, fullfile(racine, 'resultats', 'q3_voisinage.csv'));
disp(T);

%% Figure
pal = [0.00 0.45 0.74; 0.85 0.33 0.10; 0.13 0.55 0.13];
marq = {'o-', 's--', '^:'};
fig = nouvelle_figure(17, 8.5);
tl = tiledlayout(fig, 1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

ax = nexttile(tl);  hold(ax, 'on');
for j = 1:numel(dms)
    s = T.dm == dms(j) & T.quota == 0;
    plot(ax, 2*T.dk(s) + 1, T.rho(s), marq{j}, 'Color', pal(j, :), 'LineWidth', 1.4, ...
        'DisplayName', sprintf('%d trames (±%d)', 2*dms(j) + 1, dms(j)));
end
set(ax, 'XScale', 'log', 'YScale', 'log');  xticks(ax, 2*dks + 1);  yticks(ax, [25 50 100 200 300]);  grid(ax, 'on');
xlabel(ax, 'largeur du voisinage (canaux)');  ylabel(ax, '\rho (pics/s)');
title(ax, '(a) densité de pics');

ax = nexttile(tl);  hold(ax, 'on');
for j = 1:numel(dms)
    s = T.dm == dms(j) & T.quota == 0;
    plot(ax, T.rho(s), T.p(s), marq{j}, 'Color', pal(j, :), 'LineWidth', 1.4, 'HandleVisibility', 'off');
end
r = T.quota == 1;
plot(ax, T.rho(r), T.p(r), 'kp', 'MarkerSize', 11, 'MarkerFaceColor', 'k');
set(ax, 'XScale', 'log');  xticks(ax, [25 50 100 200 300]);  grid(ax, 'on');  ylim(ax, [0 1]);
xlabel(ax, '\rho (pics/s)');  ylabel(ax, sprintf('p (bruit blanc %d dB)', RSB));
title(ax, '(b) survie des pics');

ax = nexttile(tl);  hold(ax, 'on');
for j = 1:numel(dms)
    s = T.dm == dms(j) & T.quota == 0;
    plot(ax, T.rho(s), T.rho_p2(s), marq{j}, 'Color', pal(j, :), 'LineWidth', 1.4, ...
        'DisplayName', sprintf('voisinage de %d trames (±%d), sans quota', 2*dms(j) + 1, dms(j)));
end
plot(ax, T.rho(r), T.rho_p2(r), 'kp', 'MarkerSize', 11, 'MarkerFaceColor', 'k', ...
    'DisplayName', 'réglage retenu (±3 trames × ±5 canaux, avec quota)');
set(ax, 'XScale', 'log');  xticks(ax, [25 50 100 200 300]);  grid(ax, 'on');
xlabel(ax, '\rho (pics/s)');  ylabel(ax, '\rho p^2 (pics/s)');
title(ax, '(c) critère \rho p^2');
lg = legend(ax, 'NumColumns', 2, 'FontSize', 7);
lg.Layout.Tile = 'south';

title(tl, sprintf('Voisinage : %d extraits de %d s, bruit blanc à %d dB (sans quota, sauf l''étoile)', ...
    n, Tq, RSB), 'FontSize', 10);
sauver_figure(fig, 'p_en_fonction_de_rho');

function ligne = mesurer(P, propre, bruite, Tq)
% ρ et p cumulés sur tous les extraits.
nPics = 0;  nSurv = 0;
for i = 1:numel(propre)
    a = detection_pics(calcul_spectrogramme(propre{i}, P), P);
    b = detection_pics(calcul_spectrogramme(bruite{i}, P), P);
    nPics = nPics + size(a, 1);
    nSurv = nSurv + sum(ismember(a, b, 'rows'));
end
rho = nPics / (numel(propre) * Tq);
p = nSurv / nPics;
ligne = [P.dk, P.dm, isfinite(P.rho), rho, p, rho * p^2];
end
