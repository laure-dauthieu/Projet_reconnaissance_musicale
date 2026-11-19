function pics = detection_pics(SdB, P)
%DETECTION_PICS  Étape 3 : carte de constellation (maxima locaux du spectrogramme).
%   pics = detection_pics(SdB, P)   pics = [m, k] (trame, canal), triés par trame
%   pics = detection_pics(SdB)      P = parametres()
%   detection_pics()                démo sur un signal synthétique
%
%   (m,k) est gardé s'il est :
%     1. le maximum de son voisinage ±dm trames x ±dk canaux ;
%     2. au-dessus de la médiane de sa bande + marge_dB ;
%     3. parmi les rho/Nb plus forts de sa bande sur chaque seconde.
%   On ne garde que la position : elle ne change pas avec le volume.

if nargin == 0
    pics = demo();
    return;
end
if nargin < 2 || isempty(P), P = parametres_par_defaut(); end

[K, M] = size(SdB);

% 1. Maximum glissant 2D, en deux passes (canaux puis trames) :
%    ordfilt2 demanderait l'Image Processing Toolbox.
Smax = movmax(movmax(SdB, 2*P.dk + 1, 1), 2*P.dm + 1, 2);
estMax = (SdB == Smax);

fk = (0:K-1)' * P.Fe / P.Nfft;               % fréquence de chaque canal
trParSec = P.Fe / P.H;
nWin = max(1, round(P.T_mediane * trParSec));
nParBloc = max(1, round(P.rho / P.Nb));      % pics par bande et par seconde
bloc = max(1, round(trParSec));              % une seconde, en trames

pics = zeros(0, 2);
for b = 1:P.Nb
    kb = find(fk >= P.bandes(b) & fk < P.bandes(b+1));
    if isempty(kb), continue; end

    % 2. Seuil local
    medTrame = median(SdB(kb, :), 1);
    tau = movmedian(medTrame, nWin) + P.marge_dB;    % 1 x M
    cand = estMax(kb, :) & (SdB(kb, :) >= tau);

    % 3. Quota : les plus forts de chaque seconde
    for m0 = 1:bloc:M
        cols = m0:min(m0 + bloc - 1, M);
        [kk, mm] = find(cand(:, cols));
        if isempty(kk), continue; end
        v = SdB(sub2ind([K, M], kb(kk), cols(mm)'));
        [~, ordre] = sort(v, 'descend');
        garde = ordre(1:min(nParBloc, numel(ordre)));
        pics = [pics; cols(mm(garde))', kb(kk(garde))]; %#ok<AGROW>
    end
end

pics = sortrows(pics, [1 2]);
end

function pics = demo()
% Démo : constellation de 8 s de musique synthétique.
P = parametres_par_defaut();
x = morceau_synthetique(8, P.Fe, 1);
[SdB, f, t] = calcul_spectrogramme(x, P);
pics = detection_pics(SdB, P);
fprintf('detection_pics : %d pics en %.0f s, soit %.1f pics/s (voisinage ±%d trames x ±%d canaux).\n', ...
    size(pics, 1), numel(x) / P.Fe, size(pics, 1) / (numel(x) / P.Fe), P.dm, P.dk);
figure('Name', 'detection_pics');
imagesc(t, f / 1000, SdB);  axis xy;  colormap(flipud(gray));  hold on;
plot(t(pics(:, 1)), f(pics(:, 2)) / 1000, 'r.', 'MarkerSize', 12);
xlabel('temps (s)');  ylabel('fréquence (kHz)');
title('Carte de constellation superposée au spectrogramme');
end

function P = parametres_par_defaut()
% Ajoute le projet au chemin MATLAB et renvoie les paramètres de départ.
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'src'), fullfile(racine, 'utils'));
P = parametres();
end
