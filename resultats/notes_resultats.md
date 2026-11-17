# Fiches de résultats (pour le rapport)

Une fiche par figure : protocole, chiffres clés, ce qu'on observe.
Les chiffres viennent de [synthese.csv](synthese.csv) et [passage_echelle.csv](passage_echelle.csv).
Toutes les figures sont dans `figures/`, en PDF (à insérer dans le rapport) et en PNG.

## Protocole commun

- **Base** : 100 morceaux de `fma_small` (extraits de 30 s), 12 ou 13 par genre sur les 8 genres. Liste complète : `liste_morceaux.csv`.
- **Requêtes positives** : 1 extrait par morceau de la base, soit N⁺ = 100. Début tiré au hasard, en échantillons à la fréquence d'origine (donc pas aligné sur la grille des trames).
- **Requêtes négatives** : 1 extrait par morceau hors base (100 morceaux, mêmes genres).
  - 50 servent à **fixer le seuil** (calibration) ;
  - les 50 autres servent à **mesurer le TFD**, d'où N⁻ = 50.
- **Un même extrait** sert à toutes les conditions, pour que seule la dégradation change.
- Les dégradations sont appliquées à la fréquence d'origine, **avant** le prétraitement (mono, 8 kHz), comme dans un vrai téléphone.
- **Paramètres** : ceux de départ du sujet (`parametres.m`) : N = 1024, H = 512, voisinage ±3 trames × ±5 canaux, 6 bandes, F = 10, γf = 1.
- Graines aléatoires fixées : relancer les scripts redonne les mêmes chiffres.

## Seuil de décision (Q5)

- Le plus fort score d'une négative de calibration, toutes conditions confondues, vaut **21**.
- **Méthode** : s_thr = ⌈1,5 × max des scores négatifs de calibration⌉ = **32**.
- Avec ce seuil, **aucune des 50 négatives de test n'est identifiée, dans aucune condition** : TFD = 0 % partout.
- **Mais de justesse** : sur les négatives de test, le score monte jusqu'à **28**, alors qu'il ne dépassait pas 21 sur celles de calibration. Un seuil collé au maximum de calibration (22) aurait donc laissé passer des fausses détections. **C'est ce qui justifie la marge de 1,5**, et c'est pour ça qu'il faut mesurer le TFD sur d'autres négatives que celles qui ont servi à fixer le seuil.
- Avec 50 négatives, « 0 erreur » veut dire que le vrai TFD est probablement inférieur à environ 6 % (3/50). Le dire dans le rapport : on ne peut pas affirmer TFD = 0 sur 50 essais.
- **Pourquoi 10 à 25 et pas 1 ou 2.** Le sujet prévoit 1 ou 2 pour un mauvais morceau si les clés étaient uniformément réparties ; on observe 3 à 28, comme dans les slides (10 à 25). Leur explication : certaines clés sont beaucoup plus fréquentes que d'autres.

## Figure `histo_scores` : scores des requêtes positives et négatives (Q5)

- Tq = 5 s, toutes les dégradations réunies : 1 200 requêtes positives et 1 200 négatives.
- **Négatives** : scores entre 3 et 28, pic vers 8–10.
- **Positives** : scores de 30 à 800, avec une queue vers le bas (quelques-unes sous le seuil).
- **Les deux populations sont séparées d'un ordre de grandeur, mais les queues se touchent** : les positives sous le seuil viennent surtout de la réverbération à 1 s et du bruit à 0 dB.
- Ordre de grandeur théorique pour un bon morceau : s ≈ F·ρ·Tq·p² = 10 × 25 × 5 × p² = 1 250 p². Sans dégradation, on mesure une médiane de 269, ce qui correspondrait à p ≈ 0,46 (à confirmer avec la mesure de p en Q4). Même sans dégradation p < 1, car l'extrait ne tombe pas sur la grille des trames : certains pics changent de trame (propriété (1) du sujet).

## Figure `tbd_rsb` : TBD en fonction du RSB, une courbe par Tq

Bruit blanc additif, s_thr = 32, N⁺ = 100, N⁻ = 50, TFD = 0 % partout.

| RSB | Tq = 3 s | Tq = 5 s | Tq = 10 s |
|---|---|---|---|
| sans bruit | 95 % | 98 % | 100 % |
| 20 dB | 92 % | 97 % | 100 % |
| 15 dB | 94 % | 97 % | 100 % |
| 10 dB | 92 % | 95 % | 100 % |
| 5 dB | 89 % | 95 % | 99 % |
| 0 dB | 74 % | 88 % | 98 % |

- **Toutes les erreurs sont des non-détections** (score sous le seuil), jamais des confusions avec un autre morceau.
- **Plus la requête est longue, plus elle résiste** : le score croît comme Tq (s ≈ F·ρ·Tq·p²), alors que le seuil reste fixe. À 0 dB, passer de 3 à 10 s fait remonter le TBD de 74 % à 98 %.
- Entre 20 et 5 dB, le TBD baisse peu : la plupart des pics survivent. La chute est nette à 0 dB.
- Les petites irrégularités (par exemple 92 % à 20 dB contre 94 % à 15 dB pour Tq = 3 s) correspondent à 1 ou 2 requêtes sur 100 : c'est la variabilité de l'échantillon, pas un effet réel.

## Figure `tbd_mp3` : TBD en fonction du débit MP3

Tq = 5 s, s_thr = 32.

| Débit | TBD |
|---|---|
| sans dégradation | 98 % |
| 128 kbit/s | 98 % |
| 64 kbit/s | 98 % |
| 32 kbit/s | 97 % |

- **Le MP3 ne dégrade presque pas la reconnaissance**, même à 32 kbit/s.
- **Pour Q6** : MP3 64 kbit/s donne 98 %, contre 95 % pour un bruit blanc à 10 dB, à Tq = 5 s. C'est l'effet annoncé par le sujet. Explication à développer : le codeur ne supprime que ce qui est masqué par les composantes fortes, et les pics sont justement les composantes les plus fortes de leur voisinage. Le bruit blanc, lui, remplit tout le plan temps-fréquence.

## Figure `tbd_tfd` : TBD en fonction du TFD en balayant le seuil

- Tq = 5 s, six conditions. Le cercle noir marque le seuil retenu (s_thr = 32).
- Pour toutes les conditions sauf la réverbération à 1 s, la courbe colle au coin en haut à gauche : on peut obtenir un TBD de 96 à 100 % avec un TFD nul.
- **La réverbération à 1 s est la seule condition où l'on doit vraiment choisir** entre bonnes détections et fausses alarmes : pour atteindre 90 % de TBD, il faudrait accepter environ 4 % de TFD.
- L'axe TFD avance par pas de 2 % (1 négative sur 50).

## Autres dégradations (`synthese.csv`)

Tq = 5 s, s_thr = 32, TFD = 0 %.

| Dégradation | TBD |
|---|---|
| Passe-bande 300–3 400 Hz | 98 % |
| Réverbération T60 = 0,3 s | 88 % |
| Réverbération T60 = 1 s | 55 % |

- **Le passe-bande ne gêne pas** : c'est un filtrage court (réponse impulsionnelle brève devant la fenêtre de 128 ms), qui n'ajoute qu'un décalage g(k) en dB (propriété (3)). Les pics loin des bords de la bande ne bougent pas (condition (5)).
- **La réverbération est la dégradation la plus difficile** : à T60 = 1 s, la réponse impulsionnelle dure 8 000 échantillons à 8 kHz, bien plus que la fenêtre N = 1 024. L'approximation (3) ne tient plus : l'énergie d'une trame déborde sur les suivantes, et les pics se déplacent.
- **Pas encore mesuré** : le brouhaha (en attente de l'enregistrement de cafétéria) et l'enregistrement au micro en salle.

## Figure `passage_echelle` : temps de requête et taille de l'index

Requêtes de 5 s non dégradées.

| Morceaux indexés | Entrées | Taille | Construction | Requête (médiane) |
|---|---|---|---|---|
| 10 | 67 867 | 1,8 Mo | 0,1 s | 1,9 ms |
| 25 | 170 816 | 4,3 Mo | 0,2 s | 1,9 ms |
| 50 | 340 872 | 8,0 Mo | 0,4 s | 1,9 ms |
| 100 | 677 171 | 14,6 Mo | 0,7 s | 2,0 ms |
| 200 | 1 361 201 | 26,2 Mo | 1,5 s | 2,1 ms |
| 500 | 3 408 739 | 56,0 Mo | 3,7 s | 2,4 ms |

- **La taille de l'index croît linéairement** avec le nombre de morceaux : environ 6 800 entrées par extrait de 30 s, soit environ 225 entrées par seconde de musique (ρ ≈ 25 pics/s × F = 10 cibles, moins les ancres qui ont moins de 10 cibles).
- **Le temps de requête reste presque constant** (de 1,9 à 2,4 ms quand la base est multipliée par 50). C'est l'intérêt de l'index inversé : une requête ne lit que ses propres clés, son coût ne dépend presque pas du nombre de morceaux. La légère hausse vient du nombre d'entrées par clé, qui augmente avec la base.
- Ces temps ne comptent que l'identification à partir du signal prétraité (spectrogramme, pics, clés, recherche, vote), pas le décodage du fichier.
