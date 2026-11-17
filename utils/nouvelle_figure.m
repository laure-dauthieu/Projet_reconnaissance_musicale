function fig = nouvelle_figure(largeur_cm, hauteur_cm)
%NOUVELLE_FIGURE  Figure au style commun du rapport (fond clair, police lisible).
%   fig = nouvelle_figure(largeur_cm, hauteur_cm)

fig = figure('Theme', 'light', 'Units', 'centimeters', ...
    'Position', [2 2 largeur_cm hauteur_cm], 'Color', 'w');
set(fig, 'DefaultAxesFontSize', 9, 'DefaultTextFontSize', 9, ...
    'DefaultAxesBox', 'on', 'DefaultLineLineWidth', 1.2);
end
