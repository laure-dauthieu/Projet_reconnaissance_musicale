function res = evaluer(INDEX, requetes, P)
%EVALUER  Étape d'évaluation : identifie toutes les requêtes d'un coup.
%   res = evaluer(INDEX, requetes, P)
%   res = evaluer(INDEX, requetes)    avec les réglages de l'index (INDEX.P)
%   evaluer()                         démo sur des morceaux synthétiques
%
%   requetes(i).y        signal prétraité ; requetes(i).id_vrai : morceau
%                        d'origine, 0 pour une requête négative
%   res                  table id_vrai, id_max, score, temps (une ligne par requête)
%
%   Le seuil n'est pas appliqué ici : taux_detection(res, s_thr) donne TBD et
%   TFD pour n'importe quel seuil sans tout relancer.

if nargin == 0
    res = demo();
    return;
end
if nargin < 3 || isempty(P)
    if isfield(INDEX, 'P')
        P = INDEX.P;
    else
        P = parametres_par_defaut();
    end
end

n = numel(requetes);
id_vrai = zeros(n, 1);
id_max = zeros(n, 1);
score = zeros(n, 1);
temps = zeros(n, 1);
for i = 1:n
    t = tic;
    R = identifier(requetes(i).y, INDEX, P);
    temps(i) = toc(t);
    id_vrai(i) = requetes(i).id_vrai;
    id_max(i) = R.id_max;
    score(i) = R.score;
end
res = table(id_vrai, id_max, score, temps);
end

function res = demo()
% Démo : 5 morceaux indexés, 10 requêtes positives, 10 négatives
% (5 pour fixer le seuil, 5 pour mesurer le TFD).
P = parametres_par_defaut();
rs = RandStream('mt19937ar', 'Seed', 1);
morceaux = arrayfun(@(g) morceau_synthetique(30, P.Fe, g), 1:5, 'UniformOutput', false);
INDEX = construire_index(morceaux, P);

requetes = struct('y', {}, 'id_vrai', {});
for i = 1:5
    for r = 1:2
        requetes(end + 1) = struct('y', extraire_requete(morceaux{i}, P.Fe, P.Tq, rs), 'id_vrai', i); %#ok<AGROW>
    end
end
for g = 101:110
    requetes(end + 1) = struct('y', morceau_synthetique(P.Tq, P.Fe, g), 'id_vrai', 0); %#ok<AGROW>
end
res = evaluer(INDEX, requetes, P);

neg = find(res.id_vrai == 0);
calib = neg(1:5);
s_thr = calibrer_seuil(res.score(calib));
test = res([find(res.id_vrai > 0); neg(6:end)], :);
T = taux_detection(test, s_thr);
fprintf(['evaluer : %d requêtes (%d positives, %d négatives) ; seuil calibré sur 5 négatives : ' ...
    's_thr = %d.\n'], height(res), sum(res.id_vrai > 0), numel(neg), s_thr);
fprintf('  TBD = %.0f %%, TFD = %.0f %% (5 négatives de test), confusions = %.0f %%.\n', ...
    100 * T.TBD, 100 * T.TFD, 100 * T.confusion);
end

function P = parametres_par_defaut()
% Ajoute le projet au chemin MATLAB et renvoie les paramètres de départ.
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'src'), fullfile(racine, 'utils'), fullfile(racine, 'eval'));
P = parametres();
end
