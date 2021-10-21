function [Px,Mp,p] = getMfromLookupFull(earth,loop,Berdt,Bpre,ramp)
% "earth" and "loop" hold general parameters
% "B0" and "Bpre" are the Bfields(x,y,z) in a certain depth layer
% "ramp" holds PrePol switch-off ramp parameters
% this routine respects the original spatial orientation of Bpre and B0

%% 1.) lookup-table stuff from previous BLOCHUS simulations
lookup = load(['PPramp_',ramp.name,'_',sprintf('%3.1f',ramp.time*1e3),'ms.mat']);
lookup = lookup.data;
% create the interpolation function for the magnetization M depending on
% the PrePol factor and angle theta
[rbt,rbp] = meshgrid(lookup.PPfac,lookup.theta);
rbt = rbt(:); rbp = rbp(:);
rbMx = lookup.M(:,:,1);
rbMy = lookup.M(:,:,2);
rbMz = lookup.M(:,:,3);
rbMx = rbMx(:);
rbMy = rbMy(:);
rbMz = rbMz(:);
% M interpolation fcn depending on theta and PrePol factor
Fx = scatteredInterpolant(rbt,rbp,rbMx);
Fy = scatteredInterpolant(rbt,rbp,rbMy);
Fz = scatteredInterpolant(rbt,rbp,rbMz);

%% 2.) MRSmatlab data for the current depth layer
% scale factor due to the Px current and No of turns
Ifactor = loop.PXcurrent*loop.PXturns;
% local B0 field
B0(:,:,1) = earth.erdt.*Berdt.x;
B0(:,:,2) = earth.erdt.*Berdt.y;
B0(:,:,3) = earth.erdt.*Berdt.z;
% local PP field
Bp(:,:,1) = Ifactor.*Bpre.x;
Bp(:,:,2) = Ifactor.*Bpre.y;
Bp(:,:,3) = Ifactor.*Bpre.z;
% amplitudes of B0 and PP field
B0n = sqrt( B0(:,:,1).^2 + B0(:,:,2).^2 + B0(:,:,3).^2 ); % ampl.
Bpn = sqrt( Bp(:,:,1).^2 + Bp(:,:,2).^2 + Bp(:,:,3).^2 ); % ampl.
% directions of B0 and PP field
B0dir = [Berdt.x(1); Berdt.y(1); Berdt.z(1)];
Bpdir = [Bpre.x(:) Bpre.y(:) Bpre.z(:)];
Bpdir = Bpdir./(sqrt( Bpdir(:,1).^2 + Bpdir(:,2).^2 + Bpdir(:,3).^2 ));

% rotation matrix that rotates B0 to zunit
% is later needed for spatial correction
R0 = RotationFromTwoVectors(B0dir,[0 0 1]);

% old standard PrePol factor is simply the length of the resulting
% vector B0+Bp in units of B0 (-> ./earth.erdt)
Amp = abs( sqrt( (B0(:,:,1)+Bp(:,:,1)).^2 +...
                 (B0(:,:,2)+Bp(:,:,2)).^2 +...
                 (B0(:,:,3)+Bp(:,:,3)).^2 ) ./ earth.erdt );

% k and theta are needed for the interpolation of M
kpp = Bpn./B0n;
% angle theta between B0 and Bp
theta = acosd( dot(B0,Bp,3) ./ (B0n.*Bpn) );

% make column vectors
Amp = Amp(:);
kpp = kpp(:);
theta = theta(:);

% interpolated Mp based on BlochSim lookup table
MpIx = Fx(kpp,theta).*Amp;
MpIy = Fy(kpp,theta).*Amp;
MpIz = Fz(kpp,theta).*Amp;

% due to the interpolation, Mp is oriented within the Bloch-frame (B0 along
% zunit); now we rotate it back depending on the original orientation of M
MM = zeros(numel(MpIx),3);
for i = 1:numel(MpIx)
   % first rotation of B0 to zunit 
   MB0frame = R0*Bpdir(i,:)';
   % second rotation towards x-axis (Px in lookup table caluclation always points into x)
   Rx = RotationFromTwoVectors([MB0frame(1:2); 0]./norm([MB0frame(1:2); 0]),[1 0 0]);
   % apply the two back rotations to reorient Mp from the Bloch-frame (B0
   % along z) to the "real" xyz-frame
   MM(i,1:3) = R0'*Rx'*[MpIx(i) MpIy(i) MpIz(i)]';
end
Mp.x = reshape(MM(:,1),size(B0n));
Mp.y = reshape(MM(:,2),size(B0n));
Mp.z = reshape(MM(:,3),size(B0n));

Mp.x1 = reshape(MpIx(:,1),size(B0n));
Mp.y1 = reshape(MpIy(:,1),size(B0n));
Mp.z1 = reshape(MpIz(:,1),size(B0n));

% within the bloch simulation, per definition B0 points into direction of
% zunit [0 0 1]; therefore the effective component of Mp that gets excited
% after the PP switch-off is the z-compenent of MpI (parallel to B0)
Px = MpIz;
Px = reshape(Px,size(B0n));
% the adiabatic quality p is defined as the projection of the direction of
% Mp onto the direction of B0 (dot(MpI,zunit)/norm(zunit))
% hence p is simply the z-component of MpI
p = MpIz./Amp;
p = reshape(p,size(B0n));
end