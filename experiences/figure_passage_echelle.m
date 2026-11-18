%FIGURE_PASSAGE_ECHELLE  Figure du passage à l'échelle à partir de resultats/passage_echelle.csv.
%   Prérequis : experiences/passage_echelle.m (qui appelle ce script à la fin).
%   Séparé des mesures pour pouvoir retoucher la figure sans tout relancer.
%
%   Produit : figures/temps_et_taille_index (.pdf, .png)

racine = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(racine, 'utils'));
T = readtable(fullfile(racine, 'resultats', 'passage_echelle.csv'));
n = T.n_morceaux;
bleu = [0.00 0.45 0.74];  orange = [0.85 0.33 0.10];

fig = nouvelle_figure(17, 7);
tl = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

% (a) temps de requête : quasi constant, la recherche ne parcourt pas la base
ax = nexttile(tl);  hold(ax, 'on');
plot(ax, n, T.requete_mediane_ms, 'o-', 'Color', bleu, 'LineWidth', 1.6, ...
    'MarkerSize', 6, 'MarkerFaceColor', bleu);
text(ax, n, T.requete_mediane_ms + 0.12, compose('%.1f', T.requete_mediane_ms), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 8, 'Color', bleu);
set(ax, 'XScale', 'log', 'XMinorGrid', 'off', 'XMinorTick', 'off');
xticks(ax, n);  xlim(ax, [8 650]);  ylim(ax, [0 3]);  grid(ax, 'on');
xlabel(ax, 'nombre de morceaux indexés');  ylabel(ax, 'temps médian d''une requête (ms)');
title(ax, '(a) temps de requête (extraits de 5 s)');

% (b) taille de l'index : proportionnelle au nombre de morceaux (pente 1 en log-log)
ax = nexttile(tl);  hold(ax, 'on');
moParMorceau = T.taille_Mo(end) / n(end);
plot(ax, [8 650], moParMorceau * [8 650], '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1, ...
    'DisplayName', sprintf('proportionnel : %.2f Mo par morceau', moParMorceau));
plot(ax, n, T.taille_Mo, 's-', 'Color', orange, 'LineWidth', 1.6, 'MarkerSize', 6, ...
    'MarkerFaceColor', orange, 'DisplayName', 'mesuré');
text(ax, n(end), T.taille_Mo(end), sprintf('%.0f Mo, %.1f M entrées  ', T.taille_Mo(end), ...
    T.n_entrees(end) / 1e6), 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'right', 'FontSize', 8);
set(ax, 'XScale', 'log', 'YScale', 'log', 'XMinorGrid', 'off', 'YMinorGrid', 'off', 'XMinorTick', 'off');
xticks(ax, n);  yticks(ax, [1 2 5 10 20 50 100]);  xlim(ax, [8 650]);  ylim(ax, [1 100]);  grid(ax, 'on');
xlabel(ax, 'nombre de morceaux indexés');  ylabel(ax, 'taille de l''index en mémoire (Mo)');
title(ax, '(b) taille de l''index');
legend(ax, 'Location', 'southeast', 'FontSize', 8);

sauver_figure(fig, 'temps_et_taille_index');
