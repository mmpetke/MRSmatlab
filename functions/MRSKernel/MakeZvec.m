function model = MakeZvec(model)
%% make z-discretization
switch model.z_space
    
    case 1   % sinh discritization (Ahmad)
        
        nl_temp = model.nz+1;
        N1 = nl_temp-1; %n=NLAY-1
        N2 = nl_temp-2;
        L0 = model.zmax/model.sinh_zmin;
        FAC = L0^(1/N2);      % initial asymptotic factor f
        F2 = 1/(FAC*FAC);     %f^-2
        
        % compute asymptotic value f for detemination of A and B
        test = zeros(1,11);
        test(1) = FAC;
        for i = 1:10
            LL = L0*(1-F2)/(1-F2^N1);   %LL = y = f^(n-1)
            FAC = LL^(1/N2);  %f
            test(i+1) = FAC;
            F2 = 1/(FAC*FAC);
        end
        
        % define A and B
        SAMP = zeros(1,nl_temp); %check shavad
        f2 = zeros(1,nl_temp);
        
        B = log(FAC);
        A = model.sinh_zmin/sinh(B);
        
        for in = 1:nl_temp
            SAMP(1,in) = A*sinh(B*(in-1));
            f2(1,in)   = A*B*cosh(B*(in-1));
        end
        z_vec = SAMP;
        
        model.z  = (z_vec(2:end)+z_vec(1:end-1))/2;
        model.Dz = z_vec(2:end)-z_vec(1:end-1);
        
        
    case 2 % loglin
        dzlogmin      = model.LL_dzmin;  % minimum layer thickness in log part
        dzlogmax      = model.LL_dzmax; % max layer thickness in log part equal to lin spacing
        zlogmax       = model.LL_dlog; % depth until log spacing
        model.zmax    = model.zmax;    % maximum total depth
        
        % testing how many log layer are necessary to match parameters
        lnumspace = logspace(log10(1),log10(1000),100);
        for n=1:length(lnumspace)
            z = zlogmax - [0 cumsum(fliplr(logspace(log10(dzlogmin),log10(dzlogmax),lnumspace(n))))];
            if (z(end) < dzlogmin)
                lnumber=lnumspace(n);
                break
            end
        end
        z  = zlogmax - [0 cumsum(fliplr(logspace(log10(dzlogmin),log10(dzlogmax),floor(lnumber))))];
        % sometimes first layer is very thin
        z1 = fliplr(z(z>0)); if (z1(1)<(0.7*dzlogmin));z1(1)=[];end;
        % create lin part
        z2 = z1(end)+dzlogmax:dzlogmax:model.zmax;
        % put things together
        model.z   = sort([z1 z2]);
        model.Dz  = diff([0 model.z]);
        model.nz  = length(model.z);
        model.zi = [];
        %         for n = 1:length(earth.zm)
        %             model.zi(n) = find(model.z > earth.zm(n), 1);
        %         end
        
    case 4 % lin (anonymous)
        layer    = 0:model.dz:model.zmax;
        model.nz = length(layer)-1;
        model.z  = (layer(1:end-1)+layer(2:end))/2;
        model.Dz = layer(2:end)-layer(1:end-1);
        model.zi = [];
        %         for n = 1:length(earth.zm)
        %             model.zi(n) = find(model.z > earth.zm(n), 1);
        %         end
        
        
end
end