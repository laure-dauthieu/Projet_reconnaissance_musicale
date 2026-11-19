function [E, pics, SdB] = empreintes_signal(x, P)
%EMPREINTES_SIGNAL  Chaîne d'extraction commune aux deux phases.
%   [E, pics, SdB] = empreintes_signal(x, P)  avec x déjà prétraité.
%   [E, pics, SdB] = empreintes_signal(x)     P par défaut : parametres().
%   empreintes_signal()                       démonstration autonome.
%
%   Indexation et identification appellent cette même fonction : une même
%   musique produit ainsi les mêmes clés, qu'elle vienne du fichier ou du micro.

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
% Démonstration : spectrogramme -> pics -> clés pour 8 s de « musique » synthétique.
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
