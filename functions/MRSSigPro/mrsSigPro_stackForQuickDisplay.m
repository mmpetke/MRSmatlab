function [t, gateT, QStackTD, freq_range, QStackFD, AllRecFD, e, nSample] = mrsSigPro_stackForQuickDisplay(gui,fdata,proclog)
% function proclog = mrsSigPro_stackForQuickDisplay(gui,fdata,proclog)
%
% quick overview of data quality
% one receiver channel
% one signal (FID, T1, T2)
% all q
% all rec 
%
% 12June2015 MMP
% =========================================================================    

% number of pulse moments
nq  = length(fdata.Q);      

% determine parameter to plot from current dropdown list selection
iiQ   = get(gui.panel_controls.popupmenu_Q, 'Value');
iirec = get(gui.panel_controls.popupmenu_REC, 'Value');
irx  = get(gui.panel_controls.popupmenu_RX, 'Value');
isig = get(gui.panel_controls.popupmenu_SIG, 'Value');

% parameter for quadrature detection
fT = fdata.Q(iiQ).rec(iirec).info.fT; % transmitter freq
fS = fdata.Q(1).rec(1).info.fS;     % sampling freq
fW = str2double(get(gui.panel_controls.edit_filterwidth, 'String'));

for iQ=1:nq % all pulse moments
    nrec = length(fdata.Q(iQ).rec);   % number of recordings (can be different for each q if recording was interrupted)
    %if fdata.info.rxinfo(irx).task == 1 % if channel is receiver  
        if fdata.Q(iQ).rec(1).rx(irx).sig(isig).recorded % if SIG recorded
            
            t    = fdata.Q(iQ).rec(1).rx(irx).sig(isig).t1; % [s]
            
            % assemble stack
            v_all  = zeros(nrec,length(t));
            u_all  = zeros(nrec,length(t));
            phases = zeros(1,nrec);
            keep   = zeros(1,nrec);
            
            for iirec = 1:nrec
                v_all(iirec,1:length(t)) = fdata.Q(iQ).rec(iirec).rx(irx).sig(isig).v1;
                keep(iirec) = mrs_getkeep(proclog,iQ,iirec,irx,isig);
                if strcmp(fdata.info.device,'GMR')
                    if sign(fdata.Q(iQ).rec(iirec).info.phases.phi_gen(isig)) ~= 0 
                        switch isig
                            case 2 % FID
                                v_all(iirec,:)  = v_all(iirec,:).*sign(fdata.Q(iQ).rec(iirec).info.phases.phi_gen(2));
                            case 3 % 2nd FID (T1)
                                v_all(iirec,:)  = v_all(iirec,:).*sign(fdata.Q(iQ).rec(iirec).info.phases.phi_gen(3));
                            case 4 % Echo (T2)
                                v_all(iirec,:)  = v_all(iirec,:).*sign(fdata.Q(iQ).rec(iirec).info.phases.phi_gen(2));      
                        end
                    end
                end
                
                if iQ==iiQ % for current selected q
                    v0                  = mrsSigPro_QD(v_all(iirec,:),t,fT,fS,fW,proclog.LPfilter);
                    v0(isnan(v0)==1)    = 0;
                    a                   = mod(length(v0),2); 
                    [freq_range,spec]   = mrs_sfft(t(1:end-a),v0(1:end-a));
                    AllRecFD(iirec,:)   = spec;
                    v0_all(iirec,:)     = v0;
                end
            end
            
            
            
            % stacked signals
            V  = sum(v_all(keep==1,:),1)/size(v_all(keep==1,:),1);
                   
            % get QD signal for stacked signals
            u = mrsSigPro_QD(V,t,fT,fS,fW,proclog.LPfilter);
            
            % assemble stacks in time domain
            % include gating
            t1 = t; t1(isnan(u)==1)=[];
            u1 = u; u1(isnan(u)==1)=[];
            if isig == 4
                QStackTD(iQ,:) = u1;
                gateT          = t1;
            else
                [realTemp,dummy] = mrs_GateIntegration(real(u1),t1,50,0);
                [imagTemp,gateT,gateL] = mrs_GateIntegration(imag(u1),t1,50,0);
                QStackTD(iQ,:) = complex(realTemp,imagTemp);    
%                 [realTemp,dummy] = mrs_GateIntegration(abs(u1)/2,t1,50,0);
%                 [imagTemp,gateT,gateL] = mrs_GateIntegration(abs(u1)/2,t1,50,0);
%                 QStackTD(iQ,:) = complex(realTemp,imagTemp);  
            end
            
            
            if iQ==iiQ
                % error estimate for the selected Q
                zwerg   = t(isnan(u(1:round(end/2)))==1);
                index   = length(zwerg)+1;
                nSample = length(t(index:index:end-index) - t(index));
                e  = complex((std(real(v0_all(keep==1,:)),1))/sqrt(size(v0_all(keep==1,:),1)),... 
                             (std(imag(v0_all(keep==1,:)),1))/sqrt(size(v0_all(keep==1,:),1))); 
            end
            
            % replace nan by zeros --> easier to handle for FFT 
            u(isnan(u)==1)    = 0;
            % assemble stacks in freq domain
            a = mod(length(u),2); % check for even number of samples for fft
            [freq_range,spec] = mrs_sfft(t(1:end-a),u(1:end-a));
            QStackFD(iQ,:)    = spec;
            
            
            
        end
    %end
end
