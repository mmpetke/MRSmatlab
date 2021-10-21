function [B1, dh] = B1dipole(r, Dr, z, dipolePosition, dipoleMoment)

dphi = 2*pi/360;
phi = 0:dphi:2*pi;

% r-phi 2D meshgrid
[rr,pp] = meshgrid(r,phi);

% horizontal discretization
dh = dphi*ones(length(phi),1) * (Dr .* r)' ;

% create x,y,z points from r, phi and z
x = cos(pp).*rr;
y = sin(pp).*rr;
z = z.*ones(size(y));

% mu_0 / 4pi --> only 1e-7 here because it's a B-field and not H-field
m0 = 1e-7;

% shift points by dipole position to put the dipole in the center
X = x - dipolePosition(1);
Y = y - dipolePosition(2);
Z = z - dipolePosition(3);

% distance vector r
rVector(:,:,1) = X;
rVector(:,:,2) = Y;
rVector(:,:,3) = Z;
xSize = size(X);
clear X Y Z;

% x-oriented dipole with 1 [Am^2] dipole moment
% dipoleMoment = [1 0 0]; 

% magnetization vector
mVector(:,:,1) = dipoleMoment(1).*ones(xSize);
mVector(:,:,2) = dipoleMoment(2).*ones(xSize);
mVector(:,:,3) = dipoleMoment(3).*ones(xSize);

R = sqrt(dot(rVector,rVector,3));
B = zeros(size(rVector));
mDotR = dot(mVector,rVector,3);
for iDim = 1:3
  B(:,:,iDim) = m0.*(3.*rVector(:,:,iDim).*mDotR./R.^5 - mVector(:,:,iDim)./R.^3);
end

B1.x = B(:,:,1);
B1.y = B(:,:,2);
B1.z = B(:,:,3);

%
B1.r   = r;
B1.phi = phi;

% AMP = sqrt(B1.x.^2+B1.y.^2+B1.z.^2);
% figure(5); pcolor(cos(B1.phi')*B1.r', sin(B1.phi')*B1.r', (real(B1.x))); axis equal, axis tight;shading flat;
% figure(6); pcolor(cos(B1.phi')*B1.r', sin(B1.phi')*B1.r', (real(B1.y))); axis equal, axis tight; shading flat;
% figure(7); pcolor(cos(B1.phi')*B1.r', sin(B1.phi')*B1.r', (real(B1.z))); axis equal, axis tight; shading flat;
return