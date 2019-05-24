function [dh,ic] = FigureOfEightTriangulation(B01,loop)

% get cartesian coordinates for first loop and reshape to vector 
Xc01 = reshape(cos(B01.phi')*B01.r',1,size(B01.x,1)*size(B01.x,2));
Yc01 = reshape(sin(B01.phi')*B01.r',1,size(B01.x,1)*size(B01.x,2));

% same for second but shiftes by loop distance
Xc02 = reshape(cos(B01.phi')*B01.r' + loop.size*cos(loop(1).eightoritn),1,size(B01.x,1)*size(B01.x,2));
Yc02 = reshape(sin(B01.phi')*B01.r' + loop.size*sin(loop(1).eightoritn),1,size(B01.x,1)*size(B01.x,2));

% complete coordinates of both fields
Xcomplete = [Xc01 Xc02];
Ycomplete = [Yc01 Yc02];

% triangulation of these point
dt = DelaunayTri(Xcomplete',Ycomplete');
% centers of triangles --> calculation of fields at these points
ic = incenters(dt); % Xnew = ic(:,1); Ynew = ic(:,2);
% get area of triangles
dh  = polyarea(Xcomplete(dt.Triangulation)',Ycomplete(dt.Triangulation)')';