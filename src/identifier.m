function R = identifier(x, INDEX, P)
%IDENTIFIER  Étape 5b : alignement temporel et décision.
%   R = identifier(x, INDEX, P)   avec x déjà prétraité (colonne à P.Fe).
%
%   Chaque clé de la requête retrouve toutes ses entrées dans l'index.
%   Pour un appariement (ancre requête m_q, ancre référence m_r), on calcule
%   δ = m_r - m_q. Si l'extrait vient du morceau, tous les bons appariements
%   donnent le même δ (propriété (1)) ; les appariements fortuits sont
%   dispersés. Le score d'un morceau est la hauteur du plus grand pic de son
%   histogramme des δ, et non le nombre de clés communes.
%
%   R.id        : morceau reconnu, 0 si « inconnu » (score < P.s_thr)
%   R.id_max    : morceau de score maximal (même s'il est sous le seuil)
%   R.score     : score de ce morceau
%   R.delta     : δ du pic (trames) ; position estimée = delta*H/Fe secondes
%   R.scores    : score de chaque morceau de l'index
%   R.app       : tous les appariements [id, δ, m_q, m_r]
%   R.nCles     : nombre de clés de la requête
%   R.pics, R.SdB : constellation et spectrogramme de la requête
%
%   R = identifier(x, INDEX)   P par défaut : les paramètres de l'index (INDEX.P).
%   identifier()               démonstration autonome (3 morceaux synthétiques).

if nargin == 0
    R = demo();
    return;
end
if nargin < 3 || isempty(P)
    if isfield(INDEX, 'P')
        P = INDEX.P;                % mêmes réglages que l'index : mêmes clés
    else
        P = parametres_par_defaut();
    end
end

[E, R.pics, R.SdB] = empreintes_signal(x, P);
R.nCles = size(E, 1);
nM = numel(INDEX.noms);

% Recherche de toutes les entrées de chaque clé de la requête
[trouve, loc] = ismember(uint32(E(:, 1)), INDEX.ucle);
mq = E(trouve, 2);
loc = loc(trouve);
debut = double(INDEX.debut(loc));
nb = double(INDEX.nb(loc));

if isempty(nb)
    R.app = zeros(0, 4);
else
    total = sum(nb);
    % indices des entrées : debut, debut+1, ..., debut+nb-1 pour chaque clé
    decal = (1:total)' - repelem(cumsum([0; nb(1:end-1)]), nb) - 1;
    idx = repelem(debut, nb) + decal;
    mqR = repelem(mq, nb);
    mr = double(INDEX.m1(idx));
    id = double(INDEX.id(idx));
    R.app = [id, mr - mqR, mqR, mr];
end

% Histogramme des δ par morceau : vote dans la case (id, δ)
R.scores = zeros(nM, 1);
R.deltas = zeros(nM, 1);
if ~isempty(R.app)
    dmin = min(R.app(:, 2));
    col = R.app(:, 2) - dmin + 1;
    V = accumarray([R.app(:, 1), col], 1, [nM, max(col)], [], [], true);
    [s, c] = max(V, [], 2);
    R.scores = full(s);
    R.deltas = full(c) + dmin - 1;
end

[R.score, R.id_max] = max(R.scores);
R.delta = R.deltas(R.id_max);
if R.score >= P.s_thr
    R.id = R.id_max;
else
    R.id = 0;
end
end

function R = demo()
% Démonstration : 3 « morceaux » synthétiques indexés ; une requête de Tq secondes
% tirée du 2e à un instant quelconque, puis une requête absente de l'index.
P = parametres_par_defaut();
morceaux = arrayfun(@(g) morceau_synthetique(30, P.Fe, g), 1:3, 'UniformOutput', false);
INDEX = construire_index(morceaux, P, {'morceau A', 'morceau B', 'morceau C'});

debut = 81234;                                  % en échantillons : pas un multiple de H
y = morceaux{2}(debut:debut + P.Tq * P.Fe - 1);
R = identifier(y, INDEX, P);
fprintf(['identifier : requête de %g s tirée de « morceau B » à %.2f s -> réponse « %s », ' ...
    'score %d (seuil %d), position estimée %.2f s.\n'], P.Tq, (debut - 1) / P.Fe, ...
    INDEX.noms{max(R.id, 1)}, R.score, P.s_thr, R.delta * P.H / P.Fe);
fprintf('  scores des 3 morceaux : %s\n', mat2str(R.scores'));

absent = morceau_synthetique(P.Tq, P.Fe, 99);
R2 = identifier(absent, INDEX, P);
fprintf('  requête absente de l''index -> %s (score %d < %d).\n', ...
    ternaire(R2.id == 0, '« inconnu »', INDEX.noms{max(R2.id, 1)}), R2.score, P.s_thr);

% Histogramme des δ du bon morceau : un pic net en δ = m0
d = R.app(R.app(:, 1) == R.id_max, 2);
[u, ~, ic] = unique(d);
figure('Name', 'identifier');
stem(u, accumarray(ic, 1), 'Marker', 'none');
xlabel('\delta = m_{réf} - m_{req} (trames)');  ylabel('appariements');
title(['Histogramme des \delta du meilleur candidat : score ' num2str(R.score)]);
end

function s = ternaire(c, a, b)
if c, s = a; else, s = b; end
end

function P = parametres_par_defaut()
% Ajoute le projet au chemin MATLAB et renvoie les paramètres de départ.
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'src'), fullfile(racine, 'utils'));
P = parametres();
end
