function [E, pics, SdB] = empreintes_signal(x, P)
%EMPREINTES_SIGNAL  Chaîne d'extraction commune aux deux phases.
%   [E, pics, SdB] = empreintes_signal(x, P)  avec x déjà prétraité.
%
%   Indexation et identification appellent cette même fonction : une même
%   musique produit ainsi les mêmes clés, qu'elle vienne du fichier ou du micro.

SdB  = calcul_spectrogramme(x, P);
pics = detection_pics(SdB, P);
E    = generer_empreintes(pics, P);
end
