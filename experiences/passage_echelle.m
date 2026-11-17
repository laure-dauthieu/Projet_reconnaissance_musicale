%PASSAGE_ECHELLE  Temps de requête et taille de l'index selon le nombre de morceaux.
%   Prérequis : experiences/preparer_donnees.m.
%
%   On indexe 10, 25, 50, 100, 200 puis 500 morceaux : les 100 morceaux de la
%   base, complétés par d'autres morceaux de fma_small (ni dans la base, ni
%   dans les morceaux hors base). Pour chaque taille, on mesure le temps de
%   construction, la taille de l'index et le temps médian de 50 requêtes de
%   5 s (extraits non dégradés de morceaux indexés).
%
%   Produit : resultats/passage_echelle.csv, figures/passage_echelle (.pdf, .png)

clear; close all;
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'src'), fullfile(racine, 'utils'), fullfile(racine, 'eval'));
P = parametres();
load(fullfile(racine, 'cache', 'base.mat'), 'base', 'horsBase');
load(fullfile(racine, 'cache', 'signaux_base.mat'), 'signauxBase');
rs = RandStream('mt19937ar', 'Seed', 11);
tailles = [10 25 50 100 200 500];

%% Morceaux supplémentaires de fma_small
fichiers = dir(fullfile(racine, 'data', 'fma_small', '**', '*.mp3'));
ids = str2double(erase({fichiers.name}, '.mp3'));
libres = find(~ismember(ids, [base.id; horsBase.id]));
libres = libres(randperm(rs, numel(libres)));
besoin = max(tailles) - height(base);
signauxSup = {};
tic;
for i = libres
    if numel(signauxSup) == besoin, break; end
    f = fullfile(fichiers(i).folder, fichiers(i).name);
    try
        x = pretraitement(f, P);
        if numel(x) >= 25 * P.Fe
            signauxSup{end+1, 1} = x; %#ok<SAGROW>
        end
    catch
        % fichier illisible : on passe au suivant
    end
end
fprintf('%d morceaux supplémentaires prétraités en %.0f s\n', numel(signauxSup), toc);
signaux = [signauxBase; signauxSup];

%% Requêtes : 50 extraits de 5 s, pris dans les 10 premiers morceaux
% (présents dans tous les index, quelle que soit leur taille)
nReq = 50;
Tq = 5;
idReq = randi(rs, min(tailles), nReq, 1);
requetes = cell(nReq, 1);
for j = 1:nReq
    x = signaux{idReq(j)};
    d = randi(rs, numel(x) - Tq * P.Fe);
    requetes{j} = x(d + 1:d + Tq * P.Fe);
end

%% Mesures
nT = numel(tailles);
nEntrees = zeros(nT, 1);  tailleMo = zeros(nT, 1);
tConstruction = zeros(nT, 1);  tRequeteMs = zeros(nT, 1);
for t = 1:nT
    n = tailles(t);
    tic;
    INDEX = construire_index(signaux(1:n), P);
    tConstruction(t) = toc;
    info = whos('INDEX');
    tailleMo(t) = info.bytes / 2^20;
    nEntrees(t) = numel(INDEX.cle);
    identifier(requetes{1}, INDEX, P);          % requête de chauffe, non chronométrée
    tps = zeros(nReq, 1);
    for j = 1:nReq
        tt = tic;
        identifier(requetes{j}, INDEX, P);
        tps(j) = toc(tt);
    end
    tRequeteMs(t) = 1000 * median(tps);
    fprintf('%4d morceaux : %8d entrées, %6.1f Mo, construction %5.1f s, requête %5.1f ms\n', ...
        n, nEntrees(t), tailleMo(t), tConstruction(t), tRequeteMs(t));
end
T = table(tailles', nEntrees, tailleMo, tConstruction, tRequeteMs, 'VariableNames', ...
    {'n_morceaux', 'n_entrees', 'taille_Mo', 'construction_s', 'requete_mediane_ms'});
writetable(T, fullfile(racine, 'resultats', 'passage_echelle.csv'));

%% Figure
fig = nouvelle_figure(16, 7);
subplot(1, 2, 1);
plot(tailles, tRequeteMs, 'o-');  set(gca, 'XScale', 'log');  grid on;
xticks(tailles);  ylim([0 max(tRequeteMs) * 1.3]);
xlabel('nombre de morceaux indexés');  ylabel('temps médian de requête (ms)');
title(sprintf('Requêtes de %d s', Tq));
subplot(1, 2, 2);
plot(tailles, tailleMo, 's-');  set(gca, 'XScale', 'log', 'YScale', 'log');  grid on;
xticks(tailles);
xlabel('nombre de morceaux indexés');  ylabel('taille de l''index (Mo)');
title('Taille de l''index');
sauver_figure(fig, 'passage_echelle');
