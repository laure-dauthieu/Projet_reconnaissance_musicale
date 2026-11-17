%CAMPAGNE_EVALUATION  TBD et TFD pour toutes les dégradations simulées (sujet §7).
%   Prérequis : experiences/preparer_donnees.m (cache/base.mat, cache/index_base.mat).
%
%   Requêtes :
%     - 2 extraits par morceau de la base, à des instants tirés au hasard :
%       200 requêtes positives (environ 25 par genre, pour Q6) ;
%     - 1 extrait par morceau hors base : 100 requêtes négatives, coupées en
%       deux moitiés. 50 servent à fixer le seuil (calibration), les 50 autres
%       à mesurer le TFD.
%   Un même extrait sert à toutes les conditions : seule la dégradation change.
%
%   Où s'applique chaque dégradation :
%     - MP3 : AVANT le passage à 8 kHz, sur le signal d'origine (44,1 kHz),
%       comme pour un vrai fichier. À 8 kHz, même 32 kbit/s serait presque
%       sans perte et la comparaison entre débits n'aurait pas de sens ;
%     - bruit (blanc, brouhaha), passe-bande, réverbération : APRÈS le passage
%       à 8 kHz. Un bruit blanc ajouté à 44,1 kHz s'étale jusqu'à 22 kHz ; le
%       passage à 8 kHz en retirerait environ 80 % (10 log10(22,05/4) = 7,4 dB),
%       et le RSB réel serait meilleur que le RSB annoncé.
%
%   Produit :
%     resultats/synthese.csv       TBD, TFD, confusions, non-détections par condition
%     resultats/campagne.mat       scores de toutes les requêtes
%     figures/ (via figures_campagne.m)

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
nParMorceau = 2;                                   % requêtes positives par morceau
nB = height(base);  nH = height(horsBase);
idVrai = [repelem((1:nB)', nParMorceau); zeros(nH, 1)];
source = [repelem((1:nB)', nParMorceau); nB + (1:nH)'];   % ligne dans [base; horsBase]
genre = [base.genre; horsBase.genre];
genre = genre(source);
n = numel(idVrai);
neg = find(idVrai == 0);
calib = false(n, 1);  calib(neg(1:2:end)) = true;  % une négative sur deux
chemins = [base.chemin; horsBase.chemin];
ext = cell(n, 1);  fe = zeros(n, 1);
tic;
for i = 1:n
    [x, fe(i)] = audioread(chemins(source(i)));
    ext{i} = single(extraire_requete(x, fe(i), TqMax, rs));
end
fprintf('%d extraits de %d s préparés en %.0f s\n', n, TqMax, toc);

%% Conditions du tableau du sujet
% avant = true : appliquée au signal d'origine, avant pretraitement (MP3 seulement).
C = struct('nom', {}, 'degradation', {}, 'param', {}, 'Tq', {}, 'avant', {}, 'f', {});
for Tq = [3 5 10]
    C(end+1) = cond('sans dégradation', 'aucune', NaN, Tq, false, @(y, fe) y); %#ok<SAGROW>
    for rsb = [20 15 10 5 0]
        C(end+1) = cond(sprintf('bruit blanc %d dB', rsb), 'bruit blanc', rsb, Tq, false, ...
            @(y, fe) ajouter_bruit(y, rsb, 'blanc', rs)); %#ok<SAGROW>
    end
end
for debit = [128 64 32]
    C(end+1) = cond(sprintf('MP3 %d kbit/s', debit), 'MP3', debit, 5, true, ...
        @(y, fe) degrader_mp3(y, fe, debit, P)); %#ok<SAGROW>
end
C(end+1) = cond('passe-bande 300-3400 Hz', 'passe-bande', NaN, 5, false, ...
    @(y, fe) filtre_passe_bande(y, fe, 300, 3400, true));
for T60 = [0.3 1]
    C(end+1) = cond(sprintf('réverbération T60 = %g s', T60), 'réverbération', T60, 5, false, ...
        @(y, fe) reverberation(y, fe, T60, rs)); %#ok<SAGROW>
end
fichierBrouhaha = fullfile(racine, 'data', 'enregistrements', 'brouhaha_cafet.wav');
if exist(fichierBrouhaha, 'file')
    [b, feB] = audioread(fichierBrouhaha);
    b = resample(mean(b, 2), P.Fe, feB);          % brouhaha ramené à 8 kHz une fois
    for rsb = [10 5 0]
        C(end+1) = cond(sprintf('brouhaha %d dB', rsb), 'brouhaha', rsb, 5, false, ...
            @(y, fe) ajouter_bruit(y, rsb, b, rs)); %#ok<SAGROW>
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
        if C(c).avant
            req(i).y = pretraitement(C(c).f(y, fe(i)), P, fe(i));
        else
            req(i).y = C(c).f(pretraitement(y, P, fe(i)), P.Fe);
        end
    end
    res = evaluer(INDEX, req, P);
    res.calib = calib;
    res.genre = genre;
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
C = rmfield(C, 'f');                               % les fonctions ne servent plus
save(fullfile(dossierRes, 'campagne.mat'), 'C', 'resultats', 's_thr', 'synthese', 'calib');
disp(synthese(:, {'condition', 'Tq', 'seuil', 'TBD', 'TFD', 'confusion', 'non_detection', 'N_pos', 'N_neg'}));

%% Figures (script séparé, relançable seul)
run(fullfile(racine, 'experiences', 'figures_campagne.m'));

function c = cond(nom, degradation, param, Tq, avant, f)
c = struct('nom', nom, 'degradation', degradation, 'param', param, 'Tq', Tq, ...
    'avant', avant, 'f', f);
end
