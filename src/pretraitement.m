function x = pretraitement(entree, P, Fe0)
%PRETRAITEMENT  Étape 1 : passage en mono et rééchantillonnage à P.Fe.
%   x = pretraitement('morceau.mp3', P)  lit le fichier.
%   x = pretraitement(signal, P, Fe0)    traite un signal échantillonné à Fe0.
%
%   Sortie : vecteur colonne (double) à P.Fe.
%
%   resample inclut le filtre anti-repliement. Une décimation x(1:k:end)
%   replierait le contenu au-delà de Fe/2 dans la bande utile et créerait
%   des faux pics différents entre la référence et la requête.

if ischar(entree) || isstring(entree)
    [x, Fe0] = audioread(entree);
else
    x = entree;
    if nargin < 3
        error('pretraitement:Fe0', 'Fe0 est obligatoire quand on passe un signal.');
    end
end

x = double(x);
if isrow(x), x = x(:); end
if size(x, 2) > 1
    x = mean(x, 2);                 % stéréo -> mono
end
if Fe0 ~= P.Fe
    x = resample(x, P.Fe, Fe0);     % filtre anti-repliement inclus
end
end
