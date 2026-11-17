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
