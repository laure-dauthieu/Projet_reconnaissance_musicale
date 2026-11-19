function R = identifier(x, INDEX, P)
%IDENTIFIER  Étape 5b : retrouve le morceau d'où vient l'extrait x.
%   R = identifier(x, INDEX, P)   x prétraité (colonne à P.Fe)
%   R = identifier(x, INDEX)      avec les réglages de l'index (INDEX.P)
%   identifier()                  démo sur 3 morceaux synthétiques
%
%   Chaque clé commune vote pour un décalage δ = m_réf - m_req. Le bon morceau
%   met presque tous ses votes sur le même δ ; son score est la hauteur de ce pic.
%
%   R.id       morceau reconnu, 0 si inconnu (score < s_thr)
%   R.id_max   meilleur morceau, même sous le seuil
%   R.score    son score ; R.delta : δ du pic (position = delta*H/Fe secondes)
%   R.scores   score de chaque morceau
%   R.app      appariements [id, δ, m_q, m_r]
%   R.nCles, R.pics, R.SdB   clés, pics et spectrogramme de la requête

if nargin == 0
    R = demo();
    return;
end
if nargin < 3 || isempty(P)
    if isfield(INDEX, 'P')
        P = INDEX.P;                % sinon les clés ne correspondraient pas
    else
        P = parametres_par_defaut();
    end
end

[E, R.pics, R.SdB] = empreintes_signal(x, P);
R.nCles = size(E, 1);
nM = numel(INDEX.noms);

% Toutes les entrées de l'index pour chaque clé de la requête
[trouve, loc] = ismember(uint32(E(:, 1)), INDEX.ucle);
mq = E(trouve, 2);
loc = loc(trouve);
debut = double(INDEX.debut(loc));
nb = double(INDEX.nb(loc));

if isempty(nb)
    R.app = zeros(0, 4);
else
    total = sum(nb);
    % entrées debut, debut+1, ..., debut+nb-1 de chaque clé, sans boucle
    decal = (1:total)' - repelem(cumsum([0; nb(1:end-1)]), nb) - 1;
    idx = repelem(debut, nb) + decal;
    mqR = repelem(mq, nb);
    mr = double(INDEX.m1(idx));
    id = double(INDEX.id(idx));
    R.app = [id, mr - mqR, mqR, mr];
end

% Histogramme des δ de chaque morceau ; score = hauteur de son pic
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
% Démo : un extrait du morceau B est reconnu, un morceau absent est rejeté.
P = parametres_par_defaut();
morceaux = arrayfun(@(g) morceau_synthetique(30, P.Fe, g), 1:3, 'UniformOutput', false);
INDEX = construire_index(morceaux, P, {'morceau A', 'morceau B', 'morceau C'});

debut = 81234;                  % volontairement pas un multiple de H
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

% le bon morceau doit montrer un pic net
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
