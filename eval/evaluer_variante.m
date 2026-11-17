function V = evaluer_variante(P, signauxBase, signauxHors, degrader, Tq, graine)
%EVALUER_VARIANTE  TBD et TFD pour un jeu de paramètres (études Q4 et F).
%   V = evaluer_variante(P, signauxBase, signauxHors, degrader, Tq, graine)
%
%   signauxBase, signauxHors : signaux prétraités à P.Fe (cache).
%   degrader : fonction y -> y dégradé, appliquée au signal à 8 kHz.
%
%   Reconstruit l'index avec P, puis :
%     - 2 requêtes positives par morceau de la base ;
%     - 1 requête négative par morceau hors base, une sur deux pour fixer le
%       seuil (calibrer_seuil), l'autre pour mesurer le TFD.
%   Le seuil est recalibré pour chaque variante : un γf ou un F différent
%   change aussi les scores des requêtes négatives.
%
%   V : struct avec s_thr, TBD, TFD, nEntrees (taille de l'index),
%       nClesRequete (nombre médian de clés par requête), scoreMedian
%       (score médian des positives).

rs = RandStream('mt19937ar', 'Seed', graine);
INDEX = construire_index(signauxBase, P);
nB = numel(signauxBase);  nH = numel(signauxHors);
nq = round(Tq * P.Fe);

src = [repelem((1:nB)', 2); zeros(nH, 1)];
idVrai = src;
req = struct('y', cell(2*nB + nH, 1), 'id_vrai', num2cell(idVrai));
nCles = zeros(numel(req), 1);
for i = 1:numel(req)
    if i <= 2*nB
        x = signauxBase{src(i)};
    else
        x = signauxHors{i - 2*nB};
    end
    d = randi(rs, numel(x) - nq + 1);
    req(i).y = degrader(x(d:d + nq - 1));
end
res = evaluer(INDEX, req, P);

neg = find(res.id_vrai == 0);
calib = false(height(res), 1);  calib(neg(1:2:end)) = true;
V.s_thr = calibrer_seuil(res.score(calib));
T = taux_detection(res(~calib, :), V.s_thr);
V.TBD = T.TBD;
V.TFD = T.TFD;
V.nEntrees = numel(INDEX.cle);
V.scoreMedian = median(res.score(res.id_vrai > 0));
for i = 1:numel(req)
    nCles(i) = size(generer_empreintes(detection_pics(calcul_spectrogramme(req(i).y, P), P), P), 1);
end
V.nClesRequete = median(nCles);
end
