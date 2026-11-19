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
% Dynamique de couleur : de la médiane du spectrogramme à son maximum. Avec
% 80 dB, presque tout le plan paraissait blanc et les raies se perdaient.
[~, f, t] = calcul_spectrogramme(yPre, P);
fig1 = nouvelle_figure(17, 7);
imagesc(t, f / 1000, R.SdB);  axis xy;  hold on;
colormap(fig1, flipud(gray));
v = sort(R.SdB(:));  clim([v(round(0.25 * end)), v(round(0.995 * end))]);   % sans Stats Toolbox
cb = colorbar;  cb.Label.String = 'S_{dB} (dB)';
plot(t(R.pics(:, 1)), f(R.pics(:, 2)) / 1000, 'o', 'MarkerSize', 3.5, ...
    'MarkerFaceColor', [0.85 0.10 0.10], 'MarkerEdgeColor', 'w', 'LineWidth', 0.4);
yline(P.f_min / 1000, '--', 'Color', [0 0.45 0.74], 'LineWidth', 1.3);
xlabel('temps (s)');  ylabel('fréquence (kHz)');

%% Figure 2 : histogrammes des δ (autre morceau, bon morceau)
autre = mod(vrai, nRef) + 1;
fig2 = nouvelle_figure(17, 6.5);
tl = tiledlayout(fig2, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
lettres = {'(a) autre morceau', '(b) bon morceau'};
for j = 1:2
    c = [autre, vrai];  c = c(j);
    ax = nexttile(tl);  hold(ax, 'on');
    d = R.app(R.app(:, 1) == c, 2);
    if isempty(d), d = 0; end
    [n, ~, ic] = unique(d);  n = [n, accumarray(ic, 1)]; %#ok<ASGLU>
    stem(ax, n(:, 1), n(:, 2), 'Marker', 'none', 'Color', ternaire(j == 2, [0.85 0.33 0.10], [0 0.45 0.74]), ...
        'LineWidth', 1, 'ShowBaseLine', 'off');   % la ligne de base débordait du cadre à l'export
    grid(ax, 'on');  box(ax, 'on');
    xlabel(ax, 'décalage \delta = m_{réf} − m_{req} (trames)');  ylabel(ax, 'nombre d''appariements');
    title(ax, sprintf('%s : score %d', lettres{j}, R.scores(c)), 'FontSize', 9);
    if j == 1
        yticks(ax, 0:max(n(:, 2)));  ylim(ax, [0 max(n(:, 2)) + 0.5]);
    else
        [smax, im] = max(n(:, 2));
        text(ax, n(im, 1), smax, sprintf('  pic à \\delta = %d trames\n  (t_0 estimé = %.2f s)', ...
            n(im, 1), n(im, 1) * P.H / P.Fe), 'VerticalAlignment', 'top', 'FontSize', 8);
        ylim(ax, [0 smax * 1.08]);
    end
end

%% Sauvegarde (noms attendus par le rapport)
sauver_figure(fig1, 'constellation', 13);
sauver_figure(fig2, 'histogramme_delta', 13);

function s = ternaire(c, a, b)
if c, s = a; else, s = b; end
end
