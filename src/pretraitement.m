function x = pretraitement(entree, P, Fe0)
%PRETRAITEMENT  Étape 1 : mono, puis rééchantillonnage à P.Fe (8 kHz).
%   x = pretraitement('morceau.mp3', P)   lit le fichier
%   x = pretraitement(signal, P, Fe0)     signal échantillonné à Fe0
%   x = pretraitement('morceau.mp3')      P = parametres()
%   pretraitement()                       démo sur un signal synthétique
%
%   x : colonne à P.Fe. On utilise resample et pas x(1:k:end) : sans filtre
%   anti-repliement, les aigus se replieraient en faux pics sous 4 kHz.

if nargin == 0
    x = demo();
    return;
end
if nargin < 2 || isempty(P), P = parametres_par_defaut(); end
if ischar(entree) || isstring(entree)
    [x, Fe0] = audioread(entree);
else
    x = entree;
    if nargin < 3
        error('pretraitement:Fe0', 'Fe0 est obligatoire quand on passe un signal.');
    end
end

x = double(x);
if isrow(x), x = x(:); end
if size(x, 2) > 1
    x = mean(x, 2);                 % stéréo -> mono
end
if Fe0 ~= P.Fe
    x = resample(x, P.Fe, Fe0);     % filtre anti-repliement inclus
end
end

function x = demo()
% Démo : 3 s de stéréo à 44,1 kHz -> mono à 8 kHz.
P = parametres_par_defaut();
Fe0 = 44100;
s = morceau_synthetique(3, Fe0, 1);
stereo = [s, 0.5 * s];
x = pretraitement(stereo, P, Fe0);
fprintf('pretraitement : %d x %d échantillons à %d Hz -> %d x 1 à %d Hz (mono).\n', ...
    size(stereo, 1), size(stereo, 2), Fe0, numel(x), P.Fe);
figure('Name', 'pretraitement');
plot((0:numel(x) - 1) / P.Fe, x);
xlabel('temps (s)');  ylabel('amplitude');
title(sprintf('Signal prétraité : mono, F_e = %d Hz', P.Fe));
end

function P = parametres_par_defaut()
% Ajoute le projet au chemin MATLAB et renvoie les paramètres de départ.
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'src'), fullfile(racine, 'utils'));
P = parametres();
end
