# Rapport (partie B)

Sources LaTeX du rapport, à compiler sur **Overleaf** (pdfLaTeX + Biber, réglages par défaut).

## Mettre le rapport sur Overleaf

1. Zipper le contenu de ce dossier `rapport/` et faire *New Project → Upload Project* sur Overleaf.
2. Créer un dossier `figures/` dans le projet Overleaf et y déposer les PDF de A (dossier `figures/` du dépôt).
3. Compiler `main.tex`.

Tant qu'une figure manque, un cadre gris « Figure à venir » s'affiche à sa place : on peut rédiger sans attendre les résultats.

## Organisation

| Fichier | Contenu | Questions |
|---|---|---|
| `main.tex` | Document principal | |
| `preambule.tex`, `macros.tex` | Packages, notations, cadres « à venir » | |
| `sections/00_resume.tex` | Résumé et tableau « où trouver Q1–Q6 » | |
| `sections/01_introduction.tex` | Introduction, Wang et Haitsma–Kalker | |
| `sections/02_modelisation.tex` | Modèle (1), tableau terme → dégradation → invariance | |
| `sections/03_theorie.tex` | Shannon, TFCT, propriétés (1) et (2) démontrées, invariance des maxima, condition (5), limites | Q1, Q2 |
| `sections/04_conception.tex` | Pics, critère ρp², paires, γf, index, score attendu, seuil automatique, tableau des paramètres | Q3, Q4, Q5 |
| `sections/05_resultats.tex` | **Squelette** (B3) | |
| `sections/06_discussion.tex` | MP3 contre bruit blanc, genres difficiles, réverbération | Q6 |
| `sections/07_conclusion.tex` | **Squelette** (B3) | |
| `sections/annexes.tex` | Tableau des notations, liste des morceaux | |
| `biblio.bib` | Références | |

## Ce qui reste à remplir

Les passages qui dépendent des mesures de A sont en **rouge** dans le PDF : `[À remplir : …]` dans le texte, `?` dans les tableaux. Avant le rendu, il ne doit plus en rester (chercher « À remplir » dans le PDF).

## Noms de fichiers attendus dans `figures/`

Ces noms sont utilisés par le rapport. Si A choisit d'autres noms, il suffit de changer le nom dans l'appel `\inclurefig{...}` correspondant.

| Fichier | Figure | Section |
|---|---|---|
| `difference_spectres_passe_bande.pdf` | S_y,dB − S_x,dB pour plusieurs trames (Q2) | Théorie |
| `p_en_fonction_de_rho.pdf` | p sous bruit à 10 dB en fonction de ρ (Q3) | Conception |
| `histogramme_delta.pdf` | Histogramme des δ, bon et mauvais morceau | Conception |
| `histogrammes_scores.pdf` | Scores positifs et négatifs, abscisse log (Q5) | Conception |
| `courbe_tbd_tfd.pdf` | TBD en fonction du TFD | Conception |
| `constellation.pdf` | Spectrogramme et constellation | Résultats |
| `tbd_en_fonction_du_rsb.pdf` | TBD selon le RSB, Tq = 3, 5, 10 s | Résultats |
| `tbd_en_fonction_du_debit_mp3.pdf` | TBD selon le débit MP3 | Résultats |
| `temps_et_taille_index.pdf` | Temps de requête et taille de l'index | Résultats |
| `tbd_par_genre.pdf` | TBD par genre (Q6) | Discussion |
