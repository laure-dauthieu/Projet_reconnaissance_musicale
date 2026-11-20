function fig = interface_reconnaissance()
%INTERFACE_RECONNAISSANCE  Interface de paramétrage et de démonstration.
%   interface_reconnaissance()
%
%   1. Requête : micro (Tq secondes), extrait de la base ou fichier audio,
%      avec un bruit blanc optionnel.
%   2. Réglages : N, voisinage, F, γf, s_thr, Tq. L'index est reconstruit
%      automatiquement si N, le voisinage, F ou γf changent.
%   3. Résultat : morceau reconnu, spectrogramme et constellation, histogramme
%      des δ, meilleurs scores, historique des essais.
%
%   Fichiers utilisés (dossier cache/) :
%     index_base.mat    index des 100 morceaux (sur git), suffit pour identifier ;
%     base.mat          titres, artistes, genres (facultatif) ;
%     signaux_base.mat  signaux à 8 kHz (hors git) : extraits de la base et
%                       reconstruction de l'index.
%
%   Écrite avec uifigure dans un .m (un .mlapp est binaire, illisible dans git).

%% Données
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'src'), fullfile(racine, 'utils'), ...
    fullfile(racine, 'eval', 'degradations'));
dossierCache = fullfile(racine, 'cache');

fichierIndex = fullfile(dossierCache, 'index_base.mat');
if ~isfile(fichierIndex)
    error('interface:index', 'Index introuvable : %s', fichierIndex);
end
S = load(fichierIndex, 'INDEX');
etat.INDEX = S.INDEX;
etat.cleIndex = cle_index(S.INDEX.P);       % réglages avec lesquels l'index a été construit
etat.noms = S.INDEX.noms;
etat.artistes = repmat({''}, numel(etat.noms), 1);
etat.titres = etat.noms;
etat.genres = repmat({''}, numel(etat.noms), 1);
if isfile(fullfile(dossierCache, 'base.mat'))
    B = load(fullfile(dossierCache, 'base.mat'), 'base');
    etat.artistes = cellstr(B.base.artiste);
    etat.titres = cellstr(B.base.titre);
    etat.genres = cellstr(B.base.genre);
    etat.noms = cellstr(B.base.artiste + " – " + B.base.titre);
end
% Quelques titres de la FMA contiennent « &amp; » au lieu de « & »
etat.noms = strrep(etat.noms, '&amp;', '&');
etat.artistes = strrep(etat.artistes, '&amp;', '&');
etat.titres = strrep(etat.titres, '&amp;', '&');
etat.fichierSignaux = fullfile(dossierCache, 'signaux_base.mat');
etat.signaux = {};                          % chargés à la première utilisation
etat.y = [];                                % requête à P.Fe, avant bruit
etat.source = '';
etat.vrai = 0;                              % morceau d'origine s'il est connu
etat.t0 = NaN;
etat.enreg = [];
etat.minuteur = [];
etat.historique = cell(0, 5);
Fe_micro = 44100;

P0 = parametres('Tq', 5);                   % réglages du rapport

% Palette « instrument de mesure » : fonds anthracite, un seul accent vert phosphore.
% Les noms C.vert, C.orange, C.rouge... sont ceux utilisés par les fonctions
% d'affichage ; seules leurs valeurs définissent le style.
C.fond    = [17 19 21] / 255;      % fenêtre
C.panneau = [26 29 33] / 255;      % panneaux, bandeau
C.ecran   = [8 9 10] / 255;        % fond des graphes
C.grille  = [42 48 54] / 255;      % grille, bordures
C.texte   = [216 221 226] / 255;
C.doux    = [125 134 143] / 255;   % texte secondaire, axes
C.accent  = [46 240 122] / 255;    % vert phosphore
C.champ   = [14 16 18] / 255;      % champs de saisie
C.bouton  = [38 42 47] / 255;
C.neutre  = C.panneau;
C.vertF   = C.panneau;  C.vert   = C.accent;            % morceau trouvé
C.orangeF = C.panneau;  C.orange = [200 205 210] / 255; % inconnu : gris clair
C.rougeF  = C.panneau;  C.rouge  = [248 248 248] / 255; % confusion : blanc
% Colormap du spectrogramme : noir -> vert sombre -> phosphore
C.cmap = interp1([0; 0.55; 1], [C.ecran; 0 60/255 25/255; C.accent], linspace(0, 1, 256)');

% Polices : chasse fixe pour les valeurs, sans empattement pour le reste
if ispc
    F.mono = 'Consolas';  F.sans = 'Segoe UI';
elseif ismac
    F.mono = 'Menlo';  F.sans = 'Helvetica Neue';
else
    F.mono = 'DejaVu Sans Mono';  F.sans = 'DejaVu Sans';
end

%% Fenêtre
% Thème sombre ; toutes les couleurs des graphes sont fixées plus bas (la ligne
% du seuil reste visible).
fig = uifigure('Name', 'Reconnaissance musicale par empreintes', 'Theme', 'dark', ...
    'Position', [40 40 1440 880], 'Color', C.fond, 'CloseRequestFcn', @fermer, ...
    'WindowState', 'maximized');
% Style des graphes en valeurs par défaut de la fenêtre : stem, barh, imagesc...
% réinitialisent les axes à chaque tracé, ces valeurs-là restent.
set(fig, 'DefaultAxesColor', C.ecran, 'DefaultAxesXColor', C.doux, 'DefaultAxesYColor', C.doux, ...
    'DefaultAxesGridColor', C.grille, 'DefaultAxesGridAlpha', 1, 'DefaultAxesMinorGridColor', C.grille, ...
    'DefaultAxesXGrid', 'on', 'DefaultAxesYGrid', 'on', 'DefaultAxesBox', 'on', ...
    'DefaultAxesLineWidth', 0.5, 'DefaultAxesTickDir', 'in', 'DefaultAxesTickLength', [0.004 0.004], ...
    'DefaultAxesFontName', F.mono, 'DefaultAxesFontSize', 10, ...
    'DefaultAxesTitleFontWeight', 'normal', 'DefaultAxesTitleFontSizeMultiplier', 1.05, ...
    'DefaultAxesLabelFontSizeMultiplier', 1, 'DefaultTextColor', C.texte, ...
    'DefaultTextFontName', F.mono, 'DefaultColorbarColor', C.doux, ...
    'DefaultColorbarFontName', F.mono, 'DefaultColorbarBox', 'off');
page = uigridlayout(fig, [3 1], 'RowHeight', {46, '1x', 22}, 'Padding', [0 0 0 0], ...
    'RowSpacing', 0, 'BackgroundColor', C.fond);

% ---- Bandeau
bandeau = uigridlayout(page, [2 2], 'ColumnWidth', {'1x', 'fit'}, 'RowHeight', {'1x', '1x'}, ...
    'Padding', [14 4 14 4], 'RowSpacing', 0, 'BackgroundColor', C.panneau);
lbl = uilabel(bandeau, 'Text', 'RECONNAISSANCE MUSICALE PAR EMPREINTES', ...
    'FontSize', 14, 'FontWeight', 'bold', 'FontColor', C.texte, 'FontName', F.mono);
lbl.Layout.Row = 1;  lbl.Layout.Column = 1;
lbl = uilabel(bandeau, 'Text', 'Fe 8 kHz  |  TFCT Hann  |  constellation > paires > index inversé > vote sur δ', ...
    'FontSize', 11, 'FontColor', C.doux, 'FontName', F.mono);
lbl.Layout.Row = 2;  lbl.Layout.Column = 1;
lblIndexHaut = uilabel(bandeau, 'Text', '', 'FontSize', 11, 'FontColor', C.doux, ...
    'HorizontalAlignment', 'right', 'FontName', F.mono);
lblIndexHaut.Layout.Row = [1 2];  lblIndexHaut.Layout.Column = 2;

% ---- Corps
corps = uigridlayout(page, [1 2], 'ColumnWidth', {320, '1x'}, 'Padding', [8 8 8 6], ...
    'ColumnSpacing', 8, 'BackgroundColor', C.fond);

% ---- Colonne de gauche : contrôles
gauche = uigridlayout(corps, [3 1], 'RowHeight', {'fit', 'fit', 'fit'}, ...
    'Padding', [0 0 0 0], 'RowSpacing', 6, 'BackgroundColor', C.fond, 'Scrollable', 'on');

% Acquisition
pReq = panneau(gauche, 'ACQUISITION');
gReq = uigridlayout(pReq, [9 2], 'RowHeight', {'fit', 'fit', 34, 'fit', 'fit', 'fit', 'fit', 'fit', 'fit'}, ...
    'ColumnWidth', {'1x', '1x'}, 'RowSpacing', 4, 'Padding', [8 8 8 8], 'BackgroundColor', C.neutre);
[nomsMicro, idsMicro] = micros();
uilabel(gReq, 'Text', 'ENTRÉE', 'FontColor', C.doux);
ddMicro = uidropdown(gReq, 'Items', nomsMicro, 'ItemsData', idsMicro);
bMicro = uibutton(gReq, 'Text', 'Enregistrer au micro', 'FontWeight', 'bold', ...
    'ButtonPushedFcn', @enregistrer);
bMicro.Layout.Column = [1 2];
jauge = uigauge(gReq, 'linear', 'Limits', [0 P0.Tq], 'Value', 0, 'MajorTicks', 0:P0.Tq, ...
    'MinorTicks', [], 'ScaleColors', C.grille, 'ScaleColorLimits', [0 P0.Tq], ...
    'FontSize', 9, 'FontColor', C.doux, 'BackgroundColor', C.panneau);
jauge.Layout.Column = [1 2];
uilabel(gReq, 'Text', 'BASE', 'FontColor', C.doux);
spDebut = uispinner(gReq, 'Limits', [0 25], 'Value', 10, 'Step', 0.5, ...
    'ValueDisplayFormat', 't0 = %.1f s');
ddMorceau = uidropdown(gReq, 'Items', compose('%d. %s', (1:numel(etat.noms))', string(etat.noms)), ...
    'ItemsData', 1:numel(etat.noms));
ddMorceau.Layout.Column = [1 2];
bJouer = uibutton(gReq, 'Text', 'Jouer le morceau (haut-parleurs)', ...
    'Tooltip', 'Pour tester au micro : lancez la lecture, puis « Enregistrer au micro ». « Stop » arrête le son.', ...
    'ButtonPushedFcn', @jouer_morceau);
bJouer.Layout.Column = [1 2];
uibutton(gReq, 'Text', 'Extrait à t0', 'ButtonPushedFcn', @(~, ~) extrait_base(false));
uibutton(gReq, 'Text', 'Extrait aléatoire', 'ButtonPushedFcn', @(~, ~) extrait_base(true));
bFichier = uibutton(gReq, 'Text', 'Fichier audio…', 'ButtonPushedFcn', @charger_fichier);
bFichier.Layout.Column = [1 2];
uilabel(gReq, 'Text', 'DÉGRADATION', 'FontColor', C.doux);
ddBruit = uidropdown(gReq, 'Items', {'aucune', 'bruit blanc 10 dB', 'bruit blanc 5 dB', 'bruit blanc 0 dB'}, ...
    'ItemsData', [Inf 10 5 0]);

% Paramètres
pPar = panneau(gauche, 'PARAMÈTRES');
gPar = uigridlayout(pPar, [10 2], 'RowHeight', repmat({'fit'}, 1, 10), ...
    'ColumnWidth', {'1.2x', '1x'}, 'RowSpacing', 3, 'Padding', [8 8 8 8], 'BackgroundColor', C.neutre);
uilabel(gPar, 'Text', 'N      fenêtre');
ddN = uidropdown(gPar, 'Items', {'256', '512', '1024', '2048'}, 'ItemsData', [256 512 1024 2048], ...
    'Value', P0.N, 'ValueChangedFcn', @reglage_change);
lblInfoN = info(gPar);
uilabel(gPar, 'Text', 'm_v    ± trames');
spDm = uispinner(gPar, 'Limits', [1 8], 'Value', P0.dm, 'ValueChangedFcn', @reglage_change);
uilabel(gPar, 'Text', 'k_v    ± canaux');
spDk = uispinner(gPar, 'Limits', [1 15], 'Value', P0.dk, 'ValueChangedFcn', @reglage_change);
uilabel(gPar, 'Text', 'F      cibles/ancre');
spF = uispinner(gPar, 'Limits', [1 20], 'Value', P0.F, 'ValueChangedFcn', @reglage_change);
uilabel(gPar, 'Text', 'γf     regroupement');
ddGf = uidropdown(gPar, 'Items', {'1', '2', '4', '8'}, 'ItemsData', [1 2 4 8], ...
    'Value', P0.gamma_f, 'ValueChangedFcn', @reglage_change);
lblInfoGf = info(gPar);
uilabel(gPar, 'Text', 's_thr  seuil');
spSthr = uispinner(gPar, 'Limits', [1 500], 'Value', P0.s_thr, 'ValueChangedFcn', @reglage_change);
uilabel(gPar, 'Text', 'Tq     durée');
spTq = uispinner(gPar, 'Limits', [1 20], 'Value', P0.Tq, 'ValueDisplayFormat', '%.0f s', ...
    'ValueChangedFcn', @reglage_change);
lblEtatIndex = uilabel(gPar, 'Text', '', 'FontSize', 10, 'WordWrap', 'on');
lblEtatIndex.Layout.Column = [1 2];
bDefaut = uibutton(gPar, 'Text', 'Réglages du rapport', 'ButtonPushedFcn', @valeurs_defaut);
bDefaut.Layout.Column = [1 2];

% Analyse
pId = panneau(gauche, 'ANALYSE');
gId = uigridlayout(pId, [2 3], 'RowHeight', {34, 'fit'}, 'RowSpacing', 4, 'Padding', [8 8 8 8], ...
    'BackgroundColor', C.neutre);
bIdent = uibutton(gId, 'Text', 'IDENTIFIER', 'FontWeight', 'bold', 'FontSize', 14, ...
    'BackgroundColor', C.accent, 'FontColor', C.ecran, 'ButtonPushedFcn', @identifier_requete);
bIdent.Layout.Column = [1 3];
uibutton(gId, 'Text', 'Écouter', 'Tooltip', 'Écouter la requête (avec le bruit choisi)', ...
    'ButtonPushedFcn', @ecouter);
uibutton(gId, 'Text', 'Stop', 'Tooltip', 'Arrêter le son', 'ButtonPushedFcn', @(~, ~) clear('sound'));
uibutton(gId, 'Text', 'PNG', 'Tooltip', 'Enregistrer une capture de l''écran en PNG', ...
    'ButtonPushedFcn', @exporter);

% ---- Colonne de droite : correspondance, signal, spectrogramme, votes
droite = uigridlayout(corps, [4 2], 'RowHeight', {'fit', 60, '2.2x', '1x'}, ...
    'ColumnWidth', {'1.15x', '1x'}, 'Padding', [0 0 0 0], 'RowSpacing', 6, 'ColumnSpacing', 8, ...
    'BackgroundColor', C.fond);
haut = uigridlayout(droite, [1 2], 'ColumnWidth', {'1x', 400}, 'Padding', [0 0 0 0], ...
    'ColumnSpacing', 8, 'BackgroundColor', C.fond);
haut.Layout.Column = [1 2];

% Correspondance (résultat)
carte = uipanel(haut, 'Title', 'CORRESPONDANCE', 'BackgroundColor', C.neutre, 'BorderType', 'line', ...
    'HighlightColor', C.grille, 'ForegroundColor', C.doux, 'FontName', F.mono, 'FontSize', 10);

% Journal des essais
pHist = panneau(haut, 'JOURNAL');
gHist = uigridlayout(pHist, [1 1], 'Padding', [2 2 2 2], 'BackgroundColor', C.neutre);
tabHist = uitable(gHist, 'ColumnName', {'REQUÊTE', 'RÉPONSE', 'SCORE', 'VERDICT'}, ...
    'ColumnWidth', {90, 115, 60, 'auto'}, 'RowName', {}, 'FontSize', 10, 'Data', cell(0, 4), ...
    'BackgroundColor', [C.champ; C.panneau], 'ForegroundColor', C.texte);
gCarte = uigridlayout(carte, [3 4], 'RowHeight', {'fit', 'fit', 'fit'}, 'ColumnWidth', {'1.2x', '1x', '1x', '1x'}, ...
    'Padding', [12 6 12 8], 'RowSpacing', 2, 'BackgroundColor', C.neutre);
lblTitre = uilabel(gCarte, 'Text', 'EN ATTENTE', 'FontSize', 22, 'FontWeight', 'bold', 'FontColor', C.texte);
lblTitre.Layout.Column = [1 4];
lblSous = uilabel(gCarte, 'Text', 'Acquisition au micro, extrait de la base ou fichier, puis IDENTIFIER.', ...
    'FontSize', 12, 'FontColor', C.doux, 'WordWrap', 'on');
lblSous.Layout.Column = [1 4];
tuiles = gobjects(4, 2);
for i = 1:4
    g = uigridlayout(gCarte, [2 1], 'RowHeight', {'fit', 'fit'}, 'Padding', [0 4 0 0], ...
        'RowSpacing', 0, 'BackgroundColor', C.neutre);
    tuiles(i, 1) = uilabel(g, 'Text', '–', 'FontSize', 18, 'FontWeight', 'bold', 'FontColor', C.texte);
    tuiles(i, 2) = uilabel(g, 'Text', '', 'FontSize', 10, 'FontColor', C.doux);
end
tuiles(1, 2).Text = 'score';  tuiles(2, 2).Text = 'position trouvée';
tuiles(3, 2).Text = 'clés dans la requête';  tuiles(4, 2).Text = 'temps d''identification';

axOnde = uiaxes(droite);  axOnde.Layout.Column = [1 2];
axSpec = uiaxes(droite);  axSpec.Layout.Column = [1 2];
axDelta = uiaxes(droite);
axScores = uiaxes(droite);
for ax = [axOnde, axSpec, axDelta, axScores]
    ax.Toolbar.Visible = 'off';
    disableDefaultInteractivity(ax);
    ax.FontSize = 10;  ax.Box = 'on';
end
axes_vides();

% ---- Barre d'état
barre = uigridlayout(page, [1 1], 'Padding', [10 0 10 0], 'BackgroundColor', C.panneau);
lblEtat = uilabel(barre, 'Text', '', 'FontSize', 10, 'FontColor', C.doux);

% ---- Polices et couleurs des commandes (style seulement)
set(findall(fig, 'Type', 'uilabel'), 'FontName', F.sans);
set([lblIndexHaut, lblTitre, tuiles(:)', lblInfoN, lblInfoGf, lblEtatIndex, lblEtat], 'FontName', F.mono);
set(findall(gPar, 'Type', 'uilabel'), 'FontName', F.mono);
set(findall(fig, 'Type', 'uibutton'), 'BackgroundColor', C.bouton, 'FontColor', C.texte, ...
    'FontName', F.sans, 'FontSize', 12);
set(bIdent, 'BackgroundColor', C.accent, 'FontColor', C.ecran, 'FontName', F.mono, 'FontSize', 14);
set([findall(fig, 'Type', 'uidropdown'); findall(fig, 'Type', 'uispinner')], ...
    'BackgroundColor', C.champ, 'FontColor', C.texte, 'FontName', F.mono, 'FontSize', 11);
set(tabHist, 'FontName', F.mono);
set(findall(bandeau, 'Type', 'uilabel'), 'FontName', F.mono);

mettre_a_jour_reglages();
statut(sprintf('Prêt. Index chargé : %d morceaux, %s entrées.', numel(etat.noms), milliers(numel(etat.INDEX.cle))));

%% Fonctions internes

    function P = reglages()
        P = parametres('N', ddN.Value, 'dm', spDm.Value, 'dk', spDk.Value, ...
            'F', spF.Value, 'gamma_f', ddGf.Value, 's_thr', spSthr.Value, 'Tq', spTq.Value);
    end

    function statut(msg)
        lblEtat.Text = msg;
        drawnow;
    end

    function reglage_change(~, ~)
        mettre_a_jour_reglages();
    end

    function mettre_a_jour_reglages()
        % Grandeurs dérivées affichées sous les réglages, et état de l'index.
        P = reglages();
        lblInfoN.Text = sprintf('Tw = %s ms   Δf = %s Hz   %s trames/s', fr(1000 * P.N / P.Fe, '%.0f'), ...
            fr(1.44 * P.Fe / P.N, '%.1f'), fr(P.Fe / P.H, '%.1f'));
        lblInfoGf.Text = sprintf('M = %s clés possibles', milliers(P.M));
        jauge.Limits = [0 P.Tq];  jauge.MajorTicks = 0:max(1, round(P.Tq / 5)):P.Tq;
        jauge.ScaleColorLimits = [0 P.Tq];
        if isequal(cle_index(P), etat.cleIndex)
            lblEtatIndex.Text = sprintf('Index à jour : %s entrées.', milliers(numel(etat.INDEX.cle)));
            lblEtatIndex.FontColor = C.vert;
        else
            lblEtatIndex.Text = 'Index à reconstruire : il le sera à la prochaine identification (quelques secondes).';
            lblEtatIndex.FontColor = C.orange;
        end
        I = etat.INDEX.P;
        lblIndexHaut.Text = {sprintf('%d morceaux · %s entrées', numel(etat.noms), milliers(numel(etat.INDEX.cle))), ...
            sprintf('N = %d · ±%d × ±%d · F = %d · γf = %d', I.N, I.dm, I.dk, I.F, I.gamma_f)};
    end

    function valeurs_defaut(~, ~)
        ddN.Value = P0.N;  spDm.Value = P0.dm;  spDk.Value = P0.dk;  spF.Value = P0.F;
        ddGf.Value = P0.gamma_f;  spSthr.Value = P0.s_thr;  spTq.Value = P0.Tq;
        mettre_a_jour_reglages();
        statut('Réglages du rapport : N = 1024, ±3 × ±5, F = 10, γf = 1, s_thr = 35, Tq = 5 s.');
    end

    function ok = charger_signaux()
        ok = ~isempty(etat.signaux);
        if ok, return; end
        if ~isfile(etat.fichierSignaux)
            uialert(fig, sprintf(['cache/signaux_base.mat est introuvable.\n' ...
                'Il sert à prendre un extrait de la base et à reconstruire l''index ' ...
                '(N, voisinage, F ou γf modifiés).']), 'Fichier manquant');
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
        ok = true;
        if isequal(cle_index(P), etat.cleIndex), return; end
        if ~charger_signaux(), ok = false; return; end
        d = uiprogressdlg(fig, 'Title', 'Index', 'Message', sprintf( ...
            'Reconstruction de l''index : N = %d, ±%d × ±%d, F = %d, γf = %d…', ...
            P.N, P.dm, P.dk, P.F, P.gamma_f), 'Indeterminate', 'on');
        tic;
        etat.INDEX = construire_index(etat.signaux, P, etat.INDEX.noms);
        etat.cleIndex = cle_index(P);
        close(d);
        mettre_a_jour_reglages();
        msg = sprintf('Index reconstruit en %s s : %s entrées.', fr(toc, '%.1f'), milliers(numel(etat.INDEX.cle)));
        if P.s_thr == P0.s_thr && ~isequal(cle_index(P), cle_index(P0))
            msg = [msg ' Attention : s_thr = 35 a été calibré pour les réglages du rapport.'];
        end
        statut(msg);
    end

    function definir_requete(y, source, court, vrai, t0)
        etat.y = y(:);  etat.source = court;  etat.vrai = vrai;  etat.t0 = t0;
        lblTitre.Text = 'Requête prête';
        lblTitre.FontColor = C.texte;
        lblSous.Text = sprintf('%s (%s s). Cliquez sur « Identifier ».', source, fr(numel(y) / P0.Fe, '%.1f'));
        couleur_carte(C.neutre);
        tracer_onde(etat.y, P0.Fe);
        statut(['Requête : ' source]);
    end

    function extrait_base(auHasard)
        if ~charger_signaux(), return; end
        P = reglages();
        if auHasard
            ddMorceau.Value = randi(numel(etat.signaux));
        end
        x = etat.signaux{ddMorceau.Value};
        n = round(P.Tq * P.Fe);
        if numel(x) <= n
            uialert(fig, 'Le morceau est plus court que Tq.', 'Extrait impossible');
            return;
        end
        if auHasard
            debut = randi(numel(x) - n);    % en échantillons : pas aligné sur les trames
            spDebut.Value = min(spDebut.Limits(2), round((debut - 1) / P.Fe * 10) / 10);
        else
            debut = min(round(spDebut.Value * P.Fe) + 1, numel(x) - n);
        end
        t0 = (debut - 1) / P.Fe;
        definir_requete(x(debut:debut + n - 1), ...
            sprintf('Extrait de « %s » à %s s', etat.noms{ddMorceau.Value}, fr(t0, '%.2f')), ...
            sprintf('extrait n° %d', ddMorceau.Value), ddMorceau.Value, t0);
    end

    function jouer_morceau(~, ~)
        % Diffuse le morceau choisi (signal à 8 kHz de la base) pour le capter au micro.
        if ~charger_signaux(), return; end
        x = etat.signaux{ddMorceau.Value};
        clear('sound');
        sound(0.9 * x / max(abs(x) + eps), P0.Fe);
        statut(sprintf(['Lecture de « %s » (%s s). Cliquez sur « Enregistrer au micro » ; ' ...
            '« Stop » arrête le son.'], etat.noms{ddMorceau.Value}, fr(numel(x) / P0.Fe, '%.0f')));
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
        P = reglages();
        n = round(P.Tq * P.Fe);
        debut = min(round(spDebut.Value * P.Fe) + 1, max(1, numel(y) - n));
        y = y(debut:min(end, debut + n - 1));
        definir_requete(y, sprintf('Fichier « %s » à partir de %s s', nom, fr((debut - 1) / P.Fe, '%.1f')), ...
            raccourcir(nom, 14), 0, NaN);
    end

    function enregistrer(~, ~)
        if ~isempty(etat.enreg), return; end
        P = reglages();
        try
            etat.enreg = audiorecorder(Fe_micro, 16, 1, ddMicro.Value);
            record(etat.enreg);
        catch err
            etat.enreg = [];
            uialert(fig, ['Micro indisponible : ' err.message], 'Enregistrement impossible');
            return;
        end
        bMicro.Enable = 'off';  bIdent.Enable = 'off';
        jauge.Value = 0;
        t_debut = tic;
        etat.minuteur = timer('Period', 0.1, 'ExecutionMode', 'fixedRate', ...
            'TimerFcn', @(~, ~) tic_enregistrement(t_debut, P.Tq));
        start(etat.minuteur);
    end

    function tic_enregistrement(t_debut, Tq)
        if ~isvalid(fig), return; end
        ecoule = toc(t_debut);
        if ecoule < Tq
            jauge.Value = ecoule;
            bMicro.Text = sprintf('Enregistrement… %s s', fr(Tq - ecoule, '%.1f'));
            return;
        end
        stop(etat.minuteur);  delete(etat.minuteur);  etat.minuteur = [];
        stop(etat.enreg);
        y = getaudiodata(etat.enreg);
        etat.enreg = [];
        jauge.Value = Tq;
        bMicro.Text = 'Enregistrer au micro';  bMicro.Enable = 'on';  bIdent.Enable = 'on';
        definir_requete(pretraitement(y, P0, Fe_micro), 'Enregistrement au micro', 'micro', 0, NaN);
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
            uialert(fig, 'Choisissez d''abord une requête : micro, extrait ou fichier.', 'Pas de requête');
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
        % --- Carte du résultat
        bruit = '';
        if isfinite(ddBruit.Value), bruit = sprintf(' · bruit blanc à %g dB', ddBruit.Value); end
        if R.id > 0
            lblTitre.Text = etat.titres{R.id};
            details = etat.artistes{R.id};
            if ~isempty(etat.genres{R.id}), details = sprintf('%s · %s', details, etat.genres{R.id}); end
            lblSous.Text = sprintf('%s · reconnu sur %s s d''extrait%s', details, fr(numel(y) / P.Fe, '%.0f'), bruit);
            fond = C.vertF;  couleur = C.vert;  reponse = raccourcir(etat.titres{R.id}, 18);
        else
            lblTitre.Text = 'Morceau inconnu';
            lblSous.Text = sprintf('Aucun morceau ne dépasse le seuil. Meilleur candidat : %s (score %d)%s', ...
                etat.noms{R.id_max}, R.score, bruit);
            fond = C.orangeF;  couleur = C.orange;  reponse = 'inconnu';
        end
        verdict = '–';
        if etat.vrai > 0
            if R.id == etat.vrai
                verdict = 'bonne réponse';
            elseif R.id == 0
                verdict = 'non-détection';
            else
                verdict = 'confusion';  fond = C.rougeF;  couleur = C.rouge;
            end
            lblSous.Text = sprintf('%s\nVérité : %s à %s s → %s', lblSous.Text, etat.noms{etat.vrai}, ...
                fr(etat.t0, '%.2f'), verdict);
        end
        lblTitre.FontColor = couleur;
        couleur_carte(fond);
        tuiles(1, 1).Text = sprintf('%d', R.score);
        tuiles(1, 2).Text = sprintf('score (seuil %d)', P.s_thr);
        tuiles(2, 1).Text = sprintf('%s s', fr(R.delta * P.H / P.Fe, '%.2f'));
        tuiles(3, 1).Text = milliers(R.nCles);
        tuiles(4, 1).Text = sprintf('%s ms', fr(1000 * t, '%.0f'));
        tuiles(1, 1).FontColor = couleur;

        % --- Historique (le plus récent en haut)
        etat.historique = [{etat.source, reponse, R.score, verdict}; etat.historique];
        tabHist.Data = etat.historique;
        statut(sprintf('Identification en %s ms : %s, score %d.', fr(1000 * t, '%.0f'), reponse, R.score));

        % --- Forme d'onde et spectrogramme avec la constellation
        tracer_onde(y, P.Fe);
        cla(axSpec);
        K = size(R.SdB, 1);  M = size(R.SdB, 2);
        f = (0:K - 1) * P.Fe / P.Nfft;
        tt = ((0:M - 1) * P.H + P.N / 2) / P.Fe;
        imagesc(axSpec, tt, f / 1000, R.SdB);  axis(axSpec, 'xy');  hold(axSpec, 'on');
        colormap(axSpec, C.cmap);
        v = sort(R.SdB(:));  clim(axSpec, [v(max(1, round(0.25 * end))), v(round(0.995 * end))]);
        cb = colorbar(axSpec);  cb.Label.String = 'dB';
        if ~isempty(R.pics)
            plot(axSpec, tt(R.pics(:, 1)), f(R.pics(:, 2)) / 1000, 'o', 'MarkerSize', 5, ...
                'MarkerFaceColor', 'none', 'MarkerEdgeColor', [1 1 1], 'LineWidth', 0.8);
        end
        hold(axSpec, 'off');
        duree = numel(y) / P.Fe;
        xlim(axSpec, [0 duree]);  ylim(axSpec, [0 P.Fe / 2000]);
        title(axSpec, sprintf('Spectrogramme et constellation : %d pics, %s pics/s', ...
            size(R.pics, 1), fr(size(R.pics, 1) / duree, '%.1f')), 'FontWeight', 'normal');
        xlabel(axSpec, 'temps (s)');  ylabel(axSpec, 'fréquence (kHz)');

        % --- Histogramme des δ du meilleur candidat
        cla(axDelta);
        c = R.id_max;
        if ~isempty(R.app) && R.score > 0
            d = R.app(R.app(:, 1) == c, 2);
            [u, ~, ic] = unique(d);
            n = accumarray(ic, 1);
            stem(axDelta, u, n, 'Marker', 'none', 'LineWidth', 1.2, 'Color', couleur);
            hold(axDelta, 'on');
            yline(axDelta, P.s_thr, '--', sprintf('s_{thr} = %d', P.s_thr), 'Color', C.doux, ...
                'LabelHorizontalAlignment', 'left', 'FontSize', 10);
            [nMax, iMax] = max(n);
            % Axe zoomé : le pic écrase les autres δ, on plafonne juste au-dessus
            % du seuil et du bruit ; le pic dépasse et sa valeur est écrite en haut.
            nAutres = n;  nAutres(iMax) = 0;
            yHaut = min(nMax * 1.15, max([P.s_thr * 1.5, max(nAutres) * 2, 10]));
            txt = sprintf('  %d votes à δ = %d (%s s)', nMax, u(iMax), fr(u(iMax) * P.H / P.Fe, '%.2f'));
            if nMax > yHaut
                txt = ['\uparrow' txt];
            end
            text(axDelta, u(iMax), min(nMax, yHaut), txt, 'VerticalAlignment', 'top', ...
                'FontSize', 10, 'Color', C.texte, 'Clipping', 'on');
            hold(axDelta, 'off');
            ylim(axDelta, [0, yHaut]);
            xlim(axDelta, [min(u) - 5, max(u) + 5]);
        end
        title(axDelta, sprintf('Histogramme des δ : %s', raccourcir(etat.titres{c}, 30)), 'FontWeight', 'normal');
        xlabel(axDelta, 'δ = m_{réf} − m_{req} (trames)');  ylabel(axDelta, 'votes');

        % --- Les 10 meilleurs scores
        cla(axScores);
        [s, ordre] = sort(R.scores, 'descend');
        nAff = min(10, numel(s));
        s = s(1:nAff);  ordre = ordre(1:nAff);
        b = barh(axScores, flipud(s), 0.7, 'FaceColor', 'flat', 'EdgeColor', 'none');
        b.CData = repmat([0.33 0.37 0.41], nAff, 1);
        if R.id > 0, b.CData(end, :) = C.vert; end
        hold(axScores, 'on');
        xline(axScores, P.s_thr, '--', 's_{thr}', 'Color', C.doux, 'FontSize', 10, ...
            'LabelOrientation', 'horizontal', 'LabelVerticalAlignment', 'bottom');
        hold(axScores, 'off');
        axScores.YTick = 1:nAff;
        axScores.YTickLabel = cellfun(@(z) raccourcir(z, 26), etat.titres(flipud(ordre)), 'UniformOutput', false);
        axScores.XScale = 'log';  xlim(axScores, [0.8, max([s; P.s_thr]) * 1.6]);
        title(axScores, '10 meilleurs scores', 'FontWeight', 'normal');
        xlabel(axScores, 'score (échelle log)');
    end

    function tracer_onde(y, Fe)
        cla(axOnde);
        plot(axOnde, (0:numel(y) - 1) / Fe, y, 'Color', C.accent, 'LineWidth', 0.5);
        a = max(abs(y)) + eps;
        xlim(axOnde, [0, numel(y) / Fe]);  ylim(axOnde, [-a a] * 1.1);
        axOnde.YTick = [];  axOnde.XTickLabel = {};
        title(axOnde, 'Signal de la requête (8 kHz)', 'FontWeight', 'normal');
    end

    function axes_vides()
        title(axOnde, 'Signal de la requête (8 kHz)', 'FontWeight', 'normal');
        axOnde.YTick = [];  axOnde.XTickLabel = {};
        title(axSpec, 'Spectrogramme et constellation', 'FontWeight', 'normal');
        xlabel(axSpec, 'temps (s)');  ylabel(axSpec, 'fréquence (kHz)');
        title(axDelta, 'Histogramme des δ du meilleur candidat', 'FontWeight', 'normal');
        xlabel(axDelta, 'δ (trames)');  ylabel(axDelta, 'votes');
        title(axScores, '10 meilleurs scores', 'FontWeight', 'normal');
        xlabel(axScores, 'score');
    end

    function couleur_carte(fond)
        carte.BackgroundColor = fond;
        set(findobj(carte, 'Type', 'uigridlayout'), 'BackgroundColor', fond);
    end


    function exporter(~, ~)
        [nom, chemin] = uiputfile('*.png', 'Exporter l''écran', 'interface.png');
        figure(fig);
        if isequal(nom, 0), return; end
        exportapp(fig, fullfile(chemin, nom));
        statut(['Écran exporté : ' fullfile(chemin, nom)]);
    end

    function p = panneau(parent, titre)
        p = uipanel(parent, 'Title', titre, 'FontWeight', 'bold', 'FontSize', 10, ...
            'BackgroundColor', C.neutre, 'ForegroundColor', C.doux, 'BorderType', 'line', ...
            'HighlightColor', C.grille, 'FontName', F.mono);
    end

    function l = info(parent)
        % Ligne d'information sous un réglage (grandeurs dérivées).
        l = uilabel(parent, 'Text', '', 'FontSize', 10, 'FontColor', C.doux);
        l.Layout.Column = [1 2];
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

function [noms, ids] = micros()
% Entrées audio disponibles ; -1 = entrée par défaut du système.
noms = {'Entrée par défaut'};  ids = -1;
try
    d = audiodevinfo;
    for e = d.input
        noms{end + 1} = e.Name; %#ok<AGROW>
        ids(end + 1) = e.ID; %#ok<AGROW>
    end
catch
end
end

function s = fr(x, format)
% Nombre avec une virgule décimale.
s = strrep(sprintf(format, x), '.', ',');
end

function s = milliers(n)
% 677171 -> '677 171'
s = regexprep(sprintf('%d', round(n)), '(\d)(?=(\d{3})+$)', '$1 ');
end

function s = raccourcir(s, n)
s = char(s);
if numel(s) > n
    s = [s(1:n - 1) '…'];
end
end
