% function rotV = mrs_rotate(V,t,phase,df)
% rotate complex NMR FID data
% after rotation real part contains NMR and noise imaginary part only noise
% Input: 
%       V: complex FID
%       phase, df: after fitting of FID
%       t: time according to the fit

function rotV = mrs_rotate(V,t,phase,df)
   
rotV = complex(abs(V).*cos(angle(V) - phase - 2*pi*df.*t),...
               abs(V).*sin(angle(V) - phase - 2*pi*df.*t));