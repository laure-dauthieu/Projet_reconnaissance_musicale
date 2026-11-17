function [base, horsBase] = preparer_base(dossierData, nBase, nHors, graine)
%PREPARER_BASE  Choisit les morceaux de la base et les morceaux hors base.
%   [base, horsBase] = preparer_base(dossierData, nBase, nHors, graine)
%
%   dossierData : dossier qui contient fma_small/ et fma_metadata/.
%   nBase       : nombre de morceaux indexés (le sujet en demande au moins 100).
%   nHors       : nombre de morceaux absents de la base, pour les requêtes
%                 négatives (au moins 50 requêtes négatives demandées).
%   graine      : graine du tirage, pour que le choix soit reproductible.
%
%   Les deux ensembles sont répartis équitablement sur les 8 genres de
%   fma_small (Electronic, Experimental, Folk, Hip-Hop, Instrumental,
%   International, Pop, Rock) et sont disjoints. Les fichiers illisibles ou
%   de moins de 25 s (quelques-uns dans fma_small) sont écartés.
%
%   Sorties : tables avec id, artiste, titre, genre, licence, duree (s),
%   chemin (absolu) et role ("base" ou "hors base").

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
