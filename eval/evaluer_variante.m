function V = evaluer_variante(P, signauxBase, signauxHors, degrader, Tq, graine)
%EVALUER_VARIANTE  TBD et TFD pour un jeu de paramètres (études de γf et F, Q4).
%   V = evaluer_variante(P, signauxBase, signauxHors, degrader, Tq, graine)
%
%   Reconstruit l'index avec P, puis évalue 2 requêtes positives par morceau
%   et 1 négative par morceau hors base (une sur deux fixe le seuil, l'autre
%   mesure le TFD). degrader : fonction appliquée aux requêtes à 8 kHz.
%   Le seuil est recalibré à chaque fois, car γf et F changent aussi les
%   scores des négatives.
%   V : s_thr, TBD, TFD, nEntrees, nClesRequete, scoreMedian.

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
