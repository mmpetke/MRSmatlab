function idata = mrs_invQT1DMonoBlockGA(idata,k)

%% preparation
screensz = get(0,'ScreenSize');
tmpgui.fig_data  = figure( ...
            'Position', [5+355+405 screensz(4)-745 500 700], ...
            'Name', 'MRS QT Inversion - TMP Data', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'Toolbar', 'figure', ...
            'HandleVisibility', 'on');
tmpgui.fig_model = figure( ...
            'Position', [5+355 screensz(4)-745 400 700], ...
            'Name', 'MRS QT Inversion - TMP Model', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'Toolbar', 'figure', ...
            'HandleVisibility', 'on');

tmpgui.fig_misfit = figure( ...
    'Position', [5 screensz(4)-320 500 250],...        
    'Name', 'MRS QT Inversion - iteration progress', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'Toolbar', 'figure', ...
            'HandleVisibility', 'on'); 
        
timeT  = idata.data.t + idata.data.effDead;
D      = reshape(idata.data.d, length(idata.data.q), length(timeT));
E      = reshape(idata.data.e, length(idata.data.q), length(timeT));

% this is block inversion --> no need to preintegrate the kernel
% [g,z]  = mrs_invQTKernelIntegration(idata);
g=idata.kernel.K;
z=idata.kernel.z;

nlay                      = idata.para.GAnLay;          % number of layers
nparam                    = 3*nlay-1 + 1;               % number of para layerpara + instPhase
parmin(1:nlay)            = idata.para.lowerboundWater;
parmax(1:nlay)            = idata.para.upperboundWater; % water content
parmin(nlay+1:2*nlay)     = log(idata.para.lowerboundT2);          
parmax(nlay+1:2*nlay)     = log(idata.para.upperboundT2);    % decay time
% parmin(nlay+1:2*nlay)     = (idata.para.lowerboundT2);          
% parmax(nlay+1:2*nlay)     = (idata.para.upperboundT2);    % decay time
parmin(2*nlay+1:3*nlay-1) = log(idata.para.GAthkMin);              
parmax(2*nlay+1:3*nlay-1) = log(idata.para.GAthkMax);        % thickness
% parmin(2*nlay+1:3*nlay-1) = idata.para.GAthkMin;              
% parmax(2*nlay+1:3*nlay-1) = idata.para.GAthkMax;        % thickness

% additional parameter for complex inversion: instrument phase 
if isreal(D)
    parmin(nparam) = 0;
    parmax(nparam) = 1e-5;
else
    parmin(nparam) = 0;
    parmax(nparam) = 2*pi;
end

maxgen                    = idata.para.maxIteration;    % maximum number of generations
tresh                     = idata.para.GAstatistic;     % save and plot solutions below chi^2
%% some save to structure
idata.inv1Dqt.blockMono.t                    = timeT;
idata.inv1Dqt.blockMono.z                    = z;
idata.inv1Dqt.blockMono.g                    = g;

%% some variables as used in Irfans GA
zvec    = z - min(z);


%% GA
microga   =        0;         % 0 | 1 %if set to 1 when populaiton converges somewhere before reaching the maximum number of generations
                                      %population is redistributed over the search space keeping the best
pmutate   =        0.02;      % mutation probability : determines the chance of a bit to be flipped 
pcross    =        0.50;      % crossover probablity 
elit      =        1;         % 0 | 1 : Copy the best into new generation
popsize    =       idata.para.membersOfPop;      % number of individuals in population
npop      =        idata.para.numberOfPop;         % number of populations
xovertype =        'two';     % single | two | scattered
mc        =        0;         % 0 | 1 : marked constraints MC on or off
le        =        0;         % 0 | 1 : lamarckian evolution on or off

%% Create initial population
nposibl    = 2.^10*ones(1,nparam);% resolution --> 2^10 (1000) values between parmin and parmax
g0         = parmin;
pardel     = parmax-parmin;
g1         = pardel./(nposibl-1);
ig2        = log2(nposibl);

%  Count the total number of chromosomes (bits) required
nchrome    = sum(ig2);

% Initialize random number generator and create initial population
%rand('state',0);
npopsiz = popsize*npop;
iparent=ones(nchrome,npopsiz);
ras=rand(nchrome,npopsiz);
iparent(ras<0.5)=0;

%% Main genetic processing loop
y       = 0;
bm.sel  = [];
best    = 10e8;

for inesil        =  1:maxgen
    % Decode binary coded parameters into decimal
    array         =  decode1(nparam,ig2,g0,g1,iparent);
    
    % Calculate the forward response and misfit of models
    for k=1:npopsiz
        wc          = array(k,1:nlay);
        t2          = array(k,nlay+1:2*nlay);
        thk         = array(k,2*nlay+1:3*nlay-1);
        instPhase   = array(k,end);
        % some limits (additional constrains) if known can be implemented
        depthmarker  = [];
        currentdepth = 0;
        if isfield(idata.para,'layer')
        for nLay=1:idata.para.GAnLay
            if ~isnan(idata.para.layer(nLay).watercontent)
                wc(nLay) = idata.para.layer(nLay).watercontent;
            end
            if ~isnan(idata.para.layer(nLay).T2)
                t2(nLay) = log(idata.para.layer(nLay).T2);
            end
            if nLay < idata.para.GAnLay
                if ~isnan(idata.para.layer(nLay).thickness)
                    %thk(nLay) = log(idata.para.layer(nLay).thickness);
                    if (currentdepth + exp(thk(nLay))) < idata.para.layer(nLay).thickness
                        thk(nLay)    = log(idata.para.layer(nLay).thickness - currentdepth);
                        currentdepth = sum(exp(thk(1:nLay)));
                    else
                        delta  = currentdepth + exp(thk(nLay)) - idata.para.layer(nLay).thickness;
                        ddelta = delta/length([depthmarker nLay]);
                        for iLay = [depthmarker nLay]
                            if ddelta < exp(thk(iLay))
                                thk(iLay) = log(exp(thk(iLay))-ddelta);
                            else
                                thk(iLay) = log(min(2,round(100*rand(1))/20));
                                ddelta    = ddelta + exp(thk(iLay));
                            end
                        end
                        currentdepth = sum(exp(thk(1:nLay)));
                    end
                    depthmarker=[];
                else
                    currentdepth = sum(exp(thk(1:nLay)));
                    depthmarker = [depthmarker nLay];
                end
            end
        end
        end
        %thk(1) = log(1.5); 
        %thk(2) = log(1.0);
        %thk(3) = log(10);
        %thk(4) = log(20);
        %wc(1)  = min(0.03,wc(1));%t2(1) = log(0.03);  thk(1) = log(5);
        % wc(2)  = max(0.99,wc(2)); 
 %        wc(2)  = min(1.02,wc(2));%t2(2) = log(0.1);   thk(2) = log(10); 
         %wc(3)  = max(0.25,wc(3));%t2(3) = log(0.003); thk(3) = log(10);
         %wc(3)  = min(0.35,wc(3));
%         wc(4)  = min(0.03,wc(4));% t2(4) = log(0.3);   thk(4) = log(10);  
         %wc(5)  = min(0.03,wc(5));%t2(5) = log(0.003); 
%         wc(1)  = 0.01; t2(1) = log(0.03);  thk(1) = log(5);
%         wc(2)  = 0.35; t2(2) = log(0.1);   thk(2) = log(10); 
%         wc(3)  = 0.45; t2(3) = log(0.003); thk(3) = log(10); 
%         wc(4)  = 0.35; t2(4) = log(0.3);   thk(4) = log(10);  
%         wc(5)  = 0.01; t2(5) = log(0.003); 
        %wc(end)= min(0.01,wc(end));

        % code change back into binary
        iparent(:,k)  = code1([wc t2 thk instPhase],nparam,ig2,g0,g1).';
        
        % limit sum(thk) to max depth
        for ilay=(nlay-1):-1:1
            dz        = sum(exp(thk)) - max(zvec);
%             dz        = sum(thk) - max(zvec);
            if dz<=0
                break
            else
                thk(ilay)     = log(max(0,exp(thk(ilay))-dz));
%                 thk(ilay)     = max(0,thk(ilay)-dz);
                % code change back into binary
                iparent(:,k)  = code1([wc t2 thk instPhase],nparam,ig2,g0,g1).';
            end
        end

        d_est       = fwd1dnmr([wc exp(t2) exp(thk)],length(wc),zvec,g,timeT);
%         d_est       = fwd1dnmr([wc t2 thk],length(wc),zvec,g,timeT);
        mfit_nmr(k) = misfitfunc(D,d_est,E,idata.para.dataType,instPhase);
        misfit(k)   = mfit_nmr(k);
        
        
        if misfit(k)<best
            best         = misfit(k);
            bm.misfit    = best;
            bm.mnmr      = mfit_nmr(k);
            bm.dnmr      = d_est;
            bm.model.wc  = wc;
            bm.model.t2  = exp(t2);
%             bm.model.t2  = t2;
            bm.model.thk = exp(thk);
%             bm.model.thk = thk;
            bm.model.instPhase = instPhase;
            bm.model.yer = k;
            % all time best
            if misfit(k)<tresh
                bm.sel.wc(y+1,:)     = wc;
                bm.sel.t2(y+1,:)     = exp(t2);
%                 bm.sel.t2(y+1,:)   = t2;
                bm.sel.thk(y+1,:)    = exp(thk);
%                 bm.sel.thk(y+1,:)    = thk;
                bm.sel.instPhase(y+1,:) = instPhase;
                bm.sel.misfit(y+1,:) = misfit(k);
                y=y+1;
            end
        end        
    end
    
    % take 10 of it generation below tresh
    popWC  = array(misfit<tresh,1:nlay);
    popt2  = array(misfit<tresh,nlay+1:2*nlay);
    popthk = array(misfit<tresh,2*nlay+1:3*nlay-1);
    popiP  = array(misfit<tresh,end);
    for nbest = 1:min(10,size(popWC,1))
        bm.sel.wc(y+nbest,:)     = popWC(nbest,:);
        bm.sel.t2(y+nbest,:)     = exp(popt2(nbest,:));
%         bm.sel.t2(y+nbest,:)   = popt2(nbest,:);
        bm.sel.thk(y+nbest,:)    = popthk(nbest,:);
        bm.sel.instPhase(y+nbest,:) = popiP(nbest,:);
        bm.sel.msifit(y+nbest,:) = misfit(nbest);
    end
    
    % Keep the average and minumum misfit and corresponding model info for demonstration
    ort(inesil)   =  mean(misfit);
    [bestfit,yer] =  min(misfit);
    bf(inesil)    =  bestfit;
    jbest         =  yer;
    ibest         =  iparent(:,yer);
    
    
    idata.inv1Dqt.blockMono.solution(1).w        = bm.model.wc;
    idata.inv1Dqt.blockMono.solution(1).T2       = bm.model.t2;
    idata.inv1Dqt.blockMono.solution(1).thk      = bm.model.thk;
    idata.inv1Dqt.blockMono.solution(1).instPhase = bm.model.instPhase;
    idata.inv1Dqt.blockMono.solution(1).d        = reshape(bm.dnmr,numel(D),1);
    idata.inv1Dqt.blockMono.solution(1).dnorm    = [];
    idata.inv1Dqt.blockMono.solution(1).mnorm    = [];
    for isol=2:y
        idata.inv1Dqt.blockMono.solution(isol).w        = bm.sel.wc(isol,:);
        idata.inv1Dqt.blockMono.solution(isol).T2       = bm.sel.t2(isol,:);
        idata.inv1Dqt.blockMono.solution(isol).thk      = bm.sel.thk(isol,:);
        idata.inv1Dqt.blockMono.solution(isol).instPhase = bm.sel.instPhase(isol,:);
    end
    
    idata.para.instPhase = bm.model.instPhase;
    mrsInvQT_plotData(tmpgui,idata);
    figure(tmpgui.fig_misfit);plot(bf,'o'); xlabel('iteration');ylabel('misfit');grid on;
    
    % Keep npop indivdual population
    ichild = ones(nchrome,npopsiz);
    for inp=1:npop
        % Selection
        mate1         = selecter(misfit((inp-1)*popsize+1:inp*popsize),popsize);
        mate2         = selecter(misfit((inp-1)*popsize+1:inp*popsize),popsize);
        
        % Crossover
        ichildTMP     = xover(nchrome,mate1,mate2,iparent(:,(inp-1)*popsize+1:inp*popsize),popsize,xovertype,pcross);
        
        % Crossing of the individual populations after 20 iterations
        if mod(inesil,20) % keep populations separate
           ichild(:,(inp-1)*popsize+1:inp*popsize) = ichildTMP; 
        else % cross populations
            ichild(:,inp:npop:end) = ichildTMP;
        end
        
        % or keep populations individual
        %ichild(:,(inp-1)*popsize+1:inp*popsize) = ichildTMP;
    end
    
    % Mutation
    if microga~=1
        [ichild,nmutate]   =     mutate(npopsiz,nchrome,pmutate,ichild);
    end
          
    % Create the new population
    iparent       =  newgen(ibest,npopsiz,ichild,elit);
    
    if microga~=0
        [iparent,gamicrostate]=gamicro(npopsiz,nchrome,iparent,ibest);
        if gamicrostate
            display(['Restart population at generation =',num2str(inesil)])
        end
    end
end

close(tmpgui.fig_data)
close(tmpgui.fig_model)



