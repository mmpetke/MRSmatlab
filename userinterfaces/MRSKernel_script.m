clear all;

% all parameters set to default
Kernelsetup = get_defaults;



%% ---------modelparameter------------------------
Kernelsetup.loop(1).radius     = 50; % loop radius for circular loop

Kernelsetup.loop(1).turns      = 1; % number of turns
Kernelsetup.loop(2).turns      = 1; % might be different for transmitter and receiver, i.e. tino


% position of the loop. In general transmitter and receiver are calculated
% independent (dependend on Kernelsetup.mes_conf, the field might be copied for coincident case)
Kernelsetup.measure.tx_xpos    = 0; % transmitter x position (x in direction north)
Kernelsetup.measure.tx_ypos    = 0; % transmitter y position 
Kernelsetup.measure.rx_xpos    = 0; % receiver x position (x in direction north)
Kernelsetup.measure.rx_ypos    = 0; % receiver y position 


% vector of pulse moments
%Kernelsetup.measure.pm_vec     = logspace(log10(0.1),log10(15),20);
%Kernelsetup.measure.pm_vec     = linspace(1,10,20);
Kernelsetup.measure.pm_vec     = [0.0114   0.0245    0.0464    0.0767    0.1388    0.2623    0.5076    0.9705   1.5439];

% subsurface resistivity 
Kernelsetup.earth.sm		   = [1/2000 1/100]; % conductivity
Kernelsetup.earth.nl           = 2; % number of layers
Kernelsetup.earth.zm           = [5]; % lower boundary of the layers, for the last one an halfspace is assumed

% parametrisation for B fields
Kernelsetup.loop(1).rmax       = 300;   % rmax has to cover hmax/y area in all cases of loop positions

% model space parametrisation kernel
Kernelsetup.model.zmax         = 200; % maximum depth for kernel function (rule of thumb: 4*loop radius)   
Kernelsetup.model.nz           = 1;   % diskr. in z dimension

Kernelsetup.model.hmax         = 200; % maximum in x/y direction (for coincident set to be equal)
Kernelsetup.model.hmaxx        = 200; % maximum in x direction
Kernelsetup.model.hmaxy        = 200; % maximum in y direction
Kernelsetup.model.dh           = 1;   % diskr. in z dimension


% switch for sounding type
Kernelsetup.mes_conf           = 1;     % 1:coin    2:sep same      3:sep diff      4: eight 
% switch for preintegration, i.e. dimension of the kernel
Kernelsetup.measure.dim        = 1;     % 1:1D  2:2D ...
% if 2D here the direction of preintegration is defined
Kernelsetup.measure.prof_dir   = 0;  % rad, 0 in direction north, i.e. sum over y axis   


% earth field
% Kernelsetup.earth.inkl         = 60;
% Kernelsetup.earth.erdt         = 25910;
% gamma                          = +0.267518;
% Kernelsetup.earth.f            = -gamma*Kernelsetup.earth.erdt/(2*pi);
% Kernelsetup.earth.w_rf         = -gamma*Kernelsetup.earth.erdt;


%% calculate kernel
    
[K,model] = Kernel_run(Kernelsetup.loop, Kernelsetup.measure, Kernelsetup.earth, Kernelsetup.model, Kernelsetup.mes_conf);


%-------- save kernel-----------------------------
Kerneldata.loop     = Kernelsetup.loop;
Kerneldata.model    = model;
Kerneldata.measure  = Kernelsetup.measure;
Kerneldata.earth    = Kernelsetup.earth;
Kerneldata.mes_conf = Kernelsetup.mes_conf;
Kerneldata.K        = K;

    






    