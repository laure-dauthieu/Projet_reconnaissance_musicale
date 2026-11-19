function tests = test_filtre_passe_bande
%TEST_FILTRE_PASSE_BANDE  Tests isolés du filtrage passe-bande 300-3400 Hz (dégradation).
%   Lancer seul : runtests('tests/test_filtre_passe_bande.m')
tests = functiontests(localfunctions);
end

function setupOnce(tc)
racine = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(racine, 'eval', 'degradations'));
tc.TestData.Fe0 = 8000;
end

function test_bande_passante(tc)
% 1 kHz passe, 100 Hz est fortement atténué.
Fe0 = tc.TestData.Fe0;
t = (0:Fe0 - 1)' / Fe0;
gain = @(f) rms(filtre_passe_bande(sin(2*pi*f*t), Fe0)) / rms(sin(2*pi*f*t));
verifyGreaterThan(tc, gain(1000), 0.9);
verifyLessThan(tc, gain(100), 0.05);
end

function test_causal(tc)
% Version causale (un seul passage, comme un vrai haut-parleur) : même longueur, 1 kHz passe.
Fe0 = tc.TestData.Fe0;
t = (0:Fe0 - 1)' / Fe0;
s = sin(2*pi*1000*t);
yf = filtre_passe_bande(s, Fe0, 300, 3400, true);
verifyEqual(tc, size(yf), size(s));
verifyGreaterThan(tc, rms(yf(Fe0/2:end)) / rms(s), 0.8);
end
