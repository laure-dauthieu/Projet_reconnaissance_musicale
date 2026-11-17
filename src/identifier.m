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
