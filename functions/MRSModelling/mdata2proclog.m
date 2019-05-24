function proclog = mdata2proclog(mdata,kdata) 

proclog.MRSversion = mrs_version;
proclog.path       = [];
proclog.device     = 'MRSModelling';
proclog.rxinfo.channel   = 1;
proclog.rxinfo.looptype  = kdata.loop(1).shape;
proclog.rxinfo.loopsize  = kdata.loop(1).size;
proclog.rxinfo.loopturns = kdata.loop(1).turns;
proclog.txinfo.channel   = 1;
proclog.txinfo.looptype  = kdata.loop(1).shape;
proclog.txinfo.loopsize  = kdata.loop(1).size;
proclog.txinfo.loopturns = kdata.loop(1).turns;

proclog.status         =  3; % 0 rawdata, 1 processed 3 fitted
proclog.LPfilter.coeff = -1; % Filter characteristics for QD; made in initialize_proclog
proclog.event(1,1:8)   = 0;  % (ID,1:8)  row: ID; columns: type|Q|rec|rx|sig|A|B|C
                             % initialize 1st entry as zeros, as in SigPro

for pm=1:length(kdata.measure.pm_vec)
    proclog.Q(pm).q     = kdata.measure.pm_vec(pm);
    proclog.Q(pm).q2    = kdata.measure.pm_vec(pm);
    proclog.Q(pm).phi12 = 0;
    
    proclog.Q(pm).timing.tau_p1 = 0;
    proclog.Q(pm).timing.tau_dead1 = mdata.mod.tfid1(1);
    
    proclog.Q(pm).fT =  kdata.earth.w_rf/2/pi; %transmitter frequency (may change for Q if files are merged)
    proclog.Q(pm).fS =  1/diff(mdata.mod.tfid1(1:2));% sampling frequency
    
    switch kdata.measure.pulsesequence
        case 1% 'FID'
            proclog.Q(pm).rx(1).connected = 1;
            proclog.Q(pm).rx(1).sig(1).recorded = 1; % noise record
            proclog.Q(pm).rx(1).sig(1).V    = complex(mdata.mod.noise*randn(size(mdata.mod.tfid1)),mdata.mod.noise*randn(size(mdata.mod.tfid1)));
            proclog.Q(pm).rx(1).sig(1).t    = mdata.mod.tfid1 - mdata.mod.tfid1(1);

            proclog.Q(pm).rx(1).sig(2).recorded = 1; % FID1 record
            proclog.Q(pm).rx(1).sig(2).V    = mdata.dat.fid1(pm,:);
            proclog.Q(pm).rx(1).sig(2).t    = mdata.mod.tfid1 - mdata.mod.tfid1(1);
            proclog.Q(pm).rx(1).sig(2).ini  = [1e-7   0.2  0      0];
            proclog.Q(pm).rx(1).sig(2).lb   = [1e-12 1e-3  -0.1 -pi];
            proclog.Q(pm).rx(1).sig(2).ub   = [1e-4     3  +0.1  pi];
            proclog.Q(pm).rx(1).sig(2).fitc = [abs(mdata.dat.V0fit(pm))*exp(proclog.Q(pm).timing.tau_dead1/mdata.dat.T2sfit(pm)) mdata.dat.T2sfit(pm) 0 angle(mdata.dat.V0fit(pm))];
            proclog.Q(pm).rx(1).sig(2).fit  = [abs(mdata.dat.V0fit(pm)) mdata.dat.T2sfit(pm) 0 angle(mdata.dat.V0fit(pm))];
            proclog.Q(pm).rx(1).sig(2).fite.E  = mdata.mod.noise;
            proclog.Q(pm).rx(1).sig(2).E    = mdata.mod.noise.*complex(ones(size(mdata.mod.tfid1)),ones(size(mdata.mod.tfid1)));

            proclog.Q(pm).rx(1).sig(3).recorded = 0; % FID2 record
            proclog.Q(pm).rx(1).sig(4).recorded = 0; % T2 record
            
        case 2%'T1'
            proclog.Q(pm).timing.tau_d  = mdata.mod.ctau;        % delay time (time between end of pulse1 and start of pulse2)
            proclog.Q(pm).timing.tau_p2 = 0;                     % duration of 2nd pulse
            proclog.Q(pm).timing.tau_dead2 = mdata.mod.tfid2(1); % dead time2 (time between end of pulse2 and start of sig2)

            proclog.Q(pm).rx(1).connected = 1;
            proclog.Q(pm).rx(1).sig(1).recorded = 1; % noise record
            proclog.Q(pm).rx(1).sig(1).V    = complex(mdata.mod.noise*randn(size(mdata.mod.tfid1)),mdata.mod.noise*randn(size(mdata.mod.tfid1)));
            proclog.Q(pm).rx(1).sig(1).t    = mdata.mod.tfid1 - mdata.mod.tfid1(1);

            proclog.Q(pm).rx(1).sig(2).recorded = 1; % FID1 record
            proclog.Q(pm).rx(1).sig(2).V    = mdata.dat.fid1(pm,:);
            proclog.Q(pm).rx(1).sig(2).t    = mdata.mod.tfid1 - mdata.mod.tfid1(1);
            proclog.Q(pm).rx(1).sig(2).ini  = [1e-7   0.2  0      0];
            proclog.Q(pm).rx(1).sig(2).lb   = [1e-12 1e-3  -0.1 -pi];
            proclog.Q(pm).rx(1).sig(2).ub   = [1e-4     3  +0.1  pi];
            proclog.Q(pm).rx(1).sig(2).fitc = [abs(mdata.dat.V0fit(pm))*exp(proclog.Q(pm).timing.tau_dead1/mdata.dat.T2sfit(pm)) mdata.dat.T2sfit(pm) 0 angle(mdata.dat.V0fit(pm))];
            proclog.Q(pm).rx(1).sig(2).fit  = [abs(mdata.dat.V0fit(pm)) mdata.dat.T2sfit(pm) 0 angle(mdata.dat.V0fit(pm))];
            proclog.Q(pm).rx(1).sig(2).fite.E  = mdata.mod.noise;
            proclog.Q(pm).rx(1).sig(2).E    = mdata.mod.noise.*complex(ones(size(mdata.mod.tfid1)),ones(size(mdata.mod.tfid1)));
            
            proclog.Q(pm).rx(1).sig(3).recorded = 1; % FID2 record
            proclog.Q(pm).rx(1).sig(3).V    = mdata.dat.fid2(pm,:);
            proclog.Q(pm).rx(1).sig(3).t    = mdata.mod.tfid2 - mdata.mod.tfid2(1);
            proclog.Q(pm).rx(1).sig(3).ini  = [1e-7   0.2  0   0];
            proclog.Q(pm).rx(1).sig(3).lb   = [1e-12 1e-3  -0.1 -pi];
            proclog.Q(pm).rx(1).sig(3).ub   = [1e-4     3  +0.1  pi];
            proclog.Q(pm).rx(1).sig(3).fitc = [abs(mdata.dat.V0fid2fit(pm))*exp(proclog.Q(pm).timing.tau_dead2/mdata.dat.T2sfid2fit(pm)) mdata.dat.T2sfid2fit(pm) 0 angle(mdata.dat.V0fid2fit(pm))];
            proclog.Q(pm).rx(1).sig(3).fit  = [abs(mdata.dat.V0fid2fit(pm)) mdata.dat.T2sfid2fit(pm) 0 angle(mdata.dat.V0fid2fit(pm))];
            proclog.Q(pm).rx(1).sig(3).fite.E  = mdata.mod.noise;
            proclog.Q(pm).rx(1).sig(3).E    = mdata.mod.noise.*complex(ones(size(mdata.mod.tfid1)),ones(size(mdata.mod.tfid1)));

            proclog.Q(pm).rx(1).sig(4).recorded = 0; % T2 record
            
        case 3%'T2'
            proclog.Q(pm).timing.tau_e     = 0;        % echotimes saved in proclog.Q(pm).rx(1).sig(4).echotimes
            proclog.Q(pm).timing.tau_p2    = 0;                  
            proclog.Q(pm).timing.tau_dead2 = 0; % 

            proclog.Q(pm).rx(1).sig(2).recorded = 1; % FID1 record NOT FOR USE JUST FOR COMPATIBILITY!!!
            proclog.Q(pm).rx(1).sig(2).V    = 0*mdata.dat.fid1(pm,:);
            proclog.Q(pm).rx(1).sig(2).t    = mdata.mod.tfid1 - mdata.mod.tfid1(1);
            proclog.Q(pm).rx(1).sig(2).ini  = [1e-7   0.2  0      0];
            proclog.Q(pm).rx(1).sig(2).lb   = [1e-12 1e-3  -0.1 -pi];
            proclog.Q(pm).rx(1).sig(2).ub   = [1e-4     3  +0.1  pi];
            proclog.Q(pm).rx(1).sig(2).fitc = [0 0 0 0];
            proclog.Q(pm).rx(1).sig(2).fit  = [0 0 0 0];
            proclog.Q(pm).rx(1).sig(2).fite.E  = 1e-11;
            proclog.Q(pm).rx(1).sig(2).E    = 1e-11.*complex(ones(size(mdata.mod.tfid1)),ones(size(mdata.mod.tfid1)));
            
            proclog.Q(pm).rx(1).sig(3).recorded = 0; % FID2 record
            
            proclog.Q(pm).rx(1).sig(4).recorded = 1; % Echo record
            proclog.Q(pm).rx(1).sig(4).V    = mdata.dat.fid1(pm,:);
            proclog.Q(pm).rx(1).sig(4).t    = mdata.mod.tfid1 - mdata.mod.tfid1(1);
            proclog.Q(pm).rx(1).sig(4).nE   = length(mdata.mod.tau);
            proclog.Q(pm).rx(1).sig(4).echotimes   = mdata.mod.tau;
            proclog.Q(pm).rx(1).sig(4).ini  = [1e-7   0.2  0      0];
            proclog.Q(pm).rx(1).sig(4).lb   = [1e-12 1e-3  -0.1 -pi];
            proclog.Q(pm).rx(1).sig(4).ub   = [1e-4     3  +0.1  pi];
            proclog.Q(pm).rx(1).sig(4).fitc = [0 0 0];
            proclog.Q(pm).rx(1).sig(4).fit  = [mdata.dat.T2sfit(pm); mdata.dat.V0echofit(:,pm)];
            proclog.Q(pm).rx(1).sig(4).V_fit  = mdata.dat.V_fit(:,pm);
            proclog.Q(pm).rx(1).sig(4).fite.E  = mdata.mod.noise;
            proclog.Q(pm).rx(1).sig(4).E    = mdata.mod.noise.*complex(ones(size(mdata.mod.tfid1)),ones(size(mdata.mod.tfid1)));
    end
    
end

