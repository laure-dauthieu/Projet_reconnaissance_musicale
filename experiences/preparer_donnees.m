%PREPARER_DONNEES  Choix des morceaux, indexation de la base, listes pour B.
%   À lancer une fois, après avoir dézippé fma_small et fma_metadata dans data/.
%
%   Produit :
%     liste_morceaux.csv                       morceaux utilisés (livrable du zip)
%     cache/base.mat                           tables base / horsBase
%     cache/signaux_base.mat, signaux_hors.mat signaux prétraités à 8 kHz
%     cache/index_base.mat                     index inversé des 100 morceaux
%     resultats/morceaux_a_enregistrer.csv     morceaux à jouer en salle (B)
%     data/a_enregistrer/                      copie de ces fichiers, pour le Drive

clear;
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'src'), fullfile(racine, 'eval'));
P = parametres();
dossierData = fullfile(racine, 'data');
dossierCache = fullfile(racine, 'cache');
if ~exist(dossierCache, 'dir'), mkdir(dossierCache); end

nBase = 100;          % sujet : au moins 100 morceaux
nHors = 100;          % pour au moins 50 requêtes négatives
graine = 2026;

%% Choix des morceaux
tic;
[base, horsBase] = preparer_base(dossierData, nBase, nHors, graine);
fprintf('Base : %d morceaux, hors base : %d morceaux (%.1f s)\n', height(base), height(horsBase), toc);
disp(groupcounts(base, 'genre'));

liste = [base; horsBase];
writetable(removevars(liste, 'chemin'), fullfile(racine, 'liste_morceaux.csv'));
save(fullfile(dossierCache, 'base.mat'), 'base', 'horsBase');

%% Signaux prétraités (on ne décode chaque MP3 qu'une fois)
tic;
signauxBase = cellfun(@(f) pretraitement(f, P), cellstr(base.chemin), 'UniformOutput', false);
signauxHors = cellfun(@(f) pretraitement(f, P), cellstr(horsBase.chemin), 'UniformOutput', false);
fprintf('Décodage et prétraitement de %d fichiers : %.1f s\n', height(liste), toc);
save(fullfile(dossierCache, 'signaux_base.mat'), 'signauxBase');
save(fullfile(dossierCache, 'signaux_hors.mat'), 'signauxHors');

%% Index de la base
tic;
noms = cellstr(base.artiste + " – " + base.titre);
INDEX = construire_index(signauxBase, P, noms);
info = whos('INDEX');
fprintf('Index : %d entrées, %d clés distinctes, %.1f Mo, construit en %.1f s\n', ...
    numel(INDEX.cle), numel(INDEX.ucle), info.bytes / 2^20, toc);
save(fullfile(dossierCache, 'index_base.mat'), 'INDEX');

%% Morceaux à enregistrer en salle (B) : 20 de la base, 10 hors base
rs = RandStream('mt19937ar', 'Seed', graine);
aEnr = [base(randperm(rs, height(base), 20), :); horsBase(randperm(rs, height(horsBase), 10), :)];
dossierRes = fullfile(racine, 'resultats');
if ~exist(dossierRes, 'dir'), mkdir(dossierRes); end
writetable(removevars(aEnr, 'chemin'), fullfile(dossierRes, 'morceaux_a_enregistrer.csv'));
dossierCopie = fullfile(dossierData, 'a_enregistrer');
if ~exist(dossierCopie, 'dir'), mkdir(dossierCopie); end
for i = 1:height(aEnr)
    copyfile(aEnr.chemin(i), dossierCopie);
end
fprintf('%d morceaux copiés dans data/a_enregistrer pour les enregistrements en salle\n', height(aEnr));
