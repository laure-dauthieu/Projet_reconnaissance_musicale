%FIGURE_Q2_FILTRAGE  Vérification expérimentale de la propriété (2) du sujet (Q2).
%   Si y = h * x avec h court devant la fenêtre (L_h << N), alors
%       S_y,dB[m,k] - S_x,dB[m,k] ≈ g(k) = 20 log10 |ĥ(f_k)|,
%   et la différence ne dépend pas de la trame m.
%
%   On le vérifie sur un vrai morceau, pour deux réponses impulsionnelles :
%     (a) un passe-bande 300–3400 Hz (Butterworth d'ordre 4, réponse courte) :
%         les courbes de 5 trames doivent se superposer sur la courbe théorique ;
%     (b) une réverbération T60 = 1 s (8 000 échantillons >> N = 1 024) :
%         hors du domaine de validité de (2), les courbes doivent se séparer.
%
%   ATTENTION : filtre_passe_bande filtre par défaut avec filtfilt (aller-retour,
%   sans retard). Le filtre est donc appliqué deux fois : le gain réel est |H|²,
%   et la courbe théorique est 40 log10 |H(f)| et non 20 log10 |H(f)|.
%
%   Comme le prévoit le protocole, le filtrage est appliqué APRÈS le passage à
%   8 kHz (même chaîne que dans experiences/campagne_evaluation.m).
%
%   Utilisation : régler la variable « fichier » ci-dessous (ou la laisser vide
%   pour choisir le fichier dans une fenêtre), puis lancer le script.
%
%   Produit : figures/difference_spectres_passe_bande (.pdf, .png)
%             resultats/q2_filtrage.csv (chiffres pour le rapport)

clear; close all;
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'src'), fullfile(racine, 'utils'), ...
    fullfile(racine, 'eval'), fullfile(racine, 'eval', 'degradations'));
P = parametres();

%% Morceau analysé
fichier = '';   % ex. fullfile(racine, 'data', 'morceau.mp3') ; vide = fenêtre de choix
if isempty(fichier)
    [nomF, dossierF] = uigetfile({'*.mp3;*.wav;*.m4a;*.flac', 'Fichiers audio'}, ...
        'Choisir un morceau pour la figure Q2');
    if isequal(nomF, 0), error('figure_q2:annule', 'Aucun fichier choisi.'); end
    fichier = fullfile(dossierF, nomF);
end
x = pretraitement(fichier, P);          % mono, 8 kHz
fprintf('Morceau : %s (%.1f s)\n', fichier, numel(x) / P.Fe);

%% (a) Passe-bande 300–3400 Hz
f1 = 300; f2 = 3400;
y_pb = filtre_passe_bande(x, P.Fe, f1, f2);          % filtfilt : gain |H|²

[Sx, f, t] = calcul_spectrogramme(x, P);
Sy_pb = calcul_spectrogramme(y_pb, P);
D_pb = Sy_pb - Sx;                                    % K x M

% Courbe théorique, recalculée avec le même filtre que filtre_passe_bande
[z, p, k] = butter(4, [f1 f2] / (P.Fe/2), 'bandpass');
[sos, gsos] = zp2sos(z, p, k);
H = gsos * freqz(sos, f, P.Fe);
g_theo_pb = 40 * log10(abs(H) + eps);                 % filtfilt : 2 x 20 log10|H|

%% (b) Réverbération T60 = 1 s
rs = RandStream('mt19937ar', 'Seed', 2);
[y_rv, h] = reverberation(x, P.Fe, 1, rs);
Sy_rv = calcul_spectrogramme(y_rv, P);
D_rv = Sy_rv - Sx;
% Ce que prédirait (2) si elle s'appliquait : 20 log10|ĥ| (avec le facteur de
% normalisation de puissance appliqué par reverberation)
yr_brut = fftfilt(h, [x; zeros(numel(h), 1)]);
c = sqrt(mean(x.^2) / mean(yr_brut(1:numel(x)).^2));
g_theo_rv = 20 * log10(abs(c * freqz(h, 1, f, P.Fe)) + eps);

%% Choix de 5 trames : réparties dans le morceau, parmi les trames énergiques
energie = sum(10.^(Sx / 10), 1);
candidates = find(energie > median(energie));
candidates = candidates(candidates > 20 & candidates < numel(t) - 20);  % loin des bords
trames = candidates(round(linspace(1, numel(candidates), 5)));

%% Chiffres : dispersion entre trames dans la bande passante
dansBande = f >= 400 & f <= 3000;                     % loin des fréquences de coupure
% écart des 5 trames à la courbe théorique, et dispersion entre ces trames
ecart_pb = D_pb(dansBande, trames) - g_theo_pb(dansBande);
ecart_rv = D_rv(dansBande, trames) - g_theo_rv(dansBande);
disp_pb = std(D_pb(dansBande, trames), 0, 2);         % écart-type entre trames, par canal
disp_rv = std(D_rv(dansBande, trames), 0, 2);

res = table( ...
    ["passe-bande 300-3400 Hz"; "reverberation T60 = 1 s"], ...
    [median(abs(ecart_pb(:))); median(abs(ecart_rv(:)))], ...
    [quantile95(abs(ecart_pb(:))); quantile95(abs(ecart_rv(:)))], ...
    [median(disp_pb); median(disp_rv)], ...
    'VariableNames', {'degradation', 'ecart_median_dB', 'ecart_95pc_dB', ...
                      'dispersion_entre_trames_dB'});
disp(res);
fprintf('Trames utilisées : %s (instants %s s)\n', mat2str(trames), mat2str(round(t(trames)', 2)));
writetable(res, fullfile(racine, 'resultats', 'q2_filtrage.csv'));

%% Figure
fig = nouvelle_figure(17, 7.5);
tl = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
couleurs = lines(5);
fk = f / 1000;

ax = nexttile(tl); hold(ax, 'on');
for i = 1:5
    plot(ax, fk, D_pb(:, trames(i)), 'Color', couleurs(i, :), 'LineWidth', 0.7);
end
plot(ax, fk, g_theo_pb, 'k--', 'LineWidth', 1.6);
xline(ax, [f1 f2] / 1000, ':', 'Color', [0.4 0.4 0.4]);
ylim(ax, [-80 10]); xlim(ax, [0 4]);
xlabel(ax, 'fréquence (kHz)'); ylabel(ax, 'S_{y,dB} - S_{x,dB} (dB)');
title(ax, '(a) passe-bande 300–3400 Hz', 'FontWeight', 'normal');
legend(ax, [compose('trame %d', trames(:)); {'40 log_{10}|H(f)| (théorie)'}], ...
    'Location', 'south', 'FontSize', 7, 'NumColumns', 2);

ax = nexttile(tl); hold(ax, 'on');
for i = 1:5
    plot(ax, fk, D_rv(:, trames(i)), 'Color', couleurs(i, :), 'LineWidth', 0.7);
end
plot(ax, fk, g_theo_rv, 'k--', 'LineWidth', 1.2);
ylim(ax, [-40 40]); xlim(ax, [0 4]);
xlabel(ax, 'fréquence (kHz)'); ylabel(ax, 'S_{y,dB} - S_{x,dB} (dB)');
title(ax, '(b) réverbération T_{60} = 1 s', 'FontWeight', 'normal');

sauver_figure(fig, 'difference_spectres_passe_bande');
fprintf('Figure enregistrée : figures/difference_spectres_passe_bande.pdf\n');

%% Fonction locale
function q = quantile95(v)
%QUANTILE95  Quantile à 95 % sans Statistics Toolbox (prctile n'est pas installé).
v = sort(v(:));
q = v(max(1, ceil(0.95 * numel(v))));
end
