# Plan d'action

Projet OBL-4101 : reconnaissance musicale par empreintes audio.
**Rendu : vendredi 27 novembre 2026** (repoussé, initialement le 20). On vise un dépôt vendredi à **12 h** (tout retard coûte 5 points).

- **A = Alessandro** : chaîne MATLAB, base, évaluation, mesures, enregistrements réels (B2 et B3 repris), livraison.
- **B = Laure** : théorie, rapport, vidéo, **interface de paramétrage** (B6).

**État au mardi 17 au soir** : A0 à A4 sont faits (branche `a/chaine`). Les fonctions de dégradation de B2 ont été codées et testées avec A2 : B2 se réduit à la figure Q2. Résultats et figures : `resultats/notes_resultats.md`.

> **À vérifier avec l'enseignant dès mercredi matin** : le sujet est prévu pour un **trinôme** (zip `Nom1_Nom2_Nom3`). Si nous sommes deux, confirmer que c'est accepté et le nom du zip. Demander aussi comment déposer la vidéo : le §8 ne la met pas dans le zip.

Ce plan couvre d'abord **tout ce que le sujet demande**. Les améliorations sont à la fin (section 8) : on n'y touche qu'une fois le reste terminé. Seule exception : l'interface de paramétrage, qui compte pour 10 % de la note et sert aussi de démo. Elle est donc intégrée au plan (B6).

---

## 1. Ce que le sujet demande

**Code** (§8 du sujet) :

- une fonction par étape : prétraitement, spectrogramme, pics, empreintes, index, décision, évaluation ;
- un programme principal et un README ;
- chaque fonction testable isolément ;
- code commenté.

**Base et requêtes** (§7) :

- au moins 100 morceaux de genres variés (FMA) ;
- au moins 50 requêtes positives (extraits de morceaux de la base, à des instants tirés au hasard) ;
- au moins 50 requêtes négatives (extraits de morceaux absents de la base).

On dépasse ces minima parce que les requêtes ne coûtent presque rien. On fait **2 requêtes positives par morceau, soit 200**, ce qui donne environ 25 requêtes par genre pour Q6. On fait aussi **100 requêtes négatives** : avec 50 seulement, le TFD ne se mesure que par pas de 2 %.

**Dégradations** (§7) :

| Dégradation | Paramètres | Appliquée |
|---|---|---|
| Bruit blanc additif | RSB = 20, 15, 10, 5, 0 dB | après passage à 8 kHz |
| Bruit réel (brouhaha) | RSB = 10, 5, 0 dB | après passage à 8 kHz |
| Codage MP3 | 128, 64, 32 kbit/s | **avant** passage à 8 kHz, à 44,1 kHz |
| Filtrage passe-bande | 300–3 400 Hz | après passage à 8 kHz |
| Réverbération | T60 = 0,3 s et 1 s | après passage à 8 kHz |
| Enregistrement au micro | en salle, 2 distances | signal réel |

Pourquoi cet ordre :

- **Bruit.** Si on ajoutait le bruit à 44,1 kHz, le passage à 8 kHz en supprimerait environ 80 %, alors que la musique est surtout sous 4 kHz. Le RSB réel serait alors meilleur d'environ 7 dB que le RSB annoncé.
- **MP3.** Dans la réalité, le codage s'applique au fichier d'origine. À 8 kHz, un débit de 128 kbit/s serait presque sans perte, ce qui fausserait la comparaison entre débits.

**Figures attendues** (§7) :

1. TBD en fonction du RSB, une courbe par durée Tq ∈ {3, 5, 10} s, pour le bruit blanc et le brouhaha ;
2. TBD en fonction du débit MP3 ;
3. courbe TBD en fonction du TFD, obtenue en balayant le seuil ;
4. histogrammes des scores sur les requêtes positives et négatives ;
5. temps de requête et taille de l'index en fonction du nombre de morceaux indexés.

S'y ajoutent les figures demandées dans les questions et les étapes :

- la constellation superposée au spectrogramme (étape 3) ;
- l'histogramme des δ (jalon de la chaîne « jouet ») ;
- S_y,dB − S_x,dB pour plusieurs trames (Q2) ;
- ρ en fonction de la taille du voisinage, et p en fonction de ρ (Q3).

Deux éléments ne sont pas listés par le sujet mais sont indispensables :

- **un tableau récapitulatif** du TBD et du TFD pour **chacune des 6 dégradations**, avec un seuil et un Tq fixés. Sans lui, le filtrage passe-bande, la réverbération et le micro n'apparaissent nulle part dans les résultats ;
- **la confrontation entre théorie et mesure**. On mesure p en fonction du RSB, on en déduit le score prédit s ≈ F·ρ·Tq·p², puis on le compare à s_thr. On obtient ainsi le RSB à partir duquel la théorie prévoit l'échec, et on le superpose à la figure 1. C'est ce que demandent la slide 13 et le « Dernier mot » du sujet.

**Questions 1 à 6** : à traiter dans le rapport (détail en B1).

**Livrables** (§8) :

- rapport de 12 à 15 pages hors annexes, sans code dans le corps, au plan imposé ;
- vidéo de 7 min : slides, démo en direct (morceau joué dans la salle, spectrogramme et constellation affichés), résultats, analyse des échecs ;
- zip `Projet_Groupe_Nom1_Nom2_Nom3.zip` sur le Drive (« Projet » → « Rapport/Dossier complet ») : programmes commentés, rapport en PDF, liste des morceaux.

**Règles de rédaction** : tout taux est annoncé avec son seuil, sa durée Tq et sa dégradation ; une courbe sans commentaire ne vaut rien ; un paramètre non justifié est considéré comme non choisi.

**Barème** : théorie 20 %, implémentation 20 %, évaluation 20 %, rapport 10 %, **vidéo 20 %**, interface (bonus) 10 %. La vidéo pèse autant que le code : elle mérite un vrai créneau.

---

## 2. Partie A : MATLAB (Alessandro)

### A0. Dès mardi après-midi

- [x] Lancer le téléchargement de `fma_small.zip` (environ 7,2 Go) et de `fma_metadata.zip`, qui contient `tracks.csv` avec le genre de chaque morceau.
- [x] Vérifier que la **Signal Processing Toolbox** est installée (`resample`, `spectrogram`), avec `ver`. Vérifier aussi que `ffmpeg` est accessible depuis MATLAB (`system('ffmpeg -version')`).

### A1. Chaîne de reconnaissance (mardi)

- [x] `parametres.m` : renvoie une structure contenant tous les réglages, avec les valeurs de départ du sujet (tableau du §8). Toutes les fonctions la reçoivent en argument, ce qui permettra à l'interface de les modifier.
- [x] `pretraitement` : mono, puis `resample` à 8 kHz. Si le signal est déjà mono à 8 kHz, la fonction ne fait rien.
- [x] `calcul_spectrogramme` : Hann (`'periodic'`), N = 1 024, H = N/2, Nfft = N, sortie en dB avec + eps.
- [x] `detection_pics` :
  - maxima locaux sur ±3 trames × ±5 canaux, avec `Smax = movmax(movmax(SdB, 2*dk+1, 1), 2*dm+1, 2)` : pas d'`ordfilt2`, car l'Image Processing Toolbox n'est pas installée ;
  - seuil local : médiane de S_dB dans la bande, plus une marge. Attention aux plages constantes (silence), où chaque point est égal à son maximum local : c'est la marge qui doit les éliminer ;
  - nombre fixe de pics par bande et par seconde, sur 6 bandes géométriques (200 | 330 | 543 | 894 | 1 474 | 2 428 | 4 000 Hz). Cible : ρ ≈ 25 à 35 pics/s.
- [x] `generer_empreintes` : F cibles par ancre dans la zone Δt ∈ [0,1 ; 2] s, soit Δm ∈ [2 ; 31] trames (Nt = 30), et |Δk| ≤ 60. La clé u = (Qf(k1), Qf(k2), Δm) est codée en un seul entier : `u = (Qf(k1)*Nf + Qf(k2))*Nt + (Δm − Δm_min)`.
  - Vérification : avec γf = 1, on doit trouver M = 513² × 30 ≈ 7,9·10⁶, la valeur du sujet.
- [x] `construire_index` : tableau `[clé, idMorceau, instant]` trié par clé. Pour récupérer **toutes** les entrées d'une clé (`ismember` n'en renvoie qu'une) : `[uk, debut] = unique(cles, 'first')`, nombre d'entrées = `diff([debut; n+1])`, puis `ismember(clés_requête, uk)` pour trouver les plages à lire.
- [x] `identifier` :
  - histogramme des δ = m_r − m_q pour chaque morceau, avec `accumarray`. δ peut être négatif pour les appariements fortuits : il faut lui ajouter un décalage ;
  - score = maximum de l'histogramme ;
  - réponse « morceau de score maximal » si ce score dépasse s_thr, « inconnu » sinon.
- [x] `main.m` : chaîne « jouet » sur 3 morceaux, affichage de la constellation sur le spectrogramme et de l'histogramme des δ.
- [x] **Jalon (mardi 23 h)** : l'histogramme des δ présente un pic net pour le bon morceau.
- [x] Un petit script de test par fonction dans `tests/`.

### A2. Base et requêtes (mercredi matin)

- [x] `preparer_base` :
  - 100 morceaux de `fma_small` répartis sur ses 8 genres, plus au moins 50 morceaux hors base, eux aussi répartis par genre ;
  - écarter les fichiers illisibles ou trop courts : quelques fichiers de FMA sont vides ou corrompus ;
  - écrire `liste_morceaux.csv` avec l'identifiant, le titre, l'artiste, le genre et l'appartenance à la base.
  - Les morceaux de `fma_small` sont des **extraits de 30 s** : le dire dans le rapport, car cela joue sur la taille de l'index.
- [x] `extraire_requete` : extrait de Tq secondes commençant à un instant tiré au hasard, **en échantillons** et non en trames. Ainsi, le décalage n'est généralement pas un multiple de H, comme dans la réalité. La propriété (1) n'est alors qu'approchée, ce qui est à discuter.
- [x] Graine aléatoire fixée (`rng`) pour que les résultats soient reproductibles.
- [x] Mercredi 11 h : envoyer à B la liste des morceaux à jouer pour les enregistrements au micro, avec les fichiers sur le Drive. Prévoir aussi quelques morceaux **hors base**, pour mesurer un TFD en conditions réelles.
  - Liste : `resultats/morceaux_a_enregistrer.csv` (20 de la base, 10 hors base). Fichiers : `data/a_enregistrer/`, **à déposer sur le Drive par A**.

### A3. Évaluation (mercredi)

- [x] `evaluer` : TBD et TFD, en séparant « mauvais morceau » (confusion) et « inconnu » (non-détection).
- [x] Fixer s_thr à partir des requêtes négatives, selon la méthode de Q5. Couper les négatives en deux moitiés : l'une sert à **calibrer** le seuil, l'autre à **mesurer** le TFD. Sinon le TFD annoncé est optimiste.
- [x] Générer les 5 figures attendues (section 1) et le tableau récapitulatif des 6 dégradations (`resultats/synthese.csv`).
  - [x] Brouhaha réel ajouté à la campagne (10, 5, 0 dB) ; enregistrements en salle à 1 m et 3 m évalués (`evaluer_enregistrements.m`).
- [x] Mesurer le temps de requête et la taille de l'index pour plusieurs tailles de base, par exemple 25, 50 et 100 morceaux. Résultat attendu : la taille de l'index croît linéairement, et le temps de requête dépend très peu du nombre de morceaux.

### A4. Mesures pour les questions (mercredi après-midi et soir) — fait

Scripts dans `experiences/` : `etude_q3_voisinage`, `etude_q4_p_gamma_F`, `theorie_mesure`, `etude_q6_genres`. Figures : `p_en_fonction_de_rho`, `p_par_bande`, `theorie_mesure`, `tbd_par_genre`. Résultats et interprétations : fin de `resultats/notes_resultats.md`.

| Question | Mesure à produire |
|---|---|
| Q2 | *(fait par B, voir B2)* |
| Q3 | Faire varier la taille du voisinage, tracer ρ, mesurer p après bruit à 10 dB, tracer p en fonction de ρ |
| Q4 | p pour bruit à 10 dB et MP3 à 64 kbit/s ; pour γf = 1, 2, 4, 8 : M, nq·Nu/M et taux d'identification mesuré |
| Q5 | Histogrammes des scores positifs et négatifs, abscisse logarithmique |
| Q6 | TBD MP3 64 kbit/s contre bruit blanc 10 dB ; taux de réussite par genre |
| Théorie/mesure | p en fonction du RSB (bruit blanc), score prédit F·ρ·Tq·p² comparé au score mesuré et à s_thr |
| F | Petit balayage F = 5, 10, 15 (TBD, taille de l'index), pour justifier F |

Définir p précisément dans le code et le rapport : c'est la proportion des pics de l'extrait propre qui se retrouvent **à la même position (m, k)** dans l'extrait dégradé.

Point d'attention pour mesurer p avec le MP3 : le codeur ajoute un retard d'environ 1 100 échantillons à 44,1 kHz, soit environ 25 ms. Il faut recaler l'extrait par intercorrélation avant de comparer les pics.

- [x] Écrire pour B une fiche par figure dans `resultats/notes_resultats.md` : protocole, chiffres clés, ce qu'on observe.
- [x] Écrire dans `resultats/parametres_finaux.md` la valeur finale de chaque paramètre et la mesure qui la justifie.

### A5. Livraison (jeudi et vendredi)

- [ ] Tests des fonctions d'évaluation (`extraire_requete`, `taux_detection`, `calibrer_seuil`, `mesurer_p`, `evaluer`).
- [x] Enregistrements en salle (B3, repris par A) : faits à 1 m et 3 m, évalués sur 5 s, 10 s et la prise entière.
- [ ] **Mercredi 25, 18 h : gel du code.**
- [ ] Vendredi : README final, commentaires, zip.

---

## 3. Partie B : théorie, dégradations, enregistrements, rapport, vidéo (Laure)

### B1. Théorie (mardi soir, puis au fil de l'eau)

- [ ] Lire Wang (2003).
- [ ] **Q1** : justifier Fe = 8 kHz par Shannon et le contenu spectral de la musique. Dire ce qu'on perd et pourquoi c'est acceptable *ici*.
- [ ] **Q2** : tableau de Tw, Δf et trames/s pour N = 256, 512, 1 024, 2 048 ; justifier N ; démontrer la propriété (2).
- [ ] Démontrer la propriété (1), l'invariance des maxima au gain et l'invariance de la clé au décalage et au gain. Expliquer la condition (5).
- [ ] **Q3** : expliquer pourquoi le critère pertinent est ρp² et pas p seul.
- [ ] **Q4** : refaire le tableau pic/paire avec nos valeurs de p ; expliquer pourquoi le meilleur γf n'est pas celui qui donne le moins de parasites.
- [ ] **Q5** : proposer une méthode automatique pour fixer s_thr, par exemple choisir un quantile des scores négatifs pour viser un TFD donné. Expliquer aussi pourquoi les scores négatifs mesurés sont plus élevés que ceux du modèle uniforme : les clés ne sont pas uniformément réparties (slide 12).
- [ ] **Q6** : expliquer pourquoi le MP3 à 64 kbit/s gêne moins qu'un bruit blanc à 10 dB (codage perceptuel et définition (4) des pics) ; analyser les genres qui échouent.

Remarques utiles :

- Le sujet donne κw = 1,30, qui est la valeur pour une fenêtre de **Hamming**. Pour la fenêtre de **Hann** utilisée, κw ≈ 1,44 (Harris, 1978), soit Δf ≈ 11 Hz pour N = 1 024. C'est justement cette valeur qui donne la séparation des demi-tons à partir de 190 Hz annoncée par le sujet.
- Pour la réverbération, la propriété (3) suppose une réponse impulsionnelle bien plus courte que la fenêtre (L_h ≪ N, soit 128 ms). Avec T60 = 0,3 s, et surtout 1 s, cette hypothèse est fausse : c'est la « limite de (3) » du tableau du §7, à exploiter dans la discussion.

### B2. Figure Q2 (mercredi matin, à livrer à 13 h)

Les quatre fonctions de dégradation sont **déjà faites et testées** par A (dans `eval/degradations/`, tests dans `tests/test_degradations.m`) : `ajouter_bruit`, `degrader_mp3`, `filtre_passe_bande`, `reverberation`. B n'a plus que la figure :

- [x] **Figure Q2** (`figures/difference_spectres_passe_bande.pdf`) — **faite par A** (`experiences/figure_q2_filtrage.m`), voir `resultats/notes_resultats.md`. : filtrer un morceau par le passe-bande (`filtre_passe_bande`), tracer S_y,dB − S_x,dB en fonction de k pour plusieurs trames (`calcul_spectrogramme`), et superposer 20·log10|ĥ(f_k)|. Utiliser `nouvelle_figure` et `sauver_figure` (dans `utils/`) pour garder le style des autres figures.

### B3. Enregistrements au micro (mercredi)

**Repris par A** (B ne pouvait pas utiliser MATLAB) : les prises se font avec le Mac de A, qui joue les morceaux sur une enceinte et les enregistre au micro (`experiences/enregistrer_salle.m`, `enregistrer_brouhaha.m`), puis `evaluer_enregistrements.m`. Reste à faire physiquement : poser l'enceinte à 1 m puis à 4 m, et enregistrer le brouhaha à la cafétéria.

- [ ] **Mercredi midi** : enregistrer quelques minutes de brouhaha à la cafétéria, sans musique. C'est l'heure où il y a le plus de monde. Les déposer sur le Drive avant 14 h, sous le nom `brouhaha_cafet.wav` : la campagne d'évaluation le cherche dans `data/enregistrements/` et ajoute alors toute seule les conditions « bruit réel ».
- [ ] **Mercredi après-midi** : jouer les morceaux de la liste de A sur une enceinte et les enregistrer avec un téléphone, en salle, à 2 distances (par exemple 1 m et 4 m). Inclure quelques morceaux hors base.
- [ ] Noter le protocole : salle, enceinte, téléphone, distances, volume, format des fichiers.
- [ ] Nommer les fichiers clairement, par exemple `micro_<idMorceau>_<distance>.wav`. Les déposer sur le Drive avant 19 h, et pas dans git.

### B4. Rapport (mercredi à vendredi)

Plan imposé par le sujet :

| Section | Contenu | Questions |
|---|---|---|
| Introduction | Le problème, le principe de Wang | — |
| Modélisation | Le modèle (1) et ce que chaque terme impose à l'empreinte | — |
| Théorie | Spectrogramme, compromis temps-fréquence, invariances démontrées | Q1, Q2 |
| Conception | Pics, hachage, index, décision ; **tableau de tous les paramètres avec leur justification** | Q3, Q4, Q5 |
| Résultats | Protocole, TBD/TFD, courbes, tableau des 6 dégradations, **théorie confrontée à la mesure** | — |
| Discussion des cas d'échec | MP3 contre bruit, réverbération, genres difficiles | Q6 |
| Conclusion | Bilan, limites, pistes | — |

- [ ] Rédiger sur Overleaf (pas de LaTeX installé localement).
- [ ] Le tableau des paramètres reprend Fe, fenêtre, N, H, Nfft, voisinage, bandes, pics par bande et par seconde, marge, zone cible, F, γf, Tq et s_thr. Pour chacun : la valeur, la justification (théorique ou mesurée) et la figure ou la question correspondante.
- [ ] Chaque figure est citée et commentée dans le texte. Chaque taux est accompagné de son seuil, de son Tq et de sa dégradation.
- [ ] 12 à 15 pages hors annexes ; liste des morceaux en annexe ou en fichier joint.

### B5. Vidéo (jeudi et vendredi matin)

- [ ] **Jeudi après-midi** : slides synthétiques et script minuté. Découpage indicatif : problème et principe 1 min 30, chaîne 1 min 30, démo 1 min 30, résultats 1 min 30, échecs 1 min.
- [ ] Démo en direct avec l'interface : morceau joué dans la salle, reconnaissance, affichage du spectrogramme et de la constellation.
- [ ] **Jeudi soir** : tournage avec A.
- [ ] **Vendredi 10 h** : vidéo exportée, durée vérifiée (7 min).

### B6. Interface de paramétrage = démo (bonus de 10 %)

- [x] Fenêtre `uifigure` écrite dans un fichier `.m` (`interface/interface_reconnaissance.m`, faite le 19 ; extrait, bruit, reconstruction de l'index et micro testés ; thème clair imposé pour la vidéo), plutôt qu'avec App Designer : un `.mlapp` est un fichier binaire, illisible dans git. Elle contient :
  - quelques curseurs pour N, la taille du voisinage, F, γf et s_thr ;
  - un bouton « Enregistrer », qui utilise `audiorecorder` pendant Tq secondes, et un bouton « Identifier » ;
  - l'affichage du spectrogramme, de la constellation, de l'histogramme des δ et du résultat.
- Ce qu'il faut pour la faire tourner :
  - `cache/index_base.mat` (sur git) : suffit pour identifier et régler s_thr et Tq ;
  - `cache/signaux_base.mat` (zip envoyé en privé par A, pas sur git : 184 Mo et licences « No Derivatives ») : nécessaire pour reconstruire l'index quand on change N, le voisinage, F ou γf (`construire_index(signauxBase, P, INDEX.noms)`, environ 1 s).
- Fonctions à appeler, toutes déjà testées : `parametres(...)` avec les réglages en paires nom/valeur, `pretraitement`, `identifier` (renvoie `.id`, `.score`, `.scores`, `.delta`, `.app`, `.pics`, `.SdB`), `calcul_spectrogramme`. `main.m` montre comment tracer la constellation et l'histogramme des δ.

---

## 4. Échanges entre A et B

| A fournit à B | Quand |
|---|---|
| Liste des morceaux à enregistrer et fichiers audio | mercredi 11 h |
| Figures (PDF) dans `figures/` et fiches dans `resultats/notes_resultats.md` | au fil de l'eau, tout pour mercredi 21 h |
| Valeurs finales des paramètres et justifications (`resultats/parametres_finaux.md`) | mercredi 21 h |

| B fournit à A | Quand |
|---|---|
| Figure Q2 | mercredi 13 h |
| Brouhaha | mercredi 14 h |
| Enregistrements en salle | mercredi 19 h |
| Retour sur les figures (lisibilité, ce qui manque) | mercredi soir |

On utilise les **notations du sujet** partout : code, figures, rapport, slides.

---

## 5. Planning

| Quand | A | B | Point commun |
|---|---|---|---|
| Mar. 17 après-midi | Téléchargement de FMA, vérification des toolboxes (A0) | — | — |
| Mar. 17 soir | Chaîne « jouet » (A1) | Lecture de Wang, Q1, Q2, propriétés (B1) | **23 h : pic net dans l'histogramme des δ** |
| Mer. 18 matin | Mesures des questions (A4), commencées en avance | Figure Q2 (B2) ; question à l'enseignant | 13 h : point sur A4 |
| Mer. 18 midi | — | Brouhaha à la cafétéria (B3) | — |
| Mer. 18 après-midi | Évaluation et mesures des questions (A3, A4) | Enregistrements au micro (B3) | — |
| Mer. 18 soir | Figures finales et fiches | Rédaction théorie et conception | **21 h : toutes les mesures faites** |
| Jeu. 19 | Enregistrements réels faits (1 m, 3 m, brouhaha) | Résultats, discussion ; début de l'interface (B6) | — |
| Ven. 20 – dim. 22 | Tests des fonctions d'évaluation ; aide sur l'interface si besoin | Interface (B6) ; rapport complet, ramené à 12–15 pages | Dim. soir : relecture croisée du rapport |
| Lun. 23 – mar. 24 | Corrections demandées par la relecture | Slides, script vidéo | Mar. soir : répétition de la démo |
| Mer. 25 | **18 h : gel du code** | Rapport final | Soir : tournage de la vidéo |
| Jeu. 26 | README, commentaires, zip | Montage, export | Relecture finale ensemble |
| Ven. 27 matin | Dépôt | — | **12 h : dépôt** |

---

## 6. Avant de déposer

- [ ] `main.m` tourne sans erreur sur une installation propre ; chaque fonction a son en-tête et son test.
- [ ] Les 5 figures attendues, le tableau des 6 dégradations et la confrontation théorie/mesure sont dans le rapport, commentés.
- [ ] Q1 à Q6 ont chacune une réponse explicite.
- [ ] Chaque paramètre figure dans le tableau des paramètres avec sa justification.
- [ ] Chaque taux est annoncé avec son seuil, son Tq et sa dégradation.
- [ ] Le rapport fait 12 à 15 pages hors annexes, sans code dans le corps.
- [ ] La vidéo dure 7 min et contient la démo en direct.
- [ ] Le zip a le bon nom et contient programmes, rapport PDF et liste des morceaux.

---

## 7. Organisation du dépôt et Git

```text
README.md  PLAN.md  main.m  parametres.m  liste_morceaux.csv
src/          pretraitement, calcul_spectrogramme, detection_pics,
              generer_empreintes, construire_index, identifier
eval/         preparer_base, extraire_requete, evaluer, taux_detection, calibrer_seuil
eval/degradations/  ajouter_bruit, degrader_mp3, filtre_passe_bande, reverberation
experiences/  preparer_donnees, campagne_evaluation, figures_campagne, passage_echelle
utils/        nouvelle_figure, sauver_figure, morceau_synthetique
interface/    interface de paramétrage et démo
tests/        un test par fonction
figures/      figures du rapport (PDF + PNG), aux noms de rapport/README.md
resultats/    notes_resultats.md, synthese.csv, passage_echelle.csv, parametres_finaux.md
rapport/      export Overleaf, rapport.pdf
video/        slides, script
data/  cache/ audio et index : NON versionnés
```

- **Passer le dépôt en privé** (Settings → General → Danger Zone → Change visibility). Un dépôt public peut être copié par d'autres groupes, et c'est vous qu'on soupçonnerait. En privé, les collaborateurs restent illimités et gratuits.
- `.gitignore` : `data/`, `cache/`, `*.mat`, `*.asv`, `*.wav`, `*.mp3`, `*.m4a`.
- `git pull` avant de commencer ; une branche par tâche (`a/...` ou `b/...`) ; Pull Request vers `main`. Sous pression jeudi, on peut fusionner sans relecture, mais toujours par une Pull Request.
- Chacun reste dans ses dossiers, donc pas de conflit, sauf sur `README.md`, `PLAN.md` et `parametres.m` : petits commits et `git pull` avant d'y toucher.

---

## 8. Plus tard, seulement si tout le reste est fini

À choisir selon le temps restant, une fois le sujet entièrement traité :

- Tolérance δ ± 1 dans le vote, puisque les extraits ne tombent pas sur la grille des trames. C'est rapide à coder et à mesurer : TBD avant et après.
- Base plus grande (500 à 1 000 morceaux, déjà téléchargés avec `fma_small`) pour la courbe de passage à l'échelle.
- Intervalles de confiance sur le TBD et le TFD (loi binomiale).
- Modèle prédictif de p en fonction du RSB, comparé à la mesure.
