function T = taux_detection(res, s_thr)
%TAUX_DETECTION  TBD, TFD et types d'erreur pour un seuil donné.
%   T = taux_detection(res, s_thr)     res : sortie de evaluer
%
%   Le système répond « morceau id_max » si score >= s_thr, « inconnu » sinon.
%     Requête positive : bon morceau -> bonne détection ; autre morceau ->
%                        confusion ; « inconnu » -> non-détection.
%     Requête négative : « inconnu » -> rejet correct ; un morceau -> fausse
%                        détection.
%   TBD = #{positives bien identifiées} / N+ ;  TFD = #{négatives identifiées} / N-.
%   Si s_thr est un vecteur, T a une ligne par seuil.

pos = res.id_vrai > 0;
neg = ~pos;
nPos = sum(pos);
nNeg = sum(neg);

s_thr = s_thr(:);
TBD = zeros(size(s_thr));  TFD = TBD;  confusion = TBD;  nonDetection = TBD;
for j = 1:numel(s_thr)
    repond = res.score >= s_thr(j);
    bon = pos & repond & (res.id_max == res.id_vrai);
    TBD(j) = sum(bon) / nPos;
    confusion(j) = sum(pos & repond & (res.id_max ~= res.id_vrai)) / nPos;
    nonDetection(j) = sum(pos & ~repond) / nPos;
    TFD(j) = sum(neg & repond) / nNeg;
end
T = table(s_thr, TBD, TFD, confusion, nonDetection, ...
    repmat(nPos, size(s_thr)), repmat(nNeg, size(s_thr)), ...
    'VariableNames', {'seuil', 'TBD', 'TFD', 'confusion', 'non_detection', 'N_pos', 'N_neg'});
end
