function [yr, h] = reverberation(y, Fe0, T60, rs)
%REVERBERATION  Convolution par une réponse de salle synthétique.
%   [yr, h] = reverberation(y, Fe0, T60)
%   [yr, h] = reverberation(y, Fe0, T60, rs)   rs : RandStream (reproductible)
%
%   Modèle classique de réverbération diffuse : bruit blanc à décroissance
%   exponentielle, h(t) = n(t) exp(-6,91 t / T60). Le facteur 6,91 = 3 ln 10
%   donne une décroissance d'énergie de 60 dB en T60 secondes. On ajoute un
%   trajet direct en h(0). La réponse dure T60 : au-delà, elle est 60 dB
%   sous son début.
%
%   Pour T60 = 1 s à Fe = 8 kHz, h dure 8000 échantillons, bien plus que la
%   fenêtre N = 1024 : c'est la limite de l'approximation (3) du sujet.
%   La sortie a la même longueur et la même puissance que y.

if nargin < 4, rs = RandStream.getGlobalStream; end
L = round(T60 * Fe0);
t = (0:L-1)' / Fe0;
h = randn(rs, L, 1) .* exp(-6.91 * t / T60);
h(1) = max(abs(h)) * 2;                  % trajet direct
h = h / norm(h);

y = y(:);
yr = fftfilt(h, [y; zeros(L, 1)]);
yr = yr(1:numel(y));
yr = yr * sqrt(mean(y.^2) / mean(yr.^2));
end
