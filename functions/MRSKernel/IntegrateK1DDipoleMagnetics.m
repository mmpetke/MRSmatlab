function K = IntegrateK1DDipoleMagnetics(loop,measure,earth,B0,Bpre,dh,z,dz,loopshape,obsPos)

gamma = 0.267518*1e9;
pm_vec = measure.pm_vec;

if loopshape == 8
    
    % effective DC of Px-loop
    pre = loop.PXcurrent*loop.PXturns;
    % Btotal =  B0 + Bp
    Btotal = abs(sqrt((earth.erdt*B0.x + pre*Bpre.x).^2 + ...
        (earth.erdt*B0.y + pre*Bpre.y).^2 + ...
        (earth.erdt*B0.z + pre*Bpre.z).^2));
    
    inkl = earth.inkl/360.0*2.0*pi;
    decl = earth.decl/360.0*2.0*pi;
    
    % B0 direction vector
    dir_vec(1) = cos(inkl) * cos(-decl);
    dir_vec(2) = cos(inkl) * sin(-decl);
    dir_vec(3) = + sin(inkl); % z positiv nach unten!
    
    K = zeros(length(pm_vec),1,3);
    
    for n = 1:length(pm_vec)
        
        % 3D coord of voxels
        dipole_location.x = cos(Bpre.phi').*Bpre.r';
        dipole_location.y = sin(Bpre.phi').*Bpre.r';
        dipole_location.z = z.*ones(size(dipole_location.x));
        
        % get curie-eq. factor
        curie = getCurie_frac(gamma,earth.temp);
        
        if loop.usePXramp    
            % normalized M from BLOCHUS lookup
            % multiplied with B0 to get correct M value
            mag.x = earth.erdt .* measure.Mp.x;
            mag.y = earth.erdt .* measure.Mp.y;
            mag.z = earth.erdt .* measure.Mp.z;
        else
            % direction of B0 multiplied by total B-field length
            mag.x = dir_vec(1).*Btotal;
            mag.y = dir_vec(2).*Btotal;
            mag.z = dir_vec(3).*Btotal;
        end
        % dipole moment
        % M = dm/dV -> m = M*V
        dipole_moment(:,:,1) = (curie.*mag.x) .*dh.*dz;
        dipole_moment(:,:,2) = (curie.*mag.y) .*dh.*dz;
        dipole_moment(:,:,3) = (curie.*mag.z) .*dh.*dz;
        
        % observer position (uses external 'dipolePosition' variable as dummy)
        % default = [0 0 0]
        obs_location.x = obsPos(1);
        obs_location.y = obsPos(2);
        obs_location.z = obsPos(3);
        
        B = getBfromMultipleDipoles(obs_location,dipole_location,dipole_moment);
        
        % integrate field
        K(n,1,1) = sum(sum(B.x));
        K(n,1,2) = sum(sum(B.y));
        K(n,1,3) = sum(sum(B.z));
    end    
else
    msgbox('Use B-field sensor');
end

return