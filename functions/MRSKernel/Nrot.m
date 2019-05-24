function RN=Nrot(phi,n)
% RN=Nrot(phi,n)
% rotation about the axis of a normal vector n about an angle phi
% Input:
% phi   : rotation vector [rad]
% n     : vector defines rotation axis [x y z]
% 
% Output:
% RN    : Rotation matrix

n   = n/norm(n); % normalize vector
n1  = n(1);
n2  = n(2);
n3  = n(3);

RN = [n1^2* (1-cos(phi))+cos(phi)       n1*n2*(1-cos(phi))-n3*sin(phi)  n1*n3*(1-cos(phi))+n2*sin(phi); ...
      n2*n1*(1-cos(phi))+n3*sin(phi)    n2^2* (1-cos(phi))+cos(phi)     n2*n3*(1-cos(phi))-n1*sin(phi); ...
      n3*n1*(1-cos(phi))-n2*sin(phi)    n3*n2*(1-cos(phi))+n1*sin(phi)  n3^2* (1-cos(phi))+   cos(phi)];

