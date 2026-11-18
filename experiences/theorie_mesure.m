%THEORIE_MESURE  Score prévu par la théorie contre score mesuré, selon le RSB.
%   Prérequis : experiences/preparer_donnees.m (cache/).
%
%   Le sujet prévoit, pour le bon morceau, s ≈ (nombre de clés de la requête) x p²
%   (s ≈ F ρ Tq p²) : une clé est retrouvée si ses deux pics survivent. On
%   mesure p, on en déduit le score prévu, et on le compare :
%     - au score mesuré du bon morceau (médiane sur 200 requêtes) ;
%     - au seuil s_thr : la théorie prévoit l'échec quand le score prévu passe
%       sous s_thr, c'est-à-dire au RSB où le TBD doit tomber vers 50 %.
%
%   Deux p sont mesurés :
%     p_bruit : extrait aligné, seul le bruit déplace des pics ;
%     p_eff   : extrait pris à un instant quelconque, comparé aux pics du
%               morceau de référence. S'y ajoute l'effet de la grille de trames
%               (propriété (1) seulement approchée) : c'est le p qui compte.
%   Requêtes : bruit blanc ajouté à 8 kHz, RSB de 20 à -10 dB, Tq = 3, 5, 10 s.
%
%   Produit : resultats/theorie_mesure.csv, resultats/theorie_mesure_rupture.csv,
%             figures/theorie_mesure (.pdf, .png)

clear; close all;
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'src'), fullfile(racine, 'utils'), ...
    fullfile(racine, 'eval'), fullfile(racine, 'eval', 'degradations'));
load(fullfile(racine, 'cache', 'signaux_base.mat'), 'signauxBase');
load(fullfile(racine, 'cache', 'index_base.mat'), 'INDEX');
P = parametres();
rs = RandStream('mt19937ar', 'Seed', 9);
RSBs = [Inf 20 15 10 5 0 -5 -10];
Tqs = [3 5 10];
nParMorceau = 2;
nB = numel(signauxBase);

% Pics de référence de chaque morceau entier (sur sa propre grille de trames)
picsRef = cell(nB, 1);
for j = 1:nB
    picsRef{j} = detection_pics(calcul_spectrogramme(signauxBase{j}, P), P);
end

%% Mesures
L = [];
for Tq = Tqs
    nq = Tq * P.Fe;
    for rsb = RSBs
        nAppPics = 0;  nAppRef = 0;  nSurvBruit = 0;  nPicsPropres = 0;
        score = zeros(nB * nParMorceau, 1);  bon = false(size(score));  nCles = score;
        q = 0;
        for j = 1:nB
            x = signauxBase{j};
            for r = 1:nParMorceau
                q = q + 1;
                d = randi(rs, numel(x) - nq + 1);           % pas forcément sur la grille
                propre = x(d:d + nq - 1);
                if isfinite(rsb)
                    y = ajouter_bruit(propre, rsb, 'blanc', rs);
                else
                    y = propre;
                end
                R = identifier(y, INDEX, P);
                score(q) = R.scores(j);
                bon(q) = R.id_max == j && R.score >= P.s_thr;
                [Ep, pp] = empreintes_signal(propre, P);
                nCles(q) = size(Ep, 1);
                % p_bruit : même extrait, aligné
                nPicsPropres = nPicsPropres + size(pp, 1);
                nSurvBruit = nSurvBruit + sum(ismember(pp, R.pics, 'rows'));
                % p_eff : pics du morceau dans la durée de l'extrait, retrouvés
                % dans la requête au meilleur des deux décalages entiers voisins
                m0s = floor((d - 1) / P.H) + [0 1];
                M = size(R.SdB, 2);
                best = 0;  nRefSpan = 0;
                for m0 = m0s
                    dansSpan = picsRef{j}(:, 1) > m0 & picsRef{j}(:, 1) <= m0 + M;
                    ref = picsRef{j}(dansSpan, :);
                    ref(:, 1) = ref(:, 1) - m0;
                    nm = sum(ismember(ref, R.pics, 'rows'));
                    if nm >= best, best = nm; nRefSpan = size(ref, 1); end
                end
                nAppPics = nAppPics + best;
                nAppRef = nAppRef + nRefSpan;
            end
        end
        pEff = nAppPics / nAppRef;
        pBruit = nSurvBruit / nPicsPropres;
        L = [L; Tq, rsb, pBruit, pEff, median(nCles), median(nCles) * pEff^2, ...
            median(score), mean(bon)]; %#ok<AGROW>
        fprintf('Tq = %2d s, RSB = %4g dB : p_bruit %.2f, p_eff %.2f, score prévu %5.0f, mesuré %5.0f, TBD %5.1f %%\n', ...
            Tq, rsb, pBruit, pEff, median(nCles) * pEff^2, median(score), 100 * mean(bon));
    end
end
T = array2table(L, 'VariableNames', {'Tq', 'RSB', 'p_bruit', 'p_eff', 'nq', ...
    'score_prevu', 'score_mesure_median', 'TBD'});
writetable(T, fullfile(racine, 'resultats', 'theorie_mesure.csv'));

%% RSB de rupture : prévu (score prévu = s_thr) et mesuré (TBD = 50 %)
finis = isfinite(RSBs);
rupture = zeros(numel(Tqs), 3);
for t = 1:numel(Tqs)
    s = T(T.Tq == Tqs(t) & isfinite(T.RSB), :);
    rupture(t, :) = [Tqs(t), croisement(s.RSB, log(s.score_prevu), log(P.s_thr)), ...
        croisement(s.RSB, s.TBD, 0.5)];
end
TR = array2table(rupture, 'VariableNames', {'Tq', 'RSB_rupture_prevu', 'RSB_TBD50_mesure'});
writetable(TR, fullfile(racine, 'resultats', 'theorie_mesure_rupture.csv'));
disp(TR);

%% Figure
pal = [0.00 0.45 0.74; 0.85 0.33 0.10; 0.13 0.55 0.13];
x = RSBs(finis);
fig = nouvelle_figure(17, 7.5);
tl = tiledlayout(fig, 1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

ax = nexttile(tl);  hold(ax, 'on');
s = T(T.Tq == 5 & isfinite(T.RSB), :);
plot(ax, s.RSB, s.p_bruit, 's--', 'Color', [0.4 0.4 0.4], 'LineWidth', 1.4, ...
    'DisplayName', 'p_{bruit} (aligné)');
plot(ax, s.RSB, s.p_eff, 'ko-', 'LineWidth', 1.6, 'MarkerFaceColor', 'k', ...
    'DisplayName', 'p_{eff}');
set(ax, 'XDir', 'reverse');  xticks(ax, -10:10:20);  xtickangle(ax, 0);  ylim(ax, [0 1]);  grid(ax, 'on');
xlabel(ax, 'RSB (dB)');  ylabel(ax, 'p');  title(ax, '(a) survie des pics (T_q = 5 s)');
legend(ax, 'Location', 'northeast', 'FontSize', 7);

ax = nexttile(tl);  hold(ax, 'on');
for t = 1:numel(Tqs)
    s = T(T.Tq == Tqs(t) & isfinite(T.RSB), :);
    plot(ax, s.RSB, s.score_mesure_median, 'o-', 'Color', pal(t, :), 'LineWidth', 1.4, ...
        'MarkerFaceColor', pal(t, :), 'HandleVisibility', 'off');
    plot(ax, s.RSB, s.score_prevu, '--', 'Color', pal(t, :), 'LineWidth', 1.4, ...
        'HandleVisibility', 'off');
end
% Légende de style seulement : les couleurs (Tq) sont celles du panneau (c)
plot(ax, NaN, NaN, 'ko-', 'MarkerFaceColor', 'k', 'LineWidth', 1.4, 'DisplayName', 'mesuré');
plot(ax, NaN, NaN, 'k--', 'LineWidth', 1.4, 'DisplayName', 'prévu n_q p_{eff}^2');
yline(ax, P.s_thr, 'k:', sprintf('s_{thr} = %d', P.s_thr), 'LineWidth', 1.2, ...
    'HandleVisibility', 'off', 'LabelHorizontalAlignment', 'left', ...
    'LabelVerticalAlignment', 'bottom');
set(ax, 'XDir', 'reverse', 'YScale', 'log', 'YMinorGrid', 'off');  xticks(ax, -10:10:20);  xtickangle(ax, 0);  grid(ax, 'on');
xlabel(ax, 'RSB (dB)');  ylabel(ax, 'score du bon morceau (médiane)');
title(ax, '(b) score prévu et mesuré');
legend(ax, 'Location', 'southwest', 'FontSize', 7);

ax = nexttile(tl);  hold(ax, 'on');
for t = 1:numel(Tqs)
    s = T(T.Tq == Tqs(t) & isfinite(T.RSB), :);
    plot(ax, s.RSB, 100 * s.TBD, 'o-', 'Color', pal(t, :), 'LineWidth', 1.4, ...
        'DisplayName', sprintf('T_q = %d s', Tqs(t)));
    if ~isnan(rupture(t, 2))
        xline(ax, rupture(t, 2), '--', 'Color', pal(t, :), 'LineWidth', 1.2, 'HandleVisibility', 'off');
    end
end
yline(ax, 50, 'k:', 'HandleVisibility', 'off');
set(ax, 'XDir', 'reverse');  xticks(ax, -10:10:20);  xtickangle(ax, 0);  ylim(ax, [0 101.5]);  grid(ax, 'on');
xlabel(ax, 'RSB (dB)');  ylabel(ax, 'TBD (%)');
title(ax, '(c) TBD mesuré et rupture prévue (- -)');
legend(ax, 'Location', 'southwest', 'FontSize', 7);

title(tl, sprintf('Théorie confrontée à la mesure : bruit blanc, %d requêtes par point, s_{thr} = %d', ...
    nB * nParMorceau, P.s_thr), 'FontSize', 10);
sauver_figure(fig, 'theorie_mesure');

function xc = croisement(x, y, niveau)
% Premier x (en parcourant les RSB décroissants) où y passe sous niveau,
% par interpolation linéaire. NaN si y ne passe jamais sous niveau.
[x, o] = sort(x, 'descend');  y = y(o);
xc = NaN;
for i = 1:numel(x) - 1
    if y(i) >= niveau && y(i+1) < niveau
        xc = x(i) + (niveau - y(i)) * (x(i+1) - x(i)) / (y(i+1) - y(i));
        return;
    end
end
end
