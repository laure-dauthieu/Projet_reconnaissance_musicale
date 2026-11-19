function [p, pParBande, nRef] = mesurer_p(picsRef, picsDeg, P)
%MESURER_P  Proportion p de pics qui survivent à une dégradation (Q3, Q4, Q6).
%   p = mesurer_p(picsRef, picsDeg)
%   [p, pParBande, nRef] = mesurer_p(picsRef, picsDeg, P)
%
%   picsRef, picsDeg : pics [m, k] du même extrait, propre et dégradé, alignés.
%   Un pic ne compte que s'il est retrouvé exactement au même (m, k) : sinon
%   la clé qu'il forme change.
%   pParBande : p dans chaque bande (NaN si vide) ; nRef : pics propres par bande.

survit = ismember(picsRef, picsDeg, 'rows');
p = mean(survit);

if nargout > 1
    if nargin < 3 || isempty(P)
        racine = fileparts(fileparts(mfilename('fullpath')));
        addpath(racine);
        P = parametres();
    end
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
