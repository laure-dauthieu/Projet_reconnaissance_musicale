function E = generer_empreintes(pics, P)
%GENERER_EMPREINTES  Étape 4 : paires de pics -> clés de hachage.
%   E = generer_empreintes(pics, P)
%
%   pics : [m, k] triés par trame (sortie de detection_pics).
%   E    : [cle, m1], une ligne par paire (ancre, cible).
%
%   Pour chaque ancre (m1,k1), on prend les P.F premières cibles (m2,k2)
%   de la zone P.dm_min <= m2-m1 <= P.dm_max et |k2-k1| <= P.dk_max.
%   La clé u = (Qf(k1), Qf(k2), Δm) est codée en un seul entier :
%       u = (q1*Nf + q2)*Nt + (Δm - dm_min),   Qf(k) = floor((k-1)/gamma_f).
%   Elle ne dépend que de Δm = m2-m1 : l'instant absolu m1 est rangé à part,
%   ce qui la rend indépendante de l'endroit où l'extrait a été capté.
%
%   E = generer_empreintes(pics)   P par défaut : parametres().
%   generer_empreintes()           démonstration autonome (pics d'un signal synthétique).

if nargin == 0
    E = demo();
    return;
end
if nargin < 2 || isempty(P), P = parametres_par_defaut(); end

m = pics(:, 1);
k = pics(:, 2);
n = numel(m);
q = floor((k - 1) / P.gamma_f);

cles = zeros(n * P.F, 1);
m1s  = zeros(n * P.F, 1);
nE = 0;
j0 = 1;                                  % premier pic avec m >= m1 + dm_min
for i = 1:n
    while j0 <= n && m(j0) < m(i) + P.dm_min
        j0 = j0 + 1;
    end
    j = j0;
    nc = 0;
    while j <= n && m(j) <= m(i) + P.dm_max && nc < P.F
        if abs(k(j) - k(i)) <= P.dk_max
            nE = nE + 1;
            nc = nc + 1;
            cles(nE) = (q(i)*P.Nf + q(j))*P.Nt + (m(j) - m(i) - P.dm_min);
            m1s(nE)  = m(i);
        end
        j = j + 1;
    end
end

E = [cles(1:nE), m1s(1:nE)];
end

function E = demo()
% Démonstration : clés formées à partir des pics de 8 s de « musique » synthétique.
P = parametres_par_defaut();
x = morceau_synthetique(8, P.Fe, 1);
pics = detection_pics(calcul_spectrogramme(x, P), P);
E = generer_empreintes(pics, P);
fprintf(['generer_empreintes : %d pics -> %d paires (F = %d cibles par ancre), ' ...
    '%d clés distinctes sur M = %.2g possibles.\n'], size(pics, 1), size(E, 1), P.F, ...
    numel(unique(E(:, 1))), P.M);
% Décodage de la première clé : u = (q1*Nf + q2)*Nt + (Δm - dm_min)
u = E(1, 1);
dm = mod(u, P.Nt) + P.dm_min;  q = floor(u / P.Nt);
fprintf('  1re clé : u = %d -> classes (%d, %d), Δm = %d trames, ancre à la trame %d.\n', ...
    u, floor(q / P.Nf), mod(q, P.Nf), dm, E(1, 2));
end

function P = parametres_par_defaut()
% Ajoute le projet au chemin MATLAB et renvoie les paramètres de départ.
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'src'), fullfile(racine, 'utils'));
P = parametres();
end
