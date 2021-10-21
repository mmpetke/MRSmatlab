%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% default config for cossmo  %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function data = get_defaults()
data.gammaH             = +0.267518*1e9;
data.K                  = [];
data.mes_conf           = 1;

data.loop.shape         = 1; % circ:1 eight:2
data.loop.eightoritn    = 0; % inline:1 normal:2
data.loop.eightsep      = 0; % for 8 only
data.loop.size          = 50; % diameter for circular, side for square
data.loop.turns         = [1 1]; % number of turns [transmitter receiver]
data.loop.rmax          = 300; 
data.loop.dr            = 24;
data.loop.PXsize        = 2;
data.loop.PXshape       = 1;
data.loop.PXcurrent     = 20;
data.loop.PXsign        = 1;
data.loop.PXturns       = 50;
data.loop.PX8dir        = 0;
data.loop.usePXramp     = false;
data.loop.PXramp        = 'none';
data.loop.PXramptime    = 1e-3; % [s]

data.earth.inkl         = 68;
data.earth.decl         = 0;
data.earth.erdt         = 48000*1e-9;
data.earth.f            = data.gammaH*data.earth.erdt/(2*pi);
data.earth.w_rf         = data.gammaH*data.earth.erdt;
data.earth.res          = 0; % 1: earth is a insolator, i.e. any conductivity is ignored; 0 - consider conductivity 
data.earth.nl           = 1;
data.earth.zm           = []; % Depth
data.earth.sm		    = 0.01; % Conductivity
data.earth.fm		    = 1.00; % Water content
data.earth.temp         = 281; % aquifer temperature
data.earth.type         = 1; % 1: single pulse; 2: double pulse kernel; 3: single-pulse df kernel

data.model.dh           =        1;   %
data.model.dphi         = 1*pi/180;   % for pol cordinates   [deg]
data.model.zmax         = 1.5*data.loop.size;   % for both             [m]
data.model.z_space      =        1;   % log:1 lin:2
data.model.dz           =        1;   % layer thickness, thickness of first layer for log
data.model.nz           =       72; 
data.model.sinh_zmin    =  data.loop.size/500;
data.model.zlogmin      =        1;
data.model.zlogmax      =       10;
% data.model.hmaxx        =      150;
% data.model.hmaxy        =      100;
data.model.hmaxx        =      200;
data.model.hmaxy        =      200;

data.measure.dim        =        1;   % Dimension of Kernel
data.measure.pm_vec     =       [278 320  436 540 675 830 1049 1250 1460 1760 2106 2458 2925 3391 4004 4677 5473 6273 7155 8148 9281 ...
		10515 11926 13556] / 1000; 
data.measure.pm_vec_2ndpulse =  data.measure.pm_vec; % second pulse pulse moment
data.measure.pulsesequence = 1; % 1 FID, 2 T1, 3 T2
data.measure.pulsetype    = 1; % 1 standard , 2 adiabatic
data.measure.taud         = 1e9; % inter pulse delay for double pulse 
data.measure.taup1        = 0.04; % duration pulse 1
data.measure.taup2        = 0.04; % duration pulse 2
data.measure.df           = 0; % frequency offset [Hz] for standard pulses
data.measure.Imax_vec      = data.measure.pm_vec./data.measure.taup1;   
                            % maximum effective current of pulse moment
                            % replace pm_vec for off-res excitation
data.measure.flag_loadAHP  = 0; % set flag if AHP are loaded to load I(t) of the pulse
data.measure.flag_offres   = 0; % 
data.measure.fmod.shape    = 1; % shape of frq-modulation; 1: const., 2: linear; 3: tanh
data.measure.fmod.startdf  = -300; % frequency offset at start of pulse [Hz]
data.measure.fmod.enddf    = 0; % frequency offset at end of pulse [Hz]
data.measure.fmod.A        = 3; % parameter to describe shape of frq-modulation
data.measure.fmod.B        = 0; % parameter to describe shape of frq-modulation
data.measure.Imod.shape    = 1; % shape of I-modulation; 1: const., 2: linear; 3: tanh
data.measure.Imod.startI   = 1; % norm. current amplitude at start of pulse [Hz]
data.measure.Imod.endI     = 1; % norm. current amplitude at end of pulse [Hz]
data.measure.Imod.A        = 0; % parameter to describe shape of I-modulation
data.measure.Imod.B        = 0; % parameter to describe shape of I-modulation 
data.measure.Imod.flag_Q   = 0; % 
data.measure.Imod.Q        = 10; % quality-factor Q of circuit for I-modulation 
data.measure.Imod.Qdf      = 0; % offset between Eigen-frq of circuit and Larmor Frq
data.measure.Imod.Qf0      = data.earth.f+data.measure.Imod.Qdf; % Eigen-frq of tuned circuit 
data.measure.RDP.flag      = 0; % consider relaxation during pulse: 0: no
data.measure.RDP.T1        = 0; % T1 relaxation during pulse [s]
data.measure.RDP.T2        = 0; % T2 relaxation during pulse [s]
data.measure.PX            = 0; % prepolarisation

return
end