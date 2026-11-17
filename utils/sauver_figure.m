function sauver_figure(fig, nom)
%SAUVER_FIGURE  Enregistre une figure dans figures/ en PDF (vectoriel) et PNG.
%   sauver_figure(fig, 'tbd_rsb')  ->  figures/tbd_rsb.pdf et figures/tbd_rsb.png

racine = fileparts(fileparts(mfilename('fullpath')));
dossier = fullfile(racine, 'figures');
if ~exist(dossier, 'dir'), mkdir(dossier); end
exportgraphics(fig, fullfile(dossier, [nom '.pdf']), 'ContentType', 'vector');
exportgraphics(fig, fullfile(dossier, [nom '.png']), 'Resolution', 150);
end
