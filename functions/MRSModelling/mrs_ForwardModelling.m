function mdata = mrs_ForwardModelling(mdata,kdata)

mdata.dat.fid1=[];
mdata.dat.fid1_rot=[];
mdata.dat.fid2=[];
mdata.dat.fid2_rot=[];

fi   = zeros(length(kdata.model.z),1);
T2si = zeros(length(kdata.model.z),1);
T1i  = zeros(length(kdata.model.z),1);
for ilayer = 1:mdata.mod.Nlayer
    inthislayer       = find(mdata.mod.zlayer(ilayer) <= kdata.model.z & kdata.model.z < mdata.mod.zlayer(ilayer+1));
    fi(inthislayer)   = mdata.mod.f(ilayer);
    T2si(inthislayer) = mdata.mod.T2s(ilayer);
    T1i(inthislayer)  = mdata.mod.T1(ilayer);
end
fi(end)   = mdata.mod.f(end);
T2si(end) = mdata.mod.T2s(end);
T1i(end)  = mdata.mod.T1(end);

switch kdata.measure.pulsesequence
    case 1 %'FID'
        ft = zeros(length(kdata.model.z), length(mdata.mod.tfid1));
        for m = 1:length(kdata.model.z)
            ft(m,:) = fi(m) * exp(-mdata.mod.tfid1./T2si(m));
        end
        mdata.dat.v0     = kdata.K * fi;
        mdata.dat.fid1   = kdata.K * ft;
        mdata.dat.fid1   = mdata.dat.fid1 + complex(mdata.mod.noise*randn(size(mdata.dat.fid1)),...
                           mdata.mod.noise*randn(size(mdata.dat.fid1)));
    case 2%'T1'
        % fid1
        % restrict length to tau
        mdata.mod.tfid1(mdata.mod.tfid1 > mdata.mod.ctau)=[];
        ft = zeros(length(kdata.model.z), length(mdata.mod.tfid1));
        for m = 1:length(kdata.model.z)
            ft(m,:) = fi(m) * exp(-mdata.mod.tfid1./T2si(m));
        end
        mdata.dat.v0     = kdata.K * fi;
        mdata.dat.fid1   = kdata.K * ft;
        mdata.dat.fid1   = mdata.dat.fid1 + complex(mdata.mod.noise*randn(size(mdata.dat.fid1)),...
                           mdata.mod.noise*randn(size(mdata.dat.fid1)));

        % fid2
        ft = zeros(length(kdata.model.z), length(mdata.mod.tfid2));
        for m = 1:length(kdata.model.z)
            ft(m,:) = fi(m) * exp(-mdata.mod.tfid2./T2si(m));
        end
        mdata.dat.v0fid2   = kdata.KT1 * fi;
        mdata.dat.fid2   = kdata.KT1 * ft;
        mdata.dat.fid2   = mdata.dat.fid2 + complex(mdata.mod.noise*randn(size(mdata.dat.fid2)),...
                           mdata.mod.noise*randn(size(mdata.dat.fid2)));
    case 3%'T2'
        ft        = zeros(length(kdata.model.z), length(mdata.mod.tfid1));
        echotimes = mdata.mod.tau;
        nE        = numel(echotimes);
        for m = 1:length(kdata.model.z)
            for iE=1:nE
                t_echo  = mdata.mod.tfid1 - echotimes(iE) - mdata.mod.tfid1(1);
                ft(m,:) = max(ft(m,:),fi(m) * exp(-echotimes(iE)/T1i(m)).*exp(-(t_echo.^2)/T2si(m)^2));
            end
        end
        mdata.dat.v0     = kdata.K * fi;
        mdata.dat.fid1   = kdata.K * ft;
        mdata.dat.fid1   = mdata.dat.fid1 + complex(mdata.mod.noise*randn(size(mdata.dat.fid1)),...
                           mdata.mod.noise*randn(size(mdata.dat.fid1)));
end

switch kdata.measure.pulsesequence
    case 1% 'FID'
        % fitting fid1
        for m = 1:length(kdata.measure.pm_vec)
            lb  = [1e-10 1e-3  -0.01 -2*pi];
            ub  = [1e-5  1     +0.01  2*pi];
            ini = [1e-7  0.2   0       0];
            
            s = mrs_fitFID(mdata.mod.tfid1-mdata.mod.tfid1(1),mdata.dat.fid1(m,:),lb,ini,ub);
            mdata.dat.V0fit(m)  = [complex(s(1)*cos(s(4)),s(1)*sin(s(4)))];
            mdata.dat.T2sfit(m) = s(2);
            
        end
    case 2%'T1'
        % fitting fid1
        for m = 1:length(kdata.measure.pm_vec)
            lb  = [1e-10 1e-3  -0.01 -2*pi];
            ub  = [1e-5  1     +0.01  2*pi];
            ini = [1e-7  0.2   0       0];
            
            s = mrs_fitFID(mdata.mod.tfid1-mdata.mod.tfid1(1),mdata.dat.fid1(m,:),lb,ini,ub);
            mdata.dat.V0fit(m)  = [complex(s(1)*cos(s(4)),s(1)*sin(s(4)))];
            mdata.dat.T2sfit(m) = s(2);
            
        end
        % fitting fid2
        for m = 1:length(kdata.measure.pm_vec)
            lb  = [1e-11 1e-3  -0.01 -pi];
            ub  = [1e-5  1     +0.01  pi];
            ini = [1e-7  0.5   0       0];
            
            s = mrs_fitFID(mdata.mod.tfid2-mdata.mod.tfid2(1),mdata.dat.fid2(m,:),lb,ini,ub);
            mdata.dat.V0fid2fit(m)  = [complex(s(1)*cos(s(4)),s(1)*sin(s(4)))];
            mdata.dat.T2sfid2fit(m) = s(2);
            
        end
    case 3% 'T2'
        mdata.dat.V0echofit  = []; % all echo
        mdata.dat.V_fit      = [];
        t                    = mdata.mod.tfid1 - mdata.mod.tfid1(1);
        for m = 1:length(kdata.measure.pm_vec)
            nE=length(echotimes);
            %   t2s n-times amplitude (one for each echo)
            lb_echo  = [0.01  1e-11*zeros(1,nE)];
            ini_echo = [0.10  1e-7*ones(1,nE)];
            ub_echo  = [1.00  1e-5*ones(1,nE)];
            
            [f,s] = mrs_fitEchoTrain(t,mdata.dat.fid1(m,:),echotimes,lb_echo,ini_echo,ub_echo);
            
            mdata.dat.V0fit(m)        = f(2); % first echo
            mdata.dat.V0echofit(:,m)  = f(2:end); % all echo
            mdata.dat.V_fit(:,m)      = s;
            mdata.dat.T2sfit(m)       = f(1); % T2s
            
        end
end







