function P = parametres(varargin)
%PARAMETRES  Tous les réglages de la chaîne.
%   P = parametres()                     valeurs de départ du sujet (§8)
%   P = parametres('F', 15, 'Tq', 5)     en change certaines ; H, K, M... sont recalculés
%
%   Justification de chaque valeur : resultats/parametres_finaux.md.

% Étape 1 : prétraitement
P.Fe = 8000;            % Hz, bande utile 0-4 kHz (Q1)

% Étape 2 : spectrogramme
P.N = 1024;             % fenêtre de 128 ms, Δf ≈ 11 Hz (Q2)

% Étape 3 : constellation
P.dk = 5;               % voisinage : ±5 canaux
P.dm = 3;               % voisinage : ±3 trames
P.f_min = 200;          % bandes géométriques de 200 à 4000 Hz
P.f_max = 4000;
P.Nb    = 6;            % nombre de bandes
P.rho      = 30;        % pics/s visés (Inf = pas de quota)
P.marge_dB = 6;         % seuil local = médiane de la bande + 6 dB
P.T_mediane = 2;        % médiane glissante sur 2 s

% Étape 4 : empreintes
P.dt_min  = 0.1;        % zone cible : 0,1 à 2 s après l'ancre
P.dt_max  = 2;
P.dk_max  = 60;         % et au plus 60 canaux d'écart
P.F       = 10;         % cibles par ancre
P.gamma_f = 1;          % canaux par classe de fréquence

% Étape 5 : décision
P.s_thr = 35;           % 1,5 x le plus fort score négatif de calibration (23), Q5

% Requêtes
P.Tq = 8;               % durée d'une requête (s)

% ffmpeg (pour le MP3) : MATLAB lancé depuis le Dock du Mac ne voit pas le PATH,
% d'où les chemins Homebrew essayés en premier.
if isfile('/opt/homebrew/bin/ffmpeg')
    P.ffmpeg = '/opt/homebrew/bin/ffmpeg';
elseif isfile('/usr/local/bin/ffmpeg')
    P.ffmpeg = '/usr/local/bin/ffmpeg';
else
    P.ffmpeg = 'ffmpeg';
end

% Valeurs passées en argument
if mod(numel(varargin), 2) ~= 0
    error('parametres:arguments', 'Arguments attendus par paires : nom, valeur.');
end
for i = 1:2:numel(varargin)
    nom = varargin{i};
    if ~isfield(P, nom)
        error('parametres:inconnu', 'Paramètre inconnu : %s', nom);
    end
    P.(nom) = varargin{i+1};
end

% Grandeurs dérivées (calculées, ne pas les régler à la main)
P.H    = P.N/2;                         % avance entre trames
P.Nfft = P.N;
P.K    = P.Nfft/2 + 1;                  % canaux (513)
P.bandes = P.f_min * (P.f_max/P.f_min).^((0:P.Nb)/P.Nb);
P.dm_min = ceil(P.dt_min * P.Fe / P.H);     % 2 trames
P.dm_max = floor(P.dt_max * P.Fe / P.H);    % 31 trames
P.Nt = P.dm_max - P.dm_min + 1;             % valeurs possibles de Δm
P.Nf = ceil(P.K / P.gamma_f);               % classes de fréquence
P.M  = P.Nf^2 * P.Nt;                       % clés possibles (7,9e6)
end
