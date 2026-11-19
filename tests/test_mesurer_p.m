function tests = test_mesurer_p
%TEST_MESURER_P  Tests isolés de la mesure de p (proportion de pics conservés).
%   Lancer seul : runtests('tests/test_mesurer_p.m')
%   Les pics sont écrits à la main : aucune autre étape n'est appelée.
tests = functiontests(localfunctions);
end

function setupOnce(tc)
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(racine, fullfile(racine, 'eval'));
tc.TestData.P = parametres();
end

function test_position_exacte(tc)
% p compte les pics retrouvés EXACTEMENT à la même position (m, k).
ref = [1 30; 2 40; 3 50; 4 60];
deg = [1 30; 2 41; 3 50; 9 99];       % un pic décalé d'un canal ne compte pas
verifyEqual(tc, mesurer_p(ref, deg), 0.5);
verifyEqual(tc, mesurer_p(ref, ref), 1);
verifyEqual(tc, mesurer_p(ref, zeros(0, 2)), 0);
end

function test_par_bande(tc)
% p par bande : un pic grave conservé, un pic aigu perdu.
P = tc.TestData.P;
k = @(f) round(f * P.Nfft / P.Fe) + 1;           % canal d'une fréquence
ref = [1 k(250); 2 k(3000)];
deg = [1 k(250)];
[p, pb, n] = mesurer_p(ref, deg, P);
verifyEqual(tc, p, 0.5);
verifyEqual(tc, pb(1), 1);                       % bande 200-330 Hz
verifyEqual(tc, pb(end), 0);                     % bande 2428-4000 Hz
verifyEqual(tc, sum(n), 2);
verifyTrue(tc, all(isnan(pb(2:end-1))));          % bandes sans pic de référence
end
