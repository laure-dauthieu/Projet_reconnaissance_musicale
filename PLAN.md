# Plan d'action complet

Projet OBL-4101 : reconnaissance musicale par empreintes audio.
**Rendu : vendredi 20 novembre 2026.** On se fixe le dépôt à **12 h**, pour garder une marge.

- **A = Alessandro** : tout le MATLAB (code, expériences, figures, interface).
- **B = coéquipière** : théorie, enregistrements réels, rapport, vidéo.

---

## 0. En bref

**Notre ambition.** Faire mieux qu'une chaîne qui marche : un système dont on **prédit** les performances par la théorie, puis qu'on **vérifie** par la mesure. Le « Dernier mot » de l'énoncé le demande explicitement : expliquer pourquoi le système reconnaît, pourquoi il échoue, et à partir de quel niveau de dégradation la théorie prévoyait l'échec. C'est là que se joue la différence entre une bonne note et une très bonne.

**Le principe de la répartition.** On découpe par nature de travail. A produit le code et les résultats chiffrés. B produit la théorie, les données réelles et tout ce qui se lit ou se regarde. Chaque personne a ses propres dossiers, donc les merges ne peuvent pas entrer en conflit.

**Trois niveaux de priorité**, indiqués sur chaque tâche :

| Niveau | Sens | Règle |
|---|---|---|
| **N1** | Exigé par l'énoncé | Non négociable, terminé mercredi soir |
| **N2** | Approfondissement qui fait la différence | Jeudi |
| **N3** | Si le temps le permet | Coupé en premier en cas de retard |

**Les jalons :**

| Jalon | Quand | Critère de réussite |
|---|---|---|
| J1 | mar. 17, 23 h | Chaîne « jouet » sur 3 morceaux : pic net dans l'histogramme des δ |
| J2 | mer. 18, 13 h | 100 morceaux indexés, premiers TBD et TFD |
| J3 | mer. 18, 21 h | Tout le N1 mesuré, liste des figures figée |
| J4 | jeu. 19, 18 h | **Gel du code**, toutes les figures finales générées |
| J5 | ven. 20, 12 h | **Dépôt du zip sur le Drive** |

---

## 1. Ce qui est noté, et ce qu'on fait pour viser le maximum

| Critère | Poids | Socle (N1) | Ce qui fera la différence (N2/N3) | Qui |
|---|---|---|---|---|
| Justification théorique | 20 % | Démonstrations des propriétés (1), (2) et (5), réponses Q1 à Q6, chaque paramètre justifié | Modèle qui **prédit** p en fonction du RSB et le RSB de rupture ; alphabet effectif qui explique les scores négatifs ; seuil tiré d'un modèle statistique | B (mesures : A) |
| Implémentation | 20 % | Chaîne complète, une fonction par étape, `main.m`, README | Code vectorisé, index trié, tests automatiques d'invariance, `run_all.m` qui régénère tout, passage à 8 000 morceaux | A |
| Évaluation expérimentale | 20 % | 100 morceaux, au moins 50 requêtes positives et 50 négatives, toutes les dégradations, figures exigées | 200 + 200 requêtes par condition, intervalles de confiance à 95 %, seuil calibré sur un jeu et testé sur un autre, positions de requête non alignées sur la grille, analyse par genre | A (+ B pour les enregistrements) |
| Rapport | 10 % | Plan imposé, 12 à 15 pages, figures légendées et commentées | Tableau « où sont les réponses Q1–Q6 », tableau des paramètres avec renvois aux figures, figures vectorielles de style uniforme | B |
| Vidéo | 20 % | 7 min, slides, démo en direct, résultats, échecs | Script minuté, démo qui montre les paires qui votent, morceau hors base rejeté en direct, montage propre | B (+ A pour la démo) |
| Interface (bonus) | 10 % | — | Interface de paramétrage qui recalcule en direct et affiche les grandeurs dérivées, mode micro | A |

---

## 2. Répartition

### 2.1 Qui possède quoi

Chaque dossier a un seul propriétaire. On ne modifie pas un dossier de l'autre sans le prévenir.

| Dossier / fichier | Propriétaire | Contenu |
|---|---|---|
| `src/`, `eval/`, `experiences/`, `app/`, `utils/`, `tests/` | A | Code MATLAB |
| `figures/`, `resultats/` | A | Figures PDF, tableaux `.tex`, fiches de résultats |
| `main.m`, `run_all.m`, `parametres.m`, `liste_morceaux.csv` | A | Points d'entrée, réglages, liste des morceaux |
| `rapport/` | B | Export des sources Overleaf, `rapport.pdf`, protocole des enregistrements |
| `video/` | B | Slides, script (la vidéo elle-même va sur le Drive) |
| `README.md`, `PLAN.md` | Les deux | Petits commits, `git pull` avant d'y toucher |

### 2.2 Rôles transverses

- **A** est responsable technique et prépare le zip final.
- **B** est responsable du rapport, de la vidéo et de la cohérence des notations.
- **Ensemble** : la démo, la relecture croisée, et la compréhension de la partie de l'autre. À J3, chacun explique sa partie à l'autre pendant 30 min. La vidéo porte sur tout le projet, donc chacun doit pouvoir parler de tout.

---

## 3. Partie A : MATLAB (Alessandro)

### A0. Mise en place — mardi, 1 h — N1

- [ ] Installer ffmpeg : `brew install ffmpeg`. MATLAB lancé depuis le Dock **n'hérite pas du PATH du terminal** : on stocke le chemin complet dans `P.ffmpeg = '/opt/homebrew/bin/ffmpeg'`.
- [ ] Télécharger `fma_metadata.zip` (342 Mo) et `fma_small.zip` (7,2 Go) avec les liens du README de <https://github.com/mdeff/fma>. Vérifier les SHA1, dézipper dans `data/`. **À lancer tout de suite**, c'est le plus long.
- [ ] Créer l'arborescence (section 11), `parametres.m` et `utils/style_figure.m`. Ce dernier fixe un style unique : police 9 pt, largeur 8,5 ou 17 cm, couleurs lisibles par les daltoniens, export vectoriel avec `exportgraphics(..., 'ContentType', 'vector')`.
- [ ] Écrire `utils/exporter_tableau_latex.m`, qui produit des tableaux `.tex` au format booktabs que B insère directement avec `\input`.
- [ ] Graine aléatoire fixée (`rng(...)`) dans chaque script d'expérience.

### A1. Chaîne de reconnaissance — mardi — N1

| Fonction | Ce qu'elle fait | Points d'attention |
|---|---|---|
| `pretraitement` | Mono puis `resample` à 8 kHz | Accepte un fichier ou un signal. Renvoie une colonne en double. Jamais `x(1:k:end)` |
| `calcul_spectrogramme` | TFCT, Hann périodique, N = 1024, H = N/2, sortie en dB | Renvoie aussi les axes t et f. Matrice K × M (canaux × trames) |
| `detection_pics` | Maxima locaux sur ±3 trames × ±5 canaux | `movmax` deux fois (pas d'Image Processing Toolbox). Seuil local = médiane glissante de S_dB dans la bande + marge. Quota de pics par bande et par seconde (6 bandes géométriques de 200 à 4 000 Hz) |
| `generer_empreintes` | Paires (ancre, cible) puis clés | Zone cible Δt ∈ [0,1 ; 2] s soit Δm ∈ [2, 31], \|Δk\| ≤ 60, F premières cibles. Clé en un seul entier `uint32` : u = (q1·Nf + q2)·Nt + (Δm − 2). Vectorisé |
| `construire_index` | Tableau `[clé, id, m1]` trié par clé | Types compacts (`uint32`, `uint16`). Clés uniques + position de début + nombre d'entrées. Sauvegarde dans `cache/` |
| `identifier` | Vote par décalage δ = m_r − m_q | Récupère **toutes** les entrées de chaque clé. Vote sur (morceau, δ) avec `accumarray`. Score = hauteur du plus grand pic. Renvoie aussi les paires qui ont voté, pour l'affichage |

- [ ] `main.m` : indexe 3 morceaux, identifie un extrait, affiche spectrogramme + constellation + histogramme des δ.
- [ ] **J1 :** pic net dans l'histogramme des δ pour le bon morceau, rien de comparable pour les autres. Tant que ce n'est pas le cas, on ne passe pas à la suite.

### A2. Tests automatiques — mardi soir — N1 puis N2

On utilise `matlab.unittest` (inclus dans MATLAB), un fichier par test dans `tests/`. Ces tests servent aussi de **preuves expérimentales des invariances**, à citer dans le rapport.

- [ ] **Gain** : les pics de α·x sont exactement ceux de x, pour α de 0,01 à 100.
- [ ] **Décalage entier** : x décalé de m0·H donne les mêmes clés, et le vote tombe sur δ = m0.
- [ ] **Sinusoïdes** : une somme de sinusoïdes donne des pics aux canaux attendus.
- [ ] **Index** : la recherche donne le même résultat qu'une recherche exhaustive sur un petit index.
- [ ] **Bruit** : `ajouter_bruit` produit le RSB demandé à 0,1 dB près.
- [ ] **Prétraitement** : fréquence 8 kHz, mono, vecteur colonne.

### A3. Base de morceaux et requêtes — mercredi matin — N1

- [ ] `preparer_base` :
  - lit `tracks.csv` (attention, il a **deux lignes d'en-tête**) ;
  - écarte les fichiers illisibles ou trop courts (quelques fichiers de `fma_small` sont corrompus) ;
  - tire **100 morceaux de base répartis sur les 8 genres** de `fma_small` (Electronic, Experimental, Folk, Hip-Hop, Instrumental, International, Pop, Rock) ;
  - tire un **réservoir d'au moins 300 morceaux hors base**, eux aussi équilibrés ;
  - écrit `liste_morceaux.csv` (track_id, artiste, titre, genre, licence, durée, rôle).
- [ ] Mettre en cache les signaux prétraités (`int16`) pour ne décoder chaque MP3 qu'une seule fois.
- [ ] Écrire `resultats/morceaux_a_enregistrer.csv` pour B (20 morceaux de la base + 10 hors base) **avant 11 h**, et partager les fichiers audio correspondants sur le Drive.
- [ ] `extraire_requete` : début t0 tiré **en continu** à la fréquence d'origine, donc pas aligné sur un multiple de H. C'est le cas réaliste. Garde la vérité terrain (id, t0).
- [ ] Ordre de traitement d'une requête : extrait d'origine → dégradation → `pretraitement`, comme dans un vrai téléphone.
- [ ] Jeux de requêtes, pour chaque condition :
  - 200 positives (2 par morceau de la base) ;
  - 200 négatives, coupées en **100 de calibration** (pour fixer le seuil) et **100 de test** (pour mesurer le TFD) ;
  - une graine fixée par condition.

### A4. Dégradations — mercredi matin — N1

| Fonction | Paramètres | Mise en œuvre |
|---|---|---|
| `ajouter_bruit` | RSB = 20, 15, 10, 5, 0 dB | Px calculé **sur l'extrait**. b = √(Px / 10^(RSB/10)) · randn |
| idem, avec brouhaha | RSB = 10, 5, 0 dB | Segment aléatoire de l'enregistrement de cafétéria fait par B, même formule |
| `degrader_mp3` | 128, 64, 32 kbit/s | `audiowrite` en WAV → ffmpeg (`libmp3lame -b:a 64k`) → `audioread`. **Piège :** le codeur ajoute environ 1 100 échantillons de retard. Le compenser par intercorrélation avant de mesurer p (inutile pour le TBD, le vote absorbe le décalage) |
| `filtre_passe_bande` | 300–3 400 Hz | Butterworth d'ordre 4. `filtfilt` (sans retard) pour mesurer p, `filter` (causal, réaliste) pour le TBD |
| `reverberation` | T60 = 0,3 et 1 s | Réponse synthétique h(t) = n(t)·exp(−6,91·t/T60) plus un trajet direct, appliquée avec `fftfilt` |
| enregistrements réels | salle à 1 m et 4 m, haut-parleur de téléphone | Fichiers de B dans `data/enregistrements/` |

### A5. Évaluation et seuil — mercredi — N1

- [ ] `evaluer` classe chaque réponse :

  | Requête | Réponse | Compte comme |
  |---|---|---|
  | positive | le bon morceau | bonne détection (TBD) |
  | positive | un autre morceau | confusion |
  | positive | « inconnu » | non-détection |
  | négative | « inconnu » | rejet correct |
  | négative | un morceau | fausse détection (TFD) |

  Elle donne aussi le temps de calcul par requête.
- [ ] **Intervalles de confiance à 95 %** (score de Wilson, codé à la main car il n'y a pas de Statistics Toolbox). Avec 0 erreur sur n requêtes, on donne la borne haute 3/n (« règle de trois »).
- [ ] `calibrer_seuil` (Q5) : ajustement d'une loi de Gumbel par la méthode des moments sur les scores des négatives de calibration, puis s_thr = μ − β·ln(−ln(1 − α)) pour un TFD visé α = 1 %. On compare avec la règle des slides (plus grand score négatif + marge). On **valide sur les négatives de test**, jamais sur celles qui ont servi à calibrer.
- [ ] Chaque taux est publié avec son seuil, son Tq, sa dégradation et son nombre de requêtes.

### A6. Études demandées par l'énoncé — mercredi après-midi — N1

- [ ] **Q2** :
  - T01 (Tw, Δf et trames/s pour N = 256 à 2 048) ;
  - F03 : p sous bruit à 10 dB et score en fonction de N ;
  - F04 : S_y,dB − S_x,dB en fonction de k pour 5 trames. Avec un passe-bande, les courbes doivent se superposer. Avec la réverbération à 1 s, elles ne se superposent plus : c'est la limite de la propriété (3).
- [ ] **Q3** : balayage de Δk ∈ {2, 3, 5, 8, 12} et Δm ∈ {1, 2, 3, 5}, quota désactivé. Mesure de ρ, de p à 10 dB et de ρp² → F07.
- [ ] **Q4** :
  - p mesuré pour le bruit à 10 dB et le MP3 à 64 kbit/s ;
  - T02 : le tableau pic/paire de l'énoncé avec nos valeurs, plus la survie des clés **mesurée** à côté de p² ;
  - T03 : pour γf = 1, 2, 4, 8, le nombre de clés M, les parasites attendus nqNu/M et le TBD mesuré.
- [ ] **Q5** : F10 (histogrammes des scores positifs et négatifs, abscisse log) et F11 (courbe TBD/TFD en balayant le seuil, une courbe par dégradation).
- [ ] **Figures de résultats exigées** :
  - F12 : TBD en fonction du RSB, une courbe par Tq ∈ {3, 5, 10} s ;
  - F13 : TBD en fonction du débit MP3 ;
  - F15 : synthèse de toutes les dégradations ;
  - F16 : temps de requête et taille de l'index en fonction du nombre de morceaux.
- [ ] **Q6** : F17 (p par bande, MP3 64 kbit/s contre bruit à 10 dB) et F18 (TBD par genre).
- [ ] À J3 : remplir `resultats/notes_resultats.md` (voir section 5.1).

### A7. Approfondissements — jeudi matin — N2

- [ ] **X1. Théorie confrontée à la mesure.** On prédit p(RSB) avec le modèle de RSB local de B (D8), puis on compare à la mesure. On en déduit le **RSB de rupture prédit** pour chaque Tq, là où FρTq·p² = s_thr, et on le compare au RSB où le TBD mesuré passe sous 50 % → F14.
- [ ] **X2. Les deux pics d'une paire survivent-ils indépendamment ?** On compare la survie des clés mesurée à p². Un écart montre que les survies sont corrélées.
- [ ] **X3. Alphabet effectif.** On calcule M_eff = 1 / Σ π_u², où π_u est la part des entrées de l'index qui portent la clé u. On en déduit le nombre corrigé d'appariements fortuits, nqNu/M_eff, qui doit expliquer les scores négatifs de 10 à 25 au lieu de 1 à 2 → F21.
- [ ] **X5. Positions non alignées.** On compare des requêtes alignées sur la grille et non alignées, avec et sans tolérance δ ± 1 (score = meilleure somme de deux cases voisines).
- [ ] **X6. Passage à l'échelle.** Base de 100, 500, 1 000 puis 2 000 morceaux, et 8 000 (tout `fma_small`) en tâche de nuit. Mesures : temps de construction, mémoire, temps de requête médian, et **TFD à seuil fixe**, qui augmente avec la taille de la base → F16, T06.
- [ ] **X7. Pourquoi certains genres échouent.** Descripteurs par morceau : densité de pics avant quota, platitude spectrale, part d'énergie au-dessus de 2 kHz. On regarde leur corrélation avec le score obtenu.
- [ ] **X9. « En 5 secondes ? »** Reconnaissance sur fenêtre glissante. On trace le TBD pour Tq de 1 à 10 s et la distribution du temps avant décision → F20. C'est la réponse directe au titre du sujet.

### A8. Si le temps le permet — N3

- [ ] **X8. Canal réel.** Une fois l'enregistrement en salle aligné, on estime g(k) = moyenne sur les trames de S_y,dB − S_x,dB, aux deux distances → F19. On vérifie ainsi la propriété (3) sur un vrai haut-parleur dans une vraie salle.
- [ ] **X11. Clés redondantes.** On supprime les clés répétées sur des trames consécutives (notes tenues) ou les clés trop fréquentes, et on mesure l'effet sur la séparation entre scores positifs et négatifs.
- [ ] **X13. Repliement.** On compare une décimation naïve à `resample` (F02), avec une requête MP3 pour que les hautes fréquences diffèrent entre la référence et la requête.

### A9. Interface (bonus) et démo — jeudi après-midi

- [ ] On construit l'interface en code dans `app/ReconnaissanceApp.m` avec `uifigure`, **pas avec App Designer** : un fichier `.mlapp` est binaire, illisible dans git et impossible à fusionner.
- [ ] Les onglets :
  - **Base** : choix du dossier, indexation avec barre de progression, statistiques (morceaux, entrées, mémoire, temps).
  - **Paramètres** : un réglage par paramètre, regroupés par étape. Les grandeurs dérivées s'affichent en direct : Tw, Δf, ρ, M, score attendu, p critique. Un bouton remet les « valeurs justifiées ».
  - **Requête** : fichier, micro ou extrait aléatoire de la base, avec dégradations réglables (RSB, débit MP3, passe-bande, T60).
  - **Résultat** :
    - titre, artiste et genre trouvés ;
    - score comparé au seuil ;
    - position estimée dans le morceau, comparée à la vraie ;
    - temps de calcul ;
    - spectrogramme et constellation, avec **les paires qui ont voté mises en évidence** ;
    - histogramme des δ et cinq meilleurs scores.
- [ ] **Mode démo** : écoute continue au micro et décision dès que le score dépasse s_thr, avec affichage du temps de décision.
- [ ] Autoriser le micro pour MATLAB : Réglages Système → Confidentialité et sécurité → Microphone.
- [ ] Le micro enregistre à 44,1 kHz, puis le signal passe par `pretraitement` : c'est exactement la même chaîne que pour les références.

### A10. Livraison — vendredi matin

- [ ] `run_all.m` régénère **toutes** les figures et tableaux depuis un clone propre. Indiquer sa durée dans le README.
- [ ] README final : installation, lancement, rôle de chaque fonction, reproduction des figures.
- [ ] Chaque fonction a un en-tête : rôle, entrées, sorties, justification des paramètres.
- [ ] Préparer le zip `Projet_Groupe_Nom1_Nom2_Nom3.zip` : programmes commentés, rapport PDF, `liste_morceaux.csv`.

---

## 4. Partie B : théorie, données réelles, rapport, vidéo (coéquipière)

### B0. Démarrage — mardi soir

- [ ] Lire Wang (2003), 5 pages, l'article fondateur. Survoler Haitsma et Kalker (2002). En tirer une dizaine de lignes pour l'introduction et une idée de perspective pour la conclusion.
- [ ] Ouvrir le projet **Overleaf** (aucune installation LaTeX sur nos machines) :
  - squelette avec le plan imposé (section 6) ;
  - préambule : `babel` (français), `amsmath`, `siunitx` (virgule décimale), `booktabs`, `graphicx`, `subcaption`, `hyperref`, `cleveref` ;
  - tableau des notations, **repris exactement de l'énoncé** ;
  - une macro qui affiche un cadre « figure à venir » tant que le PDF de A n'existe pas (`\IfFileExists`), pour écrire sans attendre les résultats.
- [ ] Bibliographie : Wang 2003, Haitsma et Kalker 2002, Harris 1978, Müller 2015, plus un article sur le codage perceptuel pour Q6 (par exemple Painter et Spanias, *Perceptual coding of digital audio*, Proc. IEEE, 2000).

### B1. Théorie — mardi soir à mercredi midi — N1 et N2

| Réf. | Contenu | Où dans le rapport |
|---|---|---|
| **D1** | **Q1.** Shannon : Fe = 8 kHz garde la bande 0–4 kHz. Le fondamental le plus aigu du piano est vers 4,2 kHz, et l'essentiel du contenu mélodique est sous 2 kHz. On perd la brillance (cymbales, sifflantes), qui est aussi ce que le canal acoustique et le MP3 détruisent en premier. Coût de calcul divisé par 44 100 / 8 000 ≈ 5,5. À appuyer par F01 (part de l'énergie et des pics sous 4 kHz, mesurée sur notre base) | §3.1 |
| **D2** | **Q2.** Tw = N/Fe et Δf = κw·Fe/N avec **κw ≈ 1,44 pour la fenêtre de Hann** (Harris, 1978). L'énoncé donne 1,30, qui est la valeur pour Hamming : le signaler. Pour N = 1 024 : Δf ≈ 11,25 Hz, et deux demi-tons sont séparés dès f = Δf / (2^(1/12) − 1) ≈ 190 Hz. Tableau T01 pour N = 256, 512, 1 024, 2 048 : Tw = 32, 64, 128, 256 ms ; Δf ≈ 45, 22,5, 11,25, 5,6 Hz ; 62,5, 31,25, 15,6, 7,8 trames/s | §3.2 |
| **D3** | Démonstration de la propriété (1) par changement de variable. Ce qui se passe quand le décalage n'est pas un multiple de H : des pics changent de trame, ce qui justifie la tolérance δ ± 1 (X5) | §3.3 |
| **D4** | Démonstration de la propriété (2). On écrit (h∗x)[n + mH] = Σ_l h[l]·x[n + mH − l], puis on pose n' = n − l. Le résultat vaut ĥ(f_k)·X_x[m,k] plus un terme d'erreur qui vient de la variation de la fenêtre sur la durée Lh de h, d'ordre Lh/N. Conséquence : la réverbération sort du modèle, car Lh ≈ T60·Fe ≈ 8 000 ≫ N = 1 024 | §3.3 |
| **D5** | Invariance des maxima à un gain positif (l'ordre des valeurs est conservé). Démonstration de (5) : si le pic dépasse ses voisins d'au moins μ dB, ajouter g(k) ne le déplace pas tant que Δg(V) < μ. Conséquence : un voisinage étroit en fréquence est plus robuste | §3.4 |
| **D6** | **Dimensionnement.** Nt = 30 valeurs de Δm ; M = Nf²·Nt ≈ 7,9 × 10⁶ pour γf = 1 ; score attendu s ≈ F·ρ·Tq·p² ; condition F·p > 1 ; pourquoi le bon critère est ρp² (Q3) : le nombre de clés correctes retrouvées est proportionnel à ρp² | §4.1–4.2 |
| **D7** | **Modèle des fausses alarmes.** Modèle uniforme : nqNu/M appariements fortuits répartis sur toutes les cases (loi de Poisson), dont on prend le maximum. Il donne un **plancher** de seuil. Correction par l'alphabet effectif M_eff (X3). Hypothèse à vérifier avec X3 et X11 : en gamme tempérée, deux morceaux partagent les mêmes fréquences de notes, et une note tenue produit la même clé sur plusieurs trames consécutives. Cela crée des votes fortuits **cohérents dans le temps**, d'où des scores négatifs de 10 à 25 | §4.4 |
| **D8** | **Modèle de RSB local (X1).** Pour chaque pic propre, on compare son niveau S_x[m,k] au niveau moyen du bruit dans ce canal, σ_b²·Σw². On prédit qu'un pic survit si ce RSB local dépasse un seuil θ, ajusté une seule fois sur quelques morceaux. On en déduit p(RSB) prédit, puis le RSB de rupture, là où F·ρ·Tq·p² = s_thr | §5.3 |
| **D9** | **Q6.** Le codage perceptuel retire ce qui est sous le seuil de masquage et cache le bruit de quantification sous ce seuil. Les pics sont, par construction, les composantes les plus fortes de leur voisinage : ce sont les masqueurs, que le codeur conserve. Le bruit blanc, lui, remplit tout le plan temps-fréquence avec le même niveau, alors que le spectre musical décroît avec la fréquence. Le RSB local est donc très négatif dans les bandes hautes, et les pics y sont remplacés. À appuyer par F17 | §6 |
| **D10** | **Seuil automatique (Q5).** Loi de Gumbel ajustée sur les scores négatifs, TFD visé, séparation calibration/test, intervalles de confiance | §4.4 |

- [ ] **Mercredi 12 h :** envoyer à A les formules de D6, D7, D8 et D10, pour qu'il trace les courbes théoriques à côté des mesures.

### B2. Enregistrements réels — mercredi après-midi, environ 2 h — N1

- [ ] **Matériel** : une enceinte, un téléphone qui enregistre en WAV à 44,1 ou 48 kHz (sans mode « voix » ni réduction de bruit), une application de sonomètre.
- [ ] **Morceaux** : la liste que A fournit dans `resultats/morceaux_a_enregistrer.csv` (20 morceaux de la base et 10 hors base). Les fichiers sont sur le Drive.
- [ ] **Prises**, 15 s chacune, en démarrant le morceau à un instant quelconque :
  - en salle à environ **1 m** de l'enceinte ;
  - en salle à environ **4 m** ;
  - morceau joué par le **haut-parleur d'un téléphone** (vrai passe-bande) ;
  - **brouhaha** de cafétéria, 3 min, sans musique (pour la dégradation « bruit réel »).
- [ ] **Nommage** : `salle_1m_<track_id>.wav`, `salle_4m_<track_id>.wav`, `hptel_<track_id>.wav`, `brouhaha_cafet.wav`.
- [ ] **Fiche protocole** dans `rapport/protocole_enregistrements.md` : salle et dimensions approximatives, matériel, distances, niveau mesuré en dB, bruit ambiant, photo du montage.
- [ ] Déposer sur le Drive **avant 19 h** (pas dans git : c'est de l'audio et le dépôt est public).

### B3. Rapport — mercredi à vendredi

- [ ] Ordre de rédaction :
  1. théorie (mardi et mercredi) ;
  2. conception (mercredi soir) ;
  3. résultats et discussion (jeudi, à partir des fiches de A) ;
  4. introduction, conclusion et résumé (jeudi soir) ;
  5. relecture croisée (vendredi matin).
- [ ] Plan détaillé : section 6.
- [ ] Liste de contrôle : section 8.2.

### B4. Vidéo — jeudi

- [ ] Slides : 10 à 12, mêmes figures que le rapport, très peu de texte.
- [ ] Script minuté : section 7.
- [ ] Tournage jeudi soir avec A, montage vendredi matin.

---

## 5. Contrat entre A et B

### 5.1 Ce que A fournit à B

- **Figures** dans `figures/`, en PDF vectoriel et en PNG, nommées `FNN_nom.pdf`, toutes avec le même style.
- **Tableaux** dans `resultats/tableaux/`, au format `.tex`, prêts pour `\input`.
- **Fiche de résultats** dans `resultats/notes_resultats.md`, une entrée par figure :
  - protocole (nombre de requêtes, graine, condition) ;
  - chiffres clés ;
  - ce qu'on voit sur la figure ;
  - une piste d'interprétation.
- `morceaux_a_enregistrer.csv` (mercredi 11 h), `liste_morceaux.csv`, valeurs finales des paramètres (J3).

### 5.2 Ce que B fournit à A

- Formules D6, D7, D8 et D10 (mercredi 12 h).
- Enregistrements et brouhaha (mercredi 19 h).
- Retour sur les figures (lisibilité, ce qui manque) à J3.

### 5.3 Liste des figures et tableaux

| ID | Contenu | Sert à | Niveau |
|---|---|---|---|
| F01 | Énergie cumulée et position des pics en fonction de la fréquence (base entière, analyse pleine bande) | Q1 | N2 |
| F02 | p avec décimation naïve contre `resample` | Q1 | N3 |
| T01 | Tw, Δf, trames/s pour N = 256 à 2 048 | Q2 | N1 |
| F03 | p sous bruit à 10 dB et score en fonction de N | Q2 | N2 |
| F04 | S_y,dB − S_x,dB en fonction de k, 5 trames : passe-bande puis réverbération à 1 s | Q2 | N1 |
| F05 | Spectrogramme avec la constellation superposée | Étape 3 | N1 |
| F06 | Pics après un gain × 0,1 et un filtre en pente : seuil global contre seuil local | Seuil | N2 |
| F07 | ρ, p à 10 dB et ρp² en fonction du voisinage | Q3 | N1 |
| F08 | Zone cible et paires d'une ancre, sur nos données | Étape 4 | N1 |
| T02 | Tableau pic/paire avec nos p (bruit 10 dB, MP3 64 kbit/s) et la survie des clés mesurée | Q4 | N1 |
| T03 | M, parasites attendus et TBD mesuré pour γf = 1, 2, 4, 8 | Q4 | N1 |
| F09 | Histogrammes des δ : bon morceau contre mauvais morceau | Étape 5 | N1 |
| F10 | Histogrammes des scores positifs et négatifs, abscisse log, seuil | Q5 | N1 |
| F11 | Courbe TBD/TFD en balayant le seuil, une courbe par dégradation | §7 | N1 |
| F12 | TBD en fonction du RSB, une courbe par Tq ∈ {3, 5, 10} s, avec intervalles de confiance | §7 | N1 |
| F13 | TBD en fonction du débit MP3 | §7 | N1 |
| F14 | p(RSB) mesuré et prédit ; RSB de rupture prédit et mesuré | X1 | N2 |
| F15 | TBD et TFD pour toutes les dégradations, réelles comprises | §7 | N1 |
| F16 | Temps de requête, taille de l'index et TFD en fonction du nombre de morceaux | §7 | N1 (≤ 1 000), N2 (8 000) |
| F17 | p par bande et RSB local par bande, MP3 64 kbit/s contre bruit à 10 dB | Q6 | N2 |
| F18 | TBD par genre (N1), avec descripteurs (N2) | Q6 | N1/N2 |
| F19 | g(k) mesuré sur les enregistrements en salle | X8 | N3 |
| F20 | TBD en fonction de Tq de 1 à 10 s, temps avant décision | X9 | N2 |
| F21 | Distribution des fréquences des clés (log-log) et M_eff | X3 | N2 |
| T04 | Synthèse TBD et TFD avec intervalles, seuil, Tq et dégradation | §7 | N1 |
| T05 | Tous les paramètres : valeur, justification, renvoi à la figure | §4 | N1 |
| T06 | Chiffres du passage à l'échelle | §7 | N1 |

### 5.4 Conventions communes

- **Notations de l'énoncé partout** : code, figures, rapport, slides. Dans le code : `P.Fe`, `P.N`, `P.H`, `P.Nfft`, `P.dk`, `P.dm`, `P.rho`, `P.F`, `P.gamma_f`, `P.Tq`, `P.s_thr`.
- **Axes en français et avec unités** : « temps (s) », « fréquence (kHz) », « RSB (dB) », « TBD (%) ».
- Un taux n'est **jamais** donné sans son seuil, son Tq, sa dégradation et son nombre de requêtes.

---

## 6. Rapport : plan détaillé (12 à 15 pages hors annexes)

En première page : un résumé de 5 lignes avec les chiffres clés, et un petit tableau « Où trouver les réponses aux questions 1 à 6 ».

| § | Section | Pages | Contenu | Figures |
|---|---|---|---|---|
| 1 | Introduction | 0,75 | Le problème, Wang 2003, ce que nous avons fait, résultat principal en une phrase | — |
| 2 | Modélisation | 1 | Modèle (1) terme par terme ; tableau terme → dégradation simulée → invariance visée | — |
| 3 | Théorie | 3 | 3.1 Prétraitement et Shannon (Q1) ; 3.2 TFCT et compromis temps-fréquence (Q2) ; 3.3 propriétés (1) et (2) démontrées et vérifiées ; 3.4 invariance des maxima et condition (5) ; 3.5 limites (réverbération, décalage non entier) | F01, T01, F03, F04 |
| 4 | Conception | 3,5 | 4.1 Pics : seuil local, bandes, quota (Q3) ; 4.2 empreintes : paires, zone cible, F, γf (Q4) ; 4.3 index inversé : structure, complexité, mémoire ; 4.4 décision : alignement, seuil théorique puis calibré (Q5) ; 4.5 tableau des paramètres | F05–F10, T02, T03, T05 |
| 5 | Résultats | 4 | 5.1 Protocole (base, requêtes, graines, séparation calibration/test) ; 5.2 TBD et TFD ; 5.3 théorie confrontée à la mesure ; 5.4 conditions réelles ; 5.5 passage à l'échelle ; 5.6 temps de décision | T04, F11–F16, F20, F21 |
| 6 | Discussion des échecs | 1,5 | Q6 : MP3 contre bruit ; genres difficiles ; réverbération ; limites (changement de tempo ou de hauteur) | F17, F18, F19 |
| 7 | Conclusion | 0,5 | Bilan, ce que la théorie prédisait et ce qui a été confirmé, perspectives | — |
| A | Annexes | — | Démonstrations complètes, liste des morceaux, résultats détaillés, protocole des enregistrements | — |

Règles de l'énoncé à respecter :

- **Pas de code dans le corps du rapport.**
- Une courbe sans commentaire ne vaut rien : chaque figure est citée dans le texte avec **ce qu'il faut y voir**.
- Un paramètre non justifié est considéré comme non choisi : chaque paramètre apparaît dans T05 avec son renvoi.

---

## 7. Vidéo : script minuté (7 min maximum)

| Temps | Contenu | Qui |
|---|---|---|
| 0:00–0:25 | Accroche : un morceau sur l'enceinte, l'interface affiche le titre en quelques secondes | A |
| 0:25–1:10 | Le problème : modèle (1), les deux exigences contradictoires (robustesse et spécificité) | B |
| 1:10–2:40 | La méthode en 4 images : spectrogramme → constellation (invariance au gain) → paires et clés → alignement des δ | B puis A |
| 2:40–4:00 | **Démo en direct** dans une salle : à 1 m, à 4 m, avec une conversation en fond, puis un morceau hors base qui doit répondre « inconnu ». À l'écran : spectrogramme, constellation, paires qui votent, histogramme des δ | A |
| 4:00–5:30 | Résultats : TBD selon le RSB et Tq, MP3, courbe TBD/TFD et seuil, RSB de rupture prédit contre mesuré | B |
| 5:30–6:30 | Échecs : MP3 contre bruit (explication par bandes), genres difficiles, réverbération | A |
| 6:30–7:00 | Conclusion : ce qu'il faut retenir | B |

**Production :**

- Capture d'écran et webcam avec OBS ; un téléphone sur pied pour filmer la salle.
- Le micro près de la bouche pour la voix.
- Montage dans iMovie ou DaVinci Resolve, export MP4 en 1080p.
- **Une répétition chronométrée** avant le tournage final.
- **Plan de secours :** enregistrer une première prise de la démo dès jeudi après-midi.

---

## 8. Listes de contrôle qualité

### 8.1 Code (A)

- [ ] `run_all.m` tourne de bout en bout depuis un clone propre (après avoir mis les données dans `data/`).
- [ ] Tous les tests de `tests/` passent.
- [ ] Aucun chemin absolu dans le code, sauf `P.ffmpeg` ; aucun nombre magique en dehors de `parametres.m`.
- [ ] Chaque fonction a son en-tête et se teste seule.
- [ ] Graines fixées : relancer donne les mêmes chiffres.
- [ ] Le README explique l'installation, le lancement et la reproduction des figures.

### 8.2 Rapport (B, relu par A)

- [ ] Q1 à Q6 ont chacune une réponse explicite, repérable depuis le tableau de la première page.
- [ ] Chaque figure est citée, commentée, légendée, vectorielle et lisible en noir et blanc.
- [ ] Chaque paramètre figure dans T05 avec sa justification.
- [ ] Chaque taux est accompagné de son seuil, son Tq, sa dégradation, son nombre de requêtes et son intervalle de confiance.
- [ ] Les notations sont celles de l'énoncé, et identiques dans le texte, les figures et les slides.
- [ ] Entre 12 et 15 pages hors annexes, sans code dans le corps.
- [ ] Orthographe vérifiée (LanguageTool ou Antidote).

### 8.3 Vidéo (B, relue par A)

- [ ] Durée inférieure ou égale à 7:00.
- [ ] Son clair, démo visible et lisible.
- [ ] Les deux personnes parlent.
- [ ] On voit le spectrogramme et la constellation (exigé).
- [ ] Résultats et analyse des échecs présents.

### 8.4 Dépôt (A et B ensemble)

- [ ] Nom : `Projet_Groupe_Nom1_Nom2_Nom3.zip`.
- [ ] Contenu : programmes commentés, `rapport.pdf`, `liste_morceaux.csv`, README.
- [ ] Déposé dans le dossier du groupe sur le Drive : « Projet » → « Rapport/Dossier complet ».
- [ ] La vidéo est déposée selon les consignes, et le lien est vérifié.
- [ ] **Avant vendredi 12 h.**

---

## 9. Planning détaillé

| Quand | A (MATLAB) | B (théorie, rapport, vidéo) | Synchro |
|---|---|---|---|
| **Mar. 17, après-midi** | A0 : ffmpeg, lancement du téléchargement FMA, arborescence, `parametres.m` | B0 : lecture de Wang, squelette Overleaf, bibliographie | — |
| **Mar. 17, soir** | A1 : chaîne jouet sur 3 morceaux, puis A2 (tests gain et décalage) | D1 à D3 | **J1, 23 h :** pic δ net |
| **Mer. 18, matin** | A3 et A4 : base de 100 morceaux, requêtes, dégradations ; liste à enregistrer pour B (11 h) | D4 à D8, protocole des enregistrements | **J2, 13 h :** premiers TBD/TFD ; B envoie ses formules |
| **Mer. 18, après-midi** | A5 et A6 : évaluation, seuil, études Q2 à Q6 | B2 : enregistrements réels (Drive à 19 h), puis rédaction de la section Conception | — |
| **Mer. 18, soir** | Campagne d'évaluation complète, passage à 8 000 morceaux pendant la nuit | Rédaction de la section Théorie | **J3, 21 h :** N1 complet, figures figées, 30 min d'explications croisées |
| **Jeu. 19, matin** | A7 : X1, X2, X3, X5, X7, X9 ; évaluation des enregistrements réels | Rédaction des Résultats et de la Discussion à partir des fiches | Point à 12 h |
| **Jeu. 19, après-midi** | A9 : interface et mode démo, première prise de la démo | Introduction, conclusion, slides, script de la vidéo | **J4, 18 h : gel du code** |
| **Jeu. 19, soir** | Tournage de la vidéo (ensemble) | Tournage de la vidéo (ensemble) | Relecture croisée du rapport |
| **Ven. 20, matin** | A10 : `run_all` depuis un clone propre, README, commentaires, zip | Montage final de la vidéo, version finale du rapport en PDF | **J5, 12 h : dépôt** |

**Si on prend du retard, on coupe dans cet ordre :**

1. N3 (X8, X11, X13) ;
2. passage à 8 000 morceaux (on s'arrête à 1 000) ;
3. finitions de l'interface ;
4. X7 (descripteurs par genre) et X9.

**On ne coupe jamais :**

- les requêtes négatives et la séparation calibration/test ;
- les figures exigées par l'énoncé ;
- la démo en direct ;
- la confrontation théorie/mesure F14.

---

## 10. Risques et parades

| Risque | Parade |
|---|---|
| Le téléchargement de FMA est lent ou échoue | Le lancer dès maintenant. Si besoin, commencer la chaîne jouet avec 3 MP3 quelconques |
| MATLAB ne trouve pas ffmpeg | Chemin complet dans `P.ffmpeg`. Tester `system([P.ffmpeg ' -version'])` |
| Fonction d'une toolbox absente (`ordfilt2`, `gevfit`, `binofit`) | On reste en MATLAB de base et Signal Processing : `movmax`, Gumbel par les moments, Wilson codé à la main |
| Le micro ne marche pas dans MATLAB | Autorisation macOS. Tester mercredi, pas jeudi soir |
| Le MP3 décale le signal et fausse la mesure de p | Recalage par intercorrélation avant la mesure |
| Le seuil est sur-ajusté | Calibration et test sur des négatives différentes |
| Les figures arrivent tard pour le rapport | Cadres « figure à venir » dans Overleaf. B écrit la théorie et la conception d'abord |
| Perte de travail | Commit et push à chaque tâche terminée. Rapport sur Overleaf, audio sur le Drive |
| La démo rate pendant le tournage | Prise de secours jeudi après-midi |
| Dépôt en retard (−5 points) | Dépôt visé à 12 h vendredi, vérifié par les deux |

---

## 11. Organisation du dépôt et Git

```text
README.md  PLAN.md  main.m  run_all.m  parametres.m  liste_morceaux.csv
src/          pretraitement, calcul_spectrogramme, detection_pics,
              generer_empreintes, construire_index, identifier
eval/         preparer_base, extraire_requete, evaluer, calibrer_seuil, ic_wilson
eval/degradations/   ajouter_bruit, degrader_mp3, filtre_passe_bande, reverberation
experiences/  un script par étude ou figure (exp_Q2_choix_N.m, ...)
app/          ReconnaissanceApp.m (interface, bonus)
utils/        style_figure, exporter_tableau_latex, cache
tests/        tests automatiques (matlab.unittest)
figures/      F01 à F21 en PDF et PNG (versionnés)
resultats/    tableaux .tex et .csv, notes_resultats.md
rapport/      export des sources Overleaf, rapport.pdf, protocole_enregistrements.md
video/        slides.pdf, script.md
data/  cache/ audio et index : NON versionnés (dépôt public)
```

**Méthode de travail :**

```bash
git pull                              # toujours avant de commencer
git checkout -b a/detection-pics      # a/... pour A, b/... pour B
git add <fichiers>
git commit -m "Détection de pics : seuil local et quota par bande"
git push -u origin a/detection-pics   # puis Pull Request vers main
```

- On merge sur `main` aux jalons J1 à J4. `main` doit toujours tourner.
- Comme les dossiers sont séparés, les conflits ne peuvent venir que de `README.md`, `PLAN.md` et `parametres.m` : petits commits, et `git pull` avant d'y toucher.
- Le rapport vit sur Overleaf. B exporte les sources dans `rapport/` à J3, J4 et à la fin.
- On coche les cases de ce fichier au fur et à mesure.
