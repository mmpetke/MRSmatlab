function idata = mrs_invQTpreparation(idata)

%% data preparation
% delete any frequency offset
for m = 1:size(idata.data.dcubeRaw,1)
    dcube(m,:) = mrs_rotate(idata.data.dcubeRaw(m,:),...
        idata.data.tRaw,...
        0,...
        idata.data.df(m));
end
idata.data.dcube = dcube; dcube=[];
idata.data.t     = idata.data.tRaw;

% introduce error cube
% idata.data.ecube = mean(idata.data.e)*ones(size(idata.data.dcube));
idata.data.ecube = repmat(idata.data.estack,1,size(idata.data.dcube,2));
idata.data.e     = reshape(idata.data.ecube,size(idata.data.dcube,1)*length(idata.data.t),1);

gatedt=0;
if isfield(idata.para,'gatedt'), gatedt=idata.para.gatedt; end
% reduce to gates
if idata.para.gates
    for m = 1:size(idata.data.dcube,1)
        idata.para.Ngates = min(idata.para.Ngates,length(idata.data.t));
        [realTemp,dummy] = mrs_GateIntegration(real(idata.data.dcube(m,:)),...
            idata.data.t,...
            idata.para.Ngates,gatedt);
        [imagTemp,gateT,gateL] = mrs_GateIntegration(imag(idata.data.dcube(m,:)),...
            idata.data.t,...
            idata.para.Ngates,gatedt);
        dcube(m,:) = complex(realTemp,imagTemp);    
    end
    idata.data.dcube = dcube; dcube=[];
    idata.data.t     = gateT;
    idata.data.gateL = gateL;
    idata.data.ecube = repmat(idata.data.estack,1,size(idata.data.dcube,2))./...
                       repmat(sqrt(gateL*1.0),size(idata.data.dcube,1),1);
    
    idata.data.e     = reshape(idata.data.ecube,size(idata.data.dcube,1)*length(idata.data.t),1);
end

switch idata.para.dataType
    case 1 % amplitudes
        idata.data.d = reshape(abs(idata.data.dcube),size(idata.data.dcube,1)*length(idata.data.t),1);
    case 2 % rotated complex
        for m = 1:size(idata.data.dcube,1)
            idata.data.dcube(m,:) = mrs_rotate(idata.data.dcube(m,:),...
                                                idata.data.t,...
                                                idata.data.phi(m),...
                                                0);
        end
        idata.data.d = reshape(real(idata.data.dcube),size(idata.data.dcube,1)*length(idata.data.t),1);
    case 3 % complex
        %idata.data.dcube = abs(idata.data.dcube).*exp(1i*(angle(idata.data.dcube) - idata.para.instPhase));
        % mmp: implement instrument phase during inversion for the estimated
        % data instead of correcting measured data
        idata.data.d = reshape(idata.data.dcube,size(idata.data.dcube,1)*length(idata.data.t),1);
            
end

%% model preparation
idata.para.decaySpecVec = logspace(log10(idata.para.decaySpecMin),...
                                   log10(idata.para.decaySpecMax),idata.para.decaySpecN);