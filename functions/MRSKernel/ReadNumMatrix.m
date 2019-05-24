function Kerneldata = ReadNumMatrix(varargin)

if nargin==0

    [filename,path] = uigetfile({'*.mrm;*MRM','pick a numis kernel matrix'},'MultiSelect','off',...
                                 'open NumisKernel');
    file            = [path,filename];
   
else
    file            = varargin{1};
end

[path,name,ext] = fileparts(file);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fid = fopen(file);

    inkl=fscanf(fid,'%g',[1 1]);
    shape = fscanf(fid,'%g',[1 1]);
    diameter = fscanf(fid,'%g',[1 1]);
    freq = fscanf(fid,'%g',[1 1]);
    unknown = fscanf(fid,'%g',[2 1]);
    res = fscanf(fid,'%g',[2 6]);
    dummy = fscanf(fid,'%g',[2 100]);
    pulse = dummy(1,:);
    depth = dummy(2,:);

    dummy = fscanf(fid,'%g',[2 100*100]);
    fclose(fid);

    dummy = [dummy(1,:)+i*dummy(2,:)];

    kernel = zeros(100,100);

    for n=1:100
        kernel(1:100,n) = dummy(n*100-100+1:n*100)';
    end

    kernel              = 0.1*kernel.'; % orignally calc. by 10m basis layers --> interpolate to 1m --> divide by 10
    
    
    Kerneldata.measure.pm_vec = pulse/1000;
    Kerneldata.model.z_vec    = [0.5:1:max(depth)];
    Kerneldata.model.nz       = 1;
    [X,Y]                     = meshgrid(Kerneldata.measure.pm_vec,Kerneldata.model.z_vec);
    Kerneldata.K              = interp2(pulse/1000,depth,kernel,X,Y);
    
    switch shape
        case {1,3}
            Kerneldata.loop(1).radius = diameter/2;
        case {2,4}
            Kerneldata.loop(1).radius = diameter;
    end
 
    Kerneldata.earth.sm       = res(2,:); Kerneldata.earth.sm(Kerneldata.earth.sm==0)=[]; Kerneldata.earth.sm=1./Kerneldata.earth.sm;
    Kerneldata.earth.dm       = res(1,:); Kerneldata.earth.dm(Kerneldata.earth.dm==0)=[];
    
    
    if ~isempty(Kerneldata.earth.dm)
         Kerneldata.earth.sm = [Kerneldata.earth.sm 1./10000];
    end   
    
    gamma                   =  +0.267518;
    Kerneldata.earth.f     =  -freq;
    Kerneldata.earth.w_rf  =  -freq*2*pi;
    Kerneldata.earth.erdt  =  abs(Kerneldata.earth.w_rf/gamma);
    Kerneldata.earth.inkl  =  inkl;
    Kerneldata.mes_conf    =  shape;
