function [y, t0] = extraire_requete(x, Fe0, Tq, rs)
%EXTRAIRE_REQUETE  Extrait de Tq secondes pris à un instant tiré au hasard.
%   [y, t0] = extraire_requete(x, Fe0, Tq)
%   [y, t0] = extraire_requete(x, Fe0, Tq, rs)   rs : RandStream (reproductible)
%
%   x  : signal à sa fréquence d'origine Fe0 (mono ou stéréo).
%   y  : extrait mono, toujours à Fe0. Le MP3 s'applique à ce signal (avant
%        pretraitement) ; les autres dégradations au signal prétraité à 8 kHz
%        (voir experiences/campagne_evaluation.m).
%   t0 : instant de début de l'extrait dans le morceau (s).
%
%   L'instant est tiré en échantillons d'origine : il ne tombe donc pas, en
%   général, sur un multiple de H. C'est le cas réaliste (sujet, propriété (1)).

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
