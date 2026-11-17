# Protocole des enregistrements au micro (B3)

Deux séances, mercredi 18 novembre :

| Séance | Quand | Résultat | Dépôt sur le Drive |
|---|---|---|---|
| Brouhaha | midi, cafétéria | 1 fichier `brouhaha_cafet.wav` | avant 14 h |
| Salle | après-midi | 60 fichiers `micro_<id>_<distance>.wav` | avant 19 h |

**Rien de tout ça ne va dans git** : le dépôt est public, et `.wav`, `.m4a` et `.mp3` sont exclus par le `.gitignore`. Les fichiers vont sur le Drive. Alessandro les copie ensuite dans `data/enregistrements/`, où la campagne d'évaluation les cherche.

---

## 0. À préparer avant (mardi soir ou mercredi matin)

- [ ] **Les 30 morceaux** : demander à Alessandro les fichiers audio de la liste (section 4). Son script `experiences/preparer_donnees.m` les copie dans `data/a_enregistrer/`. Les mettre sur le téléphone ou l'ordinateur qui servira de lecteur.
- [ ] **Une enceinte** (Bluetooth ou filaire) et un appareil pour la piloter.
- [ ] **Un téléphone pour enregistrer**, réglé ainsi :
  - format **sans compression** : WAV ou « sans perte », à 44,1 ou 48 kHz. Éviter le M4A/AAC compressé, sinon on ajoute un codage avec perte qu'on ne maîtrise pas ;
  - **désactiver toute amélioration automatique** : réduction de bruit, « améliorer l'enregistrement », mode « voix » ou « réunion ». Ces traitements modifient le spectre de façon non linéaire et fausseraient l'expérience ;
  - faire un essai de 5 s et vérifier sur l'ordinateur que le fichier s'ouvre et que son format est le bon.
- [ ] **Une application de sonomètre** sur un second téléphone (n'importe laquelle, pour un ordre de grandeur en dB).
- [ ] **Un mètre**, ou compter les pas (1 pas ≈ 0,7 m).
- [ ] Imprimer ou ouvrir ce fichier pour cocher au fur et à mesure.

---

## 1. Brouhaha à la cafétéria (mercredi midi)

But : un bruit **réel**, coloré et non stationnaire, pour la dégradation « bruit réel » à RSB = 10, 5 et 0 dB. Le code en tire des segments au hasard, donc il faut une prise longue.

1. Se placer à l'heure de plus forte affluence, au milieu de la salle, **sans musique** diffusée : sinon le brouhaha contiendrait des pics musicaux qui fausseraient les tests.
2. Poser le téléphone sur la table, micro vers le haut, sans le tenir en main : les frottements font des bruits parasites.
3. Enregistrer **au moins 3 minutes**, 5 si possible, sans parler soi-même.
4. Noter le niveau affiché par le sonomètre (quelques relevés, en dB).
5. Nommer le fichier **exactement** `brouhaha_cafet.wav`. Si le téléphone ne sait produire que du M4A, le garder tel quel et prévenir Alessandro, qui le convertira.

> **Respect des personnes** : on n'enregistre que le fond sonore global. Ne pas se placer à côté d'une conversation en particulier, ne pas filmer, et ne jamais publier ce fichier. Il ne sert que de bruit, et il reste sur le Drive du groupe.

---

## 2. Enregistrements en salle (mercredi après-midi)

### 2.1 Mise en place

- Une salle de cours ordinaire, porte fermée. Noter ses dimensions approximatives : elles fixent la réverbération.
- Enceinte posée sur une table, à hauteur d'oreille si possible.
- Téléphone posé (pas tenu), micro orienté vers l'enceinte, à **1 m** puis à **4 m**, mesurés de l'avant de l'enceinte au téléphone.
- **Volume fixé une fois pour toutes** : un niveau de musique d'ambiance confortable, autour de 70 dB au sonomètre à 1 m. On ne le touche plus de toute la séance, pour que les deux distances soient comparables.
- Prendre **une photo du montage** à chaque distance, pour le rapport.

### 2.2 Pour chaque morceau

1. Lancer l'enregistrement sur le téléphone.
2. Lancer le morceau **à un instant quelconque** entre 0 et 15 s : les morceaux font 30 s, et le système ne doit pas savoir où commence l'extrait.
3. Laisser enregistrer **12 à 15 secondes** de musique. Cela permet d'en tirer des requêtes de 3, 5 et 10 s.
4. Arrêter l'enregistrement, puis le renommer **tout de suite** :
   - `micro_<id>_1m.wav` à 1 m ;
   - `micro_<id>_4m.wav` à 4 m,

   où `<id>` est l'identifiant de la section 4, par exemple `micro_48861_1m.wav`. C'est par ce nom que le code retrouvera le bon morceau.
5. Cocher la case dans la section 4.

Pour aller vite, faire **les 30 morceaux à 1 m, puis les 30 à 4 m**, sans déplacer l'enceinte. Compter environ 45 minutes par distance.

### 2.3 Pendant la séance

- Si quelqu'un entre ou parle fort pendant une prise, la refaire.
- Relever le **bruit ambiant** au sonomètre, musique coupée, au début et à la fin.
- Écouter une prise sur deux pour vérifier qu'elle n'est ni vide ni saturée.

---

## 3. Fiche protocole (à remplir sur place, elle ira dans le rapport)

| Élément | Valeur |
|---|---|
| Date et heure | |
| Salle (nom, dimensions approximatives L × l × h) | |
| Revêtements (moquette, carrelage, rideaux…) | |
| Enceinte (modèle) | |
| Téléphone enregistreur (modèle, application) | |
| Format des fichiers (WAV ou autre, fréquence d'échantillonnage) | |
| Traitements automatiques désactivés ? | oui / non |
| Niveau de la musique au sonomètre, à 1 m (dB) | |
| Niveau de la musique au sonomètre, à 4 m (dB) | |
| Bruit ambiant, musique coupée (dB) | |
| Brouhaha : lieu, heure, durée, niveau (dB) | |
| Remarques (prises refaites, incidents) | |

---

## 4. Liste des 30 morceaux et suivi

Source : `resultats/morceaux_a_enregistrer.csv` (Alessandro). Les 10 morceaux **hors base** ne sont pas dans l'index : le système doit répondre « inconnu ». Ils servent à mesurer le TFD en conditions réelles.

| # | id | Artiste — Titre | Genre | Rôle | 1 m | 4 m | Remarque |
|---|---|---|---|---|---|---|---|
| 1 | 48861 | NaDa BaBa — Skull Flower | Experimental | base | [ ] | [ ] | |
| 2 | 11861 | 6th Sense & Mick Boogie — Nike Boots Freestyle | Hip-Hop | base | [ ] | [ ] | |
| 3 | 122397 | Gorilla Chief — Cocaine Girl | Rock | base | [ ] | [ ] | |
| 4 | 55808 | Blasterhead — Killbots | Electronic | base | [ ] | [ ] | |
| 5 | 11775 | 6th Sense — We Don't Stop Instrumental | Hip-Hop | base | [ ] | [ ] | |
| 6 | 68821 | Zulus — Death in the Current | Rock | base | [ ] | [ ] | |
| 7 | 39278 | U Can Unlearn Guitar — Chicago, Etc. | Experimental | base | [ ] | [ ] | |
| 8 | 148288 | LoveyDove — Deep Down Inc. | Pop | base | [ ] | [ ] | |
| 9 | 97037 | CuzOH! Black Feat. Wordsmith — Stronger Living | Hip-Hop | base | [ ] | [ ] | |
| 10 | 73761 | Dad Rocks! — Weapons | International | base | [ ] | [ ] | |
| 11 | 116873 | Itasca — After Dawn | Folk | base | [ ] | [ ] | |
| 12 | 139110 | Anthony Pasquarosa — What Makes A Man? | Folk | base | [ ] | [ ] | |
| 13 | 10443 | Big Blood — Beast (1 Beast) | Folk | base | [ ] | [ ] | |
| 14 | 70425 | Supercute — Assked | Pop | base | [ ] | [ ] | |
| 15 | 67638 | Southman — Wake Up | Electronic | base | [ ] | [ ] | |
| 16 | 91443 | Cal Folger Day — Easy Sometimes | Folk | base | [ ] | [ ] | |
| 17 | 26014 | Comfort Fit — Whenever You Wanna Call Me | Hip-Hop | base | [ ] | [ ] | |
| 18 | 10993 | Big Blood — Oh Country (Skin & Bones) | Folk | base | [ ] | [ ] | |
| 19 | 120315 | Cory Gray — Life Size Head | Instrumental | base | [ ] | [ ] | |
| 20 | 41018 | Unity Vibration — Au royaume de la money | International | base | [ ] | [ ] | |
| 21 | 66390 | krackatoa — Komodo Dodo | Electronic | **hors base** | [ ] | [ ] | |
| 22 | 146458 | Langax — The Cavern | Electronic | **hors base** | [ ] | [ ] | |
| 23 | 56015 | Tone Poets — Surface | Experimental | **hors base** | [ ] | [ ] | |
| 24 | 114534 | Blue Dot Sessions — Diner Gothic - Dasher | Instrumental | **hors base** | [ ] | [ ] | |
| 25 | 93986 | Bugs and Rats — Irish Clouds | Rock | **hors base** | [ ] | [ ] | |
| 26 | 136707 | Tojamura 7 — 100ft Wave | Rock | **hors base** | [ ] | [ ] | |
| 27 | 145043 | Hermit — Rock'n'Roll Hara-Kiri | Experimental | **hors base** | [ ] | [ ] | |
| 28 | 23016 | The Lights Galaxia — While She Sleeps (Morning Edit) | Electronic | **hors base** | [ ] | [ ] | |
| 29 | 75372 | Kellee Maize — 2012 | Hip-Hop | **hors base** | [ ] | [ ] | |
| 30 | 148537 | E A Terra Nunca Me Pareceu Tão Distante — Medo de Morrer | Rock | **hors base** | [ ] | [ ] | |

---

## 5. Après les séances

- [ ] Vérifier qu'il y a bien **61 fichiers** : 60 prises et le brouhaha, tous nommés comme ci-dessus.
- [ ] Les déposer sur le Drive, dans un dossier `enregistrements/`.
- [ ] Prévenir Alessandro. Il les copie dans `data/enregistrements/` et relance la campagne d'évaluation : les conditions « brouhaha » s'ajoutent automatiquement, et il évalue les prises « micro ».
- [ ] Reporter la fiche de la section 3 et les photos dans la section « Conditions réelles » du rapport (`rapport/sections/05_resultats.tex`).
