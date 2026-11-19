function yb = ajouter_bruit(y, RSB_dB, bruit, rs)
%AJOUTER_BRUIT  Ajoute un bruit à un RSB donné (terme b(t) du modèle (1)).
%   yb = ajouter_bruit(y, RSB_dB)          bruit blanc
%   yb = ajouter_bruit(y, RSB_dB, b)       bruit réel b (brouhaha), segment pris au hasard
%   yb = ajouter_bruit(..., rs)            rs : RandStream, pour rejouer le tirage
%
%   Px est mesuré sur l'extrait y, pas sur le morceau entier (équation (8)).
%   À appliquer au signal à 8 kHz : à 44,1 kHz, le rééchantillonnage retirerait
%   ~80 % du bruit blanc et le vrai RSB serait ~7 dB meilleur que prévu.

if nargin < 3 || isempty(bruit), bruit = 'blanc'; end
if nargin < 4, rs = RandStream.getGlobalStream; end
y = y(:);
n = numel(y);

if ischar(bruit) || isstring(bruit)
    b = randn(rs, n, 1);
else
    b = bruit(:);
    if numel(b) < n
        b = repmat(b, ceil(n / numel(b)), 1);
    end
    debut = randi(rs, numel(b) - n + 1);
    b = b(debut:debut + n - 1);
end

Px = mean(y.^2);
Pb = mean(b.^2);
b = b * sqrt(Px / (Pb * 10^(RSB_dB / 10)));
yb = y + b;
end
