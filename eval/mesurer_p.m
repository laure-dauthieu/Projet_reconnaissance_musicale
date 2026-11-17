function [p, pParBande, nRef] = mesurer_p(picsRef, picsDeg, P)
%MESURER_P  Proportion p de pics qui survivent à une dégradation.
%   p = mesurer_p(picsRef, picsDeg)
%   [p, pParBande, nRef] = mesurer_p(picsRef, picsDeg, P)
%
%   picsRef : pics [m, k] de l'extrait propre ; picsDeg : pics du même
%   extrait dégradé, ALIGNÉ sur le propre (même grille de trames).
%   p = proportion des pics propres retrouvés à la même position (m, k)
%   exactement dans l'extrait dégradé. C'est la définition du sujet : une
%   clé n'est retrouvée que si ses pics sont exactement au même endroit.
%
%   pParBande : p pour chacune des P.Nb bandes de fréquence (NaN si vide).
%   nRef      : nombre de pics propres dans chaque bande.

survit = ismember(picsRef, picsDeg, 'rows');
p = mean(survit);

if nargout > 1
    fk = (picsRef(:, 2) - 1) * P.Fe / P.Nfft;
    bande = discretize(fk, P.bandes);
    pParBande = nan(P.Nb, 1);
    nRef = zeros(P.Nb, 1);
    for b = 1:P.Nb
        sel = bande == b;
        nRef(b) = sum(sel);
        if nRef(b) > 0
            pParBande(b) = mean(survit(sel));
        end
    end
end
end
