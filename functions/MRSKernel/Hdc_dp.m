%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Diplofeld im Nichtleiter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MH 03/2002

function [Hr_dc, Hz_dc] = Hdc_dp(zmax, dz, r);

z			=		(dz/2:dz:zmax);
z_mat		=		repmat(z',1,size(r,2));
r_mat		=		repmat(r ,size(z,2),1);

Hz_dc       =       1 ./ (4*pi*(r_mat.^2 + z_mat.^2).^1.5) .* (3 * z_mat.^2 ./ (r_mat.^2 + z_mat.^2) - 1);
Hr_dc       =       1 ./ (4*pi*(r_mat.^2 + z_mat.^2).^2.5) .* (3 * z_mat .* r_mat); 

return