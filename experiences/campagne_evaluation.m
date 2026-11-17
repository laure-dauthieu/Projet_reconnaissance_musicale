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
%     figures/tbd_rsb, tbd_mp3, tbd_tfd, histo_scores, via figures_campagne.m

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

%% Figures (script séparé, relançable seul)
run(fullfile(racine, 'experiences', 'figures_campagne.m'));


function c = cond(nom, degradation, param, Tq, f)
c = struct('nom', nom, 'degradation', degradation, 'param', param, 'Tq', Tq, 'f', f);
end
