function sauver_figure(fig, nom, largeur_cm)
%SAUVER_FIGURE  Enregistre une figure dans figures/ en PDF (vectoriel) et PNG.
%   sauver_figure(fig, 'tbd_rsb')        ->  figures/tbd_rsb.pdf et figures/tbd_rsb.png
%   sauver_figure(fig, 'tbd_rsb', 8.8)   ->  idem, la figure ramenée à 8,8 cm de large
%
%   largeur_cm : largeur à laquelle la figure est imprimée dans le rapport. La
%   figure est redimensionnée (proportions conservées) avant l'export, mais pas
%   ses polices : le rapport l'insère sans réduction, et le texte des figures
%   reste à sa taille nominale (8-9 pt) au lieu d'être réduit avec l'image.

if nargin >= 3 && ~isempty(largeur_cm)
    fig.Units = 'centimeters';
    pos = fig.Position;
    fig.Position = [pos(1:2), largeur_cm, largeur_cm * pos(4) / pos(3)];
    drawnow;  pause(0.5);  drawnow;   % sinon l'export PDF peut partir avant la mise en page
end
racine = fileparts(fileparts(mfilename('fullpath')));
dossier = fullfile(racine, 'figures');
if ~exist(dossier, 'dir'), mkdir(dossier); end
exportgraphics(fig, fullfile(dossier, [nom '.pdf']), 'ContentType', 'vector');
exportgraphics(fig, fullfile(dossier, [nom '.png']), 'Resolution', 150);
end
