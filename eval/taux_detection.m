function T = taux_detection(res, s_thr)
%TAUX_DETECTION  TBD, TFD, confusions et non-détections pour un ou plusieurs seuils.
%   T = taux_detection(res, s_thr)   res : sortie de evaluer ; une ligne par seuil
%
%   Réponse = id_max si score >= s_thr, « inconnu » sinon.
%   Positive : bon morceau = bonne détection, autre = confusion, inconnu = non-détection.
%   Négative : un morceau = fausse détection.
%   TBD = bonnes détections / N+ ; TFD = fausses détections / N-.

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
