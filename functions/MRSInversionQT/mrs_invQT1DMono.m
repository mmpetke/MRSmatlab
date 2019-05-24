function idata = mrs_invQT1DMono(idata,statisticRuns)

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


D        = idata.data.d;
E        = 1./idata.data.e;
ub       = [idata.para.upperboundWater idata.para.upperboundT2];
lb       = [idata.para.lowerboundWater idata.para.lowerboundT2];
lambda.W = idata.para.regMonoWC;
lambda.T = idata.para.regMonoT2;

dMmin  = idata.para.minModelUpdate;
itmax  = idata.para.maxIteration;

[g,z]    = mrs_invQTKernelIntegration(idata);

%% smoothness
L      = zeros(2*length(z),2*length(z));
LW     = get_l(length(z),1); % smoothing water content
LT     = get_l(length(z),1); % smoothing decay time
L(1:length(LW'*LW),1:length(LW'*LW)) = LW'*LW;
L(length(LW'*LW)+1:end,length(LW'*LW)+1:end) = (lambda.T/lambda.W)*LT'*LT;

%% some save to structure
idata.inv1Dqt.smoothMono.t                    = timeT;
idata.inv1Dqt.smoothMono.z                    = z;
idata.inv1Dqt.smoothMono.g                    = g;
 


%% inversion
disp('start inversion ...'); 
% primary run on measured data
phaseI=[];
runCGLSCDP(1);               

% statistics via bootstrapping
for sRun=2:statisticRuns
    reT   = sort(mrs_randsample(1:length(timeT),floor(length(timeT)*1),'false'));     %this just grabs all the times currently, changing it to a number <1 and >0 picks a subset of the time samples
    reQ   = sort(mrs_randsample(1:length(idata.data.q),floor(length(idata.data.q)*1),'true'));
% reQ   = sort(mrs_randsample(1:length(idata.data.q),floor(length(idata.data.q)-2),'false'));
    dcube = idata.data.dcube(reQ,reT);
    ecube = idata.data.ecube(reQ,reT);
    g     = idata.inv1Dqt.smoothMono.g(reQ,:);
    switch idata.para.dataType
        case 1
            D = reshape(abs(dcube),size(dcube,1)*length(idata.data.t),1);
        case 2
            D = reshape(real(dcube),size(dcube,1)*length(idata.data.t),1);
        case 3
            D = reshape(dcube,size(dcube,1)*length(idata.data.t),1);
    end
    runCGLSCDP(sRun);
    disp(['current run: ' num2str(sRun)]);
end
% run for statistics using the model of the first run and create new data
% statistics via new noise realization
% for sRun=2:statisticRuns
%     switch idata.para.dataType
%         case 1
%             D = abs(complex(real(idata.inv1Dqt.smoothMono.solution(1).d) + idata.data.e.*randn(length(D),1),...
%                         imag(idata.inv1Dqt.smoothMono.solution(1).d) + idata.data.e.*randn(length(D),1)));
%         case 2
%             D = abs(idata.inv1Dqt.smoothMono.solution(1).d) + idata.data.e.*randn(length(D),1);
%         case 3
%             D = (complex(real(idata.inv1Dqt.smoothMono.solution(1).d) + idata.data.e.*randn(length(D),1),...
%                         imag(idata.inv1Dqt.smoothMono.solution(1).d) + idata.data.e.*randn(length(D),1)));
%     end
%    
%     runCGLSCDP(sRun);
% end

close(tmpgui.fig_data)
close(tmpgui.fig_model)
close(tmpgui.fig_misfit)



%% some nested functions due to use memory efficient

    function runCGLSCDP(run) 
        
        lam          = lambda.W;
        w            = 0.25*ones(length(idata.inv1Dqt.smoothMono.z),1); 
        T2           = 0.3*ones(length(idata.inv1Dqt.smoothMono.z),1);
        
        % first estimate of instrument phase (mostly already quite nice)
        switch idata.para.dataType
            case 3
                G       = QTIMonoKernelComplex(g,timeT,T2,w);
                dDls     = [];
                tmpPhase = [-pi:0.01:pi];
                for n=1:length(tmpPhase)
                    %                         TMPd_est = abs(Gc*w).*exp(1i*(angle(Gc*w) - tmpPhase(n)));
                    %                         TMPdD    = [real(D)-real(TMPd_est); imag(D)-imag(TMPd_est)];
                    TMPd_est = G*w;
                    Dcor     = abs(D).*exp(1i*(angle(D) - tmpPhase(n)));
                    TMPdD    = [real(Dcor)-real(TMPd_est); imag(Dcor)-imag(TMPd_est)];
                    dDls(n)  = norm([E; E].*TMPdD)/sqrt(length(TMPdD));
                end
                [dummy,index] = min(abs(dDls));
                idata.para.instPhase = tmpPhase(index);
                phaseI(1)=idata.para.instPhase;
        end
        
        if run>1
            % change starting model arbitrary between limits
            w_start  = lb(1) + (ub(1)-lb(1))*rand(1,1);
            T2_start = lb(2) + (ub(2)-lb(2))*rand(1,1);
            w            = 0.1*ones(length(idata.inv1Dqt.smoothMono.z),1); 
            T2           = 0.1*ones(length(idata.inv1Dqt.smoothMono.z),1);
        end
        
        [A,b,e]      = transform;
        x            = cglscdp;
        [w,T2,G]     = linesearch;
        phaseI(2) = idata.para.instPhase;
        
        % for temporary plotting
        idata.inv1Dqt.smoothMono.solution(run).w        = w;
        idata.inv1Dqt.smoothMono.solution(run).T2       = T2;
        G                                               = QTIMonoKernelComplex(g,timeT,T2,w);
        idata.inv1Dqt.smoothMono.solution(run).d        = G*w;
        switch idata.para.dataType
            case {1,2}
                dnorm                                           = norm(E.*(D - abs(G*w)))/sqrt(length(D));
            case 3
%                 TMPd_est  = abs(G*w).*exp(1i*(angle(G*w) - idata.para.instPhase));
%                 TMPdD     = [real(D) - real(TMPd_est); imag(D) - imag(TMPd_est)];
                TMPd_est = G*w;
                Dcor     = abs(D).*exp(1i*(angle(D) - idata.para.instPhase));
                TMPdD    = [real(Dcor)-real(TMPd_est); imag(Dcor)-imag(TMPd_est)];
                dnorm     = norm([E; E].*TMPdD)/sqrt(length(TMPdD));
        end 
        idata.inv1Dqt.smoothMono.solution(run).dnorm    = dnorm;
        idata.inv1Dqt.smoothMono.solution(run).mnorm    = [];
        mrsInvQT_plotData(tmpgui,idata,run);
 
        for iter=1:itmax
            [A,b,e]      = transform;
            x            = cglscdp;
            [w,T2,G]     = linesearch;
            phaseI(iter+2) = idata.para.instPhase;
            
            % for temporary plotting
            idata.inv1Dqt.smoothMono.solution(run).w        = w;
            idata.inv1Dqt.smoothMono.solution(run).T2       = T2;
            G                                               = QTIMonoKernelComplex(g,timeT,T2,w);
            idata.inv1Dqt.smoothMono.solution(run).d        = G*w;
            switch idata.para.dataType
                case {1,2}
                    dnorm                                           = norm(E.*(D - abs(G*w)))/sqrt(length(D));
                case 3
%                     TMPd_est  = abs(G*w).*exp(1i*(angle(G*w) - idata.para.instPhase));
%                     TMPdD     = [real(D)-real(TMPd_est); imag(D)-imag(TMPd_est)]; 
                    TMPd_est = G*w;
                    Dcor     = abs(D).*exp(1i*(angle(D) - idata.para.instPhase));
                    TMPdD    = [real(Dcor)-real(TMPd_est); imag(Dcor)-imag(TMPd_est)];
                    dnorm     = norm([E; E].*TMPdD)/sqrt(length(TMPdD));
            end
            idata.inv1Dqt.smoothMono.solution(run).dnorm    = dnorm;
            idata.inv1Dqt.smoothMono.solution(run).mnorm    = norm(LW*w+LT*T2);
            mrsInvQT_plotData(tmpgui,idata,run);
            set(0,'currentFigure',tmpgui.fig_misfit);plot(iter,dnorm,'o'); xlabel('iteration');ylabel('misfit');grid on; hold on;
            if idata.para.struCoupling,
                si = size(LW);
                rw = abs( LW * log( w ) );
                rt = abs( LT * log( T2 ) );
                if 1, % IRLS (L1-L2) function
                    ww = sum( rw.^2 ) / sum(rw) ./ rw;
                    wt = sum( rt.^2 ) / sum(rt) ./ rt;
                else % self-defined function (Guenther et al, SAGEEP, 2010)
                    alfat = 0.1;
                    alfaw = 0.1;
                    c = 1;
                    ww = ( alfaw ./ ( alfaw + rw ) + alfaw  ).^c;
                    wt = ( alfat ./ ( alfat + rt ) + alfat  ).^c;
                end
                ww( ww > 1 ) = 1; % only decrease of weight
                wt( wt > 1 ) = 1;                
                LW1 = spdiags(wt,0,si(1),si(1)) * LW;
                LT1 = spdiags(ww,0,si(1),si(1)) * LT;
                L(1:length(LW'*LW),1:length(LW'*LW)) = LW1'*LW1;
                L(length(LW'*LW)+1:end,length(LW'*LW)+1:end) = (lambda.T/lambda.W)*LT1'*LT1;
            end
        end
        
        function [J,dD,e] = transform
            switch idata.para.dataType
                case {1,2}
                    J      = QTIMonoJacobian(g,timeT,T2,w,ub,lb); % Jacobian matrix
                    G      = QTIMonoKernelComplex(g,timeT,T2,w);
                    dD     = D - abs(G*w);
                    e      = 1./(idata.data.e);
                case 3
                    J      = QTIMonoJacobianComplex(g,timeT,T2,w,ub,lb); % Jacobian matrix
                    G      = QTIMonoKernelComplex(g,timeT,T2,w);
%                     d_est  = abs(G*w).*exp(1i*(angle(G*w) - idata.para.instPhase));
%                     dD     = [real(D) - real(d_est); imag(D) - imag(d_est)];
                    d_est  = G*w;
                    Dcor   = abs(D).*exp(1i*(angle(D) - idata.para.instPhase));
                    dD     = [real(Dcor) - real(d_est); imag(Dcor) - imag(d_est)];
                    e      = [1./(idata.data.e); 1./(idata.data.e)];
            end
        end
        function x = cglscdp
            D_bkp  = D;
            [m,n]  = size(A);
            dx     = zeros(n,1);
            x0     = zeros(n,1);
            D      = diag(e);
            P      = 1;
            PI     = P';
            su     = sum(P,1);
            for i=1:length(su),
                if su(i)>0, PI(i,:)=PI(i,:)/su(i); end
            end
            x      = PI*x0;
            z      = D*(b - (A*(P*x))); % residuum of unregularized equation
            p      = (z'*D*A*P)';
            acc    = 1e-7;
            abbr   = p'*p*acc;             % goal for norm(r)^2
            p      = p-PI*(L*(x0+dx))*lam; % residuum of normal equation
            r      = p;
            normr2 = r'*r;
            % Iterate.
            j=0;
            fprintf(1,'%.1f',0.0)
            fort=0;oldf=0; 
            while(normr2>abbr)
                j         = j+1;
                q         = D*(A*(P*p));   % Zeile 1
                normr2old = normr2;
                Pp        = P*p;
                alpha     = normr2/(q'*q+Pp'*(L*Pp)*lam); % Zeile 2
                x         = (x + alpha*p);   % Zeile 3
                z         = z - alpha*q;   % Zeile 4
                r         = (z'*D*A*P)'-PI*(L*(P*x+dx))*lam;
                normr2    = r'*r;
                beta      = normr2/normr2old;
                p         = r + beta*p;
                fort      = 1+log10(normr2/abbr)/log10(acc);
                if fort>oldf+0.05,
                    fprintf(1, '\b\b\b');
                    fprintf(1,'%.1f',round(10*fort)/10)
                    oldf = fort;
                end
            end
            fprintf(1, '\b\b\b'); 
            x = P*x;
            D = D_bkp;
        end
        
        function [wc,T2c,Gc] = linesearch
            % linesearch parameter
            density  = 7;
            step     = [2 .5];
            dDls     = zeros(density,1);
            mc       = 2;

            for r=1:length(step)
                ms   = logspace(log10(10^(log10(mc)-step(r))),...
                    log10(mc),density);
                for ls = 1:density
                    wc      = (ub(1)-lb(1))*(atan(ms(ls)*x(1:length(x)/2) + tan((w/(ub(1)-lb(1)) - .5*(ub(1)+lb(1))/(ub(1)-lb(1)))*pi))./pi +.5*(ub(1)+lb(1))/(ub(1)-lb(1)));
                    T2c     = (ub(2)-lb(2))*(atan(ms(ls)*x(length(x)/2+1:length(x)) + tan((T2/(ub(2)-lb(2)) - .5*(ub(2)+lb(2))/(ub(2)-lb(2)))*pi))./pi +.5*(ub(2)+lb(2))/(ub(2)-lb(2)));
                    Gc      = QTIMonoKernelComplex(g,timeT,T2c,wc);
                    switch idata.para.dataType
                        case {1,2}
                            dDls(ls) = norm(E.*(abs(Gc*wc)-D))/sqrt(length(D));
                        case 3
%                             TMPd_est = abs(Gc*wc).*exp(1i*(angle(Gc*wc) - idata.para.instPhase));
%                             TMPdD    = [real(D)-real(TMPd_est); imag(D)-imag(TMPd_est)];
                            TMPd_est = Gc*wc;
                            Dcor     = abs(D).*exp(1i*(angle(D) - idata.para.instPhase));
                            TMPdD    = [real(Dcor)-real(TMPd_est); imag(Dcor)-imag(TMPd_est)];
                            dDls(ls) = norm([E; E].*TMPdD)/sqrt(length(TMPdD));
                    end
                end
                [dummy,index] = min(abs(dDls));
                mc        = ms(index);
            end
            wc      = (ub(1)-lb(1))*(atan(mc*x(1:length(x)/2) + tan((w/(ub(1)-lb(1)) - .5*(ub(1)+lb(1))/(ub(1)-lb(1)))*pi))./pi +.5*(ub(1)+lb(1))/(ub(1)-lb(1)));
            T2c     = (ub(2)-lb(2))*(atan(mc*x(length(x)/2+1:length(x)) + tan((T2/(ub(2)-lb(2)) - .5*(ub(2)+lb(2))/(ub(2)-lb(2)))*pi))./pi +.5*(ub(2)+lb(2))/(ub(2)-lb(2)));
            % estimate instrument phase
             switch idata.para.dataType
                 case 3
                    Gc       = QTIMonoKernelComplex(g,timeT,T2c,wc);
                    dDls     = [];
                    tmpPhase = [-pi:0.01:pi];
                    for n=1:length(tmpPhase)
%                         TMPd_est = abs(Gc*wc).*exp(1i*(angle(Gc*wc) - tmpPhase(n)));
%                         TMPdD    = [real(D)-real(TMPd_est); imag(D)-imag(TMPd_est)];
                        TMPd_est = Gc*wc;
                        Dcor     = abs(D).*exp(1i*(angle(D) - tmpPhase(n)));
                        TMPdD    = [real(Dcor)-real(TMPd_est); imag(Dcor)-imag(TMPd_est)];
                        dDls(n) = norm([E; E].*TMPdD)/sqrt(length(TMPdD));
                    end
                    [dummy,index] = min(abs(dDls));
                    idata.para.instPhase = tmpPhase(index);
             end
        end
    end
end




