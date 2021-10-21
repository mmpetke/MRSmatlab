function sus = getCurie_frac(gyro,temp)
% The Curie Law for equilibrium nuclear magnetisation (spin 1/2) is:
% X = gyro^2 * hBar^2 * S(S+1) /3/boltz/temp
% with S = Spin 1/2 -> S(S+1) = 3/4
% hence:
% X = gyro^2 * hBar^2 /4/boltz/temp
%
% INPUT:
%       gyro - gyromagnetic ratio (e.g. for H = 2.675222e8 [rad/s/T])
%       temp - temperature in [K]

% Diracs's constant in [Js] -> Planck's constat / 2pi -> hBar = h/2pi
hBar = 1.054571726e-34;
% Boltzmann constant in [J/K]
boltz = 1.3806488e-23;
% water atoms per unit volume (m³)
% moles per 1 liter water -> 1000g/(18g/mole) = 55.556 moles
% molecules per mole -> Avogadro*55.556 moles = 6.022e23*55.556 moles =
% 3.3456e+25 molecules
% one water molecule has two H atoms -> atoms per 1 liter = 2*3.3456e+25 =
% 6.6920e+25 atoms
% hence in 1m³ water are 6.6920e+25*1e3 H atoms
waterDens = 6.692e28;

sus = gyro.^2 .* hBar.^2 .* waterDens ./ (4.*boltz.*temp);
