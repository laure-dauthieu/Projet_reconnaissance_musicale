function INDEX = construire_index(morceaux, P, noms)
%CONSTRUIRE_INDEX  Étape 5a : index inversé, clé -> (morceau, instant m1).
%   INDEX = construire_index(morceaux, P, noms)
%   INDEX = construire_index(morceaux)   P = parametres(), noms = chemins
%   construire_index()                   démo sur 3 morceaux synthétiques
%
%   morceaux : chemins de fichiers audio, ou signaux déjà prétraités.
%
%   INDEX.cle, .id, .m1     entrées triées par clé (plus rapide qu'un containers.Map)
%   INDEX.ucle, .debut, .nb chaque clé distincte, sa 1re entrée et son nombre
%                           d'entrées : on lit ainsi TOUTES les entrées d'une clé
%   INDEX.noms, .nTrames, .P

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
% Démo : index de 3 morceaux synthétiques de 30 s.
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
