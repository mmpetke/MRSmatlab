%% FUNCTION plot data

function plotMRST1Data(idata,gui)

figure(gui.fig_data)
clf

scaleV   = 1e9;
dataType = 2; % 1: amplitudes, 2: rotated

fontname = 'Liberation Mono';
fontsize = 14;

switch dataType
    case 1
        cl = [0 1.1*max(max(abs(idata.data(end).dcube)))];
    case 2
        cl = [1.1*min(min(real(idata.data(end).dcube))) 1.1*max(max(real(idata.data(end).dcube)))];
end


%% plot WC/T2* inversion results
if isfield(idata,'inv1Dqt')
    % check which modelspace is selected
    switch idata.para.modelspace         
        case 1 %smooth-mono
            if isfield(idata.inv1Dqt,'smoothMono')
                idata.inv1Dqt.solution = idata.inv1Dqt.smoothMono.solution ;
                idata.inv1Dqt.z = idata.inv1Dqt.smoothMono.z;
                idata.inv1Dqt.t = idata.inv1Dqt.smoothMono.t;
            else
                return
            end
        case 2 %block-mono
            if isfield(idata.inv1Dqt,'blockMono')
                idata.inv1Dqt.solution = idata.inv1Dqt.blockMono.solution ;
                idata.inv1Dqt.z = idata.inv1Dqt.blockMono.z;
                idata.inv1Dqt.t = idata.inv1Dqt.blockMono.t;
            else
                return
            end
    end
    % data
%     figure(gui.fig_data)
%     dcube   = reshape(idata.inv1Dqt.solution(1).d ,length(idata.data(end).q1),length(idata.inv1Dqt.t));
%     subplot(length(idata.data),3,3*length(idata.data)-1)
%         pcolor(idata.inv1Dqt.t,idata.data(end).q1,abs(dcube))
%         axis ij; shading flat;
%         set(gca,'Xscale','log','Yscale','lin');
%         ylabel('q/A.s','FontName',fontname,'Fontsize',fontsize);
%         xlabel('t/s','FontName',fontname,'Fontsize',fontsize);
%         set(gca,'CLim',cl)
        
    % model
    figure(gui.fig_model)
    clf
    switch idata.para.modelspace
        case 1 % smooth mono
            for iSol=1:length(idata.inv1Dqt.solution)
                T2        = idata.inv1Dqt.solution(iSol).T2;
                W         = idata.inv1Dqt.solution(iSol).w;
                subplot(1,3,1)
                    stairs([T2(1); T2],[0 idata.inv1Dqt.z],'Color',[.6 .6 .6])
                    hold on
                subplot(1,3,2)
                    stairs([W(1); W],[0 idata.inv1Dqt.z],'Color',[.6 .6 .6])
                    hold on
            end           
            T2        = idata.inv1Dqt.solution(1).T2;
            W         = idata.inv1Dqt.solution(1).w;
            subplot(1,3,1)
                stairs([T2(1); T2],[0 idata.inv1Dqt.z],'k','Linewidth',2)
                axis ij; set(gca,'Xscale','log'); grid on
                set(gca,'Xminorgrid','off');
                xlabel('Decay time T_2^* /s','FontName',fontname,'Fontsize',fontsize)
                ylabel('Depth /m','FontName',fontname,'Fontsize',fontsize)
                set(gca,'FontName',fontname,'Fontsize',fontsize)
            subplot(1,3,2)
                stairs([W(1); W],[0 idata.inv1Dqt.z],'k','Linewidth',2)
                axis ij; grid on
                xlabel('Water content / m^3/m^3','FontName',fontname,'Fontsize',fontsize)
                set(gca,'FontName',fontname,'Fontsize',fontsize)
            
        case 2 % block mono
            for iSol=1:length(idata.inv1Dqt.blockMono.solution)
               T2    = [idata.inv1Dqt.blockMono.solution(iSol).T2(1) idata.inv1Dqt.blockMono.solution(iSol).T2];
               W     = [idata.inv1Dqt.blockMono.solution(iSol).w(1) idata.inv1Dqt.blockMono.solution(iSol).w];
               Depth = [0 cumsum(idata.inv1Dqt.blockMono.solution(iSol).thk) max(idata.inv1Dqt.z)];
               
               subplot(1,3,1)
                stairs(T2,Depth,'Color',[.6 .6 .6])
                hold on
               subplot(1,3,2)
                stairs(W,Depth,'Color',[.6 .6 .6])
                hold on
           end
            T2    = [idata.inv1Dqt.solution(1).T2(1) idata.inv1Dqt.solution(1).T2];
            W     = [idata.inv1Dqt.solution(1).w(1) idata.inv1Dqt.solution(1).w];
            Depth = [0 cumsum(idata.inv1Dqt.solution(1).thk) max(idata.inv1Dqt.z)];
            
            subplot(1,3,1)
                stairs(T2,Depth,'k','Linewidth',2)
                hold on
                axis ij; set(gca,'Xscale','log'); grid on
                set(gca,'Xminorgrid','off');
                xlabel('Decay time T_2^* /s','FontName',fontname,'Fontsize',fontsize)
                ylabel('Depth /m','FontName',fontname,'Fontsize',fontsize)
                set(gca,'FontName',fontname,'Fontsize',fontsize)
            subplot(1,3,2)
                stairs(W,Depth,'k','Linewidth',2)
                hold on
                axis ij; grid on
                xlabel('Water content / m^3/m^3','FontName',fontname,'Fontsize',fontsize)
                set(gca,'FontName',fontname,'Fontsize',fontsize)
           
    end
    
end

%% plot measured

%% plot T1 inversion results
show=0;
if isfield(idata,'inv1DT1')
    switch idata.para.modelspace        
        case 1 
            if isfield(idata.inv1DT1,'smooth')
            if isfield(idata.inv1DT1.smooth,'data')
                idata.inv1DT1.data = idata.inv1DT1.smooth.data;
                show=1;
            end 
            end
        case 2
            if isfield(idata.inv1DT1,'block')
            if isfield(idata.inv1DT1.block,'data')
                idata.inv1DT1.data = idata.inv1DT1.block.data;
                show=1;
            end 
            end
    end
    
    figure(gui.fig_data)
    if show % plot observed and estimated
    clf
    % common colorbars
    % data
    cl = [0 1.1*max(idata.inv1DT1.data(end).d)];
    % misfit
    d     = reshape(idata.inv1DT1.data(end).d,length(idata.inv1DT1.data(end).q1),length(idata.inv1DT1.data(end).t));
    d_est = reshape(idata.inv1DT1.data(end).d_est,length(idata.inv1DT1.data(end).q1),length(idata.inv1DT1.data(end).t));
    err   = (d-d_est)./idata.inv1DT1.data(end).ecube; 
    cle   = 1.1*[min(min(err)) max(max(err))];
    for itau = 1:length(idata.inv1DT1.data)
        % first column - observed data
        subplot(length(idata.inv1DT1.data),3,3*itau-2)
            d     = reshape(idata.inv1DT1.data(itau).d,length(idata.inv1DT1.data(itau).q1),length(idata.inv1DT1.data(itau).t));
%             pcolor(idata.inv1DT1.data(itau).t,idata.inv1DT1.data(itau).q1,d)
            imagesc(d)
            axis ij; shading flat;
            ylabel({['\tau = ' num2str(idata.tau(itau)) 's']},'FontName',fontname,'Fontsize',fontsize);
            set(gca,'CLim',cl)
            
            if itau == 1
                title('observed data','FontName',fontname,'Fontsize',fontsize);                     
            end
            if itau ~= length(idata.inv1DT1.data)
                nxt=3;
                nyt=3;
                a = round([0.5/nxt:1/nxt:1]*size(d,2));
                for nL = 1:length(a)
                    XTickLabelNew(nL,:) = sprintf('%04.2f', idata.inv1DT1.data(itau).t(a(nL)));
                end
                b = round([0.5/nyt:1/nyt:1]*size(d,1));
                for nq = 1:length(b)
                    YTickLabelNew(nq,:) = sprintf('% 5.2f', idata.inv1DT1.data(itau).q1(b(nq)));
                end
                if itau == length(idata.inv1DT1.data)-1
                    xlabel('t/s','FontName',fontname,'Fontsize',fontsize); 
                    set(gca,'YTickMode','manual','YTickLabelMode','manual','XTickMode','manual','XTickLabelMode','manual')
                    set(gca,'FontName',fontname,'Fontsize',fontsize)
                    set(gca,'XTick',a,'YTick',b)
                    set(gca,'YTick',[],'XTickLabel',XTickLabelNew);
                else
                    set(gca,'XTick',[],'YTick',[]);
                    set(gca,'FontName',fontname,'Fontsize',fontsize)  
                end
                % set larger subfigure sizes
                subsize=get(gca,'Position');movex = 0.2*subsize(3);movey = 0.2*subsize(4);
                subsize([3 4])=1.2*subsize([3 4]);subsize(1)=subsize(1)-movex;
                set(gca,'Position',subsize)
            end
            if itau == length(idata.inv1DT1.data);
                nxt=3;
                nyt=3;
                a = round([0.5/nxt:1/nxt:1]*size(d,2));
                for nL = 1:length(a)
                    XTickLabelNew(nL,:) = sprintf('%04.2f', idata.inv1DT1.data(itau).t(a(nL)));
                end
                b = round([0.5/nyt:1/nyt:1]*size(d,1));
                for nq = 1:length(b)
                    YTickLabelNew(nq,:) = sprintf('% 5.2f', idata.inv1DT1.data(itau).q1(b(nq)));
                end 
                xlabel('t/s','FontName',fontname,'Fontsize',fontsize); 
                set(gca,'YTickMode','manual','YTickLabelMode','manual','XTickMode','manual','XTickLabelMode','manual')
                set(gca,'FontName',fontname,'Fontsize',fontsize)
                set(gca,'XTick',a,'YTick',b)
                set(gca,'YTick',[],'XTickLabel',XTickLabelNew);
                % set larger subfigure sizes
                subsize=get(gca,'Position');
                subsize([3])=1.2*subsize([3]); subsize(1)=subsize(1)-movex;subsize(2)=subsize(2)-movey;
                set(gca,'Position',subsize)
            end
            
            
        % second column - estimated data    
        subplot(length(idata.inv1DT1.data),3,3*itau-1)            
            d_est = reshape(idata.inv1DT1.data(itau).d_est,length(idata.inv1DT1.data(itau).q1),length(idata.inv1DT1.data(itau).t));
%             pcolor(idata.inv1DT1.data(itau).t,idata.inv1DT1.data(itau).q1,d_est)
            imagesc(d_est)
            axis ij; shading flat;
            set(gca,'CLim',cl)
            set(gca,'YAxisLocation','right')
            if itau == 1
                title('estimated data','FontName',fontname,'Fontsize',fontsize);
            end
            ylabel('q/A.s','FontName',fontname,'Fontsize',fontsize);
            if itau ~= length(idata.inv1DT1.data) 
                if itau == length(idata.inv1DT1.data)-1
                    xlabel('t/s','FontName',fontname,'Fontsize',fontsize); 
                    set(gca,'YTickMode','manual','YTickLabelMode','manual','XTickMode','manual','XTickLabelMode','manual')
                    set(gca,'FontName',fontname,'Fontsize',fontsize)
                    set(gca,'XTick',a,'YTick',b)
                    set(gca,'YTickLabel',YTickLabelNew,'XTickLabel',XTickLabelNew);
                else
                    set(gca,'YTickMode','manual','YTickLabelMode','manual','XTickMode','manual','XTickLabelMode','manual')
                    set(gca,'FontName',fontname,'Fontsize',fontsize)
                    set(gca,'XTick',a,'YTick',b)
                    set(gca,'XTick',[],'YTickLabel',YTickLabelNew);
                    set(gca,'FontName',fontname,'Fontsize',fontsize)  
                end
                % set larger subfigure sizes
                subsize=get(gca,'Position');
                subsize([3 4])=1.2*subsize([3 4]);subsize(1)=subsize(1)-movex;
                set(gca,'Position',subsize)
            end
            if itau == length(idata.inv1DT1.data)
                xlabel('t/s','FontName',fontname,'Fontsize',fontsize);
                set(gca,'YTickMode','manual','YTickLabelMode','manual','XTickMode','manual','XTickLabelMode','manual')
                set(gca,'FontName',fontname,'Fontsize',fontsize)
                set(gca,'XTick',a,'YTick',b)
                set(gca,'XTickLabel',XTickLabelNew,'YTickLabel',YTickLabelNew);
                % set larger subfigure sizes
                subsize=get(gca,'Position');
                subsize([3])=1.2*subsize([3]); subsize(1)=subsize(1)-movex;subsize(2)=subsize(2)-movey;
                set(gca,'Position',subsize)
            end

            
       subplot(length(idata.inv1DT1.data),3,3*itau)
            err=(d-d_est)./idata.inv1DT1.data(itau).ecube;
%             pcolor(idata.inv1DT1.data(itau).t,idata.inv1DT1.data(itau).q1,err)
            imagesc(err)
            title(['\chi^2 = ' num2str(sqrt(sum(sum(err.^2)))/sqrt(numel(err)))],'FontName',fontname,'Fontsize',fontsize)
            axis ij; shading flat;
            set(gca,'CLim',cle)
            set(gca,'YAxisLocation','right')
            set(gca,'XTick',[],'YTick',[]);
            if itau ~= length(idata.inv1DT1.data)
            % set larger subfigure sizes
                subsize=get(gca,'Position');
                subsize(1)=subsize(1)+movex;
                set(gca,'Position',subsize)
            else
             % set larger subfigure sizes
                subsize=get(gca,'Position');
                subsize(1)=subsize(1)+movex;subsize(2)=subsize(2)-movey;
                set(gca,'Position',subsize)   
            end
    end
    else % plot only observed
    figure(gui.fig_data)
    clf;
    % common colorbars
    % data
    cl = [0 1.1*max(idata.inv1DT1.data(end).d)];
        for itau = 1:length(idata.inv1DT1.data)
        % first column - observed data
        subplot(length(idata.inv1DT1.data),3,3*itau-2)
            d     = reshape(idata.inv1DT1.data(itau).d,length(idata.data(itau).q1),length(idata.data(itau).t));
%             pcolor(idata.inv1DT1.data(itau).t,idata.inv1DT1.data(itau).q1,d)
            imagesc(d)
            axis ij; shading flat;
            ylabel({['\tau = ' num2str(idata.tau(itau)) 's']},'FontName',fontname,'Fontsize',fontsize);
            set(gca,'CLim',cl)
            
            if itau == 1
                title('observed data','FontName',fontname,'Fontsize',fontsize);                     
            end
            if itau ~= length(idata.inv1DT1.data)
                nxt=3;
                nyt=3;
                a = round([0.5/nxt:1/nxt:1]*size(d,2));
                for nL = 1:length(a)
                    XTickLabelNew(nL,:) = sprintf('%04.2f', idata.data(itau).t(a(nL)));
                end
                b = round([0.5/nyt:1/nyt:1]*size(d,1));
                for nq = 1:length(b)
                    YTickLabelNew(nq,:) = sprintf('% 5.2f', idata.data(itau).q1(b(nq)));
                end
                if itau == length(idata.inv1DT1.data)-1
                    xlabel('t/s','FontName',fontname,'Fontsize',fontsize); 
                    set(gca,'YTickMode','manual','YTickLabelMode','manual','XTickMode','manual','XTickLabelMode','manual')
                    set(gca,'FontName',fontname,'Fontsize',fontsize)
                    set(gca,'XTick',a,'YTick',b)
                    set(gca,'YTick',[],'XTickLabel',XTickLabelNew);
                else
                    set(gca,'XTick',[],'YTick',[]);
                    set(gca,'FontName',fontname,'Fontsize',fontsize)  
                end
                % set larger subfigure sizes
                subsize=get(gca,'Position');movex = 0.2*subsize(3);movey = 0.2*subsize(4);
                subsize([3 4])=1.2*subsize([3 4]);subsize(1)=subsize(1)-movex;
                set(gca,'Position',subsize)
            end
            if itau == length(idata.inv1DT1.data);
                nxt=3;
                nyt=3;
                a = round([0.5/nxt:1/nxt:1]*size(d,2));
                for nL = 1:length(a)
                    XTickLabelNew(nL,:) = sprintf('%04.2f', idata.data(itau).t(a(nL)));
                end
                b = round([0.5/nyt:1/nyt:1]*size(d,1));
                for nq = 1:length(b)
                    YTickLabelNew(nq,:) = sprintf('% 5.2f', idata.data(itau).q1(b(nq)));
                end 
                xlabel('t/s','FontName',fontname,'Fontsize',fontsize); 
                set(gca,'YTickMode','manual','YTickLabelMode','manual','XTickMode','manual','XTickLabelMode','manual')
                set(gca,'FontName',fontname,'Fontsize',fontsize)
                set(gca,'XTick',a,'YTick',b)
                set(gca,'YTick',[],'XTickLabel',XTickLabelNew);
                % set larger subfigure sizes
                subsize=get(gca,'Position');
                subsize([3])=1.2*subsize([3]); subsize(1)=subsize(1)-movex;subsize(2)=subsize(2)-movey;
                set(gca,'Position',subsize)
            end
        end
    end
    % model
    figure(gui.fig_model)
    subplot(1,3,3)
    if show
    switch idata.para.modelspace
        case 1
            stairs([idata.inv1DT1.smooth.T1(1); idata.inv1DT1.smooth.T1],[0 idata.inv1DT1.smooth.z],'k','Linewidth',2)
        case 2
            T1    = [idata.inv1DT1.block.T1(1) idata.inv1DT1.block.T1];
            Depth = [0 cumsum(idata.inv1DT1.block.thk) max(idata.inv1Dqt.z)];
            stairs(T1,Depth,'k','Linewidth',2)
    end
        axis ij; set(gca,'Xscale','log'); grid on
        set(gca,'Xminorgrid','off');
        xlabel('Decay time T_1 /s','FontName',fontname,'Fontsize',fontsize)
        set(gca,'FontName',fontname,'Fontsize',fontsize)
        xlim([10e-3 2])
    end
end
