function idata = loadmymrsd(filename)

%% LOADMRSDFILE
%% load MRS data (MRSD) file into idata struct
%% idata = loadmrsdfile( filename )

load(filename,'-mat');

idata=[];
idata.data.q         = zeros(length(proclog.Q),1);
idata.data.efit      = zeros(length(proclog.Q),1);
idata.data.V0fit     = zeros(length(proclog.Q),1);
idata.data.T2sfit    = zeros(length(proclog.Q),1);
idata.data.df        = zeros(length(proclog.Q),1);
idata.data.phi       = zeros(length(proclog.Q),1);
idata.data.dcubeRaw  = zeros(length(proclog.Q),length(proclog.Q(1).rx(1).sig(2).t));
idata.data.tRaw      = proclog.Q(1).rx(1).sig(2).t;
idata.data.effDead   = proclog.Q(1).timing.tau_dead1 +  0.5*proclog.Q(1).timing.tau_p1;

for m = 1:length(proclog.Q)
    idata.data.q(m)       = proclog.Q(m).q;
    idata.data.efit(m)    = proclog.Q(m).rx(1).sig(2).e.E;
    idata.data.V0fit(m)   = proclog.Q(m).rx(1).sig(2).fitc(1);
    idata.data.T2sfit(m)  = proclog.Q(m).rx(1).sig(2).fitc(2);
    idata.data.df(m)      = proclog.Q(m).rx(1).sig(2).fitc(3);
    idata.data.phi(m)     = proclog.Q(m).rx(1).sig(2).fit(4);
    idata.data.dcubeRaw(m,:) = proclog.Q(m).rx(1).sig(2).V;
end
% default settings
idata.para.dataType=2; % rot ampl.
idata.para.decaySpecMin=0.04;
idata.para.decaySpecMax=1;
idata.para.decaySpecN=30;
idata.para.gates  = 1;
idata.para.Ngates = 50;
