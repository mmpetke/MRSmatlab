function [B1, dh, B2] = B1cloop(rloop, z, dz, f, sm, zm, res, rmax)

if nargin < 8 % rmax not given
    rmax = 6*max(rloop);
end

if length(rloop)==1 % tx-size equals rx-size
    [r, Dr] = MakeXvec(rloop*2,z,dz,rmax);
    
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
    
else % tx and rx different in size 
    % for InLoop configuration and 1D Kernel to keep cylindrical coordinates 
    % the same r-spacing in necessary to avoid interpolation
    [r1, Dr1] = MakeXvec(rloop(1)*2,z,dz,rmax);
    [r2, Dr2] = MakeXvec(rloop(2)*2,z,dz,rmax);
    
    r_all  = unique(sort([r1; r2]));
    r      = (r_all(2:end)+r_all(1:end-1))/2;
    Dr     = r_all(2:end)-r_all(1:end-1);
    
    % transmitter
    [Br Bz] = CLoop(rloop(1), r, z, f, sm, zm, res);
        
    dphi = 2*pi/361;
    phi  = 0:dphi:2*pi - dphi;
    
    B1.x = cos(phi')*Br;
    B1.y = sin(phi')*Br;
    B1.z = repmat(Bz, length(phi), 1);
    
    B1.Br  = Br;
    B1.Bz  = Bz;
    B1.r    = r;
    B1.phi  = phi;
    
    dh = dphi*ones(length(phi),1) * (Dr .* r)' ;
    
    % receiver
    [Br Bz] = CLoop(rloop(2), r, z, f, sm, zm, res);
        
    dphi = 2*pi/361;
    phi  = 0:dphi:2*pi - dphi;
    
    B2.x = cos(phi')*Br;
    B2.y = sin(phi')*Br;
    B2.z = repmat(Bz, length(phi), 1);
    
    B2.Br  = Br;
    B2.Bz  = Bz;
    B2.r    = r;
    B2.phi  = phi;
    
    dh = dphi*ones(length(phi),1) * (Dr .* r)' ;
    
end
% figure(5); pcolor(cos(B1.phi')*B1.r', sin(B1.phi')*B1.r', (real(B1.x))); axis equal, axis tight;shading flat;
% figure(6); pcolor(cos(B1.phi')*B1.r', sin(B1.phi')*B1.r', (real(B1.y))); axis equal, axis tight; shading flat;
% figure(7); pcolor(cos(B1.phi')*B1.r', sin(B1.phi')*B1.r', (real(B1.z))); axis equal, axis tight; shading flat;
end