function [B1, dh] = B1cloop_v2(rloop, r, Dr, z, f, sm, zm, res)


[Br Bz] = CLoop(rloop, r, z, f, sm, zm, res);

dphi = 2*pi/361;
phi  = 0:dphi:2*pi - dphi;

B1.x = cos(phi')*Br;
B1.y = sin(phi')*Br;
B1.z = repmat(Bz, length(phi), 1);

B1.Br  = Br;
B1.Bz  = Bz;
B1.r   = r;
B1.phi = phi;

dh = dphi*ones(length(phi),1) * (Dr .* r)' ;
    
% figure(5); pcolor(cos(B1.phi')*B1.r', sin(B1.phi')*B1.r', (real(B1.x))); axis equal, axis tight;shading flat;
% figure(6); pcolor(cos(B1.phi')*B1.r', sin(B1.phi')*B1.r', (real(B1.y))); axis equal, axis tight; shading flat;
% figure(7); pcolor(cos(B1.phi')*B1.r', sin(B1.phi')*B1.r', (real(B1.z))); axis equal, axis tight; shading flat;
end