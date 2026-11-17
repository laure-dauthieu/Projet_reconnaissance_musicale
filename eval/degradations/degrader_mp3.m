function ym = degrader_mp3(y, Fe0, debit_kbps, P)
%DEGRADER_MP3  Codage puis décodage MP3 (composantes masquées supprimées).
%   ym = degrader_mp3(y, Fe0, debit_kbps, P)
%
%   y est écrit en WAV, codé en MP3 à debit_kbps par ffmpeg (libmp3lame),
%   puis relu. audiowrite ne sait pas écrire de MP3, d'où ffmpeg (chemin
%   dans P.ffmpeg).
%
%   Le codeur ajoute un retard d'environ un millier d'échantillons. On
%   l'estime par intercorrélation et on le retire, pour que ym reste aligné
%   sur y (indispensable pour mesurer la proportion p de pics conservés).
%   ym a la même longueur que y.

y = y(:);
echelle = max(1, max(abs(y)) / 0.99);      % évite l'écrêtage dans audiowrite
fWav = [tempname '.wav'];
fMp3 = [tempname '.mp3'];
nettoyer = onCleanup(@() supprimer({fWav, fMp3}));

audiowrite(fWav, y / echelle, Fe0);
cmd = sprintf('"%s" -loglevel error -y -i "%s" -codec:a libmp3lame -b:a %dk "%s"', ...
    P.ffmpeg, fWav, debit_kbps, fMp3);
[statut, sortie] = system(cmd);
if statut ~= 0
    error('degrader_mp3:ffmpeg', 'ffmpeg a échoué :\n%s', sortie);
end
[ym, FeLu] = audioread(fMp3);
ym = mean(ym, 2) * echelle;
if FeLu ~= Fe0
    ym = resample(ym, Fe0, FeLu);
end

% Retrait du retard du codeur (au plus 0,1 s)
maxLag = round(0.1 * Fe0);
nRef = min([numel(y), numel(ym), 5 * Fe0]);
[c, lags] = xcorr(ym(1:nRef), y(1:nRef), maxLag);
[~, iMax] = max(c);
retard = lags(iMax);
if retard > 0
    ym = ym(retard + 1:end);
elseif retard < 0
    ym = [zeros(-retard, 1); ym];
end

% Même longueur que l'entrée
n = numel(y);
if numel(ym) >= n
    ym = ym(1:n);
else
    ym = [ym; zeros(n - numel(ym), 1)];
end
end

function supprimer(fichiers)
for i = 1:numel(fichiers)
    if exist(fichiers{i}, 'file'), delete(fichiers{i}); end
end
end
