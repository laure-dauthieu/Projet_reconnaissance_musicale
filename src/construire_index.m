function INDEX = construire_index(morceaux, P, noms)
%CONSTRUIRE_INDEX  Étape 5a : index inversé (clé -> (morceau, instant)).
%   INDEX = construire_index(morceaux, P)
%   INDEX = construire_index(morceaux, P, noms)
%
%   morceaux : cellule de chemins de fichiers audio, ou de signaux déjà
%              prétraités (colonnes à P.Fe).
%   noms     : cellule de noms à afficher (par défaut : les chemins).
%
%   INDEX.cle, .id, .m1 : entrées triées par clé (un tableau trié plutôt
%       qu'un containers.Map, beaucoup plus rapide au-delà de quelques
%       dizaines de morceaux).
%   INDEX.ucle, .debut, .nb : clés distinctes, position de leur première
%       entrée et nombre d'entrées. Ils permettent de récupérer TOUTES les
%       entrées d'une clé (ismember n'en renvoie qu'une).
%   INDEX.noms, .nTrames, .P
%
%   INDEX = construire_index(morceaux)   P par défaut : parametres().
%   construire_index()                   démonstration autonome (3 morceaux synthétiques).

if nargin == 0
    INDEX = demo();
    return;
end
if nargin < 2 || isempty(P), P = parametres_par_defaut(); end

nM = numel(morceaux);
if nargin < 3
    noms = cell(nM, 1);
    for i = 1:nM
        if ischar(morceaux{i}) || isstring(morceaux{i})
            noms{i} = char(morceaux{i});
        else
            noms{i} = sprintf('morceau %d', i);
        end
    end
end

blocs = cell(nM, 1);
nTrames = zeros(nM, 1);
for i = 1:nM
    if ischar(morceaux{i}) || isstring(morceaux{i})
        x = pretraitement(morceaux{i}, P);
    else
        x = morceaux{i};
    end
    [E, ~, SdB] = empreintes_signal(x, P);
    nTrames(i) = size(SdB, 2);
    blocs{i} = [E, i * ones(size(E, 1), 1)];
end

T = vertcat(blocs{:});                 % [cle, m1, id]
T = sortrows(T, 1);

INDEX.cle = uint32(T(:, 1));
INDEX.m1  = uint32(T(:, 2));
INDEX.id  = uint32(T(:, 3));

[INDEX.ucle, INDEX.debut] = unique(INDEX.cle, 'first');
INDEX.nb = diff([INDEX.debut; numel(INDEX.cle) + 1]);

INDEX.noms = noms(:);
INDEX.nTrames = nTrames;
INDEX.P = P;
end

function INDEX = demo()
% Démonstration : index inversé de 3 « morceaux » synthétiques de 30 s.
P = parametres_par_defaut();
morceaux = arrayfun(@(g) morceau_synthetique(30, P.Fe, g), 1:3, 'UniformOutput', false);
tic;
INDEX = construire_index(morceaux, P, {'morceau A', 'morceau B', 'morceau C'});
fprintf(['construire_index : %d morceaux, %d entrées, %d clés distinctes, ' ...
    'construit en %.2f s.\n'], numel(morceaux), numel(INDEX.cle), numel(INDEX.ucle), toc);
fprintf('  entrées par morceau : %s ; entrées par clé : au plus %d.\n', ...
    mat2str(accumarray(double(INDEX.id), 1)'), max(INDEX.nb));
end

function P = parametres_par_defaut()
% Ajoute le projet au chemin MATLAB et renvoie les paramètres de départ.
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'src'), fullfile(racine, 'utils'));
P = parametres();
end
