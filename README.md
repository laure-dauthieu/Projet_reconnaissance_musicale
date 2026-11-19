# Reconnaissance musicale par empreintes audio

Projet OBL-4101 Traitement du signal (ESIEE, 2026–2027).
**Rendu : vendredi 27 novembre 2026** (repoussé, initialement le 20). Tout retard coûte 5 points.

Le but est d'identifier un morceau à partir d'un extrait court et bruité, pris à un instant inconnu, en MATLAB. On suit la méthode de Wang (2003) :

```text
Morceaux de référence → spectrogramme → pics → paires → clés → index inversé
Extrait inconnu       → spectrogramme → pics → paires → clés → alignement + décision
```

Les deux phases utilisent **exactement** les mêmes fonctions d'extraction.

---

## Organisation du travail

**Le plan est dans [PLAN.md](PLAN.md)** : ce que le sujet demande, répartition, tâches cochables, planning, liste de contrôle avant dépôt.

| | **A — Alessandro** | **B — Laure** |
|---|---|---|
| Rôle | Chaîne MATLAB, base, dégradations, évaluation, mesures, enregistrements réels | Théorie, rapport, vidéo, interface de paramétrage |
| Dossiers | `src/`, `eval/`, `experiences/`, `utils/`, `tests/`, `figures/`, `resultats/` | `rapport/`, `video/` |
| Fournit à l'autre | Figures PDF, fiches de résultats (`resultats/notes_resultats.md`) | Enregistrements en salle, brouhaha |

Points fixes : mesures faites (mer. 18), **mer. 25 à 18 h (gel du code)**, **ven. 27 à 12 h (dépôt)**. Détail dans [PLAN.md](PLAN.md), section 5.

---

## Fonctions de la chaîne

Les signatures sont **figées**. Si l'une doit changer, on prévient l'autre avant de pousser.

```matlab
P      = parametres();                          % struct unique avec TOUS les réglages
x      = pretraitement(fichierOuSignal, P, Fe0)  % colonne mono à P.Fe = 8000 Hz
SdB    = calcul_spectrogramme(x, P)              % K x M (canaux x trames), en dB
pics   = detection_pics(SdB, P)                  % [m, k], une ligne par pic
E      = generer_empreintes(pics, P)             % [cle, m1], une ligne par paire
INDEX  = construire_index(fichiers, P)           % .cle .id .m1 triés par clé, .noms
R      = identifier(x, INDEX, P)                 % .id (0 = inconnu), .score, .delta,
                                                 % .scores, .votes (paires qui ont voté)
```

Évaluation :

```matlab
[base, horsBase] = preparer_base(dossierData, nBase, nHors, graine)
[y, t0] = extraire_requete(signalOrigine, Fe0, Tq, rs)  % extrait mono à Fe0, début t0 (s)
yb  = ajouter_bruit(y, RSB_dB, bruit, rs)        % bruit = 'blanc' ou vecteur de brouhaha
ym  = degrader_mp3(y, Fe0, debit_kbps, P)        % retard du codeur retiré
yf  = filtre_passe_bande(y, Fe, 300, 3400, causal)
yr  = reverberation(y, Fe, T60, rs)
res = evaluer(INDEX, requetes, P)                % table : id_vrai, id_max, score, temps
T   = taux_detection(res, s_thr)                 % TBD, TFD, confusion, non-détection
s   = calibrer_seuil(scoresNegCalibration)       % 1,5 x le plus fort score négatif
```

Conventions :

- les signaux sont des vecteurs **colonne** en double ;
- le **MP3** s'applique au signal d'origine (44,1 kHz), **avant** `pretraitement` ; le **bruit**, le **passe-bande** et la **réverbération** s'appliquent **après**, au signal à 8 kHz (sinon le passage à 8 kHz retirerait ~80 % d'un bruit blanc et fausserait le RSB) ;
- les indices m (trame) et k (canal) commencent à 1 ;
- aucun nombre magique dans les fonctions : tout passe par `P` ;
- les notations sont celles de l'énoncé (`P.Fe`, `P.N`, `P.H`, `P.F`, `P.gamma_f`, `P.s_thr`…) ;
- chaque fonction a un en-tête (rôle, entrées, sorties, justification des paramètres) et un test dans `tests/`.

### Chaque fonction est testable isolément (§8 du sujet)

- **Démonstration autonome.** Chaque fonction d'étape, appelée **sans argument**, se lance seule sur un signal synthétique (aucun fichier audio nécessaire) : elle ajoute elle-même ce qu'il lui faut au chemin MATLAB, prend `parametres()` et affiche son résultat.

  ```matlab
  pretraitement()          % mono + rééchantillonnage à 8 kHz
  calcul_spectrogramme()   % spectrogramme en dB
  detection_pics()         % constellation sur le spectrogramme
  generer_empreintes()     % paires de pics -> clés
  empreintes_signal()      % étapes 2 à 4 d'un coup
  construire_index()       % index inversé de 3 morceaux
  identifier()             % reconnaissance d'un extrait + rejet d'un morceau absent
  evaluer()                % TBD et TFD avec calibration du seuil
  ```

- **`P` facultatif.** `P` peut être omis : `parametres()` par défaut, et pour `identifier` et `evaluer` les paramètres avec lesquels l'index a été construit (`INDEX.P`).
- **Un fichier de test par fonction** dans `tests/` (`test_<fonction>.m`), qui se lance seul, sans données FMA ni cache :

  ```matlab
  runtests('tests/test_identifier.m')   % une seule fonction
  runtests('tests')                     % tout (54 tests ; les 2 du MP3 sont ignorés sans ffmpeg)
  ```

---

## Lancement

Depuis le dossier du projet, dans MATLAB :

```matlab
main                                    % chaîne « jouet » : 3 morceaux, constellation, histogramme des δ
runtests('tests')                       % un fichier de test par fonction (voir plus haut)

run('experiences/preparer_donnees.m')   % une fois : choix des 200 morceaux, index de la base (≈ 15 s)
run('experiences/campagne_evaluation.m')% TBD/TFD pour toutes les dégradations, figures (≈ 2 min)
run('experiences/figures_campagne.m')   % refaire seulement les figures, sans recalcul
run('experiences/passage_echelle.m')    % temps de requête et taille de l'index (≈ 30 s)

run('experiences/etude_q3_voisinage.m') % Q3 : ρ et p selon le voisinage (≈ 1 min)
run('experiences/etude_q4_p_gamma_F.m') % Q4 : p, tableau pic/paire, γf ; choix de F (≈ 2 min)
run('experiences/theorie_mesure.m')     % score prévu contre mesuré, RSB de rupture (≈ 1 min)
run('experiences/etude_q6_genres.m')    % Q6 : TBD par genre (après la campagne)
run('experiences/figure_q2_filtrage.m') % Q2 : S_y,dB − S_x,dB pour un passe-bande et une réverbération

% Enregistrements réels (micro du Mac, enceinte en sortie audio)
addpath('experiences')
enregistrer_brouhaha()                  % 3 min de bruit de cafétéria, sans musique
enregistrer_salle('1m')                 % 30 morceaux joués et enregistrés, enceinte à 1 m (≈ 7 min)
enregistrer_salle('3m')                 % idem à 3 m
run('experiences/evaluer_enregistrements.m')  % TBD et TFD par distance

% Interface de paramétrage et démo
addpath('interface')
interface_reconnaissance                % micro, extrait de la base ou fichier ; réglages ; résultats
```

L'interface n'a besoin que de `cache/index_base.mat` (sur git) pour identifier et régler s_thr et Tq. Pour prendre un extrait de la base ou changer N, le voisinage, F ou γf (l'index est alors reconstruit), il faut aussi `cache/signaux_base.mat`, qui n'est pas sur git (184 Mo, licences « No Derivatives ») ; `cache/base.mat` sert à afficher titres et genres.

Les paramètres retenus et leur justification sont dans [resultats/parametres_finaux.md](resultats/parametres_finaux.md) ; les chiffres et interprétations de chaque figure dans [resultats/notes_resultats.md](resultats/notes_resultats.md).

Prérequis : `fma_small` et `fma_metadata` dézippés dans `data/`. Sur Mac, `unzip` échoue sur ces archives : utiliser `bsdtar -xf fma_small.zip`.

---

## Installation et pièges connus

- **MATLAB R2026a** avec la **Signal Processing Toolbox**. Pas besoin d'autre toolbox.
- **Pas d'Image Processing Toolbox**, donc pas de `ordfilt2`. Le maximum glissant se calcule avec deux `movmax` :

  ```matlab
  Smax = movmax(movmax(SdB, 2*dk+1, 1), 2*dm+1, 2);
  ```

- **MP3** : `audiowrite` ne sait pas écrire de MP3. Installer ffmpeg (`brew install ffmpeg`). MATLAB lancé depuis le Dock ne voit pas le PATH du terminal : on met le chemin complet dans `P.ffmpeg`.
- **Données** : `fma_small.zip` et `fma_metadata.zip`, liens dans le README de <https://github.com/mdeff/fma>, à dézipper dans `data/`.
- **`ismember`** ne renvoie qu'une occurrence par clé, alors qu'il les faut toutes : on passe par les clés uniques de l'index avec leur début et leur nombre d'entrées.
- **Fenêtre de Hann** : κw ≈ 1,44 (l'énoncé donne 1,30, qui vaut pour Hamming), d'où Δf ≈ 11,25 Hz pour N = 1 024.

Le dépôt est **public** : on ne commite jamais d'audio ni de `.mat` (voir `.gitignore`).

---

## Références

- A. Wang, *An industrial-strength audio search algorithm*, ISMIR 2003 (à lire en priorité)
- J. Haitsma, T. Kalker, *A highly robust audio fingerprinting system*, ISMIR 2002
- F. J. Harris, *On the use of windows for harmonic analysis with the DFT*, Proc. IEEE 66(1), 1978
- M. Müller, *Fundamentals of Music Processing*, Springer 2015, chap. 7
