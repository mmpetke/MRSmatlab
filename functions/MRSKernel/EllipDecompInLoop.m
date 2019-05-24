% Elliptical decomposition of magnetic fields B1 for separated loop
% [B_comps] = EllipDecompSepLoop(earth, B1)
% INPUT
% B1: 2D array of B-fields in T in cartesian coordinates
% inkl: inclination in degree
% measure.prof_dir: orientation of profile to magnetic north in degree
% OUTPUT
% B_comps: 2D-array of elliptical components
%
% 2002: original function written by Martina Braun
% 2010: general clean-up, Marian
% 2012: rebuild for separated loop

function [B_comps, B0] = EllipDecompInLoop(earth, B1)

inkl = earth.inkl/360.0*2.0*pi;
decl = earth.decl/360.0*2.0*pi;

% Umrechnung von Kugelkoordinaten in kartesische
B0.x =   cos(inkl) * cos(-decl);
B0.y =   cos(inkl) * sin(-decl);
B0.z = + sin(inkl); %z positiv nach unten !

B0.x = repmat(B0.x, size(B1.y));
B0.y = repmat(B0.y, size(B1.y));
B0.z = repmat(B0.z, size(B1.y));

% Berechung der Senkrechtkomponente
skalarprodukt = B0.x .* B1.x + B0.y .* B1.y + B0.z .* B1.z;                         
B_senk_1      = B1.x - skalarprodukt .* B0.x;
B_senk_2      = B1.y - skalarprodukt .* B0.y;
B_senk_3      = B1.z - skalarprodukt .* B0.z;

% Berechnung der Vorzeichenfunktion
VZcross_1     = B0.x .* (B_senk_2 .* conj(B_senk_3) - B_senk_3 .* conj(B_senk_2));
VZcross_2     = B0.y .* (B_senk_3 .* conj(B_senk_1) - B_senk_1 .* conj(B_senk_3));
VZcross_3     = B0.z .* (B_senk_1 .* conj(B_senk_2) - B_senk_2 .* conj(B_senk_1));
tmp           = 1i * (VZcross_1 + VZcross_2 + VZcross_3);
VZ = zeros(size(tmp));
VZ(real(tmp) > 0 | (real(tmp)==0 & imag(tmp)>0)) =  1; 
VZ(real(tmp) < 0 | (real(tmp)==0 & imag(tmp)<0)) = -1;

% Berechnung von alpha, beta & zeta
Bs_mal_konjBs = B_senk_1 .* conj(B_senk_1) + B_senk_2 .* conj(B_senk_2) + B_senk_3 .* conj(B_senk_3);
Bs_mal_Bs     = B_senk_1.^2+B_senk_2.^2+B_senk_3.^2;
B_comps.alpha = (1/sqrt(2) * sqrt(Bs_mal_konjBs + abs(Bs_mal_Bs)));
B_comps.beta  = VZ .* (1/sqrt(2) * sqrt(Bs_mal_konjBs-abs(Bs_mal_Bs)));
B_comps.e_zeta= (sqrt(Bs_mal_Bs ./ abs(Bs_mal_Bs)));


% Berechnung des Einheitsvektors bt ----------------------------------------
B_comps.b_1 = 1./B_comps.alpha .* real((1./B_comps.e_zeta) .* B_senk_1);
B_comps.b_2 = 1./B_comps.alpha .* real((1./B_comps.e_zeta) .* B_senk_2);
B_comps.b_3 = 1./B_comps.alpha .* real((1./B_comps.e_zeta) .* B_senk_3);


B_comps.s1=B_senk_1;
B_comps.s2=B_senk_2;
B_comps.s3=B_senk_3;
return
