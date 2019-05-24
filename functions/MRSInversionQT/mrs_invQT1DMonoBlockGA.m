function idata = mrs_invQT1DMonoBlockGA(idata,k)

%% preparation
screensz = get(0,'ScreenSize');
% tmpgui.fig_data  = figure( ...
%             'Position', [5+355+405 screensz(4)-750 500 700], ...
%             'Name', 'MRS QT Inversion - TMP Data', ...
%             'NumberTitle', 'off', ...
%             'MenuBar', 'none', ...
%             'Toolbar', 'figure', ...
%             'HandleVisibility', 'on');
% tmpgui.fig_model = figure( ...
%             'Position', [5+355 screensz(4)-750 400 700], ...
%             'Name', 'MRS QT Inversion - TMP Model', ...
%             'NumberTitle', 'off', ...
%             'MenuBar', 'none', ...
%             'Toolbar', 'figure', ...
%             'HandleVisibility', 'on');

tmpgui.fig_misfit = figure( ...
    'Position', [5 screensz(4)-750 348 700],...        
    'Name', 'MRS QT Inversion - iteration progress', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'Toolbar', 'figure', ...
            'HandleVisibility', 'on');

drawnow
        
timeT  = idata.data.t + idata.data.effDead;
D      = reshape(idata.data.d, length(idata.data.q), length(timeT));
E      = reshape(idata.data.e, length(idata.data.q), length(timeT));

g=idata.kernel.K;
z=idata.kernel.z;

nlay                      = idata.para.GAnLay;          % number of layers
nparam                    = 3*nlay-1 + 1;               % number of para layerpara + instPhase
parmin(1:nlay)            = idata.para.lowerboundWater;
parmax(1:nlay)            = idata.para.upperboundWater; % water content
parmin(nlay+1:2*nlay)     = log(idata.para.lowerboundT2);          
parmax(nlay+1:2*nlay)     = log(idata.para.upperboundT2);    % decay time
parmin(2*nlay+1:3*nlay-1) = log(idata.para.GAthkMin);              
parmax(2*nlay+1:3*nlay-1) = log(idata.para.GAthkMax);        % thickness

% additional parameter for complex inversion: instrument phase 
if isreal(D)
    parmin(nparam) = 0;
    parmax(nparam) = 1e-5;
else
    parmin(nparam) = 0;
    parmax(nparam) = 2*pi;
end

if isfield(idata.para,'layer')
        for iLay=1:idata.para.GAnLay
            if ~isnan(idata.para.layer(iLay).minTHK)
                parmin(2*nlay+iLay) = log(idata.para.layer(iLay).minTHK);
            end
            if ~isnan(idata.para.layer(iLay).maxTHK)
                parmax(2*nlay+iLay) = log(idata.para.layer(iLay).maxTHK);
            end
        end
end

maxgen                    = idata.para.maxIteration;    % maximum number of generations

%% some save to structure
idata.inv1Dqt.blockMono.t                    = timeT;
idata.inv1Dqt.blockMono.z                    = z;
idata.inv1Dqt.blockMono.g                    = g;

%% some variables as used in Irfans GA
zvec    = z - min(z);


%% GA
microga   =        3;         % 0 | 1 %if set to 1 when populaiton converges somewhere before reaching the maximum number of generations
                                      %population is redistributed over the search space keeping the best
pmutate   =        0.01;      % mutation probability : determines the chance of a bit to be flipped 
pcross    =        0.50;      % crossover probablity 
elit      =        1;         % 0 | 1 : Copy the best into new generation
popsize    =       idata.para.membersOfPop;      % number of individuals in population
npop      =        1;% idata.para.numberOfPop;         % number of populations
xovertype =        'two';     % single | two | scattered
% xovertype =        'scattered';     % single | two | scattered
mc        =        0;         % 0 | 1 : marked constraints MC on or off
le        =        0;         % 0 | 1 : lamarckian evolution on or off

%% Create initial population
nposibl    = 2.^7*ones(1,nparam);% resolution --> 2^7 (128) values between parmin and parmax
% nposibl    = 2.^10*ones(1,nparam);% resolution --> 2^10 (1000) values between parmin and parmax
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
y          = 0;
bm.sel.wc  = [];
best       = 10e8;

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
                if ~isnan(idata.para.layer(nLay).LB)
                    if (currentdepth + exp(thk(nLay))) < idata.para.layer(nLay).LB
                        thk(nLay)    = log(idata.para.layer(nLay).LB - currentdepth);
                        currentdepth = sum(exp(thk(1:nLay)));
                    else
                        delta  = currentdepth + exp(thk(nLay)) - idata.para.layer(nLay).LB;
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

        % code change back into binary
        iparent(:,k)  = code1([wc t2 thk instPhase],nparam,ig2,g0,g1).';
        
        % limit sum(thk) to max depth
        for ilay=(nlay-1):-1:1
            dz        = sum(exp(thk)) - max(zvec);
            if dz<=0
                break
            else
                thk(ilay)     = log(max(0,exp(thk(ilay))-dz));
                iparent(:,k)  = code1([wc t2 thk instPhase],nparam,ig2,g0,g1).';
            end
        end
        
        d_est       = fwd1dnmr([wc exp(t2) exp(thk)],length(wc),zvec,g,timeT);
        mfit_nmr(k) = misfitfunc(D,d_est,E,idata.para.dataType,instPhase);
        misfit(k)   = mfit_nmr(k);
        
        
        if misfit(k) < best
            best         = misfit(k);
            bm.misfit    = best;
            bm.mnmr      = mfit_nmr(k);
            bm.dnmr      = d_est;
            bm.model.wc  = wc;
            bm.model.t2  = exp(t2);
            bm.model.thk = exp(thk);
            bm.model.instPhase = instPhase;
            bm.model.yer = k;
        end        
    end
    
    
    if 0 % save member of the population that are below tresh
        array         =  decode1(nparam,ig2,g0,g1,iparent);
        % adapt tresh to current best
        tresh    = 1.02*min(misfit);
        % check for uniqueness
        [~, tmp]      = unique(misfit);
        disp([num2str(size(tmp,2)) ' ' num2str(size(misfit,2))])
        bckarray      = array;
        array         = bckarray(tmp,:);
        bckmisfit     = misfit;
        misfit        = bckmisfit(tmp);
        % select member according to their tresh 
        popWC         = array(misfit<tresh,1:nlay);
        popt2         = array(misfit<tresh,nlay+1:2*nlay);
        popthk        = array(misfit<tresh,2*nlay+1:3*nlay-1);
        popiP         = array(misfit<tresh,end);
        popmisfit     = misfit(misfit<tresh);
        % add solutions at the end (to keep old solutions)
        sizeSel = size(bm.sel.wc,1);
        sizeAva = size(popWC,1);
        for nbest = 1:sizeAva
            sel                            = nbest;
            bm.sel.wc(sizeSel+nbest,:)     = popWC(sel,:);
            bm.sel.t2(sizeSel+nbest,:)     = exp(popt2(sel,:));
            bm.sel.thk(sizeSel+nbest,:)    = exp(popthk(sel,:));
            bm.sel.instPhase(sizeSel+nbest,:) = popiP(sel,:);
            bm.sel.misfit(sizeSel+nbest,:) = popmisfit(sel);
            bm.sel.code(:,sizeSel+nbest)   = code1([popWC(sel,:) popt2(sel,:) popthk(sel,:) popiP(sel,:)],nparam,ig2,g0,g1).';
        end
        % delete old solution above tresh
        bm.sel.wc(bm.sel.misfit>tresh,:)        = [];
        bm.sel.t2(bm.sel.misfit>tresh,:)        = [];
        bm.sel.thk(bm.sel.misfit>tresh,:)       = [];
        bm.sel.instPhase(bm.sel.misfit>tresh,:) = [];
        bm.sel.misfit(bm.sel.misfit>tresh,:)    = [];
        % ensure uniqueness in misfit (may come from old solutions)
        tmp=[];
        [~, tmp]         = unique(bm.sel.misfit); 
        bm.sel.wc        = bm.sel.wc(tmp,:);
        bm.sel.t2        = bm.sel.t2(tmp,:);
        bm.sel.thk       = bm.sel.thk(tmp,:);
        bm.sel.instPhase = bm.sel.instPhase(tmp,:);
        bm.sel.misfit    = bm.sel.misfit(tmp,:);
        bm.sel.code      = bm.sel.code(:,tmp);
        % set back
        array  = bckarray;  bckarray  = [];
        misfit = bckmisfit; bckmisfit = [];
    end
    
    
    % Keep the average and minumum misfit and corresponding model info for
    % demonstration and elite
    ort(inesil)   =  mean(misfit);
    ort1(inesil)   =  std(misfit);
    [bestfit,yer] =  min(misfit);
    bf(inesil)    =  bestfit;
    jbest         =  yer;
    ibest         =  iparent(:,yer);
    
    
    idata.inv1Dqt.blockMono.solution(1).w        = bm.model.wc;
    idata.inv1Dqt.blockMono.solution(1).T2       = bm.model.t2;
    idata.inv1Dqt.blockMono.solution(1).thk      = bm.model.thk;
    idata.inv1Dqt.blockMono.solution(1).instPhase = bm.model.instPhase;
    idata.inv1Dqt.blockMono.solution(1).d        = reshape(bm.dnmr,numel(D),1);
    idata.inv1Dqt.blockMono.solution(1).dnorm    = bm.misfit;
    idata.inv1Dqt.blockMono.solution(1).mnorm    = [];
%     for isol=1:size(bm.sel.wc,1)
%         idata.inv1Dqt.blockMono.solution(1+isol).w         = bm.sel.wc(isol,:);
%         idata.inv1Dqt.blockMono.solution(1+isol).T2        = bm.sel.t2(isol,:);
%         idata.inv1Dqt.blockMono.solution(1+isol).thk       = bm.sel.thk(isol,:);
%         idata.inv1Dqt.blockMono.solution(1+isol).instPhase = bm.sel.instPhase(isol,:);
%         idata.inv1Dqt.blockMono.solution(1+isol).misfit    = bm.sel.misfit(isol,:);
%     end
%     if size(idata.inv1Dqt.blockMono.solution,1) > size(bm.sel.wc,1)
%         idata.inv1Dqt.blockMono.solution(1 + size(bm.sel.wc,1):end)=[];
%     end
    
    idata.para.instPhase = bm.model.instPhase;
    %mrsInvQT_plotData(tmpgui,idata);
%     figure(tmpgui.fig_misfit);
    set(0,'currentFigure',tmpgui.fig_misfit);
    semilogy([1:inesil],bf,'-o',[1:inesil],ort,'-x',[1:inesil],ort+ort1,'-.'); xlabel('iteration');ylabel('misfit');grid on; drawnow
    
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
    
    switch microga
        case 0 % simply create the new population
            [ichild,nmutate]   =  mutate(npopsiz,nchrome,pmutate,ichild);
            iparent            =  newgen(ibest,npopsiz,ichild,elit);
        case 1 % if population converged restart
            [iparent,gamicrostate]=gamicro(npopsiz,nchrome,iparent,ibest);
            if gamicrostate
                display(['Restart population at generation =',num2str(inesil)])
            end
        case 2 % check for population to have lots of identical member
            [~, tmp] = unique(misfit);
            if length(tmp) < npopsiz*0.3
                tmpparent        = iparent;
                iparent          = ones(nchrome,npopsiz);
                ras              = rand(nchrome,npopsiz);
                iparent(ras<0.5) = 0;
                iparent(:,1:length(tmp)) = tmpparent(:,tmp);
                display(['Particular restart of population at generation =',num2str(inesil)])
            else
                % simply create the new population
                [ichild,nmutate]   =  mutate(npopsiz,nchrome,pmutate,ichild);
                iparent            =  newgen(ibest,npopsiz,ichild,elit);
            end
        case 3 % include 10% new at each iteration
            inew             = ones(nchrome,floor(npopsiz*0.1));
            ras              = rand(nchrome,floor(npopsiz*0.1));
            inew(ras<0.5)    = 0;
            
            % simply create the new population
            [ichild,nmutate]                 = mutate(npopsiz,nchrome,pmutate,ichild);
            ichild(:,2:1+floor(npopsiz*0.1)) = inew;
            iparent                          = newgen(ibest,npopsiz,ichild,elit);
%             iparent(:,1:size(bm.sel.wc,1))   = bm.sel.code;
            
            
            
            
    end
end

% close(tmpgui.fig_data)
% close(tmpgui.fig_model)
close(tmpgui.fig_misfit)
disp(['final misfit: ' num2str(bf(end))])


