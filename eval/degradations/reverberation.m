function [yr, h] = reverberation(y, Fe0, T60, rs)
%REVERBERATION  Réverbération de salle synthétique, de durée T60.
%   [yr, h] = reverberation(y, Fe0, T60)
%   [yr, h] = reverberation(y, Fe0, T60, rs)   rs : RandStream, pour rejouer le tirage
%
%   h = bruit blanc x exp(-6,91 t / T60) (énergie -60 dB en T60), plus un trajet
%   direct en h(0). À T60 = 1 s, h fait 8000 échantillons, bien plus que N = 1024 :
%   c'est la limite de la relation (3). yr a la longueur et la puissance de y.

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
