function enregistrer_brouhaha(duree)
%ENREGISTRER_BROUHAHA  Enregistre un bruit réel (brouhaha) au micro du Mac.
%   enregistrer_brouhaha()       3 minutes
%   enregistrer_brouhaha(120)    durée en secondes
%
%   À lancer dans un lieu bruyant SANS musique (cafétéria à midi) : des
%   conversations, de la vaisselle, des pas. C'est le « bruit réel (brouhaha),
%   coloré et non stationnaire » du sujet.
%
%   Produit : data/enregistrements/brouhaha_cafet.wav (44,1 kHz, mono).
%   La campagne d'évaluation le trouve toute seule et ajoute les conditions
%   « brouhaha 10, 5 et 0 dB ».

if nargin < 1, duree = 180; end
racine = fileparts(fileparts(mfilename('fullpath')));
dossier = fullfile(racine, 'data', 'enregistrements');
if ~exist(dossier, 'dir'), mkdir(dossier); end

Fe = 44100;
rec = audiorecorder(Fe, 16, 1);
fprintf('Enregistrement de %d s... (ne rien jouer de musical)\n', duree);
recordblocking(rec, duree);
b = getaudiodata(rec);
fprintf('Niveau moyen : %.0f dBFS, crête : %.2f\n', 20*log10(rms(b) + eps), max(abs(b)));
if rms(b) < 1e-3
    warning('Niveau très faible : vérifier le micro (autorisation macOS pour MATLAB).');
end
audiowrite(fullfile(dossier, 'brouhaha_cafet.wav'), b, Fe);
fprintf('Enregistré : data/enregistrements/brouhaha_cafet.wav\n');
end
