function [x0,Dx] = MakeXvec(a,z,dz,rmax)


LMIN_IN  = min(dz/10,a/100);
LMAX_OUT = max(a*3,rmax);

if z > a
    NLAY_IN  = 11;
elseif z > a/5    
    NLAY_IN  = 21;
else
    NLAY_IN  = 31;
end
        

%=============================================================
% Discritization using sinh function
% Input:
%  a	       square loop side
%  LMIN_IN     first sample close to wire
%  NLAY_IN     number of samples insdie the loop (between wire and center) 	
%  LMAX_OUT    maximum doscritization limit outside the loop
%  Output:
%  x_vec       vector of discrete points from loop center to outside limit. 
%=============================================================
h =a/2;
LMAX_IN = h;        % the last point inside the loop (at center)
    
% sample vector inside and outside of the right loop side  
[SAMP_IN,f2_IN,A,B] = sinhSample(LMIN_IN,LMAX_IN,NLAY_IN+1); 


NLAY_OUT = NLAY_IN;
% add point close to loop center
SAMP_IN    = [SAMP_IN(1:end-1) SAMP_IN(end)-0.01 SAMP_IN(end)]; 
SAMP_IN_av = (SAMP_IN(2:end)+SAMP_IN(1:end-1))/2;
Dx1 = SAMP_IN(2:end)-SAMP_IN(1:end-1);

SAMP_OUT = SAMP_IN;
% f2 = A*B*cosh(B*i)
% f2_OUT = f2_IN;


% extend outside discritization to the next(s) 10th.
% Number of samples has to be K*10+1 for 11 point formula

for i = 1:5
    if SAMP_OUT(length(SAMP_OUT))< LMAX_OUT        
        NLAY_OUT = NLAY_OUT+10;
        SAMP_OUT = zeros(1,NLAY_OUT+1); 
%         f2_OUT   = zeros(1,NLAY_OUT-1);
        
        for in = 1:NLAY_OUT+1 
        SAMP_OUT(1,in) = A*sinh(B*(in-1));
%         f2_OUT(1,in)   = A*B*cosh(B*(in-1));
        end
    end
end

% SAMP_OUT(1) = [];
SAMP_OUT_av = (SAMP_OUT(2:end)+SAMP_OUT(1:end-1))/2;
Dx2 = SAMP_OUT(2:end)-SAMP_OUT(1:end-1);

SAMPIN_R = h-SAMP_IN_av;
% f2IN_R = f2_IN;
% f2IN_R(length(f2IN_R)) = [];
SAMPOUT_R = h+SAMP_OUT_av;
% f2OUT_R = f2_OUT;
% f2OUT_R(1) = [];

% x discritization vector
x0 = [fliplr(SAMPIN_R) SAMPOUT_R]';
Dx = [fliplr(Dx1) Dx2]';
% f2_x  = [fliplr(f2IN_R) f2OUT_R]';

function [SAMP,f2,A,B] = sinhSample(LMIN,LMAX,NLAY)
%=================================================================
%  Discritization using sinh function
%  Input:
%  ======
%  LMIN		the first sample line
%  LMAX 	the last sample line
%  NLAY		Number of sampling
%  Output:
%  =======
%  SAMP 	Sampling vector
%  f2       Vector of ABcosh(Bi) values
%  A,B      Coefficients
%=================================================================
N1 = NLAY-1; %n=NLAY-1
N2 = NLAY-2;
L0 = LMAX/LMIN;
FAC = L0^(1/N2);      % initial asymptotic factor f
F2 = 1/(FAC*FAC);     %f^-2   
% compute asymptotic value f for detemination of A and B 
for i = 1:10
      LL = L0*(1-F2)/(1-F2^N1);   %LL = y = f^(n-1)
      FAC = LL^(1/N2);  %f
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