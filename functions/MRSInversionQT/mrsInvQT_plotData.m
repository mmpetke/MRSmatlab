function mrsInvQT_plotData(gui,idata,RunToPlot)
if nargin<3;
    k=1;
else
    k=RunToPlot;
end
scaleV=1e9;
% plot data
set(0,'currentFigure',gui.fig_data)
% figure(gui.fig_data);
clf;
[Q,T] = meshgrid(idata.data.q, idata.data.t + idata.data.effDead);

%idata.data.dcube = abs(idata.data.dcube).*exp(1i*(angle(idata.data.dcube) - idata.para.instPhase));

switch idata.para.dataType
    case 1 % amplitudes
        subplot(3,2,1)
                %pcolor(idata.data.t + idata.data.effDead, idata.data.q, abs(idata.data.dcube)*scaleV)
                imagesc(abs(idata.data.dcube)*scaleV)
                a=get(gca,'xtick');a(a<1)=[];a=unique(floor(a));set(gca,'xtick',a)
                axis ij; shading flat
                set(gca,'xticklabel',num2str(0.01*round(100*(idata.data.effDead + idata.data.t(get(gca,'xtick')).'))))
                set(gca,'yticklabel',num2str(0.01*round(100*idata.data.q(get(gca,'ytick')))))
                %set(gca,'yscale','log','xscale','log')
                colorbar
                title('abs(observed voltages) /nV')
                ylabel('q /A.s'); xlabel('t /s'); 
                maxZ = max(max(abs(idata.data.dcube.'))); if maxZ==0; maxZ=eps;end
                set(gca,'clim',([-maxZ/10 maxZ]*1.05*scaleV));
    case 2 % rotated complex
        subplot(3,2,1)
%                 pcolor(idata.data.t + idata.data.effDead, idata.data.q, real(idata.data.dcube)*scaleV)
                imagesc(real(idata.data.dcube)*scaleV)
                a=get(gca,'xtick');a(a<1)=[];a=unique(floor(a));set(gca,'xtick',a)
                axis ij; shading flat
                set(gca,'xticklabel',num2str(0.01*round(100*(idata.data.effDead + idata.data.t(get(gca,'xtick')).'))))
                set(gca,'yticklabel',num2str(0.01*round(100*idata.data.q(get(gca,'ytick')))))
%                 set(gca,'yscale','log','xscale','log')
                colorbar
                title('real(observed voltages) /nV')
                ylabel('q /A.s'); xlabel('t /s'); 
        subplot(3,2,2)
                ErrorWImag = imag(idata.data.dcube)./idata.data.ecube;
%                 pcolor(idata.data.t + idata.data.effDead, idata.data.q, ErrorWImag)
                imagesc(ErrorWImag)
                a=get(gca,'xtick');a(a<1)=[];a=unique(floor(a));set(gca,'xtick',a)
                axis ij; shading flat
                set(gca,'xticklabel',num2str(0.01*round(100*(idata.data.effDead + idata.data.t(get(gca,'xtick')).'))))
                set(gca,'yticklabel',num2str(0.01*round(100*idata.data.q(get(gca,'ytick')))))
%                 set(gca,'yscale','log','xscale','log')
                colorbar
                ylabel('q /A.s'); xlabel('t /s'); 
                title('imaginary/error')
                title([ 'error weighted imaginary part (chi^2 = ' ...
                         num2str(sqrt(sum(sum(ErrorWImag.^2)))/sqrt(numel(ErrorWImag))) ')'])
    case 3 % complex
        subplot(3,2,1)
%                 pcolor(idata.data.t + idata.data.effDead, idata.data.q, real(idata.data.dcube)*scaleV)
                imagesc(real(idata.data.dcube)*scaleV)
                a=get(gca,'xtick');a(a<1)=[];a=unique(floor(a));set(gca,'xtick',a)
                axis ij; shading flat
                set(gca,'xticklabel',num2str(0.01*round(100*(idata.data.effDead + idata.data.t(get(gca,'xtick')).'))))
                set(gca,'yticklabel',num2str(0.01*round(100*idata.data.q(get(gca,'ytick')))))
%                 set(gca,'yscale','log','xscale','log')
                maxZ = max(max(real(idata.data.dcube.'))); if maxZ==0; maxZ=eps;end
                minZ = min(min(real(idata.data.dcube.'))); if minZ==0; minZ=-eps;end
                set(gca,'clim',([minZ maxZ]*1.05*scaleV));
                colorbar
                title('real(observed voltages) /nV')
                ylabel('q /A.s'); xlabel('t /s'); 
        subplot(3,2,2)
%                 pcolor(idata.data.t + idata.data.effDead, idata.data.q, imag(idata.data.dcube)*scaleV)
                imagesc(imag(idata.data.dcube)*scaleV)
                a=get(gca,'xtick');a(a<1)=[];a=unique(floor(a));set(gca,'xtick',a)
                axis ij; shading flat
                set(gca,'xticklabel',num2str(0.01*round(100*(idata.data.effDead + idata.data.t(get(gca,'xtick')).'))))
                set(gca,'yticklabel',num2str(0.01*round(100*idata.data.q(get(gca,'ytick')))))
%                 set(gca,'yscale','log','xscale','log')
                maxZ = max(max(imag(idata.data.dcube.')));if maxZ==0; maxZ=eps;end
                minZ = min(min(imag(idata.data.dcube.')));if minZ==0; minZ=-eps;end
                set(gca,'clim',([minZ maxZ]*1.05*scaleV));
                colorbar
                title('imaginary(observed voltages) /nV')
                ylabel('q /A.s'); xlabel('t /s'); 
end

% plot inversion results if exist
if isfield(idata,'inv1Dqt')
    if isfield(idata.inv1Dqt,'solution')
        idata.inv1Dqt = rmfield(idata.inv1Dqt,'solution');
    end
    % check which modelspace is selected
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
                dcube     = abs(dcube).*exp(1i*(angle(dcube) + idata.para.instPhase));
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
        set(0,'currentFigure',gui.fig_data)
        %figure(gui.fig_data)
        switch idata.para.dataType
            case 1 % amplitudes
                subplot(3,2,3)
                    ErrorW = (abs(idata.data.dcube)-abs(dcube))./idata.data.ecube;
%                     pcolor(idata.data.t + idata.data.effDead, idata.data.q, abs(dcube)*scaleV)
                    imagesc(abs(dcube)*scaleV)
                    a=get(gca,'xtick');a(a<1)=[];a=unique(floor(a));set(gca,'xtick',a)
                    axis ij; shading flat
                    set(gca,'xticklabel',num2str(0.01*round(100*(idata.data.effDead + idata.data.t(get(gca,'xtick')).'))))
                    set(gca,'yticklabel',num2str(0.01*round(100*idata.data.q(get(gca,'ytick')))))
%                     set(gca,'yscale','log','xscale','log')
                    colorbar
                    title('abs(simulated voltages) /nV')
                    ylabel('q /A.s'); xlabel('t /s');
                    maxZ = max(max(abs(idata.data.dcube.')));
                    set(gca,'clim',([-maxZ/10 maxZ]*1.05*scaleV));
                    if length(idata.inv1Dqt.t) == length(idata.data.t)
                        subplot(3,2,5)
                        imagesc(ErrorW)
                        a=get(gca,'xtick');a(a<1)=[];a=unique(floor(a));set(gca,'xtick',a)
                        set(gca,'xticklabel',num2str(0.01*round(100*(idata.data.effDead + idata.data.t(get(gca,'xtick')).'))))
                        set(gca,'yticklabel',num2str(0.01*round(100*idata.data.q(get(gca,'ytick')))))
                        axis ij; shading flat;colorbar
                        %set(gca,'Xscale','log','Yscale','log');
                        title([ 'error weighted data fit (chi^2 = ' ...
                        num2str(sqrt(sum(sum(ErrorW.^2)))/sqrt(numel(ErrorW))) ')'])
                        ylabel('q/A.s');xlabel('t/s');
                    end
                
            case 2 % rotated complex
                subplot(3,2,3)
                    ErrorW = (real(idata.data.dcube)-abs(dcube))./idata.data.ecube;
%                     pcolor(idata.data.t + idata.data.effDead, idata.data.q, abs(dcube)*scaleV)
                    imagesc(abs(dcube)*scaleV)
                    a=get(gca,'xtick');a(a<1)=[];a=unique(floor(a));set(gca,'xtick',a)
                    axis ij; shading flat
                    set(gca,'xticklabel',num2str(0.01*round(100*(idata.data.effDead + idata.data.t(get(gca,'xtick')).'))))
                    set(gca,'yticklabel',num2str(0.01*round(100*idata.data.q(get(gca,'ytick')))))
%                     set(gca,'yscale','log','xscale','log')
                    colorbar
                    title('real(simulated voltages) /nV')
                    ylabel('q /A.s'); xlabel('t /s'); 
                    maxZ = max(max(abs(idata.data.dcube.')));
                    set(gca,'clim',([-maxZ/10 maxZ]*1.05*scaleV));
                    if length(idata.inv1Dqt.t) == length(idata.data.t)
                        subplot(3,2,5)
%                         pcolor(idata.data.t+idata.data.effDead,idata.data.q,ErrorW)
                        imagesc(ErrorW)
                        a=get(gca,'xtick');a(a<1)=[];a=unique(floor(a));set(gca,'xtick',a)
                        set(gca,'xticklabel',num2str(0.01*round(100*(idata.data.effDead + idata.data.t(get(gca,'xtick')).'))))
                        set(gca,'yticklabel',num2str(0.01*round(100*idata.data.q(get(gca,'ytick')))))
                        axis ij; shading flat;colorbar
%                         set(gca,'Xscale','log','Yscale','log');
                        title([ 'error weighted data fit (chi^2 = ' ...
                        num2str(sqrt(sum(sum(ErrorW.^2)))/sqrt(numel(ErrorW))) ')'])
                        ylabel('q/A.s');xlabel('t/s');
                    end
                    
            case 3 % complex               
                subplot(3,2,3)
                    ErrorW = (real(idata.data.dcube)-real(dcube))./idata.data.ecube;
%                     pcolor(idata.data.t + idata.data.effDead, idata.data.q, real(dcube)*scaleV)
                    imagesc(real(dcube)*scaleV)
                    a=get(gca,'xtick');a(a<1)=[];a=unique(floor(a));set(gca,'xtick',a)
                    axis ij; shading flat
                    set(gca,'xticklabel',num2str(0.01*round(100*(idata.data.effDead + idata.data.t(get(gca,'xtick')).'))))
                    set(gca,'yticklabel',num2str(0.01*round(100*idata.data.q(get(gca,'ytick')))))
%                     set(gca,'yscale','log','xscale','log')
                    colorbar
                    title('real(simulated voltages) /nV')
                    ylabel('q /A.s'); xlabel('t /s');
                    
                    maxZ = max(max(real(idata.data.dcube.')));
                    minZ = min(min(real(idata.data.dcube.')));
                    set(gca,'clim',([minZ maxZ]*1.05*scaleV));
                    if length(idata.inv1Dqt.t) == length(idata.data.t)
                        subplot(3,2,5)
%                         pcolor(idata.data.t+idata.data.effDead,idata.data.q,ErrorW)
                        imagesc(ErrorW)
                        a=get(gca,'xtick');a(a<1)=[];a=unique(floor(a));set(gca,'xtick',a)
                        axis ij; shading flat;colorbar
                        set(gca,'xticklabel',num2str(0.01*round(100*(idata.data.effDead + idata.data.t(get(gca,'xtick')).'))))
                        set(gca,'yticklabel',num2str(0.01*round(100*idata.data.q(get(gca,'ytick')))))
                        title([ 'error weighted data fit (chi^2 = ' ...
                        num2str(sqrt(sum(sum(ErrorW.^2)))/sqrt(numel(ErrorW))) ')'])
%                         set(gca,'Xscale','log','Yscale','log');
                        ylabel('q/A.s');xlabel('t/s');
                    end
                subplot(3,2,4)
                    ErrorW = (imag(idata.data.dcube)-imag(dcube))./idata.data.ecube;
%                     pcolor(idata.data.t + idata.data.effDead, idata.data.q, imag(dcube)*scaleV)
                    imagesc(imag(dcube)*scaleV)
                    a=get(gca,'xtick');a(a<1)=[];a=unique(floor(a));set(gca,'xtick',a)
                    axis ij; shading flat
                    set(gca,'xticklabel',num2str(0.01*round(100*(idata.data.effDead + idata.data.t(get(gca,'xtick')).'))))
                    set(gca,'yticklabel',num2str(0.01*round(100*idata.data.q(get(gca,'ytick')))))
%                     set(gca,'yscale','log','xscale','log')
                    colorbar
                    title('imag(simulated voltages) /nV')
                    ylabel('q /A.s'); xlabel('t /s');
                    maxZ = max(max(imag(idata.data.dcube.')));
                    minZ = min(min(imag(idata.data.dcube.')));
                    set(gca,'clim',([minZ maxZ]*1.05*scaleV));
                    if length(idata.inv1Dqt.t) == length(idata.data.t)
                        subplot(3,2,6)
%                         pcolor(idata.data.t+idata.data.effDead,idata.data.q,ErrorW)
                        imagesc(ErrorW)
                        a=get(gca,'xtick');a(a<1)=[];a=unique(floor(a));set(gca,'xtick',a)
                        set(gca,'xticklabel',num2str(0.01*round(100*(idata.data.effDead + idata.data.t(get(gca,'xtick')).'))))
                        set(gca,'yticklabel',num2str(0.01*round(100*idata.data.q(get(gca,'ytick')))))
                        axis ij; shading flat;colorbar
%                         set(gca,'Xscale','log','Yscale','log');
                        title([ 'error weighted data fit (chi^2 = ' ...
                        num2str(sqrt(sum(sum(ErrorW.^2)))/sqrt(numel(ErrorW))) ')'])
                        ylabel('q/A.s');xlabel('t/s');
                    end
                    
        end
        
        % estimated model
        % determine max. penetration depth cummalative kernel --> auken et al. ???
        cumK = (abs(cumsum(fliplr(idata.kernel.K*0.3),2))); % cumulative sensitivity, i.e. halfspace from bottom with 0.3 water content change 
        for iq=1:size(cumK,1)
            dummy       = idata.kernel.z(length(idata.kernel.z)+1-find(cumK(iq,:) > 2*mean(idata.data.estack),1));
            if ~isempty(dummy)
                penMaxZvec(iq) = dummy;
            else
                penMaxZvec(iq) = 0;
            end
        end
        penMaxZ = max(penMaxZvec);
        if isempty(penMaxZ); penMaxZ = idata.inv1Dqt.z(end);end;
        
        set(0,'currentFigure',gui.fig_model)
        %figure(gui.fig_model);
        clf;
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
%                     if idata.inv1Dqt.solution(irun).dnorm < 1.05
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
%                     end
                end
                
            case 3
                chi2plot = str2num(get(gui.para.minModelUpdate,'String')); % misfit limit for model to be plotted 
                misfit   = [];
                subplot(1,5,1:2)
                        hold off
                subplot(1,5,4:5)
                        hold off
                for irun = length(idata.inv1Dqt.solution):-1:1
                    if idata.inv1Dqt.solution(irun).dnorm < chi2plot
                        T2     = [idata.inv1Dqt.solution(irun).T2(1) idata.inv1Dqt.solution(irun).T2];
                        W      = [idata.inv1Dqt.solution(irun).w(1) idata.inv1Dqt.solution(irun).w];
                        Depth  = [0 cumsum(idata.inv1Dqt.solution(irun).thk) max(idata.inv1Dqt.z)];
                        misfit = [idata.inv1Dqt.solution(irun).dnorm misfit];
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
                figure(100); plot(misfit,'x'); title('distribution of misfit for all models'); ylabel('chi^2'); xlabel('run');
        end
        
    end
end
drawnow


