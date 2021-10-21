function [dh,ic] = FigureOfEightTriangulation(B01,loop)
% ORG:
% % get cartesian coordinates for first loop and reshape to vector 
% Xc01 = reshape(cos(B01.phi')*B01.r',1,size(B01.x,1)*size(B01.x,2));
% Yc01 = reshape(sin(B01.phi')*B01.r',1,size(B01.x,1)*size(B01.x,2));
% 
% % same for second but shiftes by loop distance
% Xc02 = reshape(cos(B01.phi')*B01.r' + loop.size*cosd(-loop(1).eightoritn),1,size(B01.x,1)*size(B01.x,2));
% Yc02 = reshape(sin(B01.phi')*B01.r' + loop.size*sind(-loop(1).eightoritn),1,size(B01.x,1)*size(B01.x,2));
% 
% % complete coordinates of both fields
% Xcomplete = [Xc01 Xc02];
% Ycomplete = [Yc01 Yc02];
% 
% % triangulation of these point
% dt = DelaunayTri(Xcomplete',Ycomplete');
% % centers of triangles --> calculation of fields at these points
% ic = incenters(dt); % Xnew = ic(:,1); Ynew = ic(:,2);
% % get area of triangles
% dh  = polyarea(Xcomplete(dt.Triangulation)',Ycomplete(dt.Triangulation)')';

% THOMAS:
% get cartesian coordinates for first loop and reshape to vector 
Xc01 = cos(B01.phi')*B01.r';
Yc01 = sin(B01.phi')*B01.r';
Xc01 = Xc01(:);
Yc01 = Yc01(:);

% same for second but shift by loop distance
Xc02 = cos(B01.phi')*B01.r' + loop.size*cosd(-loop(1).eightoritn);
Yc02 = sin(B01.phi')*B01.r' + loop.size*sind(-loop(1).eightoritn);
Xc02 = Xc02(:);
Yc02 = Yc02(:);

% complete coordinates of both fields
Xcomplete = [Xc01; Xc02];
Ycomplete = [Yc01; Yc02];

% triangulation of these points
dt = delaunayTriangulation(Xcomplete,Ycomplete);
% centers of triangles --> calculation of fields at these points
ic = incenter(dt); % Xnew = ic(:,1); Ynew = ic(:,2);
% get area of triangles
dh  = polyarea(Xcomplete(dt.ConnectivityList)',Ycomplete(dt.ConnectivityList)')';