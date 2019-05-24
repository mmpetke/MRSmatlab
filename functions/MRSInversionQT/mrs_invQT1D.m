function idata = mrs_invQT1D(idata)


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

timeT  = idata.data.t + idata.data.effDead;
%timeT  = idata.data.t;
decayT = idata.para.decaySpecVec;

D      = idata.data.d;
E      = 1./idata.data.e;
ub     = idata.para.upperboundWater;
hw     = 1;

dMmin  = idata.para.minModelUpdate;
itmax  = idata.para.maxIteration;


disp('preparation in progress ...');
[g,z]  = mrs_invQTKernelIntegration(idata);
[m,n]  = meshgrid(timeT,decayT);
expM   = exp(-m./n).';
G      = kron(expM,g);


%% smoothness
[Lx,Ly]       = get_l2D(size(g,2),size(decayT,2));
L             = hw*(Lx'*Lx) + Ly'*Ly; clear Lx Ly;
M0            = 0.01/size(timeT,2)*ones(size(g,2)*size(decayT,2),1);

%% some save to structure
idata.inv1Dqt.smoothMulti.decaySpecVec         = decayT;
idata.inv1Dqt.smoothMulti.t                    = timeT;
idata.inv1Dqt.smoothMulti.z                    = z;
idata.inv1Dqt.smoothMulti.g                    = g;
 


%% inversion
disp('start inversion ...'); 
switch length(idata.para.regVec)
    case 1
        as                           = idata.para.regVec;
        k                            = 1;
        runCGLSCDP;                
end

close(tmpgui.fig_data)
close(tmpgui.fig_model)

%% some nested functions due to use memory efficient

    function M_est = runCGLSCDP 

        disp('---------------------------------------')
        disp({'start:', 'lambda = ', num2str(as(k))})
        
        lam          = as(k);
        M_est_old    = M0;
        M_est        = M0;
        [A,b,e]      = transform;
        dM           = cglscdp;
        M_est        = linesearch;
        M_est        = upperbound;
        
        % for temporary plotting
        idata.inv1Dqt.smoothMulti.solution(k).m_est    = M_est;
        idata.inv1Dqt.smoothMulti.solution(k).d        = G*M_est;
        idata.inv1Dqt.smoothMulti.solution(k).dnorm    = norm(E.*(D - abs(G*M_est)))/sqrt(length(D));
        idata.inv1Dqt.smoothMulti.solution(k).mnorm    = norm(L*M_est);
        mrsInvQT_plotData(tmpgui,idata);
        
        n             = 1;
        deltaModel(n) = norm(M_est-M0)/sqrt(length(M_est-M0));
        deltaData(n)  = norm(E.*(D - abs(G*M_est)))/sqrt(length(D));
        
        disp({'std(dM) = ',num2str(deltaModel(n)), 'std(dD) = ', num2str(deltaData(n))});   

        while deltaModel(n) > dMmin

            M_est_old     = M_est;
            n             = n+1;

            [A,b,e]      = transform;
            dM           = cglscdp;
            M_est        = linesearch;
            M_est        = upperbound;
            
            % for temporary plotting
            idata.inv1Dqt.smoothMulti.solution(k).m_est    = M_est;
            idata.inv1Dqt.smoothMulti.solution(k).d        = G*M_est;
            idata.inv1Dqt.smoothMulti.solution(k).dnorm    = norm(E.*(D - abs(G*M_est)))/sqrt(length(D));
            idata.inv1Dqt.smoothMulti.solution(k).mnorm    = norm(L*M_est);
            mrsInvQT_plotData(tmpgui,idata);
            
            deltaModel(n) = norm(M_est-M_est_old)/sqrt(length(M_est));
            deltaData(n)  = norm(E.*(D - abs(G*M_est)))/sqrt(length(D));
                        
            disp({'std(dM) = ',num2str(deltaModel(n)), 'std(dD) = ', num2str(deltaData(n)),'n = ',num2str(n)});   

            if n > itmax
                break;
            end

        end

        function [J,dD,e] = transform
            M       = M_est;
            m       = sum(reshape(M,size(g,2),size(decayT,2)),2);
            MCalib  = ones(size(G,2),1);
            mCalib  = ones(size(g,2),1);
            switch idata.para.dataType
                case {1,2}
                    jA      = AmplitudeJacobian(g,mCalib);
                    JA      = AmplitudeJacobian(G,MCalib);
                    JAW     = JA./repmat(repmat(sum(jA,2),size(timeT,2),1),1,size(M,1));
                    DAW     = D./repmat(sum(jA,2),size(timeT,2),1); % used as b in cglscdp
                    dD      = DAW - JAW*M;
                    J       = TransformJacobian(JAW,M,'log',ub);
                    e       = 1./(idata.data.e./repmat(sum(jA,2),size(timeT,2),1)); % used as D in cglscdp
                case 3
                    dD      = [real(D) - real(G*M); imag(D) - imag(G*M)]; 
                    J       = TransformJacobian([real(G);imag(G)],M,'log',ub);
                    e       = [E;E];
            end
        end

        function x = cglscdp
        D_bkp  = D; D=diag(e); P=1;
        dx     = M_est_old - M0;
        x0     = M0;
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

        function M = linesearch
            Mc = M_est_old;
            
            density  = 7;
            step     = [3,.5,.2,.1];
            dDD      = zeros(density,1);
            mc       = .1;

            for rr=1:length(step)
                ms   = logspace(log10(10^(log10(mc)-step(rr))),...
                    log10(10^(log10(mc)+step(rr))),density);
                for kk=1:density
                    M        = exp(ms(kk)*dM + log(Mc));
                    switch idata.para.dataType
                        case {1,2}
                            dDD(kk)  = norm(abs(G*M) - D);
                        case {3}
                            dDD(kk)  = norm([real(D) - real(G*M); imag(D) - imag(G*M)]);
                    end
                end
                [dummy,index] = min(abs(dDD)); 
                mc            = ms(index);
            end
            M      = exp(mc*dM + log(Mc));
        end
        
        function M = upperbound
            M_tmp    = reshape(M_est,size(g,2),size(decayT,2));
            M_total  = sum(M_tmp,2);

            if max(M_total) > ub+eps % total water content larger than upper bound ?
                indices  = find(M_total > ub+eps); % get all such indices
                if length(indices) < (size(g,2)/2) % apply boundary only if less than 50% is larger

                    % first: scan for neighbouring depth point with total water content
                    % larger than upper bound
                    % put neighbouring together and separate not neighbouring structures
                    l{1} = [indices(1)];
                    nn   = 1;
                    for jj=2:size(indices,1)
                        if indices(jj-1) == indices(jj)-1 % check for neighbours
                            l{nn} = [l{nn} indices(jj)];
                        else
                            nn=nn+1; l{nn}=[indices(jj)];
                        end
                    end

                    % take a single structure with neighbouring depth point and extend
                    % this structure up- and downwards until the mean of all point is
                    % less than the upper boundary
                    for kk = 1:size(l,2)
                        tmp = l{kk}; % initialise the mean calculation
                        istart = tmp(1);
                        iend   = tmp(end);
                        m      = mean(M_total(istart:iend));
                        while m > ub
                            rescue = 0;
                            istart = istart-1; % extend the structure upwards
                            if istart < 1
                                istart=1; rescue = 1;
                            end
                            iend = iend+1;     % extend the structure downwards
                            if iend > size(M_total,1)
                                iend = size(M_total,1); rescue = rescue + 1;
                            end
                            m = mean(M_total(istart:iend)); % calculate the mean water content
                            if rescue == 2
                                M = M_est;
                                return
                            end
                        end
                        % upper boundary is often broken outside the sensitivity range,
                        % i.e. at the largest depth, avoid coruption of the complete
                        % inv. result and simply cut down to the upper boundary
                        if tmp(end) == size(M_total,1)
                            istart = tmp(1);
                            iend   = tmp(end);
                        end
                        % asign the extended structure and recalculate the water
                        % content acording to the upper boundary
                        indices_new = [istart:1:iend];
                        for jjj=1:size(indices_new,2)
                            c     = ub/M_total(indices_new(jjj));
                            M_tmp(indices_new(jjj),:) = c*M_tmp(indices_new(jjj),:);
                        end
                        M_total  = sum(M_tmp,2); % apply changes to have correct M_total for the next structure (indices may overlapping!)
                    end
                else
                    M = M_est;
                end
                M = reshape(M_tmp,size(G,2),1);
            else
                M = M_est;
            end
        end
    end
end