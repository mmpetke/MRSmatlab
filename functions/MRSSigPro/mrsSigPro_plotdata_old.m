    %% FUNCTION PLOT DATA FIGURES--------------------------------
    function mrsSigPro_plotdata_old(gui,fdata,proclog)
        
        mrs_setguistatus(gui,1,'Drawing...')
        
        % determine which file to plot from current dropdown list selection
        iQ   = get(gui.panel_controls.popupmenu_Q, 'Value');
        irec = get(gui.panel_controls.popupmenu_REC, 'Value');
        irx  = get(gui.panel_controls.popupmenu_RX, 'Value');
        isig = get(gui.panel_controls.popupmenu_SIG, 'Value');
        
        % determine rx to plot in main window (irx) and small windows (xrx)
        nrec = length(fdata.Q(iQ).rec);             % number of recordings
        xrx = 1:length(fdata.Q(iQ).rec(irec).rx);   % all receiver indices
        xrx(irx) = [];      % define the receivers to plot in small windows
        if length(xrx) > 3  % delete additional receivers (only 3 small windows)
            xrx(4:end)=[];
        end
        if length(xrx) < 3  % fill up xrx so that RX always has 5 elements
            xrx = [xrx -1*ones(1,3-length(xrx))];
        end
        RX = [irx xrx irx]; % repeat irx on 5th entry for imaginary part!
        scalefactor = 1e9;  % show plot in [nV]
        %scalefactor = 1*1e-7*1e15;  % for SQUIDs [fT]
        
        % parameter for quadrature detection
        fT = fdata.Q(iQ).rec(irec).info.fT; % transmitter freq
        fS = fdata.Q(1).rec(1).info.fS;     % sampling freq
        fW = str2double(get(gui.panel_controls.edit_filterwidth, 'String'));
        
        % assign color
        col(1:4,1:3,1) = [ 0.3 0.3 0.3;          % color if keep == 0
            0   0.2 0.5;
            [0 100 15]/256;
            0.4 0 0.4];
        col(1:4,1:3,2) = [ 0.6  0.6 0.6;         % color if keep == 1
            0.0  0.7 1.0;
            [0   200 30]/256;
            1   0   1];
        
        for iRX = 1:length(RX)
            
            if RX(iRX) == -1
                plotdata = 0;
            elseif fdata.Q(iQ).rec(irec).rx(RX(iRX)).sig(isig).recorded % if SIG recorded
                plotdata = 1;
            else
                plotdata = 0;
            end
            
            if plotdata
                
                % assemble fid
                t  = fdata.Q(iQ).rec(irec).rx(RX(iRX)).sig(isig).t1; % [s]
                tQD  = t + fdata.Q(iQ).rec(irec).info.timing.tau_dead1 + ...
                       fdata.Q(iQ).rec(irec).info.phases.phi_gen(isig)/(2*pi*fT) + ...
                       fdata.Q(iQ).rec(irec).info.phases.phi_timing(isig)/(2*pi*fT);
                v  = fdata.Q(iQ).rec(irec).rx(RX(iRX)).sig(isig).v1; % [V]
                t0 = fdata.Q(iQ).rec(irec).rx(RX(iRX)).sig(isig).t0;
                t0QD = t0 + fdata.Q(iQ).rec(1).info.timing.tau_dead1 + ...
                       fdata.Q(iQ).rec(irec).info.phases.phi_gen(isig)/(2*pi*fT) + ...
                       fdata.Q(iQ).rec(irec).info.phases.phi_timing(isig)/(2*pi*fT);
                v0 = fdata.Q(iQ).rec(irec).rx(RX(iRX)).sig(isig).v0;
                
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
                    v_all(iirec,1:length(t))   = fdata.Q(iQ).rec(iirec).rx(RX(iRX)).sig(isig).v1;    % [V]
                    v0_all(iirec,1:length(t0)) = fdata.Q(iQ).rec(iirec).rx(RX(iRX)).sig(isig).v0;    % [V]
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
                                    v0_all(iirec,:) = v0_all(iirec,:).*sign(fdata.Q(iQ).rec(iirec).info.phases.phi_gen(2));
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
                switch iRX
                    case 1
                        subplot(gui.panel_data.FFT(1));
                            a = mod(length(v0),2); % check for even number of samples for fft
                            [freq_range,spec] = mrs_sfft(t0(1:end-a),u0(1:end-a));
                            MinMax = [min(abs(spec(freq_range > -1000 & freq_range < 1000)))...
                                      max(abs(spec(freq_range > -1000 & freq_range < 1000)))];
                            xl = [-1000 1000];   % xlimits
                            % MMP NumisPlus was already enveloppe but I used time series i.e. NumisPlus out
                            % of the selected freqrange, changed all to
                            % complex envelope
%                             if isempty(MinMax)  % happens for NUMISplus data (workaround)) 
%                                 MinMax = [min(abs(spec)) max(abs(spec))];
%                                 xl = [min(freq_range) max(freq_range)];
%                             end
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
                end
                
                % Plot fid
                subplot(gui.panel_data.fid(iRX));
                switch iRX
                    case 1
                        u0_1(u0_1==0)=nan; u_1(u_1==0)=nan; % do not plot zeros set by filter
                        plot(t0,scalefactor*u0_1, 'r:')
                        hold on
                        plot(t,scalefactor*u_1, 'Color', col(isig,:,keep(irec)+1))
                        set(gui.panel_data.txt_fid(iRX),...
                            'String',[str_u_1 ', rx',num2str(RX(iRX))]) % display rx in plot corner
                        ylim(scalefactor*[min(u_1)-1e-9, max(u_1)+1e-9])
                    case 5
                        u0_2(u0_2==0)=nan; u_2(u_2==0)=nan; % do not plot zeros set by filter
                        plot(t0,scalefactor*u0_2, 'r:')
                        hold on
                        plot(t,scalefactor*u_2, 'Color', col(isig,:,keep(irec)+1))
                        set(gui.panel_data.txt_fid(iRX),...
                            'String',[str_u_2 ', rx',num2str(RX(iRX))]) % display rx in plot corner
                        ylim(scalefactor*[min(u_2)-1e-9, max(u_2)+1e-9])
                    otherwise
                        plot(t0,scalefactor*v0, 'r:')
                        hold on
                        plot(t,scalefactor*v, 'Color', col(isig,:,keep(irec)+1))
                        set(gui.panel_data.txt_fid(iRX),...
                            'String',['rx',num2str(RX(iRX))]) % display rx in plot corner
                        ylim(scalefactor*[min(v)-1e-9, max(v)+1e-9])
                end
                
                hold off
                xlim([0 max(t0)])
                set(gca,'Color',[0 0 0])
                
                
                % Plot stack
                subplot(gui.panel_data.stk(iRX))
                switch iRX
                    case 1
                        U0_1(U0_1==0)=nan; U_1(U_1==0)=nan; % do not plot zeros set by filter
                        plot(t0,scalefactor*U0_1, 'r:')
                        hold on
                        plot(t,scalefactor*U_1, 'Color', col(isig,:,keep(irec)+1))
                        set(gui.panel_data.txt_stk(iRX),...
                            'String',[str_U_1 ', rx',num2str(RX(iRX))]) % display rx in plot corner
                        ylim(scalefactor*[min(U_1)-1e-9, max(U_1)+1e-9])
                        %title(['dD = ' num2str(E*1e9)])
                    case 5
                        U0_2(U0_2==0)=nan; U_2(U_2==0)=nan; % do not plot zeros set by filter
                        plot(t0,scalefactor*U0_2, 'r:')
                        hold on
                        plot(t,scalefactor*U_2, 'Color', col(isig,:,keep(irec)+1))
                        set(gui.panel_data.txt_stk(iRX),...
                            'String',[str_U_2 ', rx',num2str(RX(iRX))]) % display rx in plot corner
                        ylim(scalefactor*[min(U_2)-1e-9, max(U_2)+1e-9])
                    otherwise
                        plot(t0,scalefactor*V0, 'r:')
                        hold on
                        plot(t,scalefactor*V, 'Color', col(isig,:,keep(irec)+1))
                        set(gui.panel_data.txt_stk(iRX),...
                            'String',['rx',num2str(RX(iRX))]) % display rx in plot corner
                        ylim(scalefactor*[min(V)-1e-9, max(V)+1e-9])
                end
                hold off
                xlim([0 max(t0)])
                set(gca,'Color',[0 0 0])
                
            else % plotdata=0 (rx not connected or sig not recorded)
                subplot(gui.panel_data.fid(iRX));
                plot([0 1],[-1000 1000],'w-',[0 1],[1000 -1000],'w-')
                xlim([0 1]); ylim([-1000 1000])
                set(gca,'Color',[0 0 0])
                set(gui.panel_data.txt_fid(iRX),...
                            'String',['rx',num2str(RX(iRX))]) % display rx in plot corner
                
                subplot(gui.panel_data.fid(iRX));
                plot([0 1],[-1000 1000],'w-',[0 1],[1000 -1000],'w-')
                xlim([0 1]); ylim([-1000 1000])
                set(gca,'Color',[0 0 0])
                set(gui.panel_data.txt_fid(iRX),...
                            'String',['rx',num2str(RX(iRX))]) % display rx in plot corner
                
                subplot(gui.panel_data.stk(iRX));
                plot([0 1],[-1000 1000],'w-',[0 1],[1000 -1000],'w-')
                xlim([0 1]); ylim([-1000 1000])
                set(gca,'Color',[0 0 0])
                set(gui.panel_data.txt_stk(iRX),...
                            'String',['rx',num2str(RX(iRX))]) % display rx in plot corner
                
                subplot(gui.panel_data.stk(iRX));
                plot([0 1],[-1000 1000],'w-',[0 1],[1000 -1000],'w-')
                xlim([0 1]); ylim([-1000 1000])
                set(gca,'Color',[0 0 0])
                set(gui.panel_data.txt_stk(iRX),...
                            'String',['rx',num2str(RX(iRX))]) % display rx in plot corner
            end
        end
        mrs_setguistatus(gui,0)
        figure(gui.panel_controls.figureid); % set control figure to front
    end
