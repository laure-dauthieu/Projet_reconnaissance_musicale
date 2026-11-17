function yf = filtre_passe_bande(y, Fe0, f1, f2, causal)
%FILTRE_PASSE_BANDE  Filtrage passe-bande (petit haut-parleur, téléphone).
%   yf = filtre_passe_bande(y, Fe0)              300–3400 Hz, sans retard
%   yf = filtre_passe_bande(y, Fe0, f1, f2)
%   yf = filtre_passe_bande(y, Fe0, f1, f2, true) filtre causal (réaliste)
%
%   Butterworth d'ordre 4 (pente de 24 dB/octave de chaque côté), appliqué
%   en sections du second ordre pour la stabilité numérique.
%   Par défaut, filtrage à phase nulle (filtfilt) : le signal n'est pas
%   retardé, ce qui permet de comparer les pics trame à trame (Q2, Q4).
%   Avec causal = true, on applique le filtre une seule fois (sosfilt), comme
%   un vrai haut-parleur ; le léger retard ne gêne pas l'identification.

if nargin < 3 || isempty(f1), f1 = 300; end
if nargin < 4 || isempty(f2), f2 = 3400; end
if nargin < 5, causal = false; end

[z, p, k] = butter(4, [f1 f2] / (Fe0/2), 'bandpass');
[sos, g] = zp2sos(z, p, k);
if causal
    yf = g * sosfilt(sos, y(:));
else
    yf = filtfilt(sos, g, y(:));
end
end
