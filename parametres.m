function P = parametres(varargin)
%PARAMETRES  Tous les réglages de la chaîne, en un seul endroit.
%   P = parametres() renvoie une structure utilisée par toutes les
%   fonctions. Les valeurs sont les valeurs de départ du sujet (§8) ;
%   chacune est justifiée dans le rapport (resultats/parametres_finaux.md).
%
%   P = parametres('gamma_f', 4, 'F', 15) remplace des valeurs ; les
%   grandeurs dérivées (H, K, bandes, Δm, Nf, M...) sont recalculées.
%   Sert aux études paramétriques (Q2 à Q4) et à l'interface.
%
%   Notations du sujet : Fe, N, H, Nfft, K, rho, F, gamma_f, Tq, s_thr.

% --- Étape 1 : prétraitement ---------------------------------------------
P.Fe = 8000;            % fréquence d'échantillonnage (Hz) : bande utile 0–4 kHz (Q1)

% --- Étape 2 : spectrogramme ---------------------------------------------
P.N = 1024;             % longueur de fenêtre : Tw = 128 ms, Δf ≈ 11 Hz (Q2)
                        % H = N/2, Nfft = N, K = Nfft/2 + 1 : voir plus bas

% --- Étape 3 : constellation ---------------------------------------------
P.dk = 5;               % demi-largeur du voisinage en canaux (±5)
P.dm = 3;               % demi-largeur du voisinage en trames (±3)
P.f_min = 200;          % bandes géométriques entre f_min et f_max (Hz)
P.f_max = 4000;
P.Nb    = 6;            % nombre de bandes
P.rho      = 30;        % densité visée (pics/s), toutes bandes confondues
                        % (Inf : pas de quota, seuls voisinage et seuil comptent)
P.marge_dB = 6;         % seuil local = médiane de la bande + marge (dB)
P.T_mediane = 2;        % durée de la fenêtre glissante de la médiane (s)

% --- Étape 4 : empreintes ------------------------------------------------
P.dt_min  = 0.1;        % zone cible : Δt dans [dt_min, dt_max] (s)
P.dt_max  = 2;
P.dk_max  = 60;         % zone cible : |k2 - k1| <= dk_max (canaux)
P.F       = 10;         % nombre de cibles par ancre
P.gamma_f = 1;          % canaux regroupés par classe de fréquence

% --- Étape 5 : décision --------------------------------------------------
P.s_thr = 35;           % seuil sur le score : 1,5 x le plus fort score des 50 négatives
                        % de calibration (23), voir experiences/campagne_evaluation (Q5)

% --- Requêtes ------------------------------------------------------------
P.Tq = 8;               % durée d'une requête (s)

% --- Outils externes -----------------------------------------------------
% MATLAB lancé depuis le Dock (Mac) ne voit pas le PATH du terminal : on
% essaie d'abord l'emplacement Homebrew, sinon ffmpeg doit être dans le PATH.
if isfile('/opt/homebrew/bin/ffmpeg')
    P.ffmpeg = '/opt/homebrew/bin/ffmpeg';
elseif isfile('/usr/local/bin/ffmpeg')
    P.ffmpeg = '/usr/local/bin/ffmpeg';
else
    P.ffmpeg = 'ffmpeg';
end

% --- Valeurs modifiées ---------------------------------------------------
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

% --- Grandeurs dérivées (ne pas modifier à la main) ----------------------
P.H    = P.N/2;                                    % avance entre trames (64 ms)
P.Nfft = P.N;                                      % points de TFD
P.K    = P.Nfft/2 + 1;                             % nombre de canaux (513)
P.bandes = P.f_min * (P.f_max/P.f_min).^((0:P.Nb)/P.Nb);  % 200 | 330 | ... | 4000
P.dm_min = ceil(P.dt_min * P.Fe / P.H);            % 2 trames
P.dm_max = floor(P.dt_max * P.Fe / P.H);           % 31 trames
P.Nt = P.dm_max - P.dm_min + 1;                    % 30 valeurs de Δm
P.Nf = ceil(P.K / P.gamma_f);                      % classes de fréquence
P.M  = P.Nf^2 * P.Nt;                              % nombre de clés possibles
end
