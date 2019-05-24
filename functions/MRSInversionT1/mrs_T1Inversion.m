function  idata = mrs_T1Inversion(idata)

% some more preparation
for itau=1:length(idata.tau)
    idata.inv1DT1.data(itau).q1    = idata.kernel.measure.pm_vec;
    idata.inv1DT1.data(itau).q2    = idata.kernel.measure.pm_vec_2ndpulse;
    nq                             = length(idata.inv1DT1.data(itau).q1);
    idata.inv1DT1.data(itau).t     = idata.data(itau).t + idata.data(itau).effDead;
    idata.inv1DT1.data(itau).e     = idata.data(itau).e;
    idata.inv1DT1.data(itau).ecube = idata.data(itau).ecube;
end
% smoothness
L = get_l(length(idata.inv1DT1.z),1);
% reg. para
lambda = idata.para.regpara;
% limits
ub     = idata.para.decaySpecMax;
lb     = idata.para.decaySpecMin;


% temporary figures
screensz = get(0,'ScreenSize');
tmpgui.fig_data = figure( ...
    'Position', [5+355+405 screensz(4)-745 500 700], ...
    'Name', 'MRS T1 Inversion - Data TMP', ...
    'NumberTitle', 'off', ...
    'MenuBar', 'none', ...
    'Toolbar', 'figure', ...
    'HandleVisibility', 'on');
tmpgui.fig_model = figure( ...
    'Position', [5+355 screensz(4)-745 400 700], ...
    'Name', 'MRS T1 Inversion - Model TMP', ...
    'NumberTitle', 'off', ...
    'MenuBar', 'none', ...
    'Toolbar', 'figure', ...
    'HandleVisibility', 'on');

%% initial model
switch idata.para.modelspace
    case 1
        idata.inv1DT1.T1        = idata.para.T1initialM*ones(size(idata.inv1DT1.z)).';
    case 2
        idata.inv1DT1.block.T1  = idata.para.T1initialM*ones(size(idata.inv1Dqt.blockMono.solution(1).w));
        %idata.inv1DT1.block.T1(1:3) = 0.7;
        idata.inv1DT1.T1         = layerToSmooth(idata.inv1DT1.block.T1,idata.inv1Dqt.blockMono.solution(1).thk,idata.inv1DT1.z);
end
%% some save of parameter
switch idata.para.modelspace
    case 1
        % for smooth inversion
        idata.inv1DT1.smooth.T1 = idata.inv1DT1.T1;
        idata.inv1DT1.smooth.z  = idata.inv1DT1.z;
    case 2
        % for block inversion
        idata.inv1DT1.block.thk = idata.inv1Dqt.blockMono.solution(1).thk;
        %idata.inv1DT1.block.T1  = .5*ones(size(idata.inv1Dqt.blockMono.solution(1).w));
end

%% initial model
% calculate the kernel
idata.kernel.earth.T1   = idata.inv1DT1.T1;
idata.kernel.earth.type = 2;
idata.kernel.measure.pulsesequence = 'T1';
idata.kernel.measure.taud = idata.tau;

[idata.kernel.KT1TauAll, idata.kernel.JT1TauAll]  = MakeKernel(idata.kernel.loop, ...
    idata.kernel.model, ...
    idata.kernel.measure, ...
    idata.kernel.earth,...
    idata.kernel.B1);

% forward response
for itau=1:length(idata.tau)
    g                              = idata.kernel.KT1TauAll((itau-1)*nq+1:itau*nq,:);
    G                              = QTIMonoKernel(g,idata.inv1DT1.data(itau).t,idata.inv1DT1.T2,idata.inv1DT1.w);
    idata.inv1DT1.data(itau).d_est = G*idata.inv1DT1.w;
end

switch idata.para.modelspace
    case 1
        idata.inv1DT1.smooth.data = idata.inv1DT1.data;
    case 2
        idata.inv1DT1.block.data = idata.inv1DT1.data;
end

% plot
plotMRST1Data(idata,tmpgui)
    
%% inversion    
for n=1:idata.para.maxIteration     
    %% jacobian and dD
    idata.inv1DT1.J  = [];
    idata.inv1DT1.dD = [];
    idata.inv1DT1.e  = [];
    for itau=1:length(idata.tau)-1 % largest tau (100s) is first FID! Dont use it for inversion!
        j    = idata.kernel.JT1TauAll((itau-1)*nq+1:itau*nq,:);
        J    = T1QTMonoJacobian(j,idata.inv1DT1.data(itau).t,idata.inv1DT1.T1,idata.inv1DT1.T2,idata.inv1DT1.w,ub,lb);
        switch idata.para.modelspace
            case 2
                nL=length(idata.inv1DT1.zblockI)+1;
                Jtmp(:,1) = sum(J(:,1:idata.inv1DT1.zblockI(1)-1),2);
                for iL=1:length(idata.inv1DT1.zblockI)-1
                    Jtmp(:,iL+1) = sum(J(:,idata.inv1DT1.zblockI(iL):idata.inv1DT1.zblockI(iL+1)-1),2); 
                end
                Jtmp(:,nL) = sum(J(:,idata.inv1DT1.zblockI(nL-1):end),2);
                clear J;
                J=Jtmp;
        end
        idata.inv1DT1.J  = [idata.inv1DT1.J ; J];
        
        dD   = idata.inv1DT1.data(itau).d - idata.inv1DT1.data(itau).d_est ;
        idata.inv1DT1.dD = [idata.inv1DT1.dD; dD];
        idata.inv1DT1.e  = [idata.inv1DT1.e; idata.inv1DT1.data(itau).e];
    end
    
    %% three point inexact line search using quadratic polynom
    a = [0 .6 1];% a=0 is already known as last solution
    deltaLine(1) = sqrt(sum((idata.inv1DT1.dD./idata.inv1DT1.e).^2))/sqrt(length(idata.inv1DT1.e));
    % inversion step
    switch idata.para.modelspace
        case 1
            x = myT1cglscdp(idata.inv1DT1.J, idata.inv1DT1.dD, 1./idata.inv1DT1.e , L'*L, lambda);
        case 2
            x = myT1cglscdp(idata.inv1DT1.J, idata.inv1DT1.dD, 1./idata.inv1DT1.e , 1, lambda/n);
    end
    for iLine=2:length(a)
       % update step
        switch idata.para.modelspace
        case 1
            % new model
            T1  = (ub(1)-lb(1))*(atan(-(a(iLine)*x) + tan((idata.inv1DT1.T1/(ub(1)-lb(1)) - .5*(ub(1)+lb(1))/(ub(1)-lb(1)))*pi))./pi +.5*(ub(1)+lb(1))/(ub(1)-lb(1)));
        case 2
            % interpolate update
%             Depth      = [0 cumsum(idata.inv1Dqt.blockMono.solution(1).thk) max(idata.inv1Dqt.blockMono.z)];
%             [xz,z]     = stairs([x(1) x.'],Depth);
%             z(2:2:end) = z(2:2:end)+1e-10;
%             xi         = interp1(z, xz, idata.inv1DT1.z ,'linear','extrap').';
            xi         = layerToSmooth(x,idata.inv1Dqt.blockMono.solution(1).thk,idata.inv1DT1.z);
            % new model for kernel using interpolation
            T1  = (ub(1)-lb(1))*(atan(-(a(iLine)*xi) + tan((idata.inv1DT1.T1/(ub(1)-lb(1)) - .5*(ub(1)+lb(1))/(ub(1)-lb(1)))*pi))./pi +.5*(ub(1)+lb(1))/(ub(1)-lb(1)));
        end
        
        % calculate the kernel for T1
        idata.kernel.earth.T1   = T1;
        idata.kernel.earth.type = 2;
        idata.kernel.measure.taud = idata.tau;
        [idata.kernel.KT1TauAll, idata.kernel.JT1TauAll]  = MakeKernel(idata.kernel.loop, ...
            idata.kernel.model, ...
            idata.kernel.measure, ...
            idata.kernel.earth,...
            idata.kernel.B1);
        
        % forward response
        dD_all=[];
        for itau=1:length(idata.tau)-1
            g                              = idata.kernel.KT1TauAll((itau-1)*nq+1:itau*nq,:);
            G                              = QTIMonoKernel(g,idata.inv1DT1.data(itau).t,idata.inv1DT1.T2,idata.inv1DT1.w);
            dD_part                        = idata.inv1DT1.data(itau).d - G*idata.inv1DT1.w ;
            dD_all                         = [dD_all; dD_part];
        end
        
        %final misfit
        deltaLine(iLine) = sqrt(sum((dD_all./idata.inv1DT1.e).^2))/sqrt(length(idata.inv1DT1.e));
    end
    % now fit with quadratic polynom to get optimal afinal
    p              = polyfit(a,deltaLine,2);
    aDense         = linspace(0,1,100);
    deltaLineDense = p(1)*(aDense).^2 + p(2)*(aDense) + p(3);
    [dummy,index]  = min(deltaLineDense);
    afinal         = aDense(index);
    
    
    if afinal < 0.01
        n = idata.para.maxIteration;
        disp('converged')
    else
        disp(['iteration: ' num2str(n) ', step size:' num2str(afinal)])
    end
    
    %% calculate final model based on line search
    % inversion step
    switch idata.para.modelspace
        case 1
            % new model
            idata.inv1DT1.T1  = (ub(1)-lb(1))*(atan(-(afinal*x) + tan((idata.inv1DT1.T1/(ub(1)-lb(1)) - .5*(ub(1)+lb(1))/(ub(1)-lb(1)))*pi))./pi +.5*(ub(1)+lb(1))/(ub(1)-lb(1)));
            idata.inv1DT1.smooth.T1 = idata.inv1DT1.T1;
        case 2
            % interpolate update
%             Depth      = [0 cumsum(idata.inv1Dqt.blockMono.solution(1).thk) max(idata.inv1Dqt.blockMono.z)];
%             [xz,z]     = stairs([x(1) x.'],Depth);
%             z(2:2:end) = z(2:2:end)+1e-10;
%             xi         = interp1(z, xz, idata.inv1DT1.z ,'linear','extrap').';
            xi         = layerToSmooth(x,idata.inv1Dqt.blockMono.solution(1).thk,idata.inv1DT1.z);
            % new model for kernel using interpolation
            idata.inv1DT1.T1  = (ub(1)-lb(1))*(atan(-(afinal*xi) + tan((idata.inv1DT1.T1/(ub(1)-lb(1)) - .5*(ub(1)+lb(1))/(ub(1)-lb(1)))*pi))./pi +.5*(ub(1)+lb(1))/(ub(1)-lb(1)));
            idata.inv1DT1.block.T1 = (ub(1)-lb(1))*(atan(-(afinal*x).' + tan((idata.inv1DT1.block.T1/(ub(1)-lb(1)) - .5*(ub(1)+lb(1))/(ub(1)-lb(1)))*pi))./pi +.5*(ub(1)+lb(1))/(ub(1)-lb(1)));
    end
    
    % calculate the kernel for T1
    idata.kernel.earth.T1   = idata.inv1DT1.T1;
    idata.kernel.earth.type = 2;
    idata.kernel.measure.taud = idata.tau;
    [idata.kernel.KT1TauAll, idata.kernel.JT1TauAll]  = MakeKernel(idata.kernel.loop, ...
        idata.kernel.model, ...
        idata.kernel.measure, ...
        idata.kernel.earth,...
        idata.kernel.B1);
    
    % forward response
    for itau=1:length(idata.tau)
        g                              = idata.kernel.KT1TauAll((itau-1)*nq+1:itau*nq,:);
        G                              = QTIMonoKernel(g,idata.inv1DT1.data(itau).t,idata.inv1DT1.T2,idata.inv1DT1.w);
        idata.inv1DT1.data(itau).d_est = G*idata.inv1DT1.w;
    end
    
    
    switch idata.para.modelspace
        case 1
            idata.inv1DT1.smooth.data = idata.inv1DT1.data;
        case 2
            idata.inv1DT1.block.data = idata.inv1DT1.data;
    end
    
    plotMRST1Data(idata,tmpgui)
end

close(tmpgui.fig_data);
close(tmpgui.fig_model);


