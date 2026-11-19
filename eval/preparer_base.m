function [base, horsBase] = preparer_base(dossierData, nBase, nHors, graine)
%PREPARER_BASE  Choisit les morceaux de la base et ceux hors base (FMA).
%   [base, horsBase] = preparer_base(dossierData, nBase, nHors, graine)
%
%   dossierData : dossier contenant fma_small/ et fma_metadata/.
%   nBase, nHors : morceaux indexés, et morceaux absents pour les requêtes négatives.
%   Les deux ensembles sont disjoints et répartis sur les 8 genres ; les
%   fichiers illisibles ou de moins de 25 s sont écartés.
%   Sorties : tables id, artiste, titre, genre, licence, duree, chemin, role.

meta = lire_metadonnees(fullfile(dossierData, 'fma_metadata', 'tracks.csv'));
meta = meta(meta.subset == "small", :);
meta.chemin = arrayfun(@(id) fullfile(dossierData, 'fma_small', ...
    sprintf('%03d', floor(id/1000)), sprintf('%06d.mp3', id)), meta.id, 'UniformOutput', false);
meta.chemin = string(meta.chemin);

genres = unique(meta.genre);
nG = numel(genres);
rs = RandStream('mt19937ar', 'Seed', graine);

% Nombre de morceaux par genre (le reste de la division va aux premiers genres)
parGenre = @(n) floor(n/nG) + ((1:nG)' <= mod(n, nG));
besoinBase = parGenre(nBase);
besoinHors = parGenre(nHors);

lignesBase = [];
lignesHors = [];
meta.duree = nan(height(meta), 1);
for g = 1:nG
    idx = find(meta.genre == genres(g));
    idx = idx(randperm(rs, numel(idx)));
    pris = [];
    for i = idx'
        if numel(pris) == besoinBase(g) + besoinHors(g), break; end
        d = duree_lisible(meta.chemin(i));
        if d >= 25
            meta.duree(i) = d;
            pris(end+1) = i; %#ok<AGROW>
        end
    end
    lignesBase = [lignesBase; pris(1:besoinBase(g))']; %#ok<AGROW>
    lignesHors = [lignesHors; pris(besoinBase(g)+1:end)']; %#ok<AGROW>
end

base = meta(lignesBase, {'id', 'artiste', 'titre', 'genre', 'licence', 'duree', 'chemin'});
horsBase = meta(lignesHors, {'id', 'artiste', 'titre', 'genre', 'licence', 'duree', 'chemin'});
base.role = repmat("base", height(base), 1);
horsBase.role = repmat("hors base", height(horsBase), 1);
end

function T = lire_metadonnees(fichier)
% tracks.csv a 3 lignes d'en-tête et 53 colonnes ; on garde celles utiles.
opts = delimitedTextImportOptions('NumVariables', 53, 'DataLines', [4 Inf], 'Delimiter', ',');
opts.VariableTypes = repmat({'string'}, 1, 53);
opts.SelectedVariableNames = opts.VariableNames([1 27 33 41 47 53]);
T = readtable(fichier, opts);
T.Properties.VariableNames = {'id', 'artiste', 'subset', 'genre', 'licence', 'titre'};
T.id = str2double(T.id);
end

function d = duree_lisible(chemin)
% Durée du fichier en secondes, 0 s'il est absent ou illisible.
try
    info = audioinfo(chemin);
    d = info.Duration;
catch
    d = 0;
end
end
