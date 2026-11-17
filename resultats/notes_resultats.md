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

---

# Mesures des questions (A4)

## Figure `p_en_fonction_de_rho` (Q3)

Script `experiences/etude_q3_voisinage.m`. 100 extraits de 8 s (un par morceau de la base), bruit blanc à 10 dB ajouté à 8 kHz, extraits alignés. Chiffres : `q3_voisinage.csv`.

- **Balayage sans quota** (P.rho = Inf) : voisinage de ±1 à ±12 canaux et de ±1 à ±5 trames.
  - **Plus le voisinage est large, moins il y a de pics** : de 308 pics/s (±1 × ±1) à 23 pics/s (±5 trames × ±12 canaux).
  - **p augmente un peu** (de 0,30 à 0,42) : un maximum sur une zone plus large domine plus nettement ses voisins, il résiste mieux au bruit (condition (5)).
  - **Mais ρ chute beaucoup plus vite que p² n'augmente**, donc ρp² décroît : de 27,7 à 4,1 pics/s.
- **Réglage retenu** (±3 trames × ±5 canaux, avec quota de 5 pics par bande et par seconde) : **ρ = 26 pics/s, p = 0,55, ρp² = 7,8**.
- **Le quota est ce qui fait la différence.** À densité comparable sans quota (±5 trames × ±12 canaux, ρ = 23), p n'est que de 0,42 et ρp² de 4,1. Le quota garde les pics les plus forts de chaque bande : ce sont ceux qui dépassent le plus le bruit.
- **Pourquoi ρp² plutôt que p seul (Q3)** : le score du bon morceau vaut s ≈ F·ρ·Tq·p². À F et Tq fixés, le nombre de clés correctes retrouvées est proportionnel à ρp². Maximiser p seul pousserait vers des voisinages immenses et très peu de pics (p augmente, mais il ne reste presque rien à apparier).
- **Pourquoi ne pas maximiser ρp² non plus** : ρp² croît sans limite quand le voisinage rétrécit. Ce qui arrête, c'est le coût : la taille de l'index est proportionnelle à ρ·F, et les appariements fortuits à ρ² (nq·Nu/M). On fixe donc ρ dans la plage du sujet (25 à 35 pics/s) par le quota, et le voisinage ±3 × ±5 sert seulement à définir ce qu'est un maximum local.

## Q4 : p mesuré et tableau « 1 pic / 1 paire »

Script `experiences/etude_q4_p_gamma_F.m`. 100 extraits de 8 s alignés. Chiffres : `q4_p.csv`, `q4_pic_paire.csv`.

| | bruit blanc 10 dB | MP3 64 kbit/s |
|---|---|---|
| p | 0,557 | 0,857 |
| p² | 0,310 | 0,735 |
| survie des clés mesurée | 0,359 | 0,748 |

Tableau du sujet refait avec nos valeurs (Tq = 8 s, ρ = 26,1 pics/s, F = 10) :

| | clé = 1 pic | clé = 1 paire |
|---|---|---|
| Nombre de clés dans la requête | 209 | 1 707 (mesuré, et non F·ρ·Tq = 2 090) |
| Probabilité qu'une clé soit retrouvée, bruit 10 dB | p = 0,56 | p² = 0,31 (mesuré : 0,36) |
| Clés correctes retrouvées, bruit 10 dB | 116 | 529 (mesuré : 612) |
| Probabilité, MP3 64 kbit/s | p = 0,86 | p² = 0,73 (mesuré : 0,75) |
| Clés correctes retrouvées, MP3 64 kbit/s | 179 | 1 254 (mesuré : 1 276) |
| Nombre de clés possibles | 513 | 7,9 × 10⁶ |

- **Les paires gagnent sur les deux tableaux**, comme le prévoit le sujet : 4 à 7 fois plus de clés correctes, et des clés 15 000 fois plus discriminantes. Condition F·p > 1 : F·p = 5,6 (bruit) et 8,6 (MP3).
- **1 707 paires et non 2 090** : les ancres des 2 dernières secondes de la requête n'ont pas toutes leurs 10 cibles dans l'extrait, et certaines ancres n'ont pas 10 pics dans leur zone cible.
- **La survie des clés est un peu meilleure que p²** (0,36 contre 0,31 sous bruit) : les deux pics d'une paire ne disparaissent pas indépendamment. Les pics forts survivent ensemble, les pics faibles disparaissent ensemble. L'hypothèse d'indépendance du sujet est donc légèrement pessimiste.

## Q4 : γf = 1, 2, 4, 8

Même script. Tq = 5 s, 200 requêtes positives, 100 négatives (50 pour fixer le seuil, 50 pour le TFD). **Le seuil est recalibré pour chaque γf**, car γf change aussi les scores des négatives. Les seuils sont plus bas que le seuil global (35), car calibrés sur une seule condition. Chiffres : `q4_gamma.csv`.

| γf | M | parasites attendus nq·Nu/M | s_thr | score médian (0 dB) | TBD 10 dB | TBD 0 dB |
|---|---|---|---|---|---|---|
| 1 | 7,9 × 10⁶ | 87 | 21 à 26 | 49 | 95,5 % | 81,5 % |
| 2 | 2,0 × 10⁶ | 347 | 26 à 33 | 65 | 96,0 % | 81,5 % |
| 4 | 5,0 × 10⁵ | 1 380 | 35 à 41 | 76 | 96,0 % | 80,5 % |
| 8 | 1,3 × 10⁵ | 5 430 | 59 | 88 | 94,0 % | 71,0 % |

(nq ≈ 1 015 clés par requête de 5 s, Nu = 677 171 entrées dans l'index ; TFD = 0 % partout.)

- **Le meilleur γf n'est pas simplement celui qui donne le moins de parasites (réponse à Q4).** Regrouper les canaux a deux effets opposés :
  - le score du bon morceau augmente (49 → 88 à 0 dB), car un pic décalé d'un canal par le bruit donne quand même la même clé ;
  - mais les parasites augmentent beaucoup plus vite (×62 de γf = 1 à 8), donc les scores des négatives aussi, et le seuil doit monter (21 → 59).
- Ce qui compte, c'est **l'écart entre le score du bon morceau et le seuil**, pas le nombre de parasites seul. Ici, γf = 1 et 2 donnent le même TBD ; au-delà, le seuil monte plus vite que les scores et le TBD chute (71 % à γf = 8). On garde γf = 1.
- Avertissement : à 10 dB, les écarts (94 à 96 %) ne représentent que 1 à 4 requêtes sur 200 ; seul 0 dB départage vraiment.

## Choix de F (5, 10, 15)

Mêmes conditions. Chiffres : `q4_F.csv`.

| F | entrées de l'index | TBD 10 dB | TBD 0 dB |
|---|---|---|---|
| 5 | 368 190 | 96,5 % | 78,0 % |
| 10 | 677 171 | 95,5 % | 81,5 % |
| 15 | 905 862 | 96,5 % | 81,5 % |

- Le score augmente avec F, mais le seuil aussi (davantage de paires fortuites). Le TBD plafonne à partir de F = 10, alors que l'index continue de croître (×2,5 entre F = 5 et 15). **F = 10 est le plus petit F qui atteint le plafond.**

## Figure `p_par_bande` (Q6)

Même script, mêmes extraits. p par bande de fréquence :

| Bande (Hz) | bruit blanc 10 dB | MP3 64 kbit/s |
|---|---|---|
| 200–330 | 0,77 | 0,92 |
| 330–543 | 0,69 | 0,91 |
| 543–894 | 0,63 | 0,91 |
| 894–1 474 | 0,55 | 0,88 |
| 1 474–2 428 | 0,48 | 0,82 |
| 2 428–4 000 | 0,37 | 0,75 |

- **C'est l'argument chiffré pour Q6.** Le bruit blanc a la même densité à toutes les fréquences, alors que l'énergie musicale décroît avec la fréquence. Le RSB local est donc bon dans les graves et mauvais dans les aigus : p tombe de 0,77 à 0,37.
- Le MP3 ne retire que ce qui est masqué par les composantes fortes ; or un pic est, par définition (4), le maximum de son voisinage : c'est un masqueur, que le codeur conserve. p reste au-dessus de 0,75 dans toutes les bandes. Il baisse un peu dans les aigus, où le codeur à 64 kbit/s a le moins de bits et coupe le plus.

## Figure `theorie_mesure` : théorie confrontée à la mesure

Script `experiences/theorie_mesure.m`. Bruit blanc ajouté à 8 kHz, de 20 à −10 dB, Tq = 3, 5 et 10 s, 200 requêtes positives par point. Chiffres : `theorie_mesure.csv`, `theorie_mesure_rupture.csv`.

- **Deux p mesurés** (panneau a) :
  - p_bruit : même extrait propre et bruité, aligné. 1 sans bruit, 0,56 à 10 dB, 0,28 à 0 dB.
  - **p_eff** : les pics du morceau de référence pendant la durée de l'extrait, retrouvés dans la requête, prise à un instant quelconque. **0,53 seulement sans bruit**, car le début de l'extrait ne tombe pas sur la grille des trames et des pics changent de trame : c'est la limite de la propriété (1) annoncée par le sujet. C'est p_eff qui gouverne le score.
- **Score prévu** (panneau b) : s_prévu = nq·p_eff², avec nq le nombre de clés de la requête. Il suit le score mesuré du bon morceau sur toute la plage (par exemple, Tq = 5 s : prévu 144 contre 131 mesuré à 10 dB, 42 contre 44 à 0 dB, 16 contre 18 à −5 dB).
- **RSB de rupture** (panneau c) : la théorie prévoit l'échec quand le score prévu passe sous s_thr = 35. On le compare au RSB où le TBD mesuré passe à 50 %.

| Tq | rupture prévue | TBD = 50 % mesuré |
|---|---|---|
| 3 s | +3,1 dB | +2,4 dB |
| 5 s | −1,0 dB | −1,8 dB |
| 10 s | −4,5 dB | −6,0 dB |

- **La théorie prévoit la rupture à 0,7 à 1,5 dB près**, un peu trop tôt à chaque fois : aux bas RSB, le score prévu est légèrement inférieur au score mesuré (16 contre 18 à −5 dB pour Tq = 5 s). C'est cohérent avec la survie des clés mesurée en Q4, un peu meilleure que p² : les deux pics d'une paire ne disparaissent pas indépendamment, et l'hypothèse d'indépendance sous-estime le score.
- Le lien entre les deux colonnes : le TBD vaut 50 % quand la moitié des requêtes ont un score au-dessus du seuil, c'est-à-dire quand le score médian vaut s_thr.
- Chaque allongement de la requête (3 → 5 → 10 s) recule la rupture d'environ 4 dB, comme le prévoit s ∝ Tq·p².
- **Pourquoi la formule du sujet F·ρ·Tq·p² surestime le score** : avec F·ρ·Tq = 10 × 26 × 5 = 1 300 et p = p_bruit, elle prévoirait environ 1 300 sans bruit, contre 250 mesuré. Deux corrections : nq = 1 015 et non 1 300 (ancres de fin d'extrait), et surtout p_eff = 0,53 et non 1 (grille des trames). Une fois ces deux effets mesurés, la théorie colle à la mesure.

## Figure `tbd_par_genre` (Q6)

Script `experiences/etude_q6_genres.m`, à partir des requêtes de la campagne. 24 à 26 requêtes positives par genre : **une requête vaut 4 points de TBD**, les écarts de moins de 10 points ne sont pas significatifs. Chiffres : `q6_genres.csv`.

| Genre | sans dégr., Tq = 3 s | bruit 5 dB | bruit 0 dB | réverb. 1 s | énergie > 900 Hz |
|---|---|---|---|---|---|
| Pop | 87,5 % | 91,7 % | 87,5 % | 66,7 % | 31 % |
| International | 100 % | 83,3 % | 83,3 % | 41,7 % | 26 % |
| Rock | 95,8 % | 91,7 % | 75,0 % | 54,2 % | 42 % |
| Folk | 96,2 % | 92,3 % | 69,2 % | 61,5 % | 21 % |
| Instrumental | 100 % | 79,2 % | 62,5 % | 54,2 % | 14 % |
| Electronic | 92,3 % | 80,8 % | 53,8 % | 42,3 % | 20 % |
| Experimental | 96,2 % | 73,1 % | 53,8 % | 38,5 % | 22 % |
| Hip-Hop | 88,5 % | 80,8 % | 50,0 % | 50,0 % | 26 % |

(bruit et réverbération à Tq = 5 s, s_thr = 35.)

- **Sans dégradation, tous les genres sont reconnus** (88 à 100 % même à 3 s).
- **Sous bruit fort (0 dB), les écarts sont nets** : Pop et International restent au-dessus de 80 %, Electronic, Experimental et Hip-Hop tombent vers 50 %.
- **Hypothèse, partiellement vérifiée** : le bruit blanc a la même densité à toutes les fréquences, donc un genre qui met peu d'énergie au-dessus de 900 Hz perd ses pics aigus (voir `p_par_bande`). La corrélation entre la part d'énergie au-dessus de 900 Hz et le TBD à 0 dB n'est que de 0,46 sur 8 genres. Instrumental (14 %) est bien parmi les plus fragiles, Pop (31 %) parmi les plus robustes ; mais Rock (42 %) n'est que 3ᵉ et Hip-Hop (26 %) est dernier. C'est une tendance, pas une preuve.
- **Autres pistes pour la discussion** (non mesurées) : en Hip-Hop et en Electronic, une grande partie de l'énergie est dans les basses sous 200 Hz, hors de nos bandes, et l'énergie aiguë vient surtout de percussions brèves (charleston) plutôt que de notes tenues ; en Experimental, beaucoup de textures bruitées sans maxima nets.
- **Ni la densité de pics brute (62 à 74 pics/s), ni le score sans dégradation ne prédisent la robustesse** : Pop a le plus faible score sans bruit (164) et résiste le mieux.
- **Réverbération à 1 s** : International, Experimental et Electronic sont les plus touchés (38 à 42 %). La réverbération étale l'énergie dans le temps et brouille surtout les attaques et les notes courtes.
