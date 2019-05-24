function B1 = FigureOfEight(B01,loop,ic)

eightOritn = loop(1).eightoritn/360.0*2.0*pi;

% get cartesian coordinates for first loop and reshape to vector 
Xc01 = reshape(cos(B01.phi')*B01.r',1,size(B01.x,1)*size(B01.x,2));
Yc01 = reshape(sin(B01.phi')*B01.r',1,size(B01.x,1)*size(B01.x,2));

% same for second but shiftes by loop distance
Xc02 = reshape(cos(B01.phi')*B01.r' + loop.size*cos(-eightOritn),1,size(B01.x,1)*size(B01.x,2));
Yc02 = reshape(sin(B01.phi')*B01.r' + loop.size*sin(-eightOritn),1,size(B01.x,1)*size(B01.x,2));

% reshape field to vector as needed for interpolation
B01x = reshape(B01.x,1,size(B01.x,1)*size(B01.x,2));
B01y = reshape(B01.y,1,size(B01.x,1)*size(B01.x,2));
B01z = reshape(B01.z,1,size(B01.x,1)*size(B01.x,2));

% split coordinate vector of innercenters of triangles to x/y
Xnew = ic(:,1); Ynew = ic(:,2);

% interpolate to complete coordinates
F     = TriScatteredInterp(Xc01(:),Yc01(:),real(B01x(:)));
B1x_r = F(Xnew,Ynew);
F     = TriScatteredInterp(Xc01(:),Yc01(:),real(B01y(:)));
B1y_r = F(Xnew,Ynew);
F     = TriScatteredInterp(Xc01(:),Yc01(:),real(B01z(:)));
B1z_r = F(Xnew,Ynew);
F     = TriScatteredInterp(Xc02(:),Yc02(:),real(B01x(:)));
B2x_r = F(Xnew,Ynew);
F     = TriScatteredInterp(Xc02(:),Yc02(:),real(B01y(:)));
B2y_r = F(Xnew,Ynew);
F     = TriScatteredInterp(Xc02(:),Yc02(:),real(B01z(:)));
B2z_r = F(Xnew,Ynew);

F     = TriScatteredInterp(Xc01(:),Yc01(:),imag(B01x(:)));
B1x_i = F(Xnew,Ynew);
F     = TriScatteredInterp(Xc01(:),Yc01(:),imag(B01y(:)));
B1y_i = F(Xnew,Ynew);
F     = TriScatteredInterp(Xc01(:),Yc01(:),imag(B01z(:)));
B1z_i = F(Xnew,Ynew);
F     = TriScatteredInterp(Xc02(:),Yc02(:),imag(B01x(:)));
B2x_i = F(Xnew,Ynew);
F     = TriScatteredInterp(Xc02(:),Yc02(:),imag(B01y(:)));
B2y_i = F(Xnew,Ynew);
F     = TriScatteredInterp(Xc02(:),Yc02(:),imag(B01z(:)));
B2z_i = F(Xnew,Ynew);

B1x = B1x_r + 1i*B1x_i;
B1y = B1y_r + 1i*B1y_i;
B1z = B1z_r + 1i*B1z_i;

B2x = B2x_r + 1i*B2x_i;
B2y = B2y_r + 1i*B2y_i;
B2z = B2z_r + 1i*B2z_i;

% replace nan (at points outside) by minimum value
B1x(isnan(B1x))= min(B1x);
B1y(isnan(B1y))= min(B1y);
B1z(isnan(B1z))= min(B1z);
B2x(isnan(B2x))= min(B2x);
B2y(isnan(B2y))= min(B2y);
B2z(isnan(B2z))= min(B2z);

% superimpose both fields
B1.x = B1x-B2x;
B1.y = B1y-B2y;
B1.z = B1z-B2z;


% figure(5); pcolor(cos(B01.phi')*B01.r', sin(B01.phi')*B01.r', (real(B01.x))); axis equal, axis tight;shading flat;
% figure(6); tri=delaunay(Xnew,Ynew); trisurf(tri,Xnew,Ynew,real(B1.x));shading flat;view([0 90])