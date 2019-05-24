%% FUNCTION loadData
function idata = loadMRST1Data(mrsproject,idata)
% sort tau to be increasing
for iS = 1:length(mrsproject.data)
    load([mrsproject.path mrsproject.data(iS).dir filesep mrsproject.data(iS).file], '-mat');
    tau(iS) = proclog.Q(1).timing.tau_p1 + proclog.Q(1).timing.tau_d;
end

[a,b] = sort(tau);
c     = 1;

for iS = b
    in = load([mrsproject.path mrsproject.data(iS).dir filesep mrsproject.data(iS).file], '-mat');
    proclog = in.proclog; 
    
    idata.tau(c)            = proclog.Q(1).timing.tau_p1 + proclog.Q(1).timing.tau_d;
    idata.data(c).q1        = zeros(length(proclog.Q),1);
    idata.data(c).q2        = zeros(length(proclog.Q),1);
    idata.data(c).efit      = zeros(length(proclog.Q),1);
    idata.data(c).estack    = zeros(length(proclog.Q),1);
    idata.data(c).V0fit     = zeros(length(proclog.Q),1);
    idata.data(c).T2sfit    = zeros(length(proclog.Q),1);
    idata.data(c).df        = zeros(length(proclog.Q),1);
    idata.data(c).phi       = zeros(length(proclog.Q),1);
    % check if there has been trim during fit and get indices
    [minRecInd, maxRecInd]  = mrs_gettrim(proclog,1,1,3);
    idata.data(c).dcubeRaw  = zeros(length(proclog.Q),length(proclog.Q(1).rx(1).sig(3).t(minRecInd:maxRecInd)));
    % tRaw should start with zero
    idata.data(c).tRaw      = proclog.Q(1).rx(1).sig(3).t(minRecInd:maxRecInd) - proclog.Q(1).rx(1).sig(3).t(minRecInd);
    % effective dead time should include all (hardware deadtime + RDP + trim)
    idata.data(c).effDead   = proclog.Q(1).timing.tau_dead1  + ...
                              0.5*proclog.Q(1).timing.tau_p1 + ...
                              proclog.Q(1).rx(1).sig(3).t(minRecInd);
                          
    if c == length(b) % largest tau to get data for tau --> infinity
        idata.tau(c+1)            = 100;
        idata.data(c+1).q1        = zeros(length(proclog.Q),1);
        idata.data(c+1).q2        = zeros(length(proclog.Q),1);
        idata.data(c+1).efit      = zeros(length(proclog.Q),1);
        idata.data(c+1).estack    = zeros(length(proclog.Q),1);
        idata.data(c+1).V0fit     = zeros(length(proclog.Q),1);
        idata.data(c+1).T2sfit    = zeros(length(proclog.Q),1);
        idata.data(c+1).df        = zeros(length(proclog.Q),1);
        idata.data(c+1).phi       = zeros(length(proclog.Q),1);
        % check if there has been trim during fit and get indices
        [minRecInd, maxRecInd]  = mrs_gettrim(proclog,1,1,2);
        idata.data(c+1).dcubeRaw  = zeros(length(proclog.Q),length(proclog.Q(1).rx(1).sig(2).t(minRecInd:maxRecInd)));
        % tRaw shold start with zero
        idata.data(c+1).tRaw      = proclog.Q(1).rx(1).sig(2).t(minRecInd:maxRecInd) - proclog.Q(1).rx(1).sig(2).t(minRecInd);
        % effective dead time should include all (hardware deadtime + RDP + trim)
        idata.data(c+1).effDead   = proclog.Q(1).timing.tau_dead1  + ...
                                    0.5*proclog.Q(1).timing.tau_p1 + ...
                                    proclog.Q(1).rx(1).sig(2).t(minRecInd);
    end
    
    for m = 1:length(proclog.Q)
        idata.data(c).q1(m)      = proclog.Q(m).q;
        idata.data(c).q2(m)      = proclog.Q(m).q2;
        % error estimation using the mono-fit (mrs_fitFID.m)
        idata.data(c).efit(m)    = proclog.Q(m).rx(1).sig(3).fite.E;
        % error estimation using stacking (mrsSigPro_stack.m)
        idata.data(c).estack(m)  = real(mean(proclog.Q(m).rx(1).sig(3).E));
        idata.data(c).V0fit(m)   = proclog.Q(m).rx(1).sig(3).fitc(1);
        idata.data(c).T2sfit(m)  = proclog.Q(m).rx(1).sig(3).fitc(2);
        idata.data(c).df(m)      = proclog.Q(m).rx(1).sig(3).fitc(3);
        idata.data(c).phi(m)     = proclog.Q(m).rx(1).sig(3).fit(4);
        [minRecInd, maxRecInd]   = mrs_gettrim(proclog,1,1,3);
        idata.data(c).dcubeRaw(m,:) = proclog.Q(m).rx(1).sig(3).V(minRecInd:maxRecInd);
        
        if c == length(b) % largest tau to get data for tau --> infinity
            idata.data(c+1).q1(m)      = proclog.Q(m).q;
            idata.data(c+1).q2(m)      = proclog.Q(m).q2;
            % error estimation using the mono-fit (mrs_fitFID.m)
            idata.data(c+1).efit(m)    = proclog.Q(m).rx(1).sig(2).fite.E;
            % error estimation using stacking (mrsSigPro_stack.m)
            idata.data(c+1).estack(m)  = real(mean(proclog.Q(m).rx(1).sig(2).E));
            idata.data(c+1).V0fit(m)   = proclog.Q(m).rx(1).sig(2).fitc(1);
            idata.data(c+1).T2sfit(m)  = proclog.Q(m).rx(1).sig(2).fitc(2);
            idata.data(c+1).df(m)      = proclog.Q(m).rx(1).sig(2).fitc(3);
            idata.data(c+1).phi(m)     = proclog.Q(m).rx(1).sig(2).fit(4);
            [minRecInd, maxRecInd]     = mrs_gettrim(proclog,1,1,2);
            idata.data(c+1).dcubeRaw(m,:) = proclog.Q(m).rx(1).sig(2).V(minRecInd:maxRecInd);
        end
    end
    
    c = c+1;
end

