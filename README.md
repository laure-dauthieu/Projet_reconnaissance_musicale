# Reconnaissance musicale par empreintes audio

Projet OBL-4101 Traitement du signal (ESIEE, 2026–2027).
**Rendu : vendredi 20 novembre 2026.** Tout retard coûte 5 points.

Le but est d'identifier un morceau à partir d'un extrait court et bruité, pris à un instant inconnu, en MATLAB. On suit la méthode de Wang (2003) :

```text
Morceaux de référence → spectrogramme → pics → paires → clés → index inversé
Extrait inconnu       → spectrogramme → pics → paires → clés → alignement + décision
```

Les deux phases utilisent **exactement** les mêmes fonctions d'extraction.

---

## Organisation du travail

**Le plan complet est dans [PLAN.md](PLAN.md)** : répartition, tâches cochables, jalons, liste des figures, plan du rapport, script de la vidéo, listes de contrôle.

| | **A — Alessandro** | **B — coéquipière** |
|---|---|---|
| Rôle | Tout le MATLAB | Théorie, enregistrements réels, rapport, vidéo |
| Dossiers | `src/`, `eval/`, `experiences/`, `app/`, `utils/`, `tests/`, `figures/`, `resultats/` | `rapport/`, `video/` |
| Fournit à l'autre | Figures PDF, tableaux `.tex`, fiches de résultats | Formules théoriques, enregistrements en salle, brouhaha |

Jalons : J1 mar. 23 h (chaîne jouet), J2 mer. 13 h, J3 mer. 21 h, **J4 jeu. 18 h (gel du code)**, **J5 ven. 12 h (dépôt)**.

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
[base, horsBase] = preparer_base(dossierFMA, nBase, nHors, P)
q   = extraire_requete(signalOrigine, Fe0, Tq)   % .y, .id_vrai (0 si négative), .t0
yb  = ajouter_bruit(y, RSB_dB, bruit)            % bruit = 'blanc' ou vecteur de brouhaha
ym  = degrader_mp3(y, Fe0, debit_kbps, P)
yf  = filtre_passe_bande(y, Fe0, 300, 3400)
yr  = reverberation(y, Fe0, T60)
res = evaluer(INDEX, requetes, P)                % TBD, TFD, confusions, scores, temps, IC 95 %
s   = calibrer_seuil(scoresNegCalibration, TFD_vise)
```

Conventions :

- les signaux sont des vecteurs **colonne** en double ;
- les dégradations s'appliquent à la fréquence d'origine, **avant** `pretraitement` ;
- les indices m (trame) et k (canal) commencent à 1 ;
- aucun nombre magique dans les fonctions : tout passe par `P` ;
- les notations sont celles de l'énoncé (`P.Fe`, `P.N`, `P.H`, `P.F`, `P.gamma_f`, `P.s_thr`…) ;
- chaque fonction a un en-tête (rôle, entrées, sorties, justification des paramètres) et un test dans `tests/`.

---

## Lancement

À compléter au fil du projet :

```matlab
main      % indexe la base, identifie un extrait, affiche spectrogramme, constellation et δ
run_all   % régénère toutes les figures et tous les tableaux du rapport
runtests('tests')
```

---

## Installation et pièges connus

- **MATLAB R2026a** avec la **Signal Processing Toolbox**. Pas besoin d'autre toolbox.
- **Pas d'Image Processing Toolbox**, donc pas de `ordfilt2`. Le maximum glissant se calcule avec deux `movmax` :

  ```matlab
  Smax = movmax(movmax(SdB, 2*dk+1, 1), 2*dm+1, 2);
  ```

- **Pas de Statistics Toolbox** : intervalles de Wilson et loi de Gumbel sont codés à la main.
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
