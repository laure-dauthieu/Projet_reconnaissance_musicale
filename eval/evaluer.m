function res = evaluer(INDEX, requetes, P)
%EVALUER  Identifie un ensemble de requêtes et calcule TBD et TFD.
%   res = evaluer(INDEX, requetes, P)
%
%   requetes : tableau de structures avec
%       .y       signal déjà prétraité (colonne à P.Fe)
%       .id_vrai morceau d'origine dans l'index, 0 pour une requête négative
%
%   res : table, une ligne par requête :
%       id_vrai, id_max (morceau de score maximal), score (son score),
%       temps (s) ; et, au seuil P.s_thr, la réponse et sa catégorie.
%   Les taux s'obtiennent avec taux_detection(res, s_thr), pour n'importe
%   quel seuil : on n'a pas besoin de relancer l'identification pour
%   balayer le seuil.

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
