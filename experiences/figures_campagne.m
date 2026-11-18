%FIGURES_CAMPAGNE  Figures du sujet §7 à partir des résultats de la campagne.
%   Prérequis : experiences/campagne_evaluation.m (resultats/campagne.mat).
%   Séparé de la campagne pour pouvoir retoucher les figures sans tout relancer.
%
%   Produit : figures/tbd_en_fonction_du_rsb, tbd_en_fonction_du_debit_mp3, courbe_tbd_tfd,
%            histogrammes_scores (.pdf et .png)

racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'utils'), fullfile(racine, 'eval'));
load(fullfile(racine, 'resultats', 'campagne.mat'), 'C', 'resultats', 's_thr', 'synthese');
nPos = sum(resultats{1}.id_vrai > 0);
% Palette contrastée, lisible sur fond blanc et à l'impression (pas de jaune)
pal = [0.00 0.45 0.74;   % bleu
       0.85 0.33 0.10;   % orange
       0.13 0.55 0.13;   % vert foncé
       0.49 0.18 0.56;   % violet
       0.60 0.40 0.20;   % brun
       0.00 0.00 0.00];  % noir

%% Figure 1 : TBD en fonction du RSB, une courbe par Tq (bruit blanc), et brouhaha
fig = nouvelle_figure(12, 8);  hold on;
marq = {'o-', 's--', '^:'};  Tqs = [3 5 10];
for j = 1:3
    sel = synthese.degradation == "bruit blanc" & synthese.Tq == Tqs(j);
    plot(synthese.parametre(sel), 100 * synthese.TBD(sel), marq{j}, 'Color', pal(j, :), ...
        'LineWidth', 1.5, 'MarkerSize', 6, 'DisplayName', sprintf('bruit blanc, T_q = %d s', Tqs(j)));
end
sel = synthese.degradation == "brouhaha";
if any(sel)
    plot(synthese.parametre(sel), 100 * synthese.TBD(sel), 'kd-', 'LineWidth', 1.8, ...
        'MarkerSize', 7, 'MarkerFaceColor', 'k', 'DisplayName', 'brouhaha réel, T_q = 5 s');
end
set(gca, 'XDir', 'reverse');  xticks(0:5:20);  xlim([-1 21]);  ylim([0 101.5]);  yticks(0:10:100);
grid on;  xlabel('RSB (dB)');  ylabel('TBD (%)');
legend('Location', 'southwest');
title(sprintf('Bruit additif (s_{thr} = %d, N^+ = %d, TFD = 0 %%)', s_thr, nPos));
sauver_figure(fig, 'tbd_en_fonction_du_rsb');

%% Figure 2 : TBD en fonction du débit MP3
% Axe resserré sur 90-100 % : sur 50-100 % la courbe et la référence se
% confondaient. Les valeurs sont écrites au-dessus des points.
fig = nouvelle_figure(12, 8);  hold on;
sel = synthese.degradation == "MP3";
deb = synthese.parametre(sel);  tbd = 100 * synthese.TBD(sel);
ref = synthese.degradation == "aucune" & synthese.Tq == 5;
yline(100 * synthese.TBD(ref), 'k--', 'LineWidth', 1, ...
    'DisplayName', sprintf('sans dégradation (%.1f %%)', 100 * synthese.TBD(ref)));
plot(deb, tbd, 'o-', 'Color', pal(1, :), 'LineWidth', 1.8, 'MarkerSize', 7, ...
    'MarkerFaceColor', pal(1, :), 'DisplayName', 'MP3');
text(deb, tbd - 0.6, compose('%.1f %%', tbd), 'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'top', 'FontSize', 8, 'Color', pal(1, :));
set(gca, 'XScale', 'log', 'XMinorGrid', 'off', 'XMinorTick', 'off');
xticks([32 64 128]);  xlim([26 158]);  ylim([90 100.5]);  yticks(90:2:100);  grid on;
legend('Location', 'southeast');
xlabel('débit MP3 (kbit/s)');  ylabel('TBD (%)');
title(sprintf('Codage MP3 (T_q = 5 s, s_{thr} = %d, N^+ = %d, TFD = 0 %%)', s_thr, nPos));
sauver_figure(fig, 'tbd_en_fonction_du_debit_mp3');

%% Figure 3 : TBD en fonction du TFD en balayant le seuil (Tq = 5 s)
% La courbe balaie tous les seuils : elle ne dépend pas du seuil retenu, on
% utilise donc les 100 négatives (pas de 1 % sur le TFD au lieu de 2 %).
% Ordre de tracé : des plus épaisses aux plus fines, pour qu'une courbe
% superposée à une autre reste visible.
choix = {'réverbération T60 = 1 s', 'bruit blanc 0 dB', 'bruit blanc 10 dB', ...
    'MP3 32 kbit/s', 'passe-bande 300-3400 Hz', 'sans dégradation'};
styles = {'-', '-', '--', '-.', ':', '-'};
epaisseurs = [1.5 3.4 2.8 2.2 2.0 1.2];
couleurs = pal;
seuils = 0:max(cellfun(@(r) max(r.score), resultats)) + 1;

fig = nouvelle_figure(17, 8.5);
tl = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
cadres = {[-1.5 40 50 101], [-0.4 10 85 100.6]};   % marge : les points à TFD = 0 restent visibles
titres = {'(a) vue d''ensemble', '(b) zoom sur le coin supérieur gauche'};
for p = 1:2
    ax = nexttile(tl);  hold(ax, 'on');
    for k = 1:numel(choix)
        c = strcmp({C.nom}, choix{k}) & [C.Tq] == 5;
        T = taux_detection(resultats{c}, seuils);
        plot(ax, 100 * T.TFD, 100 * T.TBD, styles{k}, 'Color', couleurs(k, :), ...
            'LineWidth', epaisseurs(k), 'DisplayName', choix{k});
        Ts = taux_detection(resultats{c}, s_thr);
        plot(ax, 100 * Ts.TFD, 100 * Ts.TBD, 'ko', 'MarkerSize', 7, ...
            'MarkerFaceColor', couleurs(k, :), 'HandleVisibility', 'off');
    end
    % entrée de légende neutre pour le seuil retenu
    plot(ax, NaN, NaN, 'ko', 'MarkerSize', 7, 'MarkerFaceColor', 'w', ...
        'DisplayName', sprintf('seuil retenu (s_{thr} = %d)', s_thr));
    if p == 1
        rectangle(ax, 'Position', [0 85 10 15], 'LineStyle', ':', 'LineWidth', 1);
        text(ax, 10.5, 86.5, 'zoom (b)', 'FontSize', 8);
    end
    axis(ax, cadres{p});  grid(ax, 'on');  box(ax, 'on');
    xlabel(ax, 'TFD (%)');  ylabel(ax, 'TBD (%)');  title(ax, titres{p});
end
lg = legend(ax, 'NumColumns', 3, 'FontSize', 8);
lg.Layout.Tile = 'south';
title(tl, sprintf('TBD en fonction du TFD en balayant le seuil (T_q = 5 s, N^+ = %d, N^- = %d)', ...
    nPos, sum(resultats{1}.id_vrai == 0)), 'FontSize', 10);
sauver_figure(fig, 'courbe_tbd_tfd');

%% Figure 4 : histogrammes des scores positifs et négatifs (Tq = 5 s, abscisse log)
cs = find([C.Tq] == 5);
sPos = [];  sNeg = [];
for c = cs
    r = resultats{c};
    sPos = [sPos; r.score(r.id_vrai > 0)]; %#ok<AGROW>
    sNeg = [sNeg; r.score(r.id_vrai == 0)]; %#ok<AGROW>
end
% Les scores sont entiers : des classes log quelconques contiennent tantôt
% 1, tantôt 2 entiers, d'où de fausses pointes. Les bords sont donc placés
% sur des demi-entiers, et chaque effectif est ramené à une classe de largeur
% log nominale (ce que donnerait un score continu).
% (a) vue d'ensemble en log ; (b) zoom linéaire, classes de 1, autour du seuil.
fig = nouvelle_figure(17, 7.5);
tl = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
leg = {sprintf('négatives (%d requêtes)', numel(sNeg)), sprintf('positives (%d requêtes)', numel(sPos))};
coul = pal(1:2, :);

ax = nexttile(tl);  hold(ax, 'on');
e = unique(round(logspace(0, log10(max(sPos) + 1), 30)));
bords = [e - 0.5, e(end) + 0.5];
largeurNominale = log10(bords(end) / bords(1)) / (numel(bords) - 1);
facteur = largeurNominale ./ diff(log10(bords));
nmax = 0;
for j = 1:2
    s = ternaire(j == 1, sNeg, sPos);
    n = histcounts(max(s, 1), bords) .* facteur;
    nmax = max(nmax, max(n));
    histogram(ax, 'BinEdges', bords, 'BinCounts', n, 'FaceColor', coul(j, :), ...
        'FaceAlpha', 0.65, 'EdgeColor', 'w', 'DisplayName', leg{j});
end
xline(ax, s_thr, 'k--', 'LineWidth', 1.3, 'DisplayName', sprintf('s_{thr} = %d', s_thr));
set(ax, 'XScale', 'log', 'XMinorGrid', 'off');  grid(ax, 'on');
xticks(ax, [1 3 10 35 100 300 1000]);  xlim(ax, [0.9 bords(end)]);  ylim(ax, [0 1.45 * nmax]);   % place pour la légende
xlabel(ax, 'score s (classes de même largeur en log)');  ylabel(ax, 'nombre de requêtes');
title(ax, '(a) vue d''ensemble (abscisse log)');
legend(ax, 'Location', 'northeast', 'FontSize', 8);

ax = nexttile(tl);  hold(ax, 'on');
zmax = 60;
for j = 1:2
    s = ternaire(j == 1, sNeg, sPos);
    histogram(ax, s(s <= zmax), -0.5:1:zmax + 0.5, 'FaceColor', coul(j, :), ...
        'FaceAlpha', 0.65, 'EdgeColor', 'w');
end
xline(ax, s_thr, 'k--', sprintf('s_{thr} = %d', s_thr), 'LineWidth', 1.3, ...
    'LabelVerticalAlignment', 'top', 'LabelOrientation', 'horizontal', 'FontSize', 8);
xline(ax, max(sNeg), ':', sprintf('max négatif = %d', max(sNeg)), 'Color', coul(1, :), ...
    'LineWidth', 1.3, 'LabelVerticalAlignment', 'top', 'LabelOrientation', 'horizontal', ...
    'LabelHorizontalAlignment', 'left', 'FontSize', 8);
grid(ax, 'on');  xlim(ax, [0 zmax]);
xlabel(ax, 'score s');  ylabel(ax, 'nombre de requêtes');  ylim(ax, [0 220]);
title(ax, sprintf('(b) zoom sur 0 \\leq s \\leq %d (abscisse linéaire)', zmax));

title(tl, 'Scores du meilleur candidat, T_q = 5 s, toutes dégradations confondues', 'FontSize', 10);
sauver_figure(fig, 'histogrammes_scores');

function v = ternaire(c, a, b)
if c, v = a; else, v = b; end
end
