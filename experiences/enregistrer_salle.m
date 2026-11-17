function enregistrer_salle(distance, varargin)
%ENREGISTRER_SALLE  Joue les morceaux sur une enceinte et les enregistre au micro.
%   enregistrer_salle('1m')                  enregistrement réel
%   enregistrer_salle('4m')
%   enregistrer_salle('1m', 'duree', 12)     durée de chaque prise (s, défaut 12)
%   enregistrer_salle('test', 'nombre', 2)   seulement les 2 premiers morceaux (essai)
%   enregistrer_salle('1m', 'depart', 12)    reprendre au 12e morceau après une erreur
%   enregistrer_salle('1m', 'simulation', true)
%       sans micro ni enceinte : la « prise » est l'extrait passé par une
%       réverbération et un bruit, pour tester toute la chaîne.
%
%   Dégradation « enregistrement au micro, en salle, 2 distances » du sujet :
%   toute la chaîne y(t) = α (h * x)(t − t0) + b(t) à la fois (haut-parleur,
%   salle, micro, bruit ambiant).
%
%   Montage :
%     - l'enceinte (Bluetooth ou filaire) est la SORTIE AUDIO du Mac
%       (Réglages Système > Son > Sortie) ;
%     - le micro est celui du Mac, posé à la distance indiquée de l'enceinte ;
%     - volume « normal », sans saturation ; noter la salle et le matériel.
%   Le Mac joue chaque extrait sur l'enceinte et l'enregistre en même temps.
%
%   Morceaux : resultats/morceaux_a_enregistrer.csv (20 de la base, 10 hors
%   base), fichiers dans data/fma_small/ ou data/a_enregistrer/.
%   Pour chaque morceau, un extrait de « duree » secondes commence à un instant
%   tiré au hasard ; la requête est la prise entière.
%
%   Produit : data/enregistrements/micro_<id>_<distance>.wav (44,1 kHz, mono)
%             data/enregistrements/protocole_<distance>.csv (id, rôle, début de
%             l'extrait, niveau de la prise, date)

opts = struct('duree', 12, 'simulation', false, 'graine', 21, 'nombre', Inf, 'depart', 1);
for i = 1:2:numel(varargin), opts.(varargin{i}) = varargin{i+1}; end

racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'src'), fullfile(racine, 'eval'), fullfile(racine, 'eval', 'degradations'));
liste = readtable(fullfile(racine, 'resultats', 'morceaux_a_enregistrer.csv'), 'TextType', 'string');
liste = liste(1:min(height(liste), opts.nombre), :);
dossierSortie = fullfile(racine, 'data', 'enregistrements');
if ~exist(dossierSortie, 'dir'), mkdir(dossierSortie); end
rs = RandStream('mt19937ar', 'Seed', opts.graine);
FeRec = 44100;

% Périphériques audio. MATLAB garde la liste vue au démarrage : si l'enceinte
% Bluetooth s'est reconnectée depuis, ses identifiants ont changé (« Device
% Error »). audiodevreset relit la liste. On impose ensuite le micro du Mac,
% pour ne pas enregistrer par erreur avec un iPhone proche (Continuité).
idMicro = -1;                                     % -1 : entrée par défaut
if ~opts.simulation
    audiodevreset;
    infos = audiodevinfo;
    mac = find(contains({infos.input.Name}, 'MacBook'), 1);
    if ~isempty(mac), idMicro = infos.input(mac).ID; end
    fprintf('Sortie : celle choisie dans Réglages Système > Son (disponibles : %s)\n', ...
        strjoin({infos.output.Name}, ', '));
    fprintf('Micro : %s\n', ternaire(idMicro >= 0, infos.input(max(mac, 1)).Name, 'entrée par défaut'));
end

n = height(liste);
debut = zeros(n, 1);  niveau = zeros(n, 1);  date = strings(n, 1);
fichierProto = fullfile(dossierSortie, sprintf('protocole_%s.csv', distance));
if opts.depart > 1 && exist(fichierProto, 'file')
    % reprise : on garde les lignes des prises déjà faites
    ancien = readtable(fichierProto, 'TextType', 'string');
    [dejaFait, loc] = ismember(liste.id, ancien.id);
    debut(dejaFait) = ancien.debut_extrait_s(loc(dejaFait));
    niveau(dejaFait) = ancien.niveau_dBFS(loc(dejaFait));
    date(dejaFait) = string(ancien.date(loc(dejaFait)));
end
fprintf('%d morceaux, prises de %d s, distance %s%s\n', n, opts.duree, distance, ...
    ternaire(opts.simulation, ' (SIMULATION)', ''));
for i = 1:n
    [x, fe] = audioread(chemin_morceau(racine, liste.id(i)));
    x = mean(x, 2);
    nq = round(opts.duree * fe);
    d = randi(rs, numel(x) - nq + 1);    % tiré même si on saute : mêmes extraits à la reprise
    if i < opts.depart, continue; end
    extrait = x(d:d + nq - 1);
    debut(i) = (d - 1) / fe;

    if opts.simulation
        y = reverberation(resample(extrait, FeRec, fe), FeRec, 0.5, rs);
        y = ajouter_bruit(y, 10, 'blanc', rs);
        y = 0.3 * y / max(abs(y));
    else
        y = prise(extrait, fe, FeRec, idMicro, i, n);
    end

    niveau(i) = 20*log10(rms(y) + eps);
    date(i) = string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
    nom = sprintf('micro_%06d_%s.wav', liste.id(i), distance);
    audiowrite(fullfile(dossierSortie, nom), y, FeRec);
    alerte = '';
    if max(abs(y)) > 0.99, alerte = '  ATTENTION : saturation, baisser le volume';
    elseif niveau(i) < -50, alerte = '  ATTENTION : niveau très faible, monter le volume'; end
    fprintf('[%2d/%d] %s (%s) : niveau %.0f dBFS%s\n', i, n, nom, liste.role(i), niveau(i), alerte);

    % protocole réécrit après chaque prise : rien n'est perdu en cas d'arrêt
    fait = date ~= "";
    protocole = table(liste.id(fait), liste.role(fait), liste.genre(fait), debut(fait), ...
        niveau(fait), date(fait), 'VariableNames', ...
        {'id', 'role', 'genre', 'debut_extrait_s', 'niveau_dBFS', 'date'});
    writetable(protocole, fichierProto);
end
fprintf('Terminé : %d prises dans data/enregistrements/\n', sum(date ~= ""));
end

function y = prise(extrait, fe, FeRec, idMicro, i, n)
% Joue l'extrait sur la sortie audio et l'enregistre au micro.
% Une enceinte Bluetooth peut se mettre en veille ou se reconnecter entre deux
% morceaux (« Device Error ») : on réessaie jusqu'à 3 fois avant d'abandonner.
for essai = 1:3
    try
        rec = audiorecorder(FeRec, 16, 1, idMicro);
        lecteur = audioplayer(extrait / max(1, max(abs(extrait))), fe);
        record(rec);
        pause(0.3);                       % le micro démarre avant la musique
        playblocking(lecteur);
        pause(0.5);                       % queue de réverbération
        stop(rec);
        y = getaudiodata(rec);
        return
    catch err
        try stop(rec); catch, end         %#ok<CTCH>
        fprintf('  [%d/%d] erreur audio (%s), nouvel essai dans 2 s...\n', i, n, err.message);
        pause(2);
    end
end
error('enregistrer_salle:audio', ['Échec audio au morceau %d/%d après 3 essais. ' ...
    'Vérifier que l''enceinte est connectée et choisie en sortie, puis reprendre avec ' ...
    'enregistrer_salle(distance, ''depart'', %d).'], i, n, i);
end

function f = chemin_morceau(racine, id)
f = fullfile(racine, 'data', 'fma_small', sprintf('%03d', floor(id/1000)), sprintf('%06d.mp3', id));
if ~exist(f, 'file')
    f = fullfile(racine, 'data', 'a_enregistrer', sprintf('%06d.mp3', id));
end
end

function s = ternaire(c, a, b)
if c, s = a; else, s = b; end
end
