%EVALUER_ENREGISTREMENTS  TBD et TFD sur les enregistrements au micro en salle.
%   Prérequis : experiences/preparer_donnees.m (cache/index_base.mat) et les
%   prises de experiences/enregistrer_salle.m dans data/enregistrements/.
%
%   Chaque prise micro_<id>_<distance>.wav est une requête : prétraitement,
%   identification avec l'index des 100 morceaux et le seuil retenu P.s_thr.
%   Requête positive si le morceau est dans la base, négative sinon.
%   On évalue la prise entière, puis ses 5 premières secondes (Tq = 5 s,
%   comme dans la campagne).
%
%   Produit : resultats/enregistrements.csv (une ligne par prise)
%             resultats/enregistrements_synthese.csv (TBD, TFD par distance et Tq)

clear;
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'src'), fullfile(racine, 'eval'));
P = parametres();
load(fullfile(racine, 'cache', 'base.mat'), 'base');
load(fullfile(racine, 'cache', 'index_base.mat'), 'INDEX');

fichiers = dir(fullfile(racine, 'data', 'enregistrements', 'micro_*.wav'));
if isempty(fichiers)
    error('Aucune prise dans data/enregistrements/ : lancer enregistrer_salle d''abord.');
end

L = {};
for i = 1:numel(fichiers)
    jetons = regexp(fichiers(i).name, '^micro_(\d+)_(.+)\.wav$', 'tokens', 'once');
    id = str2double(jetons{1});
    distance = string(jetons{2});
    idVrai = find(base.id == id);
    if isempty(idVrai), idVrai = 0; end
    [y, fe] = audioread(fullfile(fichiers(i).folder, fichiers(i).name));
    x = pretraitement(y, P, fe);
    for Tq = [5 numel(x) / P.Fe]
        q = x(1:min(end, round(Tq * P.Fe)));
        R = identifier(q, INDEX, P);
        reponse = R.id;                                   % 0 = « inconnu »
        if idVrai > 0
            if reponse == idVrai, issue = "bonne détection";
            elseif reponse == 0,  issue = "non-détection";
            else,                 issue = "confusion"; end
        else
            if reponse == 0, issue = "rejet correct"; else, issue = "fausse détection"; end
        end
        L(end+1, :) = {id, distance, idVrai > 0, round(Tq, 1), R.score, reponse, issue}; %#ok<SAGROW>
    end
end
T = cell2table(L, 'VariableNames', {'id', 'distance', 'positive', 'Tq', 'score', 'reponse', 'issue'});
writetable(T, fullfile(racine, 'resultats', 'enregistrements.csv'));

% Synthèse par distance et par durée (5 s, ou prise entière)
T.prise_entiere = T.Tq > 5;
G = findgroups(T.distance, T.prise_entiere);
S = table();
for g = unique(G)'
    t = T(G == g, :);
    pos = t.positive;  neg = ~pos;
    S = [S; table(t.distance(1), ternaire(t.prise_entiere(1), "prise entière", "5 s"), P.s_thr, ...
        sum(pos), mean(t.issue(pos) == "bonne détection"), mean(t.issue(pos) == "confusion"), ...
        sum(neg), mean(t.issue(neg) == "fausse détection"), median(t.score(pos)), max([t.score(neg); 0]), ...
        'VariableNames', {'distance', 'Tq', 's_thr', 'N_pos', 'TBD', 'confusion', 'N_neg', 'TFD', ...
        'score_median_pos', 'score_max_neg'})]; %#ok<AGROW>
end
writetable(S, fullfile(racine, 'resultats', 'enregistrements_synthese.csv'));
disp(S);

function s = ternaire(c, a, b)
if c, s = a; else, s = b; end
end
