function mrsInvQT_plotData_old(gui,idata,RunToPlot)
if nargin<3;
    k=1;
else
    k=RunToPlot;
end
scaleV=1e9;
% plot data
figure(gui.fig_data)
clf;
[Q,T] = meshgrid(idata.data.q, idata.data.t + idata.data.effDead);

switch idata.para.dataType
    case 1 % amplitudes
        subplot(3,1,1)
                maxZ = max(max(abs(idata.data.dcube.')));
                plot3(Q,T,abs(idata.data.dcube).'*scaleV, 'ro','MarkerSize',3)
                view([320 20]); axis ij; grid on;
                zlim([-maxZ maxZ]*1.05*scaleV);
                xlabel('q /A.s'); ylabel('t /s'); zlabel('abs(Voltage) /V')
                set(gca,'xscale','log')
    case 2 % rotated complex
        subplot(3,1,1)
                maxZ = max(max(real(idata.data.dcube.')));
                plot3(Q,T,real(idata.data.dcube).'*scaleV, 'ro','MarkerSize',3)
                view([320 20]); axis ij; grid on;
                zlim([-maxZ maxZ]*1.05*scaleV);
                xlabel('q /A.s'); ylabel('t /s'); zlabel('real(Voltage) /V')
                set(gca,'xscale','log')
        subplot(3,1,2)
%                 maxZ = max(max(imag(idata.data.dcube.')));
                ErrorWImag = imag(idata.data.dcube)./idata.data.ecube;
%                 imagesc(ErrorWImag)
                plot3(Q,T,ErrorWImag.', 'ro','MarkerSize',3)
                %plot3(Q,T,imag(idata.data.dcube).', 'ro','MarkerSize',3)
                view([320 20]); axis ij; grid on;
                set(gca,'xscale','log','yscale','log')
%                 zlim([-maxZ maxZ]*1.05*scaleV);               
                xlabel('q /A.s'); ylabel('t /s'); zlabel('imag(Voltage)/error /V')
                title([ 'error weighted imaginary part (chi^2 = ' ...
                         num2str(sqrt(sum(sum(ErrorWImag.^2)))/sqrt(numel(ErrorWImag))) ')'])
    case 3 % complex
        % get back to phase uncorrected measured data 
        idata.data.dcube = abs(idata.data.dcube).*exp(1i*(angle(idata.data.dcube) + idata.para.instPhase));
        subplot(3,1,1)
%                 maxZ = max(max(real(idata.data.dcube.')));
                plot3(Q,T,real(idata.data.dcube).'*scaleV, 'ro','MarkerSize',3)
                view([320 20]); axis ij; grid on;
                set(gca,'xscale','log')
%                 zlim([-maxZ maxZ]*1.05*scaleV);
                xlabel('q /A.s'); ylabel('t /s'); zlabel('real(Voltage) /V')
        subplot(3,1,2)
%                 maxZ = abs(max(max(imag(idata.data.dcube.'))));
                plot3(Q,T,imag(idata.data.dcube).'*scaleV, 'ro','MarkerSize',3)
                view([320 20]); axis ij; grid on;
                set(gca,'xscale','log')
%                 zlim([-maxZ maxZ]*1.05*scaleV);
                xlabel('q /A.s'); ylabel('t /s'); zlabel('imag(Voltage) /V')
end

% plot inversion results if exist
if isfield(idata,'inv1Dqt')
    if isfield(idata.inv1Dqt,'solution')
        idata.inv1Dqt = rmfield(idata.inv1Dqt,'solution');
    end
    % check with modelspace is selected
    switch idata.para.modelspace
        case 1 %smooth-multi
            if isfield(idata.inv1Dqt,'smoothMulti')
                idata.inv1Dqt.solution = idata.inv1Dqt.smoothMulti.solution ;
                idata.inv1Dqt.decaySpecVec = idata.inv1Dqt.smoothMulti.decaySpecVec;
                idata.inv1Dqt.z = idata.inv1Dqt.smoothMulti.z;
                idata.inv1Dqt.t = idata.inv1Dqt.smoothMulti.t;
            else
                return
            end            
        case 2 %smooth-mono
            if isfield(idata.inv1Dqt,'smoothMono')
                idata.inv1Dqt.solution = idata.inv1Dqt.smoothMono.solution ;
                idata.inv1Dqt.z = idata.inv1Dqt.smoothMono.z;
                idata.inv1Dqt.t = idata.inv1Dqt.smoothMono.t;
            else
                return
            end
        case 3 %block-mono
            if isfield(idata.inv1Dqt,'blockMono')
                idata.inv1Dqt.solution = idata.inv1Dqt.blockMono.solution ;
                idata.inv1Dqt.z = idata.inv1Dqt.blockMono.z;
                idata.inv1Dqt.t = idata.inv1Dqt.blockMono.t;
            else
                return
            end
    end
    if length(idata.data.d)==length(idata.inv1Dqt.solution(1).d)
        switch length(idata.para.regVec)
            case 1
                dcube     = reshape(idata.inv1Dqt.solution(k).d ,length(idata.data.q),length(idata.inv1Dqt.t));
                switch idata.para.modelspace
                    case 1       
                        M         = reshape(idata.inv1Dqt.solution(1).m_est,length(idata.inv1Dqt.z),length(idata.inv1Dqt.decaySpecVec));
                        decaycube = repmat(idata.inv1Dqt.decaySpecVec,size(M,1),1);                        
                        % water content extrapolation
                        %M         = M.*exp(idata.data.effDead./decaycube);
                        M         = M;
                    case 2
                        %T2        = idata.inv1Dqt.solution(k).T2;
                        %W         = idata.inv1Dqt.solution(k).w.*exp(idata.data.effDead./T2);
                        %W         = idata.inv1Dqt.solution(k).w;
                    case 3
%                         T2    = [idata.inv1Dqt.solution(k).T2(1) idata.inv1Dqt.solution(k).T2];
%                         W     = [idata.inv1Dqt.solution(k).w(1) idata.inv1Dqt.solution(k).w];
%                         Depth = [0 cumsum(idata.inv1Dqt.solution(k).thk) max(idata.inv1Dqt.z)];
                        
                end
            otherwise
        end
        % data fit
        figure(gui.fig_data)
        switch idata.para.dataType
            case 1 % amplitudes
                subplot(3,1,1)
                    ErrorW = (abs(idata.data.dcube)-abs(dcube))./idata.data.ecube;
                    hold on
                    s = mesh(idata.data.q,idata.inv1Dqt.t,abs(dcube.')*scaleV);
                    title([ 'error weighted data fit (chi^2 = ' ...
                        num2str(sqrt(sum(sum(ErrorW.^2)))/sqrt(numel(ErrorW))) ')'])
                    set(s,'EdgeColor','k')
                    if length(idata.inv1Dqt.t) == length(idata.data.t)
                        subplot(3,2,5)
                        pcolor(idata.data.t+idata.data.effDead,idata.data.q,(abs(idata.data.dcube) - abs(dcube))./idata.data.ecube*scaleV)
                        axis ij; shading flat;
                        set(gca,'Xscale','log','Yscale','log');
                        ylabel('q/A.s');xlabel('t/s');
                        subplot(3,2,6)
                        hist(reshape(abs(idata.data.dcube) - abs(dcube),numel(dcube),1),50)
                        grid on;
                    end
                
            case 2 % rotated complex
                subplot(3,1,1)
                    ErrorW = (real(idata.data.dcube)-abs(dcube))./idata.data.ecube;
                    hold on
                    s = mesh(idata.data.q,idata.inv1Dqt.t,abs(dcube.')*scaleV);
                    title([ 'error weighted data fit (chi^2 = ' ...
                        num2str(sqrt(sum(sum(ErrorW.^2)))/sqrt(numel(ErrorW))) ')'])
                    set(s,'EdgeColor','k')
                    if length(idata.inv1Dqt.t) == length(idata.data.t)
                        subplot(3,2,5)
                            pcolor(idata.data.t+idata.data.effDead,idata.data.q,(real(idata.data.dcube) - abs(dcube))./idata.data.ecube*scaleV)
                            set(gca,'Xscale','log','Yscale','log');
                            ylabel('q/A.s');xlabel('t/s');
                            axis ij; shading flat
                        subplot(3,2,6)
                            hist(reshape((real(idata.data.dcube) - abs(dcube)),numel(dcube),1)*scaleV,150)
                            xlabel('deviation / nV');
                            grid on
                    end
            case 3 % complex               
                dcube = abs(dcube).*exp(1i*(angle(dcube) + idata.para.instPhase));
                subplot(3,1,1)
                    ErrorW = (real(idata.data.dcube)-real(dcube))./idata.data.ecube;
                    hold on
                    s = mesh(idata.data.q,idata.inv1Dqt.t,real(dcube.')*scaleV);
                    title([ 'error weighted data fit (chi^2 = ' ...
                        num2str(sqrt(sum(sum(ErrorW.^2)))/sqrt(numel(ErrorW))) ')'])
                    set(s,'EdgeColor','k')
                subplot(3,1,2)
                    ErrorW = (imag(idata.data.dcube)-imag(dcube))./idata.data.ecube;
                    hold on
                    s = mesh(idata.data.q,idata.inv1Dqt.t,imag(dcube.')*scaleV);
                    title([ 'error weighted data fit (chi^2 = ' ...
                        num2str(sqrt(sum(sum(ErrorW.^2)))/sqrt(numel(ErrorW))) ')'])
                    set(s,'EdgeColor','k')
                    
        end
        
        % estimated model
        % determine max. penetration depth cummalative kernel --> auken et al. ???
        cumK = (abs(cumsum(fliplr(idata.kernel.K*0.3),2))); % cumalitive sensitivity, i.e. halfspace from bottom with 0.3 water content change 
        for iq=1:size(cumK,1)
            dummy       = idata.kernel.z(length(idata.kernel.z)+1-find(cumK(iq,:) > mean(idata.data.efit),1));
            if ~isempty(dummy)
                penMaxZvec(iq) = dummy;
            else
                penMaxZvec(iq) = 0;
            end
        end
        penMaxZ = max(penMaxZvec);
        if isempty(penMaxZ); penMaxZ = idata.inv1Dqt.z(end);end;
        figure(gui.fig_model);clf;
        YL = [0 idata.para.maxDepth*1.1];
        switch idata.para.modelspace
            case 1        
                subplot(1,5,1:2)
                    pcolor(idata.para.decaySpecVec,idata.inv1Dqt.z(1)/2 + [-idata.inv1Dqt.z(1)/2 idata.inv1Dqt.z],[M;M(end,:)])
                    axis ij;box on;shading flat;
                    set(gca,'Xscale','log');
                    cc=colorbar;set(get(cc,'YLabel'),'String', 'water content/ m^3/m^3')
                    xlabel('Decay time T_2^*/ s');ylabel('Depth/ m')
                    ylim([YL])
                
                subplot(1,5,4)
                    logmeanT2 = exp(sum(M.*log(decaycube),2)./sum(M,2));
                    stairs([logmeanT2(1); logmeanT2],[0 idata.inv1Dqt.z])
                    axis ij; set(gca,'Xscale','lin'); grid on
                    set(gca,'Xminorgrid','off'); box on
                    xlabel('Decay time T_2^*/ s')
                    ylim([YL])
                
                subplot(1,5,5)
                    tw = sum(M,2);
                    stairs([tw(1); tw],[0 idata.inv1Dqt.z])
                    axis ij; grid on
                    xlabel('Water content/ m^3/m^3')
                    ylim([YL])
            case 2
                subplot(1,5,1:2)
                        hold off
                subplot(1,5,4:5)
                        hold off
                for irun = 1:length(idata.inv1Dqt.solution)
                    T2        = idata.inv1Dqt.solution(irun).T2;
                    %W         = idata.inv1Dqt.solution(k(irun)).w.*exp(idata.data.effDead./T2);
                    W         = idata.inv1Dqt.solution(irun).w;
                    subplot(1,5,1:2)
                        if irun==1
                            stairs([T2(1); T2],[0 idata.inv1Dqt.z],'k','Linewidth',2)
                        else
                            stairs([T2(1); T2],[0 idata.inv1Dqt.z],'Color',[.6 .6 .6])
                        end
                        hold on
                        plot([idata.para.lowerboundT2 max([idata.para.upperboundT2 1])],[penMaxZ penMaxZ],'--k','Color',[.8 .8 .8],'Linewidth',2)
                        plot([0.1 0.1],[YL],'--','Color',[.8 .8 .8],'Linewidth',1);
                        axis ij; set(gca,'Xscale','log'); grid on
                        set(gca,'Xminorgrid','off');
                        xlabel('Decay time T_2^* /s')
                        ylim([YL])
                        xlim([idata.para.lowerboundT2 max([idata.para.upperboundT2 1])])
                    subplot(1,5,4:5)
                        if irun==1
                            stairs([W(1); W],[0 idata.inv1Dqt.z],'k','Linewidth',2)
                        else
                            stairs([W(1); W],[0 idata.inv1Dqt.z],'Color',[.6 .6 .6])
                        end
                        hold on
                        plot([idata.para.lowerboundWater idata.para.upperboundWater],[penMaxZ penMaxZ],'--k','Color',[.8 .8 .8],'Linewidth',2)
                        plot([0.1 0.1],[YL],'--','Color',[.8 .8 .8],'Linewidth',1);
                        %plot(W,idata.inv1Dqt.z)
                        axis ij; grid on
                        xlabel('Water content / m^3/m^3')
                        xlim([idata.para.lowerboundWater idata.para.upperboundWater])
                        ylim([YL])
                end
            case 3
                subplot(1,5,1:2)
                        hold off
                subplot(1,5,4:5)
                        hold off
                for irun = length(idata.inv1Dqt.solution):-1:1
                        T2    = [idata.inv1Dqt.solution(irun).T2(1) idata.inv1Dqt.solution(irun).T2];
                        W     = [idata.inv1Dqt.solution(irun).w(1) idata.inv1Dqt.solution(irun).w];
                        Depth = [0 cumsum(idata.inv1Dqt.solution(irun).thk) max(idata.inv1Dqt.z)];
                        subplot(1,5,1:2)
                            if irun==1
                                stairs(T2,Depth,'k','Linewidth',2)
                            else
                                stairs(T2,Depth,'Color',[.6 .6 .6])
                            end
                            hold on
                            plot([idata.para.lowerboundT2 max([idata.para.upperboundT2 1])],[penMaxZ penMaxZ],'--k','Color',[.8 .8 .8],'Linewidth',2)
                            axis ij; set(gca,'Xscale','log'); grid on
                            set(gca,'Xminorgrid','off');
                            xlabel('Decay time T_2^* /s')
                            ylim([YL])
                            xlim([idata.para.lowerboundT2 max([idata.para.upperboundT2 1])])
                        subplot(1,5,4:5)
                            if irun==1
                                stairs(W,Depth,'k','Linewidth',2)
                            else
                                stairs(W,Depth,'Color',[.6 .6 .6])
                            end
                            hold on
                            plot([idata.para.lowerboundWater idata.para.upperboundWater],[penMaxZ penMaxZ],'--k','Color',[.8 .8 .8],'Linewidth',2)
                            axis ij; grid on
                            xlabel('Water content / m^3/m^3')
                            xlim([idata.para.lowerboundWater idata.para.upperboundWater])
                            ylim([YL])
                end

        end
        
    end
end
drawnow


