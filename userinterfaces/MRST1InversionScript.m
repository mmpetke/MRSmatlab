clear all;

%% load all data
% load projectfile
path = '/home/mmpetke/work/data/bhpbillitonAustralia/';
projectfile = 'MineDeWatering.mrsp';
load([path projectfile],'-mat');

% load data
for nD=1:length(mrsproject.data)
    load([path mrsproject.data(nD).dir filesep mrsproject.data(nD).file], '-mat');

    idata.data.tau(nD)   = proclog.Q(1).timing.tau_d;
    idata.data.q         = zeros(length(proclog.Q),1);
    idata.data.tRaw      = proclog.Q(1).rx(1).sig(3).t;
    idata.data.effDead   = proclog.Q(1).timing.tau_dead1 +  0.5*proclog.Q(1).timing.tau_p1;
        
    for m = 1:length(proclog.Q)
        idata.data.dcubeRaw((nD-1)*length(proclog.Q) + m,:) = proclog.Q(m).rx(1).sig(3).V;
    end
end

% load kernel
load([path mrsproject.data(1).dir filesep mrsproject.kernel(1).file], '-mat');

% load qt inversion for water content and decay model
tmp = load([path mrsproject.data(5).dir filesep 'MineDeWateringTau10s.mrsi'], '-mat');
idata.inv1Dqt = tmp.idata.inv1Dqt;
clear tmp;

%% preparation
% prepare data
for iqtau=1:size(idata.data.dcubeRaw,1)
       [d(iqtau,:),idata.data.t] = mrs_GateIntegration(abs(idata.data.dcubeRaw(iqtau,:)),...
            idata.data.tRaw,...
            50);
end
idata.inv1DT1.d=[];
for itau=1:length(idata.data.tau)
    idata.inv1DT1.d = [idata.inv1DT1.d(:); reshape(d(1+(itau-1)*length(idata.data.q):itau*length(idata.data.q),:),...
                                                   length(idata.data.q)*length(idata.data.t),1)];
end

% prepare model
M         = reshape(idata.inv1Dqt.solution.m_est,length(idata.inv1Dqt.z),length(idata.inv1Dqt.decaySpecVec));
decaycube = repmat(idata.inv1Dqt.decaySpecVec,size(M,1),1);

idata.inv1DT1.z     = kdata.model.z;
idata.inv1DT1.wQT   = interp1(idata.inv1Dqt.z, sum(M,2), idata.inv1DT1.z ,'linear','extrap');
idata.inv1DT1.T2sQT = interp1(exp(sum(M.*log(decaycube),2)./sum(M,2)), idata.inv1DT1.z ,'linear','extrap');
idata.inv1DT1.T1    = .5*ones(size(idata.inv1DT1.z));

%% configure for initial model
kdata.earth.T1   = idata.inv1DT1.T1;
kdata.earth.type = 2;
kdata.earth.taud = idata.data.tau;
% calculate the kernel for T1
[kdata.KT1TauAll, kdata.JT1TauAll]  = MakeKernelT1(kdata.loop, ...
    kdata.model, ...
    kdata.measure, ...
    kdata.earth,...
    kdata.B1);

% prepare kernel
% number of tau
ntau = length(idata.data.tau);
% number of pulses
nq  = length(idata.data.q);
% number of time steps
nt  = length(idata.data.t);
% number of layers
nz  = length(idata.inv1DT1.z);    

idata.inv1DT1.g=[];idata.inv1DT1.j=[];
for itau=1:ntau
    g                       = kdata.KT1TauAll((itau-1)*nq+1:itau*nq,:);
    j                       = kdata.JT1TauAll((itau-1)*nq+1:itau*nq,:);    
    [m,n]                   = meshgrid(reshape(repmat(idata.data.t,nq,1),1,nq*nt),idata.inv1DT1.T2sQT);
    expM                    = exp(-m./n).';
    idata.inv1DT1.g         = [idata.inv1DT1.g; repmat(g,nt,1).*expM]; % for forward calc.
    idata.inv1DT1.j         = [idata.inv1DT1.j; repmat(j,nt,1).*expM]; % for jacobian
end
G = AmplitudeJacobian(idata.inv1DT1.g,idata.inv1DT1.wQT(:));
% forward
d_est  = G*idata.inv1DT1.wQT(:);

%% plotting
clf;
subplot(2,1,1)
    plot(idata.inv1DT1.d);hold on;plot(d_est,'r')
    title(num2str(norm(idata.inv1DT1.d-d_est)/sqrt(length(d_est))*1e9))
subplot(2,3,4)
    plot(idata.inv1DT1.wQT,idata.inv1DT1.z);axis ij;grid on
subplot(2,3,5)
    plot(idata.inv1DT1.T2sQT,idata.inv1DT1.z);axis ij;grid on
subplot(2,3,6)
    plot(idata.inv1DT1.T1,idata.inv1DT1.z);axis ij;grid on
    drawnow
%% iterative inversion
for iterate=1:10
    % jacobian
    % derivation with respect to T1
    T1M     = repmat(repmat(idata.inv1DT1.T1,nq*nt,1),ntau,1);
    taudM   = kron(idata.data.tau,ones(nz,nq*nt)).';
    dT1M    = -taudM./(T1M.^2);
    wM      = repmat(repmat(idata.inv1DT1.wQT,nq*nt,1),ntau,1);
    J       = AmplitudeJacobian(idata.inv1DT1.j,idata.inv1DT1.wQT(:)).*wM.*dT1M;
    
    % data
    dD = idata.inv1DT1.d - d_est;
    
    % model update
    L = get_l(nz,1);
    idata.inv1DT1.T1 = idata.inv1DT1.T1 + (inv(J'*J + 1e-9*L'*L)*J'*dD).';
    
    % get new kernel
    kdata.earth.T1   = idata.inv1DT1.T1;
    [kdata.KT1TauAll, kdata.JT1TauAll]  = MakeKernelT1(kdata.loop, ...
        kdata.model, ...
        kdata.measure, ...
        kdata.earth,...
        kdata.B1);
    
    % prepare for forward modeling
    idata.inv1DT1.g=[];idata.inv1DT1.j=[];
    for itau=1:ntau
        g                       = kdata.KT1TauAll((itau-1)*nq+1:itau*nq,:);
        j                       = kdata.JT1TauAll((itau-1)*nq+1:itau*nq,:);
        [m,n]                   = meshgrid(reshape(repmat(idata.data.t,nq,1),1,nq*nt),idata.inv1DT1.T2sQT);
        expM                    = exp(-m./n).';
        idata.inv1DT1.g         = [idata.inv1DT1.g; repmat(g,nt,1).*expM]; % for forward calc.
        idata.inv1DT1.j         = [idata.inv1DT1.j; repmat(j,nt,1).*expM]; % for jacobian
    end
    G = AmplitudeJacobian(idata.inv1DT1.g,idata.inv1DT1.wQT(:));
    % forward modeling
    d_est  = G*idata.inv1DT1.wQT(:);
    
    % plotting
    clf;
    subplot(2,1,1)
        plot(idata.inv1DT1.d);hold on;plot(d_est,'r')
        title(num2str(norm(idata.inv1DT1.d-d_est)/sqrt(length(d_est))*1e9))
    subplot(2,3,4)
        plot(idata.inv1DT1.wQT,idata.inv1DT1.z);axis ij;grid on
    subplot(2,3,5)
        plot(idata.inv1DT1.T2sQT,idata.inv1DT1.z);axis ij;grid on
    subplot(2,3,6)
        plot(idata.inv1DT1.T1,idata.inv1DT1.z);axis ij;grid on
    drawnow
end









