function x = morceau_synthetique(duree, Fe, graine)
%MORCEAU_SYNTHETIQUE  « Morceau » de test : notes harmoniques aléatoires.
%   x = morceau_synthetique(duree, Fe, graine)
%
%   Sert uniquement à tester la chaîne sans fichier audio. Chaque graine
%   donne un morceau différent : 2 voix de notes tempérées (MIDI 45 à 84)
%   à 5 harmoniques, enveloppe attaque/décroissance, plus des coups de
%   bruit court (percussions).

s = RandStream('mt19937ar', 'Seed', graine);
n = round(duree * Fe);
x = zeros(n, 1);

for voix = 1:2
    t0 = 0;
    while t0 < duree
        d = 0.15 + 0.5 * rand(s);                     % durée de la note (s)
        f0 = 440 * 2^((randi(s, [45 84]) - 69) / 12);  % note tempérée
        i0 = floor(t0 * Fe) + 1;
        i1 = min(n, i0 + round(d * Fe) - 1);
        tt = (0:(i1 - i0))' / Fe;
        env = min(1, tt / 0.01) .* exp(-tt / (0.4 * d));
        note = zeros(size(tt));
        for h = 1:5
            if h * f0 < Fe / 2
                note = note + (0.6^(h-1)) * sin(2*pi*h*f0*tt + 2*pi*rand(s));
            end
        end
        x(i0:i1) = x(i0:i1) + (0.5 + rand(s)) * env .* note;
        t0 = t0 + d;
    end
end

% Percussions : bruit court tous les 0,25 à 0,75 s
t0 = 0;
while t0 < duree
    i0 = floor(t0 * Fe) + 1;
    i1 = min(n, i0 + round(0.05 * Fe) - 1);
    tt = (0:(i1 - i0))' / Fe;
    x(i0:i1) = x(i0:i1) + 0.3 * randn(s, numel(tt), 1) .* exp(-tt / 0.01);
    t0 = t0 + 0.25 + 0.5 * rand(s);
end

x = x / max(abs(x));
end
