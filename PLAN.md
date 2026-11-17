# Plan d'action

Projet OBL-4101 : reconnaissance musicale par empreintes audio.
**Rendu : vendredi 20 novembre 2026.** On vise un dépôt vendredi à **12 h**.

- **A = Alessandro** : tout le MATLAB (code, mesures, figures).
- **B = coéquipière** : théorie, enregistrements au micro, rapport, vidéo.

Ce plan ne contient **que ce que le sujet demande**. Les améliorations possibles sont à la fin (section 8) : on n'y touche qu'une fois tout le reste terminé.

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

**Dégradations** (§7) :

| Dégradation | Paramètres |
|---|---|
| Bruit blanc additif | RSB = 20, 15, 10, 5, 0 dB |
| Bruit réel (brouhaha) | RSB = 10, 5, 0 dB |
| Codage MP3 | 128, 64, 32 kbit/s |
| Filtrage passe-bande | 300–3 400 Hz |
| Réverbération | T60 = 0,3 s et 1 s |
| Enregistrement au micro | en salle, 2 distances |

**Figures attendues** (§7) :

1. TBD en fonction du RSB, une courbe par durée Tq ∈ {3, 5, 10} s ;
2. TBD en fonction du débit MP3 ;
3. courbe TBD en fonction du TFD, obtenue en balayant le seuil ;
4. histogrammes des scores sur les requêtes positives et négatives ;
5. temps de requête et taille de l'index en fonction du nombre de morceaux indexés.

S'y ajoutent les figures demandées dans les questions et les étapes :

- la constellation superposée au spectrogramme (étape 3) ;
- l'histogramme des δ (jalon de la chaîne « jouet ») ;
- S_y,dB − S_x,dB pour plusieurs trames (Q2) ;
- p en fonction de ρ (Q3).

**Questions 1 à 6** : à traiter dans le rapport (détail en section 4).

**Livrables** (§8) :

- rapport de 12 à 15 pages hors annexes, sans code dans le corps, au plan imposé ;
- vidéo de 7 min : slides, démo en direct (morceau joué dans la salle, spectrogramme et constellation affichés), résultats, analyse des échecs ;
- zip `Projet_Groupe_Nom1_Nom2_Nom3.zip` sur le Drive : programmes commentés, rapport en PDF, liste des morceaux.

**Règles de rédaction** : tout taux est annoncé avec son seuil, sa durée Tq et sa dégradation ; une courbe sans commentaire ne vaut rien ; un paramètre non justifié est considéré comme non choisi.

---

## 2. Partie A : MATLAB (Alessandro)

### A1. Chaîne de reconnaissance (mardi)

- [ ] `parametres.m` : tous les réglages, avec les valeurs de départ du sujet (tableau du §8).
- [ ] `pretraitement` : mono, puis `resample` à 8 kHz.
- [ ] `calcul_spectrogramme` : Hann, N = 1 024, H = N/2, Nfft = N, sortie en dB.
- [ ] `detection_pics` :
  - maxima locaux sur ±3 trames × ±5 canaux, calculés avec deux `movmax` (pas d'`ordfilt2`, l'Image Processing Toolbox n'est pas installée) ;
  - seuil local : médiane de S_dB dans la bande + marge ;
  - nombre fixe de pics par bande et par seconde, sur 6 bandes géométriques de 200 à 4 000 Hz.
- [ ] `generer_empreintes` : F cibles par ancre dans la zone Δt ∈ [0,1 ; 2] s, |Δk| ≤ 60 ; clé u = (Qf(k1), Qf(k2), Δm) codée en un seul entier.
- [ ] `construire_index` : tableau `[clé, idMorceau, instant]` trié par clé, recherche de **toutes** les entrées d'une clé (`ismember` n'en renvoie qu'une).
- [ ] `identifier` : histogramme des δ = m_r − m_q par morceau, score = maximum, réponse « morceau » si le score dépasse s_thr, « inconnu » sinon.
- [ ] `main.m` : chaîne « jouet » sur 3 morceaux, affichage de la constellation sur le spectrogramme et de l'histogramme des δ.
- [ ] **Jalon (mardi soir)** : l'histogramme des δ présente un pic net pour le bon morceau.
- [ ] Un petit script de test par fonction dans `tests/`.

### A2. Base, requêtes, dégradations (mercredi matin)

- [ ] `preparer_base` : 100 morceaux de `fma_small` répartis sur ses 8 genres, plus au moins 50 morceaux hors base ; écrit `liste_morceaux.csv`.
- [ ] `extraire_requete` : extrait de Tq secondes à un instant tiré au hasard.
- [ ] Dégradations, une fonction chacune :
  - `ajouter_bruit` : bruit blanc ou brouhaha, Px calculé **sur l'extrait** ;
  - `degrader_mp3` : via ffmpeg (`audiowrite` ne sait pas écrire de MP3) ;
  - `filtre_passe_bande` : 300–3 400 Hz ;
  - `reverberation` : réponse impulsionnelle synthétique à décroissance exponentielle, T60 = 0,3 et 1 s.
- [ ] Envoyer à B la liste des morceaux à jouer pour les enregistrements au micro, avec les fichiers sur le Drive.

### A3. Évaluation (mercredi)

- [ ] `evaluer` : TBD et TFD, en séparant « mauvais morceau » et « inconnu ».
- [ ] Fixer le seuil avec les requêtes négatives.
- [ ] Générer les 5 figures attendues (section 1).
- [ ] Mesurer le temps de requête et la taille de l'index pour plusieurs tailles de base (par exemple 25, 50, 100 morceaux).

### A4. Mesures pour les questions (mercredi après-midi et soir)

| Question | Mesure à produire |
|---|---|
| Q2 | Filtrer un morceau par un passe-bande et tracer S_y,dB − S_x,dB en fonction de k pour plusieurs trames |
| Q3 | Faire varier la taille du voisinage, tracer ρ, mesurer p après bruit à 10 dB, tracer p en fonction de ρ |
| Q4 | p pour bruit à 10 dB et MP3 à 64 kbit/s ; pour γf = 1, 2, 4, 8 : M, nqNu/M et taux d'identification mesuré |
| Q5 | Histogrammes des scores positifs et négatifs, abscisse logarithmique |
| Q6 | TBD MP3 64 kbit/s contre bruit blanc 10 dB ; taux de réussite par genre |

Point d'attention pour mesurer p avec le MP3 : le codeur décale le signal d'environ 1 100 échantillons. Il faut recaler l'extrait (intercorrélation) avant de comparer les pics.

- [ ] Écrire pour B une fiche par figure dans `resultats/notes_resultats.md` : protocole, chiffres clés, ce qu'on observe.

### A5. Démo et livraison (jeudi et vendredi)

- [ ] Script de démo : enregistrement au micro de quelques secondes, identification, affichage du spectrogramme et de la constellation.
- [ ] Évaluer les enregistrements en salle de B.
- [ ] **Jeudi 18 h : gel du code.**
- [ ] Vendredi : README final, commentaires, zip.

---

## 3. Partie B : théorie, enregistrements, rapport, vidéo (coéquipière)

### B1. Théorie (mardi soir et mercredi)

- [ ] Lire Wang (2003).
- [ ] **Q1** : justifier Fe = 8 kHz par Shannon et le contenu spectral de la musique. Dire ce qu'on perd et pourquoi c'est acceptable.
- [ ] **Q2** : tableau Tw, Δf et trames/s pour N = 256, 512, 1 024, 2 048 ; justifier N ; démontrer la propriété (2).
- [ ] Démontrer la propriété (1) et l'invariance des maxima au gain ; expliquer la condition (5).
- [ ] **Q3** : pourquoi le critère pertinent est ρp² et pas p seul.
- [ ] **Q4** : refaire le tableau pic/paire avec nos valeurs de p ; expliquer pourquoi le meilleur γf n'est pas celui qui donne le moins de parasites.
- [ ] **Q5** : proposer une méthode automatique pour fixer s_thr.
- [ ] **Q6** : expliquer pourquoi le MP3 à 64 kbit/s gêne moins qu'un bruit blanc à 10 dB (codage perceptuel et définition (4) des pics) ; analyser les genres qui échouent.

Remarque utile pour Q2 : le sujet donne κw = 1,30, qui est la valeur pour une fenêtre de Hamming. Pour la fenêtre de Hann utilisée, κw ≈ 1,44, soit Δf ≈ 11 Hz pour N = 1 024.

### B2. Enregistrements au micro (mercredi après-midi)

- [ ] Jouer les morceaux de la liste de A sur une enceinte et les enregistrer avec un téléphone, en salle, à 2 distances (par exemple 1 m et 4 m).
- [ ] Enregistrer quelques minutes de brouhaha (cafétéria, sans musique) pour la dégradation « bruit réel ».
- [ ] Noter le protocole : salle, matériel, distances.
- [ ] Déposer les fichiers sur le Drive (pas dans git : le dépôt est public).

### B3. Rapport (mercredi à vendredi)

Plan imposé par le sujet :

| Section | Contenu | Questions |
|---|---|---|
| Introduction | Le problème, le principe de Wang | — |
| Modélisation | Le modèle (1) et ce que chaque terme impose à l'empreinte | — |
| Théorie | Spectrogramme, compromis temps-fréquence, invariances démontrées | Q1, Q2 |
| Conception | Pics, hachage, index, décision ; chaque paramètre justifié | Q3, Q4, Q5 |
| Résultats | Protocole, TBD/TFD, courbes, théorie confrontée à la mesure | — |
| Discussion des cas d'échec | MP3 contre bruit, genres difficiles | Q6 |
| Conclusion | Bilan | — |

- [ ] Rédiger sur Overleaf (pas de LaTeX installé localement).
- [ ] Chaque figure est citée et commentée dans le texte.
- [ ] 12 à 15 pages hors annexes ; liste des morceaux en annexe ou en fichier joint.

### B4. Vidéo (jeudi)

- [ ] Slides synthétiques.
- [ ] Démo en direct : morceau joué dans la salle, reconnaissance, affichage du spectrogramme et de la constellation.
- [ ] Résultats et analyse des échecs.
- [ ] Durée : 7 min. Tournage jeudi soir avec A, montage vendredi matin.

---

## 4. Échanges entre A et B

| A fournit à B | Quand |
|---|---|
| Liste des morceaux à enregistrer et fichiers audio | mercredi 11 h |
| Figures (PDF) dans `figures/` et fiches dans `resultats/notes_resultats.md` | au fil de l'eau, tout pour mercredi 21 h |
| Valeurs finales des paramètres | mercredi 21 h |

| B fournit à A | Quand |
|---|---|
| Enregistrements en salle et brouhaha | mercredi 19 h |
| Retour sur les figures (lisibilité, ce qui manque) | mercredi soir |

On utilise les **notations du sujet** partout : code, figures, rapport, slides.

---

## 5. Planning

| Quand | A | B | Point commun |
|---|---|---|---|
| Mar. 17 soir | Chaîne « jouet » (A1) | Lecture de Wang, Q1, Q2, propriétés (B1) | **23 h : pic net dans l'histogramme des δ** |
| Mer. 18 matin | Base, requêtes, dégradations (A2) | Suite de la théorie | 13 h : premiers TBD/TFD |
| Mer. 18 après-midi | Évaluation et mesures des questions (A3, A4) | Enregistrements au micro (B2) | — |
| Mer. 18 soir | Figures finales et fiches | Rédaction théorie et conception | **21 h : toutes les mesures faites** |
| Jeu. 19 | Démo, enregistrements réels, gel du code à 18 h | Résultats, discussion, slides | Soir : tournage de la vidéo |
| Ven. 20 matin | README, commentaires, zip | Relecture, montage vidéo | **12 h : dépôt** |

---

## 6. Avant de déposer

- [ ] `main.m` tourne sans erreur ; chaque fonction a son en-tête et son test.
- [ ] Les 5 figures attendues sont dans le rapport, commentées.
- [ ] Q1 à Q6 ont chacune une réponse explicite.
- [ ] Chaque paramètre est justifié.
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
eval/         preparer_base, extraire_requete, evaluer + degradations/
tests/        un test par fonction
figures/      figures du rapport (PDF)
resultats/    notes_resultats.md
rapport/      export Overleaf, rapport.pdf
video/        slides, script
data/  cache/ audio et index : NON versionnés (dépôt public)
```

- `git pull` avant de commencer ; une branche par tâche (`a/...` ou `b/...`) ; Pull Request vers `main`.
- Chacun reste dans ses dossiers, donc pas de conflit, sauf sur `README.md`, `PLAN.md` et `parametres.m` : petits commits et `git pull` avant d'y toucher.

---

## 8. Plus tard, seulement si tout le reste est fini

À choisir selon le temps restant, une fois le sujet entièrement traité :

- **Interface de paramétrage** : c'est le bonus de 10 % prévu par le barème.
- Courbe de p en fonction du RSB prédite par un modèle, comparée à la mesure.
- Intervalles de confiance sur le TBD et le TFD.
- Base plus grande (1 000 morceaux ou plus) pour la courbe de passage à l'échelle.
- Tolérance δ ± 1 dans le vote, quand l'extrait ne tombe pas sur la grille des trames.
