function [SdB, f, t] = calcul_spectrogramme(x, P)
%CALCUL_SPECTROGRAMME  Étape 2 : spectrogramme en dB (TFCT, fenêtre de Hann).
%   [SdB, f, t] = calcul_spectrogramme(x, P)
%
%   SdB : matrice K x M (canaux x trames), SdB = 10 log10(|X|^2 + eps).
%   f   : fréquences des canaux (Hz), f_k = (k-1) Fe / Nfft.
%   t   : instants des centres de trames (s).
%
%   La trame m (indice MATLAB, à partir de 1) commence à l'échantillon
%   (m-1)H + 1. Un décalage de m0*H échantillons translate donc le
%   spectrogramme de m0 trames (propriété (1) du sujet).

w = hann(P.N, 'periodic');
[X, f, t] = spectrogram(x, w, P.N - P.H, P.Nfft, P.Fe);
SdB = 10*log10(abs(X).^2 + eps);
end
