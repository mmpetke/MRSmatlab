function [z_vec] = sinh_disc_z(LMIN,LMAX,NLAY)
%=================================================================
%  Discritization using sinh function
%  Input:
%  LMIN		the first sample line
%  LMAX 	the last sample line
%  NLAY		Number of sampling
%  Output:
%  z_vec 	Sampling vector
%=================================================================
NLAY = NLAY+1;
N1 = NLAY-1; %n=NLAY-1
N2 = NLAY-2;
L0 = LMAX/LMIN;
FAC = L0^(1/N2);      % initial asymptotic factor f
F2 = 1/(FAC*FAC);     %f^-2
        
% compute asymptotic value f for detemination of A and B 
test = zeros(1,11);
test(1) = FAC;
for i = 1:10
      LL = L0*(1-F2)/(1-F2^N1);   %LL = y = f^(n-1)
      FAC = LL^(1/N2);  %f
      test(i+1) = FAC;
      F2 = 1/(FAC*FAC);
end
        
% define A and B
SAMP = zeros(1,NLAY); %check shavad
f2 = zeros(1,NLAY);
        
B = log(FAC);
A = LMIN/sinh(B);
        
for in = 1:NLAY
       SAMP(1,in) = A*sinh(B*(in-1));
       f2(1,in) = A*B*cosh(B*(in-1));
end
z_vec    = SAMP';
% z_vec(1) = [];