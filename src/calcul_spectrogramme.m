function [SdB, f, t] = calcul_spectrogramme(x, P)
%CALCUL_SPECTROGRAMME  Étape 2 : spectrogramme en dB (fenêtre de Hann, H = N/2).
%   [SdB, f, t] = calcul_spectrogramme(x, P)
%   [SdB, f, t] = calcul_spectrogramme(x)    P = parametres()
%   calcul_spectrogramme()                   démo sur un signal synthétique
%
%   SdB = 10 log10(|X|^2 + eps), K canaux x M trames ; f en Hz, t en s.
%   La trame m commence à l'échantillon (m-1)H + 1 : décaler x de m0*H
%   décale le spectrogramme de m0 trames (propriété (1)).

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
% Démo : spectrogramme de 5 s de musique synthétique.
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
