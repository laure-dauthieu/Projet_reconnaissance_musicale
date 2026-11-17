"""Génère rapport/sections/liste_morceaux.tex à partir de liste_morceaux.csv."""
import csv, io, sys, unicodedata

src, dst = sys.argv[1], sys.argv[2]
rows = list(csv.DictReader(io.open(src, encoding='utf-8')))

SPECIAL = {'\\': r'\textbackslash{}', '&': r'\&', '%': r'\%', '$': r'\$', '#': r'\#',
           '_': r'\_', '{': r'\{', '}': r'\}', '~': r'\textasciitilde{}', '^': r'\textasciicircum{}'}
nb_translit = 0

def tex(t):
    global nb_translit
    out = []
    t = t.strip()
    coupe = len(t) > 34
    if coupe:          # couper AVANT d'échapper, pour ne jamais couper une commande LaTeX
        t = t[:31].rstrip()
    for c in t:
        if ord(c) > 255:
            base = ''.join(x for x in unicodedata.normalize('NFKD', c) if not unicodedata.combining(x))
            base = ''.join(x for x in base if ord(x) < 128) or '?'
            nb_translit += 1
            c = base
        out.append(SPECIAL.get(c, c))
    s = ''.join(out)
    return s + r'\ldots' if coupe else s

lignes = [r'% Généré automatiquement depuis liste_morceaux.csv : ne pas modifier à la main.',
          r'\begin{footnotesize}',
          r'\begin{longtable}{@{}rlll@{}}',
          r'\toprule Identifiant & Artiste & Titre & Genre \\ \midrule \endhead',
          r'\bottomrule \endfoot']
for role, titre in (('base', 'Morceaux de la base (100)'), ('hors base', 'Morceaux hors base, requêtes négatives (100)')):
    sel = [r for r in rows if r['role'] == role]
    if not sel:
        continue
    lignes.append(r'\multicolumn{4}{@{}l}{\textbf{%s}} \\ \midrule' % titre)
    for r in sorted(sel, key=lambda r: (r['genre'], int(r['id']))):
        lignes.append('%s & %s & %s & %s \\\\' % (r['id'], tex(r['artiste']), tex(r['titre']), tex(r['genre'])))
    lignes.append(r'\midrule')
lignes += [r'\end{longtable}', r'\end{footnotesize}']
io.open(dst, 'w', encoding='utf-8').write('\n'.join(lignes) + '\n')
print(len(rows), 'morceaux,', nb_translit, 'caracteres translitteres,', sorted(set(r['role'] for r in rows)))
