# Rapport (partie B)

Sources LaTeX du rapport (pdfLaTeX + Biber).

## Compiler sur le PC (MiKTeX installé)

Dans un terminal PowerShell ouvert dans ce dossier `rapport/` :

```powershell
.\compiler.ps1
```

Le PDF est `main.pdf`. Le script affiche ensuite les erreurs, références manquantes et débordements de marge, ou « Aucune erreur ». Les figures sont lues directement dans `../figures/`.

## Ou bien : mettre le rapport sur Overleaf

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

## Figures utilisées (dossier `figures/` du dépôt)

Le rapport cherche `<nom>.pdf`, puis `<nom>.png`. Pour changer de figure, il suffit de changer le nom dans l'appel `\inclurefig{...}` correspondant.

| Fichier | Figure | Section | Disponible |
|---|---|---|---|
| `difference_spectres_passe_bande` | S_y,dB − S_x,dB pour plusieurs trames (Q2) | Théorie | non (B2, Laure) |
| `p_en_fonction_de_rho` | p sous bruit à 10 dB en fonction de ρ (Q3) | Conception | non (A4) |
| `histogramme_delta` | Histogramme des δ, bon et mauvais morceau | Conception | oui |
| `histogrammes_scores` | Scores positifs et négatifs, abscisse log (Q5) | Conception | oui |
| `courbe_tbd_tfd` | TBD en fonction du TFD | Conception | oui |
| `constellation` | Spectrogramme et constellation | Résultats | oui |
| `tbd_en_fonction_du_rsb` | TBD selon le RSB, Tq = 3, 5, 10 s | Résultats | oui |
| `tbd_en_fonction_du_debit_mp3` | TBD selon le débit MP3 | Résultats | oui |
| `temps_et_taille_index` | Temps de requête et taille de l'index | Résultats | oui |
| `tbd_par_genre` | TBD par genre (Q6) | Discussion | non (A4) |

## Liste des morceaux

`sections/liste_morceaux.tex` est généré à partir de `liste_morceaux.csv` : si la liste change, relancer `python generer_liste_morceaux.py ../liste_morceaux.csv sections/liste_morceaux.tex` depuis ce dossier.
