function yb = ajouter_bruit(y, RSB_dB, bruit, rs)
%AJOUTER_BRUIT  Ajoute un bruit à un RSB imposé (terme b(t) du modèle (1)).
%   yb = ajouter_bruit(y, RSB_dB)            bruit blanc gaussien
%   yb = ajouter_bruit(y, RSB_dB, 'blanc')
%   yb = ajouter_bruit(y, RSB_dB, b)         bruit réel b (ex. brouhaha) : on
%                                            en prend un segment au hasard
%   yb = ajouter_bruit(..., rs)              rs : RandStream (reproductible)
%
%   RSB_dB = 10 log10(Px / Pb), avec Px calculé sur l'extrait y lui-même et
%   non sur le morceau entier (sujet, équation (8)).
%
%   À appliquer au signal déjà ramené à 8 kHz : ajouté à 44,1 kHz, le bruit
%   blanc perdrait environ 80 % de sa puissance au rééchantillonnage, et le
%   RSB réel serait meilleur d'environ 7 dB que le RSB demandé.

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
