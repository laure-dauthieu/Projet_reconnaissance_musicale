function s_thr = calibrer_seuil(scoresNeg, marge)
%CALIBRER_SEUIL  Seuil de décision fixé sur des requêtes négatives (Q5).
%   s_thr = calibrer_seuil(scoresNeg)          marge = 1,5
%   s_thr = calibrer_seuil(scoresNeg, marge)
%
%   s_thr = ceil(marge x plus fort score négatif). Les mauvais morceaux ont des
%   scores de 10 à 25, les bons de plusieurs centaines : la marge couvre les
%   négatives que la calibration n'a pas vues. Le TFD se mesure ensuite sur
%   d'AUTRES négatives.

if nargin < 2, marge = 1.5; end
s_thr = ceil(marge * max(scoresNeg));
end
