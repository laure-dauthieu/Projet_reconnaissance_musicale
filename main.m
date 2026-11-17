%MAIN  Chaîne « jouet » : 3 morceaux, une requête, vérification visuelle.
%   Indexe 3 morceaux, extrait Tq secondes de l'un d'eux à un instant tiré
%   au hasard, l'identifie, puis affiche :
%     1. le spectrogramme de la requête avec sa constellation ;
%     2. l'histogramme des δ pour le bon morceau et pour un autre ;
%     3. les scores de chaque morceau.
%   Jalon du sujet : l'histogramme des δ doit présenter un pic net.
%
%   Si data/fma_small existe, on prend 3 vrais morceaux ; sinon 3 morceaux
%   synthétiques (utils/morceau_synthetique).

clear; close all;
racine = fileparts(mfilename('fullpath'));
addpath(fullfile(racine, 'src'), fullfile(racine, 'utils'));
P = parametres();
rng(1);

%% Morceaux de référence (signaux à leur fréquence d'origine)
dossierFMA = fullfile(racine, 'data', 'fma_small');
fichiers = dir(fullfile(dossierFMA, '**', '*.mp3'));
nRef = 3;
ref = cell(nRef, 1);  Fe0 = zeros(nRef, 1);  noms = cell(nRef, 1);
if numel(fichiers) >= nRef
    choix = randperm(numel(fichiers), nRef);
    for i = 1:nRef
        f = fullfile(fichiers(choix(i)).folder, fichiers(choix(i)).name);
        [ref{i}, Fe0(i)] = audioread(f);
        noms{i} = fichiers(choix(i)).name;
    end
else
    for i = 1:nRef
        Fe0(i) = 44100;
        ref{i} = morceau_synthetique(30, Fe0(i), i);
        noms{i} = sprintf('synthétique %d', i);
    end
end

%% Phase 1 : indexation
tic;
refPre = cellfun(@(x, fe) pretraitement(x, P, fe), ref, num2cell(Fe0), 'UniformOutput', false);
INDEX = construire_index(refPre, P, noms);
fprintf('Index : %d entrées, %d clés distinctes, construit en %.2f s\n', ...
    numel(INDEX.cle), numel(INDEX.ucle), toc);

%% Requête : Tq secondes du morceau 2, à un instant quelconque
vrai = 2;
x0 = ref{vrai};  fe = Fe0(vrai);
nq = round(P.Tq * fe);
debut = randi(size(x0, 1) - nq);           % en échantillons d'origine : pas aligné sur H
y = x0(debut:debut + nq - 1, :);
yPre = pretraitement(y, P, fe);

tic;
R = identifier(yPre, INDEX, P);
tReq = toc;

t0 = (debut - 1) / fe;
fprintf('Requête : %.1f s extraites de « %s » à t0 = %.2f s\n', P.Tq, noms{vrai}, t0);
fprintf('Réponse : %s (score %d, seuil %d), position estimée %.2f s, en %.0f ms\n', ...
    ternaire(R.id > 0, noms{max(R.id,1)}, 'inconnu'), R.score, P.s_thr, ...
    R.delta * P.H / P.Fe, 1000 * tReq);
fprintf('Scores : %s\n', mat2str(R.scores'));

%% Figure 1 : spectrogramme + constellation de la requête
[~, f, t] = calcul_spectrogramme(yPre, P);
fig1 = figure('Name', 'Constellation', 'Position', [100 100 900 350], 'Theme', 'light');
imagesc(t, f / 1000, R.SdB); axis xy; colormap(flipud(gray)); hold on;
clim(max(R.SdB(:)) + [-80 0]);
plot(t(R.pics(:, 1)), f(R.pics(:, 2)) / 1000, 'r.', 'MarkerSize', 10);
xlabel('temps (s)'); ylabel('fréquence (kHz)');
title(sprintf('Requête : %d pics (%.1f pics/s)', size(R.pics, 1), size(R.pics, 1) / P.Tq));

%% Figure 2 : histogrammes des δ
autre = mod(vrai, nRef) + 1;
fig2 = figure('Name', 'Histogrammes des delta', 'Position', [100 500 900 300], 'Theme', 'light');
for j = 1:2
    c = [autre, vrai];  c = c(j);
    subplot(1, 2, j);
    d = R.app(R.app(:, 1) == c, 2);
    if isempty(d), d = 0; end
    histogram(d, 'BinMethod', 'integers', 'EdgeColor', 'none', 'FaceColor', 'k');
    xlabel('décalage \delta (trames)'); ylabel('appariements par case');
    title(sprintf('%s : score %d', noms{c}, R.scores(c)), 'Interpreter', 'none');
end

%% Sauvegarde
dossierFig = fullfile(racine, 'figures');
if ~exist(dossierFig, 'dir'), mkdir(dossierFig); end
exportgraphics(fig1, fullfile(dossierFig, 'jouet_constellation.png'), 'Resolution', 120);
exportgraphics(fig2, fullfile(dossierFig, 'jouet_histogramme_delta.png'), 'Resolution', 120);

function s = ternaire(c, a, b)
if c, s = a; else, s = b; end
end
