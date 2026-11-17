%FIGURE_Q2_FILTRAGE  Q2 : un filtrage ajoute un biais g(k) qui ne dépend pas de la trame.
%   Prérequis : experiences/preparer_donnees.m (cache/signaux_base.mat).
%
%   Propriété (2) du sujet : si y = h * x avec h court devant la fenêtre
%   (Lh << N), alors S_y,dB[m,k] ≈ S_x,dB[m,k] + g(k), avec
%   g(k) = 20 log10 |ĥ(f_k)| indépendant de la trame m.
%
%   On filtre un extrait de 10 s :
%     (a) par le passe-bande 300–3400 Hz (Butterworth d'ordre 4, causal) :
%         réponse impulsionnelle de quelques millisecondes, Lh << N = 1024 ;
%     (b) par une réverbération de T60 = 1 s : Lh = 8000 échantillons > N,
%         hypothèse violée (« limite de (3) » du sujet).
%   On trace S_y,dB − S_x,dB en fonction de la fréquence pour 5 trames, et
%   20 log10 |ĥ(f_k)|. Si la propriété tient, les 5 courbes se superposent et
%   suivent |ĥ|. On mesure aussi la dispersion entre trames (écart-type sur m)
%   dans la bande 400–3000 Hz.
%
%   Produit : figures/difference_spectres_passe_bande (.pdf, .png),
%             resultats/q2_filtrage.csv

clear; close all;
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'src'), fullfile(racine, 'utils'), ...
    fullfile(racine, 'eval'), fullfile(racine, 'eval', 'degradations'));
load(fullfile(racine, 'cache', 'base.mat'), 'base');
load(fullfile(racine, 'cache', 'signaux_base.mat'), 'signauxBase');
P = parametres();

%% Extrait : 10 s du premier morceau Rock de la base (genre riche en énergie
% sur toute la bande 300–3400 Hz, pour que la différence y soit mesurable)
i0 = find(base.genre == "Rock", 1);
x = signauxBase{i0};
x = x(5*P.Fe + (1:10*P.Fe));

%% Filtrages
y_pb = filtre_passe_bande(x, P.Fe, 300, 3400, true);           % causal : y = h * x
[y_rv, h_rv] = reverberation(x, P.Fe, 1, RandStream('mt19937ar', 'Seed', 2));

% Réponse en fréquence du passe-bande (même filtre que filtre_passe_bande)
[z, p, k] = butter(4, [300 3400] / (P.Fe/2), 'bandpass');
[sos, g] = zp2sos(z, p, k);
[Hpb, f] = freqz(sos, P.K, P.Fe);  Hpb = g * Hpb;           % f_k = (k-1) Fe / Nfft
Hrv = freqz(h_rv, 1, P.K, P.Fe);
% reverberation normalise la puissance de sortie : on applique le même facteur
Hrv = Hrv * sqrt(mean(y_rv.^2) / mean(conv(x, h_rv, 'same').^2));

[Sx, ~, t] = calcul_spectrogramme(x, P);
Spb = calcul_spectrogramme(y_pb, P);
Srv = calcul_spectrogramme(y_rv, P);

%% 5 trames bien réparties parmi les plus énergiques dans la bande
dansBande = f >= 400 & f <= 3000;
energie = sum(10.^(Sx(dansBande, :) / 10), 1);
[~, ordre] = sort(energie, 'descend');
candidates = sort(ordre(1:round(numel(ordre) / 3)));
trames = candidates(round(linspace(1, numel(candidates), 5)));

Dpb = Spb(:, trames) - Sx(:, trames);
Drv = Srv(:, trames) - Sx(:, trames);
gpb = 20*log10(abs(Hpb) + eps);
grv = 20*log10(abs(Hrv) + eps);

% Dispersion entre trames dans la bande (sur toutes les trames, pas seulement 5)
ecart = @(S) median(std(S(dansBande, :) - Sx(dansBande, :), 0, 2));
erreur = @(S, gk) median(abs(median(S(dansBande, :) - Sx(dansBande, :), 2) - gk(dansBande)));
T = table(["passe-bande 300-3400 Hz"; "réverbération T60 = 1 s"], ...
    [ecart(Spb); ecart(Srv)], [erreur(Spb, gpb); erreur(Srv, grv)], ...
    'VariableNames', {'filtrage', 'ecart_type_entre_trames_dB', 'ecart_median_a_g_dB'});
writetable(T, fullfile(racine, 'resultats', 'q2_filtrage.csv'));
disp(T);

%% Figure
% (a) la mesure demandée par Q2 : 5 trames et g(k) pour le passe-bande ;
% (b) l'écart-type entre trames (toutes les trames) en fonction de la
%     fréquence : quasi nul pour le passe-bande, grand pour la réverbération.
pal = [0.00 0.45 0.74; 0.85 0.33 0.10; 0.13 0.55 0.13; 0.49 0.18 0.56; 0.60 0.40 0.20];
fig = nouvelle_figure(17, 7.5);
tl = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

ax = nexttile(tl);  hold(ax, 'on');
for j = 1:numel(trames)
    plot(ax, f / 1000, Dpb(:, j), '-', 'Color', pal(j, :), 'LineWidth', 1, ...
        'DisplayName', sprintf('trame à t = %.1f s', t(trames(j))));
end
plot(ax, f / 1000, gpb, 'k--', 'LineWidth', 1.6, 'DisplayName', 'g(k) = 20 log_{10}|ĥ(f_k)|');
xline(ax, [0.3 3.4], 'k:', 'HandleVisibility', 'off');
grid(ax, 'on');  xlim(ax, [0 4]);  ylim(ax, [-60 10]);
xlabel(ax, 'fréquence (kHz)');  ylabel(ax, 'S_{y,dB} − S_{x,dB} (dB)');
title(ax, '(a) passe-bande 300–3400 Hz, 5 trames', 'FontSize', 9);
legend(ax, 'Location', 'south', 'FontSize', 7);

ax = nexttile(tl);  hold(ax, 'on');
sdPb = std(Spb - Sx, 0, 2);
sdRv = std(Srv - Sx, 0, 2);
plot(ax, f / 1000, sdRv, '-', 'Color', pal(2, :), 'LineWidth', 1, ...
    'DisplayName', sprintf('réverbération T_{60} = 1 s (médiane %.1f dB)', T.ecart_type_entre_trames_dB(2)));
plot(ax, f / 1000, sdPb, '-', 'Color', pal(1, :), 'LineWidth', 1.4, ...
    'DisplayName', sprintf('passe-bande (médiane %.2f dB)', T.ecart_type_entre_trames_dB(1)));
xline(ax, [0.4 3], 'k:', 'HandleVisibility', 'off');
grid(ax, 'on');  xlim(ax, [0 4]);  ylim(ax, [0 15]);
xlabel(ax, 'fréquence (kHz)');  ylabel(ax, 'écart-type sur les trames (dB)');
title(ax, sprintf('(b) dispersion de S_{y,dB} − S_{x,dB} sur les %d trames', size(Sx, 2)), 'FontSize', 9);
legend(ax, 'Location', 'north', 'FontSize', 7);

title(tl, 'Propriété (2) : un filtrage court ajoute un biais g(k) indépendant de la trame', 'FontSize', 10);
sauver_figure(fig, 'difference_spectres_passe_bande');
