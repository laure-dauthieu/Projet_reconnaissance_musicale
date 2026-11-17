function s_thr = calibrer_seuil(scoresNeg, marge)
%CALIBRER_SEUIL  Fixe le seuil de décision à partir de requêtes négatives.
%   s_thr = calibrer_seuil(scoresNeg)
%   s_thr = calibrer_seuil(scoresNeg, marge)
%
%   scoresNeg : scores maximaux obtenus sur des requêtes négatives (morceaux
%               absents de la base) réservées à la calibration.
%   marge     : facteur de sécurité (défaut 1,5).
%
%   Méthode : le seuil doit être nettement au-dessus du plus fort score
%   qu'une requête négative ait obtenu, s_thr = ceil(marge * max(scoresNeg)).
%   Un mauvais morceau n'obtient que des votes fortuits et dispersés (score
%   de l'ordre de 10 à 25), alors qu'un bon morceau concentre ses votes dans
%   une seule case (score ≈ F rho Tq p^2, de l'ordre de quelques centaines).
%   La marge protège contre la queue de la distribution des négatives que
%   l'échantillon de calibration n'a pas vue. Le TFD se mesure ensuite sur
%   d'AUTRES requêtes négatives.

if nargin < 2, marge = 1.5; end
s_thr = ceil(marge * max(scoresNeg));
end
