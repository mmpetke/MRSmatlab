    %% FUNCTION PLOT DATA FIGURES--------------------------------
    function mrsSigPro_plotdata(gui,fdata,proclog)
        
        mrs_setguistatus(gui,1,'Drawing...')
        
        % determine which file to plot from current dropdown list selection
        iQ   = get(gui.panel_controls.popupmenu_Q, 'Value');
        irec = get(gui.panel_controls.popupmenu_REC, 'Value');
        irx  = get(gui.panel_controls.popupmenu_RX, 'Value');
        isig = get(gui.panel_controls.popupmenu_SIG, 'Value');
        
        nrec = length(fdata.Q(iQ).rec);             % number of recordings
        nq = length(fdata.Q);                       % number of qs
        scalefactor = 1e9;  % show plot in [nV]
        
        % parameter for quadrature detection
        fT = fdata.Q(iQ).rec(irec).info.fT; % transmitter freq
        fS = fdata.Q(1).rec(1).info.fS;     % sampling freq
        fW = str2double(get(gui.panel_controls.edit_filterwidth, 'String'));
        %fT=2000;
        
        % assign color
        col(1:4,1:3,1) = [ 0.3 0.3 0.3;          % color if keep == 0
            0   0.2 0.5;
            [0 100 15]/256;
            0.4 0 0.4];
        col(1:4,1:3,2) = [ 0.6  0.6 0.6;         % color if keep == 1
            0.0  0.7 1.0;
            [0   200 30]/256;
            1   0   1];
        
        
        if fdata.Q(iQ).rec(irec).rx(irx).sig(isig).recorded % if SIG recorded
            plotdata = 1;
        else
            plotdata = 0;
        end
        
        if plotdata
            
            % assemble fid
            t  = fdata.Q(iQ).rec(irec).rx(irx).sig(isig).t1; % [s]
            tQD  = t + fdata.Q(iQ).rec(irec).info.timing.tau_dead1 + ...
                fdata.Q(iQ).rec(irec).info.phases.phi_gen(isig)/(2*pi*fT) + ...
                fdata.Q(iQ).rec(irec).info.phases.phi_timing(isig)/(2*pi*fT);
            v  = fdata.Q(iQ).rec(irec).rx(irx).sig(isig).v1; % [V]
            t0 = fdata.Q(iQ).rec(irec).rx(irx).sig(isig).t0;
            t0QD = t0 + fdata.Q(iQ).rec(1).info.timing.tau_dead1 + ...
                fdata.Q(iQ).rec(irec).info.phases.phi_gen(isig)/(2*pi*fT) + ...
                fdata.Q(iQ).rec(irec).info.phases.phi_timing(isig)/(2*pi*fT);
            v0 = fdata.Q(iQ).rec(irec).rx(irx).sig(isig).v0;
            
            % get QD signal for single FID
            u    = mrsSigPro_QD(v,tQD,fT,fS,fW,proclog.LPfilter);
            u_1  = real(u);
            u_2  = imag(u);
            u0   = mrsSigPro_QD(v0,t0QD,fT,fS,fW,proclog.LPfilter);
            u0_1 = real(u0);
            u0_2 = imag(u0);
            str_u_1 = 're(fid)';
            str_u_2 = 'im(fid)';
            
            % assemble stack
            v_all  = zeros(nrec,length(t));
            v0_all = zeros(nrec,length(t0));
            keep   = zeros(1,nrec);
            for iirec = 1:length(fdata.Q(iQ).rec)
                v_all(iirec,1:length(t))   = fdata.Q(iQ).rec(iirec).rx(irx).sig(isig).v1;    % [V]
                v0_all(iirec,1:length(t0)) = fdata.Q(iQ).rec(iirec).rx(irx).sig(isig).v0;    % [V]
                keep(iirec) = mrs_getkeep(proclog,iQ,iirec,irx,isig);
                % GMR uses phasecycling --> get sign for stacking
                % generator phase is not good for phase cycling - >
                % generator phase is always the same for fid1 and fid2.
                % Use signal phase instead.
                if strcmp(fdata.info.device,'GMR')
                    if sign(fdata.Q(iQ).rec(iirec).info.phases.phi_gen(isig)) == 0
                        % do nothing - phi_gen is set to 0 for
                        % prepreocessed GMR files
                    else
                        %to simulate old PSR from 4phase cyle
                        %if sign(fdata.Q(iQ).rec(iirec).info.phases.phi_gen(2))*sign(fdata.Q(iQ).rec(iirec).info.phases.phi_gen(3)) > 0
                        %v_all(iirec,:)  = v_all(iirec,:).*sign(fdata.Q(iQ).rec(iirec).info.phases.phi_gen(isig));
                        %v0_all(iirec,:) = v0_all(iirec,:).*sign(fdata.Q(iQ).rec(iirec).info.phases.phi_gen(isig));
                        %end
                        switch isig
                            case 2
                                v_all(iirec,:)  = v_all(iirec,:).*sign(fdata.Q(iQ).rec(iirec).info.phases.phi_gen(2));
%                                 v_all(iirec,:)  = v_all(iirec,:);
                                v0_all(iirec,:) = v0_all(iirec,:).*sign(fdata.Q(iQ).rec(iirec).info.phases.phi_gen(2));
%                                 v0_all(iirec,:) = v0_all(iirec,:);
                            case 3
                                v_all(iirec,:)  = v_all(iirec,:).*sign(fdata.Q(iQ).rec(iirec).info.phases.phi_gen(3));
                                v0_all(iirec,:) = v0_all(iirec,:).*sign(fdata.Q(iQ).rec(iirec).info.phases.phi_gen(3));
                            case 4
                                v_all(iirec,:)  = v_all(iirec,:).*sign(fdata.Q(iQ).rec(iirec).info.phases.phi_gen(2));
                                v0_all(iirec,:) = v0_all(iirec,:).*sign(fdata.Q(iQ).rec(iirec).info.phases.phi_gen(2));
                        end
                    end
                end
            end
            V  = sum(v_all(keep==1,:),1)/size(v_all(keep==1,:),1);
            % error before QD, i.e. without filter --> good for diplay
            % but insensitive to filtering
            % E  = mean(std(v_all(keep==1,:),1))/sqrt(size(v_all(keep==1,:),1));
            V0 = sum(v0_all,1)/nrec;            % full stack (keep all)
            
            % get the pulse phase for the stacked signal (!phase cycling!)
            if fdata.Q(iQ).rec(irec).info.phases.phi_gen(isig) > 0
                phi_gen =  fdata.Q(iQ).rec(irec).info.phases.phi_gen(isig);
            else
                phi_gen =  fdata.Q(iQ).rec(irec).info.phases.phi_gen(isig) + pi;
            end
            % get QD signal for stacked signal
            tQD  = t + fdata.Q(iQ).rec(irec).info.timing.tau_dead1 + ...
                phi_gen/(2*pi*fT) + ...
                fdata.Q(iQ).rec(irec).info.phases.phi_timing(isig)/(2*pi*fT);
            U    = mrsSigPro_QD(V,tQD,fT,fS,fW,proclog.LPfilter);
            U_1  = real(U);
            U_2  = imag(U);
            t0QD = t0 + fdata.Q(iQ).rec(1).info.timing.tau_dead1 + ...
                phi_gen/(2*pi*fT) + ...
                fdata.Q(iQ).rec(irec).info.phases.phi_timing(isig)/(2*pi*fT);
            U0   = mrsSigPro_QD(V0,t0QD,fT,fS,fW,proclog.LPfilter);
            U0_1 = real(U0);
            U0_2 = imag(U0);
            str_U_1 = 're(stk)';
            str_U_2 = 'im(stk)';
            
            % Update virtual dead time (nan in envelope)
            zwerg = t(isnan(U(1:round(end/2)))==1);
            if ~isnan(zwerg) % for Numis Plus/Light data is QD --> no additional filter
                index = length(zwerg);
                switch isig
                    case 2
                        set(gui.panel_controls.filterdead,'String',num2str(fdata.Q(iQ).rec(1).info.timing.tau_dead1 + ...
                            t(index)));
                    case 3
                        set(gui.panel_controls.filterdead,'String',num2str(fdata.Q(iQ).rec(1).info.timing.tau_dead2 + ...
                            t(index)));
                end
            end
            % replace nan by zeros --> easier to handle for FFT and
            % min/max
            u(isnan(u)==1)=0;
            u0(isnan(u0)==1)=0;
            U(isnan(U)==1)=0;
            U0(isnan(U0)==1)=0;
            
            % CAREFUL WITH INDICES! PLOT Q VALUE INTO TITEL
            figure(gui.panel_data.figureid)
            
            % Plot FFT
            subplot(gui.panel_data.FFT(1));
                a = mod(length(v0),2); % check for even number of samples for fft
                [freq_range,spec] = mrs_sfft(t0(1:end-a),u0(1:end-a));
                xl = 1.5*[-fW fW];   % xlimits
                MinMax = [min(abs(spec(freq_range > xl(1) & freq_range < xl(2))))...
                          max(abs(spec(freq_range > xl(1) & freq_range < xl(2))))];
%                 MinMax = [min(abs(spec(freq_range > -1000 & freq_range < 1000)))...
%                     max(abs(spec(freq_range > -1000 & freq_range < 1000)))];
                %xl = [-1000 1000];   % xlimits
                plot(freq_range,abs(spec),':r')
                hold on
                a = mod(length(v),2);
                [freq_range,spec] = mrs_sfft(t(1:end-a),u(1:end-a));
                plot(freq_range,abs(spec),'Color', col(isig,:,keep(irec)+1))
                set(gca,'Color',[0 0 0],'xlim',xl,'yscale','log')
                ylim(MinMax)
                hold off
            subplot(gui.panel_data.FFT(2));
                a = mod(length(V0),2); % check for even number of samples for fft
                [freq_range,spec] = mrs_sfft(t0(1:end-a),U0(1:end-a));
                plot(freq_range,abs(spec),':r')
                hold on
                a = mod(length(V),2);
                [freq_range,spec] = mrs_sfft(t(1:end-a),U(1:end-a));
                plot(freq_range,abs(spec),'Color', col(isig,:,keep(irec)+1))
                set(gca,'Color',[0 0 0],'xlim',xl,'yscale','log')
                ylim(MinMax)
                hold off

            
            % Plot FID
            subplot(gui.panel_data.fid(1));
                u0_1(u0_1==0)=nan; u_1(u_1==0)=nan; % do not plot zeros set by filter
                plot(t0,scalefactor*u0_1, 'r:')
                hold on
                plot(t,scalefactor*u_1, 'Color', col(isig,:,keep(irec)+1))
                set(gui.panel_data.txt_fid(1),...
                    'String',[str_u_1 ', rx',num2str(irx)]) % display rx in plot corner
                ylim(scalefactor*[min(u_1)-1e-9, max(u_1)+1e-9])
                hold off
                xlim([0 max(t0)])
                set(gca,'Color',[0 0 0])
                % if only LIAG Noise is loaded
                instrument = mrs_checkinstrument(fdata.info.path);
                switch instrument
                    case 'LIAGNoiseMeter'
                        u0_1(isnan(u0_1))=0; u_1(isnan(u_1))=0; %
                        title(['noise level = ' num2str(round(100*std(scalefactor*u_1))/100) ' nV/m^2'])

                end
            subplot(gui.panel_data.fid(5));
                u0_2(u0_2==0)=nan; u_2(u_2==0)=nan; % do not plot zeros set by filter
                plot(t0,scalefactor*u0_2, 'r:')
                hold on
                plot(t,scalefactor*u_2, 'Color', col(isig,:,keep(irec)+1))
                set(gui.panel_data.txt_fid(5),...
                    'String',[str_u_2 ', rx',num2str(irx)]) % display rx in plot corner
                ylim(scalefactor*[min(u_2)-1e-9, max(u_2)+1e-9])
                hold off
                xlim([0 max(t0)])
                set(gca,'Color',[0 0 0])
            
            
            
            % Plot stack
            subplot(gui.panel_data.stk(1))
                U0_1(U0_1==0)=nan; U_1(U_1==0)=nan; % do not plot zeros set by filter
                plot(t0,scalefactor*U0_1, 'r:')
                hold on
                plot(t,scalefactor*U_1, 'Color', col(isig,:,keep(irec)+1))
                set(gui.panel_data.txt_stk(1),...
                    'String',[str_U_1 ', rx',num2str(irx)]) % display rx in plot corner
                ylim(scalefactor*[min(U_1)-1e-9, max(U_1)+1e-9])
                hold off
                xlim([0 max(t0)])
                set(gca,'Color',[0 0 0])
            subplot(gui.panel_data.stk(5))
                U0_2(U0_2==0)=nan; U_2(U_2==0)=nan; % do not plot zeros set by filter
                plot(t0,scalefactor*U0_2, 'r:')
                hold on
                plot(t,scalefactor*U_2, 'Color', col(isig,:,keep(irec)+1))
                set(gui.panel_data.txt_stk(5),...
                    'String',[str_U_2 ', rx',num2str(irx)]) % display rx in plot corner
                ylim(scalefactor*[min(U_2)-1e-9, max(U_2)+1e-9])
                hold off
                xlim([0 max(t0)])
                set(gca,'Color',[0 0 0])
            
            drawnow    
            % plot overview 
            [t, gateT, QStackTD, freq_range, QStackFD, AllRecFD, e, nSample] = mrsSigPro_stackForQuickDisplay(gui,fdata,proclog);
            subplot(gui.panel_data.fid(2));
%                 imagesc(t,[1:nq],abs(QStackTD))
                imagesc(abs(QStackTD))
                shading flat; hold on
                plot([1 size(QStackTD,2)],[iQ iQ],'r --','Linewidth',2)
                % set nice axes labeling
                switch isig
                    case {2,3}
                        xla = get(gca,'xtick');xla(xla<1)=[];xla=unique(floor(xla));set(gca,'xtick',xla);
                        set(gca,'xticklabel',num2cell(0.01*round(100*gateT(get(gca,'xtick')).')));
                end
                
                xla = get(gca,'xticklabel'); xla{round(length(xla)/2)}= 't /s'; set(gca,'xticklabel',xla);
                yla = get(gca,'yticklabel'); yla{round(length(yla)/2)}= 'q /#'; set(gca,'yticklabel',yla); 
                hold off
            subplot(gui.panel_data.stk(2))    
                imagesc(freq_range,[1:nq],log10(abs(QStackFD)))
                shading flat
                xlim(xl)
                MinMax = [max(max(log10(abs(QStackFD))))-2 ...
                          max(max(log10(abs(QStackFD))))];
                set(gca,'clim',MinMax)
                xla = get(gca,'xticklabel'); xla{round(length(xla)/2)}= 'f /Hz'; set(gca,'xticklabel',xla);
                yla = get(gca,'yticklabel'); yla{round(length(yla)/2)}= 'q /#'; set(gca,'yticklabel',yla); 
                hold off
            subplot(gui.panel_data.stk(4))    
                imagesc(freq_range,[1:nrec],log10(abs(AllRecFD)))
                shading flat; hold on
                plot(freq_range,irec*ones(size(freq_range)),'r --','Linewidth',2)
                xlim(xl)
                %title(['e = ' num2str(e) 'nV' num2str(nSample) 'samples'])
                %MinMax = [min(min(log10(abs(AllRecFD))))...
                %          max(max(log10(abs(AllRecFD))))];
                E=round(1000*abs(mean(e*1e9)))/1000;
                set(gui.panel_data.txt2_stk(4),'String','')
                set(gui.panel_data.txt2_stk(4),'String',['e: ' num2str(E) ' nV ['  num2str(0.1*round(10*E/sqrt(nSample))) ' nV/sqrt(nS)]']);
                MinMax = [max(max(log10(abs(AllRecFD(keep==1,:)))))-2 ...
                          max(max(log10(abs(AllRecFD(keep==1,:)))))];
                set(gca,'clim',MinMax)
                xla = get(gca,'xticklabel'); xla{round(length(xla)/2)}= 'f /Hz'; set(gca,'xticklabel',xla);
                yla = get(gca,'yticklabel'); yla{round(length(yla)/2)}= 'rec /#'; set(gca,'yticklabel',yla);
                hold off
        end
        mrs_setguistatus(gui,0)
        figure(gui.panel_controls.figureid); % set control figure to front
    end
