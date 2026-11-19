function yf = filtre_passe_bande(y, Fe0, f1, f2, causal)
%FILTRE_PASSE_BANDE  Passe-bande type téléphone ou petit haut-parleur (Butterworth d'ordre 4).
%   yf = filtre_passe_bande(y, Fe0)                 300-3400 Hz, sans retard (filtfilt)
%   yf = filtre_passe_bande(y, Fe0, f1, f2)
%   yf = filtre_passe_bande(y, Fe0, f1, f2, true)   causal, comme un vrai haut-parleur
%
%   Sans retard par défaut, pour comparer les pics trame à trame (Q2, Q4).

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
