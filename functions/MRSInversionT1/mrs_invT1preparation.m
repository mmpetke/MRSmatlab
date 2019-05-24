function idata = mrs_invT1preparation(idata)

gatedt   = idata.data(1).effDead;
Ngates   = 50;
dataType = 2; % 1: amplitudes, 2: rotated

%% data preparation
% loop for all tau
for itau=1:length(idata.tau)
    % 1. delete any frequency offset
    for m = 1:size(idata.data(itau).dcubeRaw,1)
        dcube(m,:) = mrs_rotate(idata.data(itau).dcubeRaw(m,:),...
                                idata.data(itau).tRaw,...
                                0,...
                                idata.data(itau).df(m));
    end
    idata.data(itau).dcube = dcube; dcube=[];
    idata.data(itau).t     = idata.data(itau).tRaw;

    %2. gateIntegration      
    for m = 1:size(idata.data(itau).dcube,1)
        Ngates                 = min(Ngates,length(idata.data(itau).t));
        [realTemp,dummy]       = mrs_GateIntegration(real(idata.data(itau).dcube(m,:)),...
                                               idata.data(itau).t,...
                                               Ngates,gatedt);
        [imagTemp,gateT,gateL] = mrs_GateIntegration(imag(idata.data(itau).dcube(m,:)),...
                                               idata.data(itau).t,...
                                               Ngates,gatedt);
        dcube(m,:) = complex(realTemp,imagTemp);    
    end
    idata.data(itau).dcube  = dcube; dcube=[];
    idata.data(itau).t      = gateT;
    idata.data(itau).gateL  = gateL;
    idata.data(itau).ecube  = repmat(idata.data(itau).estack,1,size(idata.data(itau).dcube,2))./...
                              repmat(sqrt(gateL*1.0),size(idata.data(itau).dcube,1),1);
    
    idata.data(itau).e      = reshape(idata.data(itau).ecube,...
                                      size(idata.data(itau).dcube,1)*length(idata.data(itau).t),1);
                           
    % 3. select data type
    switch dataType
        case 1
            idata.inv1DT1.data(itau).d  = reshape(abs(idata.data(itau).dcube),length(idata.inv1DT1.data(itau).q1)*length(idata.inv1DT1.data(itau).t),1);                       
        case 2
            for m = 1:size(idata.data(itau).dcube,1)
                idata.data(itau).dcube(m,:) = mrs_rotate(idata.data(itau).dcube(m,:),...
                                                     idata.data(itau).t,...
                                                     idata.data(itau).phi(m),...
                                                     0);
            end
            idata.inv1DT1.data(itau).d = reshape(real(idata.data(itau).dcube),size(idata.data(itau).dcube,1)*length(idata.data(itau).t),1);
    end
end


% prepare model
idata.inv1DT1.z     = idata.kernel.model.z;
switch idata.para.modelspace  
    case 1
        whichModel=1;
        idata.inv1DT1.w     = interp1(idata.inv1Dqt.smoothMono.z, idata.inv1Dqt.smoothMono.solution(whichModel).w, idata.inv1DT1.z ,'linear','extrap').';
        idata.inv1DT1.T2    = interp1(idata.inv1Dqt.smoothMono.z, idata.inv1Dqt.smoothMono.solution(whichModel).T2, idata.inv1DT1.z ,'linear','extrap').';
    case 2
        %%
        idata.inv1DT1.w                           = layerToSmooth(idata.inv1Dqt.blockMono.solution(1).w,idata.inv1Dqt.blockMono.solution(1).thk,idata.inv1DT1.z);
        [idata.inv1DT1.T2,idata.inv1DT1.zblockI]  = layerToSmooth(idata.inv1Dqt.blockMono.solution(1).T2,idata.inv1Dqt.blockMono.solution(1).thk,idata.inv1DT1.z);
        
%         idata.inv1DT1.w      = zeros(length(idata.inv1DT1.z),1);
%         idata.inv1DT1.T2     = zeros(length(idata.inv1DT1.z),1);
%         idata.inv1DT1.zLayer = 1e-2*floor([0 cumsum(idata.inv1Dqt.blockMono.solution(1).thk) max(idata.inv1Dqt.blockMono.z)]*1e2);
%         idata.inv1DT1.zblock = 1e-2*floor(cumsum(idata.inv1Dqt.blockMono.solution(1).thk)*1e2);
%         for ilayer = 1:length(idata.inv1Dqt.blockMono.solution(1).thk)
%             inthislayer                    = find(idata.inv1DT1.zLayer(ilayer) <= idata.inv1DT1.z & idata.inv1DT1.z < idata.inv1DT1.zLayer(ilayer+1));
%             idata.inv1DT1.w(inthislayer)   = idata.inv1Dqt.blockMono.solution(1).w(ilayer);
%             idata.inv1DT1.T2(inthislayer)  = idata.inv1Dqt.blockMono.solution(1).T2(ilayer);
%             idata.inv1DT1.zblockI(ilayer)  = inthislayer(end);
%         end
%         idata.inv1DT1.w(idata.inv1DT1.zblockI(end)+1:end)  = idata.inv1Dqt.blockMono.solution(1).w(end);
%         idata.inv1DT1.T2(idata.inv1DT1.zblockI(end)+1:end) = idata.inv1Dqt.blockMono.solution(1).T2(end);

        
%         T2    = [idata.inv1Dqt.blockMono.solution(1).T2(1) idata.inv1Dqt.blockMono.solution(1).T2];
%         W     = [idata.inv1Dqt.blockMono.solution(1).w(1) idata.inv1Dqt.blockMono.solution(1).w];
%         Depth = [0 cumsum(idata.inv1Dqt.blockMono.solution(1).thk) max(idata.inv1Dqt.blockMono.z)];
%         [T2z,z] = stairs(T2,Depth);
%         [Wz,z]  = stairs(W,Depth);
%         z(2:2:end)=z(2:2:end)+1e-10;
%         %z = cumsum(idata.inv1Dqt.blockMono.solution(1).thk);
%         idata.inv1DT1.w      = interp1(z, Wz, idata.inv1DT1.z ,'linear','extrap').';
%         idata.inv1DT1.T2     = interp1(z, T2z, idata.inv1DT1.z ,'linear','extrap').'; 
%         idata.inv1DT1.zblock = cumsum(idata.inv1Dqt.blockMono.solution(1).thk);
%         idata.inv1DT1.zblockI=[];
%         for nb=1:length(idata.inv1DT1.zblock)
%             idata.inv1DT1.zblockI(nb) = find(idata.inv1DT1.z < idata.inv1DT1.zblock(nb),1,'last');
%         end
%         %idata.inv1DT1.T1block    = .5*ones(size(idata.inv1Dqt.blockMono.solution(1).T2)).';
end

