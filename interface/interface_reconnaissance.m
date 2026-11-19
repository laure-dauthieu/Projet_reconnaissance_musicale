function fig = interface_reconnaissance()
%INTERFACE_RECONNAISSANCE  Interface de paramétrage et démo de la reconnaissance musicale.
%   interface_reconnaissance() ouvre une fenêtre qui permet :
%     - de capter une requête au micro (Tq secondes), de prendre un extrait de la base
%       ou de charger un fichier audio ;
%     - d'y ajouter un bruit blanc à un RSB donné (démonstration de robustesse) ;
%     - de régler N, le voisinage (±trames, ±canaux), F, gamma_f, s_thr et Tq ;
%     - d'identifier la requête et d'afficher le spectrogramme avec la constellation,
%       l'histogramme des δ du meilleur candidat et les scores des meilleurs morceaux.
%
%   Données nécessaires (dossier cache/) :
%     index_base.mat   : index des 100 morceaux (sur git) ; suffit pour identifier
%                        et pour régler s_thr et Tq ;
%     base.mat         : titres, artistes et genres (facultatif) ;
%     signaux_base.mat : signaux à 8 kHz (pas sur git) ; nécessaire pour prendre un
%                        extrait de la base et pour reconstruire l'index quand on
%                        change N, le voisinage, F ou gamma_f.
%
%   Écrite avec uifigure dans un fichier .m plutôt qu'avec App Designer : un .mlapp
%   est un fichier binaire, illisible dans git.

%% Chemins et données
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'src'), fullfile(racine, 'utils'), ...
    fullfile(racine, 'eval', 'degradations'));
dossierCache = fullfile(racine, 'cache');

fichierIndex = fullfile(dossierCache, 'index_base.mat');
if ~isfile(fichierIndex)
    error('interface:index', 'Index introuvable : %s', fichierIndex);
end
S = load(fichierIndex, 'INDEX');
etat.INDEX = S.INDEX;                       % index courant
etat.cleIndex = cle_index(S.INDEX.P);       % réglages avec lesquels il a été construit
etat.noms = S.INDEX.noms;
etat.genres = repmat({''}, numel(etat.noms), 1);
fichierBase = fullfile(dossierCache, 'base.mat');
if isfile(fichierBase)
    B = load(fichierBase, 'base');
    etat.noms = cellstr(B.base.artiste + " – " + B.base.titre);
    etat.genres = cellstr(B.base.genre);
end
etat.fichierSignaux = fullfile(dossierCache, 'signaux_base.mat');
etat.signaux = {};                          % chargés à la première utilisation
etat.y = [];                                % requête brute, à P.Fe (avant bruit)
etat.source = '';                           % description de la requête
etat.vrai = 0;                              % morceau d'origine si connu
etat.t0 = NaN;                              % instant de début dans ce morceau (s)
etat.enreg = [];                            % audiorecorder en cours
etat.minuteur = [];
Fe_micro = 44100;

P0 = parametres('Tq', 5);                   % valeurs du rapport : Tq = 5 s, s_thr = 35

%% Fenêtre
fig = uifigure('Name', 'Reconnaissance musicale par empreintes', ...
    'Position', [60 60 1380 820], 'CloseRequestFcn', @fermer);
grille = uigridlayout(fig, [1 2], 'ColumnWidth', {330, '1x'}, 'Padding', [8 8 8 8]);

% ---------------- Colonne de gauche : commandes ----------------
gauche = uigridlayout(grille, [4 1], 'RowHeight', {'fit', 'fit', 'fit', '1x'}, ...
    'Padding', [0 0 0 0], 'RowSpacing', 8);

% 1. Requête
pReq = uipanel(gauche, 'Title', '1. Requête', 'FontWeight', 'bold');
gReq = uigridlayout(pReq, [7 2], 'RowHeight', repmat({'fit'}, 1, 7), ...
    'ColumnWidth', {'1x', '1x'});
bMicro = uibutton(gReq, 'Text', '● Enregistrer au micro', 'FontWeight', 'bold', ...
    'ButtonPushedFcn', @enregistrer);
bMicro.Layout.Column = [1 2];
uilabel(gReq, 'Text', 'Morceau de la base :');
ddMorceau = uidropdown(gReq, 'Items', compose('%d. %s', (1:numel(etat.noms))', string(etat.noms)), ...
    'ItemsData', 1:numel(etat.noms));
ddMorceau.Layout.Row = 3;  ddMorceau.Layout.Column = [1 2];
uilabel(gReq, 'Text', 'Début de l''extrait (s) :');
spDebut = uispinner(gReq, 'Limits', [0 25], 'Value', 10, 'Step', 0.5);
uibutton(gReq, 'Text', 'Prendre l''extrait', 'ButtonPushedFcn', @(~, ~) extrait_base(false));
uibutton(gReq, 'Text', 'Extrait au hasard', 'ButtonPushedFcn', @(~, ~) extrait_base(true));
bFichier = uibutton(gReq, 'Text', 'Charger un fichier audio…', 'ButtonPushedFcn', @charger_fichier);
bFichier.Layout.Column = [1 2];
uilabel(gReq, 'Text', 'Dégradation :');
ddBruit = uidropdown(gReq, 'Items', {'Aucune', 'Bruit blanc 10 dB', 'Bruit blanc 5 dB', 'Bruit blanc 0 dB'}, ...
    'ItemsData', [Inf 10 5 0]);
lblSource = uilabel(gReq, 'Text', 'Aucune requête.', 'WordWrap', 'on', 'FontAngle', 'italic');
lblSource.Layout.Column = [1 2];

% 2. Paramètres
pPar = uipanel(gauche, 'Title', '2. Paramètres', 'FontWeight', 'bold');
gPar = uigridlayout(pPar, [8 2], 'RowHeight', repmat({'fit'}, 1, 8), 'ColumnWidth', {'1.3x', '1x'});
uilabel(gPar, 'Text', 'N (fenêtre, points)');
ddN = uidropdown(gPar, 'Items', {'256', '512', '1024', '2048'}, 'ItemsData', [256 512 1024 2048], ...
    'Value', P0.N, 'ValueChangedFcn', @reglage_change);
uilabel(gPar, 'Text', 'Voisinage ± trames (m_v)');
spDm = uispinner(gPar, 'Limits', [1 8], 'Value', P0.dm, 'Step', 1, 'ValueChangedFcn', @reglage_change);
uilabel(gPar, 'Text', 'Voisinage ± canaux (k_v)');
spDk = uispinner(gPar, 'Limits', [1 15], 'Value', P0.dk, 'Step', 1, 'ValueChangedFcn', @reglage_change);
uilabel(gPar, 'Text', 'F (cibles par ancre)');
spF = uispinner(gPar, 'Limits', [1 20], 'Value', P0.F, 'Step', 1, 'ValueChangedFcn', @reglage_change);
uilabel(gPar, 'Text', 'γf (canaux par classe)');
ddGf = uidropdown(gPar, 'Items', {'1', '2', '4', '8'}, 'ItemsData', [1 2 4 8], ...
    'Value', P0.gamma_f, 'ValueChangedFcn', @reglage_change);
uilabel(gPar, 'Text', 'Seuil s_thr');
spSthr = uispinner(gPar, 'Limits', [1 500], 'Value', P0.s_thr, 'Step', 1);
uilabel(gPar, 'Text', 'Durée Tq (s)');
spTq = uispinner(gPar, 'Limits', [1 20], 'Value', P0.Tq, 'Step', 1);
bDefaut = uibutton(gPar, 'Text', 'Valeurs du rapport', 'ButtonPushedFcn', @valeurs_defaut);
bDefaut.Layout.Column = [1 2];

% 3. Identification
pId = uipanel(gauche, 'Title', '3. Identification', 'FontWeight', 'bold');
gId = uigridlayout(pId, [2 2], 'RowHeight', {'fit', 'fit'});
bIdent = uibutton(gId, 'Text', 'Identifier', 'FontWeight', 'bold', 'FontSize', 15, ...
    'BackgroundColor', [0.20 0.45 0.75], 'FontColor', 'w', 'ButtonPushedFcn', @identifier_requete);
bIdent.Layout.Column = [1 2];
uibutton(gId, 'Text', '▶ Écouter la requête', 'ButtonPushedFcn', @ecouter);
uibutton(gId, 'Text', '■ Arrêter le son', 'ButtonPushedFcn', @(~, ~) clear('sound'));

% Journal
lblEtat = uitextarea(gauche, 'Editable', 'off', 'FontSize', 11, ...
    'Value', {sprintf('Index chargé : %d morceaux, %d entrées.', numel(etat.noms), numel(etat.INDEX.cle))});

% ---------------- Colonne de droite : résultats ----------------
droite = uigridlayout(grille, [3 2], 'RowHeight', {'fit', '1.2x', '1x'}, 'Padding', [0 0 0 0]);
lblRes = uilabel(droite, 'Text', 'Choisissez une requête, puis « Identifier ».', 'FontSize', 20, ...
    'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'WordWrap', 'on');
lblRes.Layout.Column = [1 2];
axSpec = uiaxes(droite);  axSpec.Layout.Column = [1 2];
axDelta = uiaxes(droite);
axScores = uiaxes(droite);
titre_axes();

%% Fonctions internes

    function P = reglages()
        % Paramètres courants lus dans l'interface.
        P = parametres('N', ddN.Value, 'dm', spDm.Value, 'dk', spDk.Value, ...
            'F', spF.Value, 'gamma_f', ddGf.Value, 's_thr', spSthr.Value, 'Tq', spTq.Value);
    end

    function journal(msg)
        lblEtat.Value = [{msg}; lblEtat.Value(:)];
        drawnow;
    end

    function reglage_change(~, ~)
        if ~isequal(cle_index(reglages()), etat.cleIndex)
            journal('Réglage modifié : l''index sera reconstruit à la prochaine identification.');
        end
    end

    function valeurs_defaut(~, ~)
        ddN.Value = P0.N;  spDm.Value = P0.dm;  spDk.Value = P0.dk;  spF.Value = P0.F;
        ddGf.Value = P0.gamma_f;  spSthr.Value = P0.s_thr;  spTq.Value = P0.Tq;
        journal('Valeurs du rapport rétablies (N = 1024, ±3 × ±5, F = 10, γf = 1, s_thr = 35, Tq = 5 s).');
    end

    function ok = charger_signaux()
        % Charge signaux_base.mat la première fois qu'on en a besoin.
        ok = ~isempty(etat.signaux);
        if ok, return; end
        if ~isfile(etat.fichierSignaux)
            uialert(fig, sprintf(['signaux_base.mat est introuvable dans cache/.\n' ...
                'Il faut ce fichier pour prendre un extrait de la base ou changer N, ' ...
                'le voisinage, F ou γf.']), 'Fichier manquant');
            return;
        end
        d = uiprogressdlg(fig, 'Title', 'Chargement', 'Message', ...
            'Chargement des signaux de la base (184 Mo)…', 'Indeterminate', 'on');
        T = load(etat.fichierSignaux, 'signauxBase');
        etat.signaux = T.signauxBase;
        close(d);
        ok = true;
    end

    function ok = index_a_jour(P)
        % Reconstruit l'index si N, le voisinage, F ou gamma_f ont changé.
        ok = true;
        if isequal(cle_index(P), etat.cleIndex), return; end
        if ~charger_signaux(), ok = false; return; end
        d = uiprogressdlg(fig, 'Title', 'Index', 'Message', sprintf( ...
            'Reconstruction de l''index (N = %d, ±%d trames × ±%d canaux, F = %d, γf = %d)…', ...
            P.N, P.dm, P.dk, P.F, P.gamma_f), 'Indeterminate', 'on');
        tic;
        etat.INDEX = construire_index(etat.signaux, P, etat.INDEX.noms);
        etat.cleIndex = cle_index(P);
        close(d);
        journal(sprintf('Index reconstruit en %.1f s : %d entrées.', toc, numel(etat.INDEX.cle)));
        if P.s_thr == P0.s_thr && ~isequal(cle_index(P), cle_index(P0))
            journal(['Attention : s_thr = 35 a été calibré pour les réglages du rapport. ' ...
                'Avec d''autres réglages, les scores des mauvais morceaux changent.']);
        end
    end

    function definir_requete(y, source, vrai, t0)
        etat.y = y(:);  etat.source = source;  etat.vrai = vrai;  etat.t0 = t0;
        lblSource.Text = sprintf('%s (%.1f s)', source, numel(y) / P0.Fe);
        journal(['Requête : ' source]);
    end

    function extrait_base(auHasard)
        if ~charger_signaux(), return; end
        P = reglages();
        if auHasard
            ddMorceau.Value = randi(numel(etat.signaux));
        end
        x = etat.signaux{ddMorceau.Value};
        duree = numel(x) / P.Fe;
        if duree <= P.Tq
            uialert(fig, 'Le morceau est plus court que Tq.', 'Extrait impossible');
            return;
        end
        if auHasard
            % début tiré au hasard en échantillons : pas aligné sur la grille des trames
            debut = randi(numel(x) - round(P.Tq * P.Fe));
            spDebut.Value = min(spDebut.Limits(2), round((debut - 1) / P.Fe * 10) / 10);
        else
            debut = round(spDebut.Value * P.Fe) + 1;
            debut = min(debut, numel(x) - round(P.Tq * P.Fe));
        end
        y = x(debut:debut + round(P.Tq * P.Fe) - 1);
        t0 = (debut - 1) / P.Fe;
        definir_requete(y, sprintf('Extrait de « %s » à %.2f s', etat.noms{ddMorceau.Value}, t0), ...
            ddMorceau.Value, t0);
    end

    function charger_fichier(~, ~)
        [nom, chemin] = uigetfile({'*.wav;*.mp3;*.m4a;*.flac;*.ogg', 'Fichiers audio'}, ...
            'Choisir un fichier audio');
        figure(fig);
        if isequal(nom, 0), return; end
        try
            y = pretraitement(fullfile(chemin, nom), P0);
        catch err
            uialert(fig, err.message, 'Lecture impossible');
            return;
        end
        % on garde Tq secondes à partir du début choisi (ou du début du fichier)
        P = reglages();
        debut = min(round(spDebut.Value * P.Fe) + 1, max(1, numel(y) - round(P.Tq * P.Fe)));
        y = y(debut:min(end, debut + round(P.Tq * P.Fe) - 1));
        definir_requete(y, sprintf('Fichier « %s » à partir de %.1f s', nom, (debut - 1) / P.Fe), 0, NaN);
    end

    function enregistrer(~, ~)
        if ~isempty(etat.enreg), return; end
        P = reglages();
        try
            etat.enreg = audiorecorder(Fe_micro, 16, 1);
            record(etat.enreg);
        catch err
            etat.enreg = [];
            uialert(fig, ['Micro indisponible : ' err.message], 'Enregistrement impossible');
            return;
        end
        bMicro.Enable = 'off';
        t_debut = tic;
        etat.minuteur = timer('Period', 0.2, 'ExecutionMode', 'fixedRate', ...
            'TimerFcn', @(~, ~) tic_enregistrement(t_debut, P.Tq));
        start(etat.minuteur);
    end

    function tic_enregistrement(t_debut, Tq)
        if ~isvalid(fig), return; end
        reste = Tq - toc(t_debut);
        if reste > 0
            bMicro.Text = sprintf('● Enregistrement… %.1f s', reste);
            return;
        end
        stop(etat.minuteur);  delete(etat.minuteur);  etat.minuteur = [];
        stop(etat.enreg);
        y = getaudiodata(etat.enreg);
        etat.enreg = [];
        bMicro.Text = '● Enregistrer au micro';  bMicro.Enable = 'on';
        y = pretraitement(y, P0, Fe_micro);
        definir_requete(y, 'Enregistrement au micro', 0, NaN);
        identifier_requete();
    end

    function y = requete_degradee(P)
        % Requête limitée à Tq secondes, avec le bruit choisi (ajouté à 8 kHz).
        y = etat.y(1:min(end, round(P.Tq * P.Fe)));
        if isfinite(ddBruit.Value)
            y = ajouter_bruit(y, ddBruit.Value);
        end
    end

    function ecouter(~, ~)
        if isempty(etat.y), return; end
        y = requete_degradee(reglages());
        sound(y / max(abs(y) + eps), P0.Fe);
    end

    function identifier_requete(~, ~)
        if isempty(etat.y)
            uialert(fig, 'Choisissez d''abord une requête (micro, extrait ou fichier).', 'Pas de requête');
            return;
        end
        P = reglages();
        if ~index_a_jour(P), return; end
        y = requete_degradee(P);
        tic;
        R = identifier(y, etat.INDEX, P);
        t = toc;
        afficher(R, P, y, t);
    end

    function afficher(R, P, y, t)
        % --- Résultat en texte
        if R.id > 0
            txt = sprintf('Reconnu : %s', etat.noms{R.id});
            if ~isempty(etat.genres{R.id}), txt = sprintf('%s (%s)', txt, etat.genres{R.id}); end
            lblRes.FontColor = [0.10 0.50 0.15];
        else
            txt = 'Inconnu : aucun morceau ne dépasse le seuil';
            lblRes.FontColor = [0.85 0.40 0.05];
        end
        pos = R.delta * P.H / P.Fe;
        detail = sprintf('score %d (seuil %d) · position estimée %.2f s · %d clés · %.0f ms', ...
            R.score, P.s_thr, pos, R.nCles, 1000 * t);
        if etat.vrai > 0
            if R.id == etat.vrai
                verdict = 'bonne réponse';
            elseif R.id == 0
                verdict = 'non-détection';
            else
                verdict = 'CONFUSION';
            end
            detail = sprintf('%s\nVérité : %s à %.2f s → %s', detail, etat.noms{etat.vrai}, etat.t0, verdict);
        end
        if isfinite(ddBruit.Value)
            detail = sprintf('%s · bruit blanc à %g dB', detail, ddBruit.Value);
        end
        lblRes.Text = {txt, detail};
        lblRes.FontSize = 18;
        journal(sprintf('Identification : %s, score %d, %.0f ms.', txt, R.score, 1000 * t));

        % --- Spectrogramme et constellation
        cla(axSpec);
        K = size(R.SdB, 1);  M = size(R.SdB, 2);
        f = (0:K - 1) * P.Fe / P.Nfft;
        tt = ((0:M - 1) * P.H + P.N / 2) / P.Fe;
        imagesc(axSpec, tt, f / 1000, R.SdB);  axis(axSpec, 'xy');  hold(axSpec, 'on');
        colormap(axSpec, flipud(gray));
        v = sort(R.SdB(:));  clim(axSpec, [v(max(1, round(0.25 * end))), v(round(0.995 * end))]);
        if ~isempty(R.pics)
            plot(axSpec, tt(R.pics(:, 1)), f(R.pics(:, 2)) / 1000, 'o', 'MarkerSize', 4, ...
                'MarkerFaceColor', [0.85 0.10 0.10], 'MarkerEdgeColor', 'w', 'LineWidth', 0.4);
        end
        hold(axSpec, 'off');
        xlim(axSpec, [0, numel(y) / P.Fe]);  ylim(axSpec, [0, P.Fe / 2000]);
        title(axSpec, sprintf('Spectrogramme de la requête et constellation : %d pics en %.1f s (%.1f pics/s)', ...
            size(R.pics, 1), numel(y) / P.Fe, size(R.pics, 1) / (numel(y) / P.Fe)));
        xlabel(axSpec, 'temps (s)');  ylabel(axSpec, 'fréquence (kHz)');

        % --- Histogramme des δ du meilleur candidat
        cla(axDelta);
        c = R.id_max;
        if ~isempty(R.app) && R.score > 0
            d = R.app(R.app(:, 1) == c, 2);
            [u, ~, ic] = unique(d);
            n = accumarray(ic, 1);
            stem(axDelta, u, n, 'Marker', 'none', 'LineWidth', 1.2, ...
                'Color', ternaire(R.id > 0, [0.85 0.33 0.10], [0.5 0.5 0.5]));
            hold(axDelta, 'on');
            yline(axDelta, P.s_thr, '--', sprintf('s_{thr} = %d', P.s_thr), 'Color', [0.2 0.2 0.2], ...
                'LabelHorizontalAlignment', 'left');
            hold(axDelta, 'off');
            ylim(axDelta, [0, max([n; P.s_thr]) * 1.12]);
        end
        title(axDelta, sprintf('Histogramme des δ du meilleur candidat (n° %d) : pic = score %d', c, R.score));
        xlabel(axDelta, 'δ = m_{réf} − m_{req} (trames)');  ylabel(axDelta, 'appariements');

        % --- Scores des 10 meilleurs morceaux
        cla(axScores);
        [s, ordre] = sort(R.scores, 'descend');
        nAff = min(10, numel(s));
        s = s(1:nAff);  ordre = ordre(1:nAff);
        b = barh(axScores, flipud(s), 'FaceColor', 'flat');
        b.CData = repmat([0.55 0.65 0.80], nAff, 1);
        if R.id > 0, b.CData(end, :) = [0.10 0.55 0.20]; end
        hold(axScores, 'on');
        xline(axScores, P.s_thr, '--', 's_{thr}', 'Color', [0.2 0.2 0.2]);
        hold(axScores, 'off');
        etiquettes = cellfun(@(z) raccourcir(z, 28), etat.noms(flipud(ordre)), 'UniformOutput', false);
        axScores.YTick = 1:nAff;  axScores.YTickLabel = etiquettes;
        axScores.XScale = 'log';  xlim(axScores, [0.8, max([s; P.s_thr]) * 1.5]);
        title(axScores, '10 meilleurs scores');
        xlabel(axScores, 'score (échelle log)');
    end

    function titre_axes()
        title(axSpec, 'Spectrogramme de la requête et constellation');
        xlabel(axSpec, 'temps (s)');  ylabel(axSpec, 'fréquence (kHz)');
        title(axDelta, 'Histogramme des δ du meilleur candidat');
        xlabel(axDelta, 'δ (trames)');  ylabel(axDelta, 'appariements');
        title(axScores, '10 meilleurs scores');
        xlabel(axScores, 'score');
    end

    function fermer(~, ~)
        if ~isempty(etat.minuteur) && isvalid(etat.minuteur)
            stop(etat.minuteur);  delete(etat.minuteur);
        end
        if ~isempty(etat.enreg), stop(etat.enreg); end
        clear('sound');
        delete(fig);
    end
end

%% Fonctions locales

function c = cle_index(P)
% Réglages dont dépend l'index : s'ils changent, il faut le reconstruire.
c = [P.N, P.dm, P.dk, P.F, P.gamma_f, P.rho, P.marge_dB, P.Nb, P.f_min, P.f_max, P.dk_max, P.dt_min, P.dt_max];
end

function s = raccourcir(s, n)
if strlength(s) > n
    s = [extractBefore(s, n) '…'];
end
end

function s = ternaire(c, a, b)
if c, s = a; else, s = b; end
end
