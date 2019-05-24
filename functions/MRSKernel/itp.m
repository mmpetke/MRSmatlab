%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to interpolate a 2D array of arbitrary
% spacing to a regular cartesian grid give by grid (see 
% function 'make_grid'
% INPUT
% B-fields in source coordinates (cart/pol), grid to 
% interpolate on
% OUTPUT
% B_fields in cart coordinates on 'grid'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MH 04/2002

function [B_fieldsC] = itp(loop, B_fieldsP, grid, n);

HrS          = squeeze(B_fieldsP.Hr(n,:,:));
HphiS        = squeeze(B_fieldsP.Hphi(n,:,:));
HzS          = squeeze(B_fieldsP.Hz(n,:,:));
[phiS, rS]   = meshgrid(B_fieldsP.phi, B_fieldsP.r);

% 1. Loop
[phiT, rT]   = cart2pol(grid.x1m, grid.y1m);
HrT          = interp2(phiS, rS, HrS, phiT, rT,'bilinear');
HphiT        = interp2(phiS, rS, HphiS, phiT, rT,'bilinear');
HxC1         = HrT .* cos(phiT) - HphiT .* sin(phiT);
HyC1         = HrT .* sin(phiT) + HphiT .* cos(phiT);
HzC1         = interp2(phiS, rS, HzS, phiT, rT,'bilinear');

clear HrT HphiT;
% 2. Loop
if (grid.eight ==1)
	[phiT, rT] = cart2pol(grid.x2m, grid.y2m);    
	HrT      = interp2(phiS, rS, HrS, phiT, rT,'bilinear');
	HphiT    = interp2(phiS, rS, HphiS, phiT, rT,'bilinear');
	HxC2     = HrT .* cos(phiT) - HphiT .* sin(phiT);
	HyC2     = HrT .* sin(phiT) + HphiT .* cos(phiT);
	HzC2     = interp2(phiS, rS, HzS, phiT, rT,'bilinear');
else
	HxC2     = 0;
	HyC2     = 0;
	HzC2     = 0;
end

% superposition
B_fieldsC.Hx = HxC1-HxC2;
B_fieldsC.Hy = HyC1-HyC2;
B_fieldsC.Hz = HzC1-HzC2;

return