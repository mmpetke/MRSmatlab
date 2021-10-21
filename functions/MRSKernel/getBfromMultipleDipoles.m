function Bout = getBfromMultipleDipoles(opos,dpos,dmom)
% INPUT:
%       opos: observation point location
%       dpos: dipole location(s)
%       dmom: dipole moment(s)
%
% OUTPUT:
%       Bout: struct with x, y, z components of B field
%
%
% dipole equation:
%
%       B = mu0/4pi * ( (3*r*(dot(m,r))/R^5) - (m/R^3)  )
%
%               mu0 - susceptibility of free space
%               m - dipole moment
%               r - distance vector
%               R = length of r
%

% in dipole formula: mu0/4pi
% mu0 is defined as 4*pi*1e-7
% hence 1e-7 remains
mu = 1e-7;

% distance vector r (observation point - dipole point(s))
X = opos.x - dpos.x;
Y = opos.y - dpos.y;
Z = opos.z - dpos.z;

% distance vector r
rVector(:,:,1) = X;
rVector(:,:,2) = Y;
rVector(:,:,3) = Z;
xSize = size(X);
clear X Y Z;

% magnetization vector
if numel(dmom)>3
    mVector = dmom;
else
    mVector(:,:,1) = dmom(1).*ones(xSize);
    mVector(:,:,2) = dmom(2).*ones(xSize);
    mVector(:,:,3) = dmom(3).*ones(xSize);
end

% norm (length) of distance vector
R = sqrt(dot(rVector,rVector,3));
% dot product of magnetization and distance vector
mDotR = dot(mVector,rVector,3);
% init B
B = zeros(size(rVector));
for iDim = 1:3
  B(:,:,iDim) = mu.*(3.*rVector(:,:,iDim).*mDotR./R.^5 - mVector(:,:,iDim)./R.^3);
end

% output variable
Bout.x = B(:,:,1);
Bout.y = B(:,:,2);
Bout.z = B(:,:,3);

return