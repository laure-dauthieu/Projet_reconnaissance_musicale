function pics = detection_pics(SdB, P)
%DETECTION_PICS  Étape 3 : carte de constellation (maxima locaux).
%   pics = detection_pics(SdB, P)
%
%   pics : matrice [m, k], une ligne par pic, triée par trame puis canal
%          (m = indice de trame, k = indice de canal, à partir de 1).
%
%   Un point (m,k) est un pic si :
%     1. c'est le maximum de SdB sur le voisinage ±P.dm trames x ±P.dk canaux ;
%     2. il dépasse le seuil local tau = médiane de SdB dans sa bande
%        (glissante sur P.T_mediane secondes) + P.marge_dB ;
%     3. il fait partie des P.rho/P.Nb plus forts de sa bande sur chaque
%        seconde (nombre fixe de pics par bande et par seconde).
%   Seule la position est gardée, jamais l'amplitude : elle est invariante
%   à un gain, et à un filtrage tant que Δg(V) < μ (condition (5)).

[K, M] = size(SdB);

% 1. Maximum glissant 2D. movmax est séparable : max sur les canaux,
%    puis sur les trames (remplace ordfilt2, absent sans Image Processing).
Smax = movmax(movmax(SdB, 2*P.dk + 1, 1), 2*P.dm + 1, 2);
estMax = (SdB == Smax);

% Canaux de chaque bande géométrique
fk = (0:K-1)' * P.Fe / P.Nfft;
trParSec = P.Fe / P.H;                       % trames par seconde
nWin = max(1, round(P.T_mediane * trParSec));
nParBloc = max(1, round(P.rho / P.Nb));      % pics gardés par bande et par seconde
bloc = max(1, round(trParSec));              % trames par seconde (arrondi)

pics = zeros(0, 2);
for b = 1:P.Nb
    kb = find(fk >= P.bandes(b) & fk < P.bandes(b+1));
    if isempty(kb), continue; end

    % 2. Seuil local : médiane de la bande, glissante dans le temps
    medTrame = median(SdB(kb, :), 1);
    tau = movmedian(medTrame, nWin) + P.marge_dB;    % 1 x M
    cand = estMax(kb, :) & (SdB(kb, :) >= tau);

    % 3. Quota : les nParBloc plus forts par seconde
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
