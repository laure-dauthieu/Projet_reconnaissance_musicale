# Fiches de résultats (pour le rapport)

Une fiche par figure : protocole, chiffres clés, ce qu'on observe.
Les chiffres viennent de [synthese.csv](synthese.csv) et [passage_echelle.csv](passage_echelle.csv).
Toutes les figures sont dans `figures/`, en PDF (à insérer dans le rapport) et en PNG, avec les noms attendus par `rapport/README.md`.

## Protocole commun

- **Base** : 100 morceaux de `fma_small` (extraits de 30 s), 12 ou 13 par genre sur les 8 genres. Liste complète : `liste_morceaux.csv`.
- **Requêtes positives** : 2 extraits par morceau de la base, soit **N⁺ = 200** (25 par genre en moyenne). Début tiré au hasard, en échantillons à la fréquence d'origine, donc pas aligné sur la grille des trames.
- **Requêtes négatives** : 1 extrait par morceau hors base (100 morceaux, mêmes genres).
  - 50 servent à **fixer le seuil** (calibration) ;
  - les 50 autres servent à **mesurer le TFD**, d'où **N⁻ = 50** dans les taux.
- **Un même extrait** sert à toutes les conditions, pour que seule la dégradation change.
- **Où s'applique chaque dégradation** :
  - le MP3 est appliqué **avant** le passage à 8 kHz, sur le signal d'origine à 44,1 kHz, comme pour un vrai fichier ;
  - le bruit, le passe-bande et la réverbération sont appliqués **après** le passage à 8 kHz. Un bruit blanc ajouté à 44,1 kHz s'étalerait jusqu'à 22 kHz et le passage à 8 kHz en retirerait environ 80 % : le RSB réel serait meilleur de 10·log10(22,05/4) ≈ 7,4 dB que le RSB annoncé.
- **Paramètres** : ceux de départ du sujet (`parametres.m`) : N = 1024, H = 512, voisinage ±3 trames × ±5 canaux, 6 bandes, F = 10, γf = 1.
- Graines aléatoires fixées : relancer les scripts redonne les mêmes chiffres.
- **Pas encore mesuré** : le brouhaha et l'enregistrement au micro en salle (en attente des enregistrements).

## Seuil de décision (Q5)

- Le plus fort score d'une négative de calibration, toutes conditions confondues, vaut **23**.
- **Méthode** : s_thr = ⌈1,5 × max des scores négatifs de calibration⌉ = **35**.
- Avec ce seuil, **aucune des 50 négatives de test n'est identifiée, dans aucune condition** : TFD = 0 % partout.
- **La marge est nécessaire** : sur les négatives de test, le score monte jusqu'à **26**, au-dessus du maximum de calibration (23). Un seuil collé à ce maximum aurait laissé passer des fausses détections. C'est pour ça qu'il faut mesurer le TFD sur d'autres négatives que celles qui ont servi à fixer le seuil.
- Avec 50 négatives, « 0 erreur » veut dire que le vrai TFD est probablement inférieur à environ 6 % (3/50). Le dire dans le rapport : on ne peut pas affirmer TFD = 0 sur 50 essais.
- **Pourquoi 10 à 25 et pas 1 ou 2.** Le sujet prévoit 1 ou 2 pour un mauvais morceau si les clés étaient uniformément réparties ; on observe de quelques unités à 26, comme dans les slides (10 à 25). Leur explication : certaines clés sont beaucoup plus fréquentes que d'autres.

## Figure `histogrammes_scores` (Q5)

- Tq = 5 s, toutes les dégradations réunies : 2 400 requêtes positives et 1 200 négatives.
- **Négatives** : scores de quelques unités à 26, pic vers 7–10.
- **Positives** : scores de 30 à 900 pour la plupart, avec une queue vers le bas : bruit à 0 dB et réverbération à 1 s surtout.
- **Les deux populations sont séparées d'un ordre de grandeur, mais les queues se recouvrent** entre 10 et 25 environ : quelques positives très dégradées ont un score de mauvais morceau. Elles deviennent des non-détections, pas des confusions.
- Ordre de grandeur théorique pour un bon morceau : s ≈ F·ρ·Tq·p² = 10 × 25 × 5 × p² = 1 250 p². Sans dégradation, la médiane mesurée vaut 232, ce qui correspondrait à p ≈ 0,43 (à confirmer avec la mesure de p en Q4). Même sans dégradation p < 1, car l'extrait ne tombe pas sur la grille des trames : certains pics changent de trame (propriété (1) du sujet).

## Figure `tbd_en_fonction_du_rsb`

Bruit blanc additif ajouté après passage à 8 kHz, s_thr = 35, N⁺ = 200, N⁻ = 50, TFD = 0 % partout.

| RSB | Tq = 3 s | Tq = 5 s | Tq = 10 s |
|---|---|---|---|
| sans bruit | 94,5 % | 98,5 % | 99,5 % |
| 20 dB | 90,5 % | 97,5 % | 99,0 % |
| 15 dB | 87,0 % | 95,0 % | 99,0 % |
| 10 dB | 81,0 % | 92,0 % | 98,5 % |
| 5 dB | 62,0 % | 84,0 % | 94,0 % |
| 0 dB | 38,5 % | 66,5 % | 85,5 % |

- **Toutes les erreurs sont des non-détections** (score sous le seuil), jamais des confusions avec un autre morceau.
- **Plus la requête est longue, plus elle résiste.** Le score croît comme Tq (s ≈ F·ρ·Tq·p²), alors que le seuil reste fixe. À 0 dB, passer de 3 à 10 s fait remonter le TBD de 38,5 % à 85,5 %.
- **La chute s'accélère sous 10 dB.** Le score suit p², et p diminue avec le RSB : quand p baisse, le score baisse deux fois plus vite en relatif et finit par passer sous le seuil. Avec Tq = 3 s, le score de départ est plus faible, donc il atteint le seuil plus tôt.
- Score médian à Tq = 5 s : 232 sans bruit, 139 à 10 dB.

## Figure `tbd_en_fonction_du_debit_mp3`

Tq = 5 s, s_thr = 35, N⁺ = 200.

| Débit | TBD |
|---|---|
| sans dégradation | 98,5 % |
| 128 kbit/s | 98,5 % |
| 64 kbit/s | 98,5 % |
| 32 kbit/s | 98,0 % |

- **Le MP3 ne dégrade presque pas la reconnaissance**, même à 32 kbit/s.
- **Pour Q6** : à Tq = 5 s, le MP3 à 64 kbit/s donne **98,5 %** et un score médian de 225 ; le bruit blanc à 10 dB donne **92 %** et un score médian de 139. C'est l'effet annoncé par le sujet. Le codeur ne supprime que ce qui est masqué par les composantes fortes, et les pics sont justement les composantes les plus fortes de leur voisinage. Le bruit blanc, lui, remplit tout le plan temps-fréquence, et surtout les hautes fréquences, où la musique est faible.

## Figure `courbe_tbd_tfd`

- Tq = 5 s, six conditions. Le cercle sur chaque courbe marque le seuil retenu (s_thr = 35).
- **Deux panneaux** : (a) vue d'ensemble ; (b) zoom sur le coin en haut à gauche, où les courbes des conditions faciles se superposent.
- La courbe balaie tous les seuils, elle ne dépend pas du seuil retenu : on y utilise donc **les 100 négatives** (calibration et test), d'où un TFD qui avance par pas de 1 %. Le dire dans la légende du rapport.
- **MP3 32 kbit/s, passe-bande et sans dégradation** atteignent 98,5 à 99,5 % de TBD dès TFD = 0 : leurs courbes se confondent avec le bord supérieur, ce n'est pas un défaut de tracé.
- **Le bruit à 0 dB et la réverbération à 1 s sont les deux conditions où l'on doit vraiment choisir** entre bonnes détections et fausses alarmes :

  | Condition | TBD à TFD = 0 | à TFD ≤ 1 % | à TFD ≤ 5 % | à TFD ≤ 10 % |
  |---|---|---|---|---|
  | bruit blanc 0 dB | 83,0 % | 84,0 % | 86,5 % | 89,0 % |
  | réverbération 1 s | 82,0 % | 88,5 % | 90,5 % | 92,5 % |

- Ces TBD à TFD = 0 sont meilleurs que ceux du seuil retenu (66,5 % et 51 %), parce qu'ils correspondent à un seuil plus bas (18 à 20) choisi **pour cette seule condition**. Le seuil retenu doit tenir pour toutes les conditions à la fois : c'est le prix d'un seuil unique.

## Autres dégradations (`synthese.csv`)

Tq = 5 s, s_thr = 35, TFD = 0 %.

| Dégradation | TBD |
|---|---|
| Passe-bande 300–3 400 Hz | 98,5 % |
| Réverbération T60 = 0,3 s | 89,0 % |
| Réverbération T60 = 1 s | 51,0 % |

- **Le passe-bande ne gêne pas**. C'est un filtrage court : sa réponse impulsionnelle est brève devant la fenêtre de 128 ms, donc il n'ajoute qu'un décalage g(k) en dB (propriété (3)). Les pics loin des bords de la bande ne bougent pas (condition (5)).
- **La réverbération est la dégradation la plus difficile**. À T60 = 1 s, la réponse impulsionnelle dure 8 000 échantillons à 8 kHz, bien plus que la fenêtre N = 1 024. L'approximation (3) ne tient plus : l'énergie d'une trame déborde sur les suivantes, et les pics se déplacent.

## Figure `temps_et_taille_index`

Requêtes de 5 s non dégradées.

| Morceaux indexés | Entrées | Taille | Construction | Requête (médiane) |
|---|---|---|---|---|
| 10 | 67 867 | 1,8 Mo | 0,1 s | 2,0 ms |
| 25 | 170 816 | 4,3 Mo | 0,2 s | 1,9 ms |
| 50 | 340 872 | 8,0 Mo | 0,4 s | 1,9 ms |
| 100 | 677 171 | 14,6 Mo | 0,8 s | 2,0 ms |
| 200 | 1 361 201 | 26,2 Mo | 1,5 s | 2,1 ms |
| 500 | 3 408 739 | 56,0 Mo | 3,8 s | 2,4 ms |

- **La taille de l'index croît linéairement** avec le nombre de morceaux : environ 6 800 entrées par extrait de 30 s, soit environ 225 entrées par seconde de musique (ρ ≈ 25 pics/s × F = 10 cibles, moins les ancres qui ont moins de 10 cibles).
- **Le temps de requête reste presque constant** : de 1,9 à 2,4 ms quand la base est multipliée par 50. C'est l'intérêt de l'index inversé : une requête ne lit que ses propres clés, son coût ne dépend presque pas du nombre de morceaux. La légère hausse vient du nombre d'entrées par clé, qui augmente avec la base.
- Ces temps ne comptent que l'identification à partir du signal prétraité (spectrogramme, pics, clés, recherche, vote), pas le décodage du fichier.

## Figures `constellation` et `histogramme_delta`

Produites par `main.m` : 3 morceaux de `fma_small` indexés, une requête de 8 s.

- **Constellation** : 205 pics en 8 s (25,6 pics/s pour une cible de 30). Les pics tombent sur les zones d'énergie, en particulier les attaques de batterie (bandes verticales).
- **Histogramme des δ** : pour le bon morceau, un pic net à 699 votes en δ = 104 trames, soit 6,66 s (vraie position : 6,65 s). Pour un autre morceau, des votes dispersés qui ne dépassent pas 2.
- Le bon morceau montre aussi **des pics secondaires** (environ 115 et 55 votes) à d'autres décalages. C'est probablement une boucle musicale répétée ailleurs dans le morceau : la même séquence produit les mêmes clés. Ça ne gêne pas la décision, puisqu'on prend le maximum.
