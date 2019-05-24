function [dh,ic] = SepLoopTriangulation(B01,B02, loop)

eightOritn = loop(1).eightoritn/360.0*2.0*pi;

% get cartesian coordinates for first loop and reshape to vector 
Xc01 = reshape(cos(B01.phi')*B01.r',1,size(B01.x,1)*size(B01.x,2));
Yc01 = reshape(sin(B01.phi')*B01.r',1,size(B01.x,1)*size(B01.x,2));

% same for second but shiftes by loop distance
Xc02 = reshape(cos(B02.phi')*B02.r' + loop.eightsep*cos(-eightOritn),1,size(B02.x,1)*size(B02.x,2));
Yc02 = reshape(sin(B02.phi')*B02.r' + loop.eightsep*sin(-eightOritn),1,size(B02.x,1)*size(B02.x,2));

% complete coordinates of both fields
Xcomplete = [Xc01 Xc02];
Ycomplete = [Yc01 Yc02];

% triangulation of these point
dt = DelaunayTri(Xcomplete',Ycomplete');
% centers of triangles --> calculation of fields at these points
ic = incenters(dt); %
% get area of triangles
dh  = polyarea(Xcomplete(dt.Triangulation)',Ycomplete(dt.Triangulation)')';