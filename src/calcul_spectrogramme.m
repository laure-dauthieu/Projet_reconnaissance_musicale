function [SdB, f, t] = calcul_spectrogramme(x, P)
%CALCUL_SPECTROGRAMME  Étape 2 : spectrogramme en dB (TFCT, fenêtre de Hann).
%   [SdB, f, t] = calcul_spectrogramme(x, P)
%   [SdB, f, t] = calcul_spectrogramme(x)   P par défaut : parametres().
%   calcul_spectrogramme()                  démonstration autonome (signal synthétique).
%
%   SdB : matrice K x M (canaux x trames), SdB = 10 log10(|X|^2 + eps).
%   f   : fréquences des canaux (Hz), f_k = (k-1) Fe / Nfft.
%   t   : instants des centres de trames (s).
%
%   La trame m (indice MATLAB, à partir de 1) commence à l'échantillon
%   (m-1)H + 1. Un décalage de m0*H échantillons translate donc le
%   spectrogramme de m0 trames (propriété (1) du sujet).

if nargin == 0
    [SdB, f, t] = demo();
    return;
end
if nargin < 2 || isempty(P), P = parametres_par_defaut(); end

w = hann(P.N, 'periodic');
[X, f, t] = spectrogram(x, w, P.N - P.H, P.Nfft, P.Fe);
SdB = 10*log10(abs(X).^2 + eps);
end

function [SdB, f, t] = demo()
% Démonstration : spectrogramme de 5 s de « musique » synthétique à 8 kHz.
P = parametres_par_defaut();
x = morceau_synthetique(5, P.Fe, 1);
[SdB, f, t] = calcul_spectrogramme(x, P);
fprintf(['calcul_spectrogramme : %d canaux x %d trames (N = %d, H = %d, ' ...
    'Tw = %.0f ms, %.1f trames/s).\n'], size(SdB, 1), size(SdB, 2), P.N, P.H, ...
    1000 * P.N / P.Fe, P.Fe / P.H);
figure('Name', 'calcul_spectrogramme');
imagesc(t, f / 1000, SdB);  axis xy;  colorbar;
xlabel('temps (s)');  ylabel('fréquence (kHz)');
title('Spectrogramme S_{dB} (fenêtre de Hann, N = 1024)');
end

function P = parametres_par_defaut()
% Ajoute le projet au chemin MATLAB et renvoie les paramètres de départ.
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'src'), fullfile(racine, 'utils'));
P = parametres();
end
