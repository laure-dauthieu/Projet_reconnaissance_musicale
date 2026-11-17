%CAMPAGNE_EVALUATION  TBD et TFD pour toutes les dégradations simulées (sujet §7).
%   Prérequis : experiences/preparer_donnees.m (cache/base.mat, cache/index_base.mat).
%
%   Requêtes : 1 extrait par morceau de la base (100 positives) et par morceau
%   hors base (100 négatives), à un instant tiré au hasard. Les négatives sont
%   coupées en deux moitiés : 50 servent à fixer le seuil (calibration), les
%   50 autres à mesurer le TFD. Un même extrait sert à toutes les conditions,
%   pour que seules les dégradations changent d'une condition à l'autre.
%
%   Produit :
%     resultats/synthese.csv       TBD, TFD, confusions, non-détections par condition
%     resultats/campagne.mat       scores de toutes les requêtes
%     figures/tbd_rsb, tbd_mp3, tbd_tfd, histo_scores (.pdf et .png)

clear; close all;
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'src'), fullfile(racine, 'utils'), ...
    fullfile(racine, 'eval'), fullfile(racine, 'eval', 'degradations'));
P = parametres();
load(fullfile(racine, 'cache', 'base.mat'), 'base', 'horsBase');
load(fullfile(racine, 'cache', 'index_base.mat'), 'INDEX');
rs = RandStream('mt19937ar', 'Seed', 7);

%% Extraits de 10 s à la fréquence d'origine (les requêtes de 3 et 5 s en sont le début)
TqMax = 10;
chemins = [base.chemin; horsBase.chemin];
nB = height(base);  nH = height(horsBase);  n = nB + nH;
idVrai = [(1:nB)'; zeros(nH, 1)];
calib = false(n, 1);  calib(nB + (1:2:nH)) = true;     % une négative sur deux
ext = cell(n, 1);  fe = zeros(n, 1);
tic;
for i = 1:n
    [x, fe(i)] = audioread(chemins(i));
    ext{i} = single(extraire_requete(x, fe(i), TqMax, rs));
end
fprintf('%d extraits de %d s préparés en %.0f s\n', n, TqMax, toc);

%% Conditions du tableau du sujet
C = struct('nom', {}, 'degradation', {}, 'param', {}, 'Tq', {}, 'f', {});
for Tq = [3 5 10]
    C(end+1) = cond('sans dégradation', 'aucune', NaN, Tq, @(y, fe) y); %#ok<SAGROW>
    for rsb = [20 15 10 5 0]
        C(end+1) = cond(sprintf('bruit blanc %d dB', rsb), 'bruit blanc', rsb, Tq, ...
            @(y, fe) ajouter_bruit(y, rsb, 'blanc', rs)); %#ok<SAGROW>
    end
end
for debit = [128 64 32]
    C(end+1) = cond(sprintf('MP3 %d kbit/s', debit), 'MP3', debit, 5, ...
        @(y, fe) degrader_mp3(y, fe, debit, P)); %#ok<SAGROW>
end
C(end+1) = cond('passe-bande 300-3400 Hz', 'passe-bande', NaN, 5, ...
    @(y, fe) filtre_passe_bande(y, fe, 300, 3400, true));
for T60 = [0.3 1]
    C(end+1) = cond(sprintf('réverbération T60 = %g s', T60), 'réverbération', T60, 5, ...
        @(y, fe) reverberation(y, fe, T60, rs)); %#ok<SAGROW>
end
fichierBrouhaha = fullfile(racine, 'data', 'enregistrements', 'brouhaha_cafet.wav');
if exist(fichierBrouhaha, 'file')
    [b, feB] = audioread(fichierBrouhaha);
    b = mean(b, 2);
    for rsb = [10 5 0]
        C(end+1) = cond(sprintf('brouhaha %d dB', rsb), 'brouhaha', rsb, 5, ...
            @(y, fe) ajouter_bruit(y, rsb, resample(b, fe, feB), rs)); %#ok<SAGROW>
    end
else
    fprintf('Pas de brouhaha (%s) : conditions « bruit réel » ignorées.\n', fichierBrouhaha);
end

%% Identification de toutes les requêtes, condition par condition
resultats = cell(numel(C), 1);
for c = 1:numel(C)
    tic;
    req = struct('y', cell(n, 1), 'id_vrai', num2cell(idVrai));
    for i = 1:n
        y = double(ext{i}(1:round(C(c).Tq * fe(i))));
        req(i).y = pretraitement(C(c).f(y, fe(i)), P, fe(i));
    end
    res = evaluer(INDEX, req, P);
    res.calib = calib;
    resultats{c} = res;
    fprintf('%-28s Tq = %2d s : %.0f s\n', C(c).nom, C(c).Tq, toc);
end

%% Seuil : calibré sur les négatives de calibration, toutes conditions confondues
scoresCalib = cell2mat(cellfun(@(r) r.score(r.calib), resultats, 'UniformOutput', false));
s_thr = calibrer_seuil(scoresCalib);
fprintf('\nScore max d''une négative de calibration : %d  ->  seuil s_thr = %d\n', ...
    max(scoresCalib), s_thr);

%% Synthèse (TFD mesuré sur les 50 négatives de test uniquement)
lignes = cell(numel(C), 1);
for c = 1:numel(C)
    r = resultats{c};
    T = taux_detection(r(~r.calib, :), s_thr);
    lignes{c} = [table(string(C(c).nom), string(C(c).degradation), C(c).param, C(c).Tq, ...
        median(r.temps) * 1000, 'VariableNames', ...
        {'condition', 'degradation', 'parametre', 'Tq', 'temps_median_ms'}), T];
end
synthese = vertcat(lignes{:});
dossierRes = fullfile(racine, 'resultats');
writetable(synthese, fullfile(dossierRes, 'synthese.csv'));
save(fullfile(dossierRes, 'campagne.mat'), 'C', 'resultats', 's_thr', 'synthese', 'calib');
disp(synthese(:, {'condition', 'Tq', 'seuil', 'TBD', 'TFD', 'confusion', 'non_detection', 'N_pos', 'N_neg'}));

%% Figure 1 : TBD en fonction du RSB, une courbe par Tq
fig = nouvelle_figure(12, 8);  hold on;
marq = {'o-', 's-', '^-'};  Tqs = [3 5 10];
for j = 1:3
    sel = synthese.degradation == "bruit blanc" & synthese.Tq == Tqs(j);
    plot(synthese.parametre(sel), 100 * synthese.TBD(sel), marq{j}, ...
        'DisplayName', sprintf('T_q = %d s', Tqs(j)));
end
set(gca, 'XDir', 'reverse');  xticks(0:5:20);  ylim([50 100]);  grid on;
xlabel('RSB (dB)');  ylabel('TBD (%)');
legend('Location', 'southwest');
title(sprintf('Bruit blanc additif, s_{thr} = %d, N^+ = %d', s_thr, nB));
sauver_figure(fig, 'tbd_rsb');

%% Figure 2 : TBD en fonction du débit MP3
fig = nouvelle_figure(12, 8);  hold on;
sel = synthese.degradation == "MP3";
plot(synthese.parametre(sel), 100 * synthese.TBD(sel), 'o-', 'DisplayName', 'MP3');
ref = synthese.degradation == "aucune" & synthese.Tq == 5;
yline(100 * synthese.TBD(ref), '--', 'DisplayName', 'sans dégradation');
set(gca, 'XScale', 'log');  xticks([32 64 128]);  xlim([25 160]);  ylim([50 100]);  grid on;
legend('Location', 'southeast');
xlabel('débit MP3 (kbit/s)');  ylabel('TBD (%)');
title(sprintf('Codage MP3, T_q = 5 s, s_{thr} = %d', s_thr));
sauver_figure(fig, 'tbd_mp3');

%% Figure 3 : TBD en fonction du TFD en balayant le seuil (Tq = 5 s)
fig = nouvelle_figure(12, 9);  hold on;
choix = {'sans dégradation', 'bruit blanc 10 dB', 'bruit blanc 0 dB', 'MP3 32 kbit/s', ...
    'passe-bande 300-3400 Hz', 'réverbération T60 = 1 s'};
seuils = 0:max(cellfun(@(r) max(r.score), resultats)) + 1;
for k = 1:numel(choix)
    c = find(strcmp({C.nom}, choix{k}) & [C.Tq] == 5);
    r = resultats{c};
    T = taux_detection(r(~r.calib, :), seuils);
    plot(100 * T.TFD, 100 * T.TBD, '-', 'DisplayName', choix{k});
end
c = find(strcmp({C.nom}, 'sans dégradation') & [C.Tq] == 5);
Tsel = taux_detection(resultats{c}(~resultats{c}.calib, :), s_thr);
plot(100 * Tsel.TFD, 100 * Tsel.TBD, 'ko', 'MarkerSize', 8, 'DisplayName', ...
    sprintf('seuil retenu s_{thr} = %d', s_thr));
grid on;  xlim([0 50]);  ylim([50 100]);
xlabel('TFD (%)');  ylabel('TBD (%)');
legend('Location', 'southeast');
title('Balayage du seuil, T_q = 5 s');
sauver_figure(fig, 'tbd_tfd');

%% Figure 4 : histogrammes des scores positifs et négatifs (Tq = 5 s, abscisse log)
cs = find([C.Tq] == 5);
sPos = [];  sNeg = [];
for c = cs
    r = resultats{c};
    sPos = [sPos; r.score(r.id_vrai > 0)]; %#ok<AGROW>
    sNeg = [sNeg; r.score(r.id_vrai == 0)]; %#ok<AGROW>
end
fig = nouvelle_figure(14, 8);  hold on;
bords = logspace(0, log10(max(sPos) + 1), 40);
histogram(max(sNeg, 1), bords, 'FaceAlpha', 0.6, 'DisplayName', ...
    sprintf('requêtes négatives (%d)', numel(sNeg)));
histogram(max(sPos, 1), bords, 'FaceAlpha', 0.6, 'DisplayName', ...
    sprintf('requêtes positives (%d)', numel(sPos)));
xline(s_thr, 'k--', sprintf('s_{thr} = %d', s_thr), 'LineWidth', 1.2, 'HandleVisibility', 'off');
set(gca, 'XScale', 'log');  grid on;
xlabel('score s (hauteur du pic de l''histogramme des \delta)');  ylabel('nombre de requêtes');
legend('Location', 'northwest');
title('Scores, T_q = 5 s, toutes dégradations');
sauver_figure(fig, 'histo_scores');

function c = cond(nom, degradation, param, Tq, f)
c = struct('nom', nom, 'degradation', degradation, 'param', param, 'Tq', Tq, 'f', f);
end
