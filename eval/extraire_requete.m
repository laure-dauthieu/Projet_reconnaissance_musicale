function [y, t0] = extraire_requete(x, Fe0, Tq, rs)
%EXTRAIRE_REQUETE  Extrait de Tq secondes pris à un instant tiré au hasard.
%   [y, t0] = extraire_requete(x, Fe0, Tq)
%   [y, t0] = extraire_requete(x, Fe0, Tq, rs)   rs : RandStream, pour rejouer le tirage
%
%   y : extrait mono à Fe0 ; t0 : son début dans le morceau (s).
%   Le début est tiré en échantillons, donc en général pas sur la grille des
%   trames : c'est le cas réel (propriété (1) seulement approchée).

if nargin < 4, rs = RandStream.getGlobalStream; end
if size(x, 2) > 1, x = mean(x, 2); end
nq = round(Tq * Fe0);
if size(x, 1) < nq
    error('extraire_requete:court', 'Le morceau (%.1f s) est plus court que Tq = %g s.', ...
        size(x, 1) / Fe0, Tq);
end
debut = randi(rs, size(x, 1) - nq + 1);
y = x(debut:debut + nq - 1);
t0 = (debut - 1) / Fe0;
end
