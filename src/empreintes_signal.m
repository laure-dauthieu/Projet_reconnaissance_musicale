function [E, pics, SdB] = empreintes_signal(x, P)
%EMPREINTES_SIGNAL  Étapes 2 à 4 d'un coup : spectrogramme -> pics -> clés.
%   [E, pics, SdB] = empreintes_signal(x, P)   x prétraité
%   [E, pics, SdB] = empreintes_signal(x)      P = parametres()
%   empreintes_signal()                        démo
%
%   L'index et la requête passent par cette même fonction, donc par exactement
%   les mêmes traitements.

if nargin == 0
    [E, pics, SdB] = demo();
    return;
end
if nargin < 2 || isempty(P), P = parametres_par_defaut(); end

SdB  = calcul_spectrogramme(x, P);
pics = detection_pics(SdB, P);
E    = generer_empreintes(pics, P);
end

function [E, pics, SdB] = demo()
% Démo sur 8 s de musique synthétique.
P = parametres_par_defaut();
x = morceau_synthetique(8, P.Fe, 1);
[E, pics, SdB] = empreintes_signal(x, P);
fprintf('empreintes_signal : %d trames -> %d pics -> %d clés.\n', size(SdB, 2), size(pics, 1), size(E, 1));
end

function P = parametres_par_defaut()
% Ajoute le projet au chemin MATLAB et renvoie les paramètres de départ.
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'src'), fullfile(racine, 'utils'));
P = parametres();
end
