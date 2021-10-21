function proclog = mrsSigPro_stack(gui,fdata,proclog)
% function proclog = mrsSigPro_stack(gui,fdata,proclog)
% 
% stack receiver channels, cut QD artefacts (filter) and adapt dead time
% delete reference channels
% 
% Jan Walbrecker
% ed. 29sep2011 JW
% ed. 06oct2011 MMP
% =========================================================================    

mrs_setguistatus(gui,1,'STACKING...')

% Replace rxinfo with signal receivers only (task==1)
proclog.rxinfo = fdata.info.rxinfo([fdata.info.rxinfo(:).task]==1);

% Remove old stacked data (if present)
if isfield(proclog.Q,'rx');
    proclog.Q=rmfield(proclog.Q,'rx');       
end

nq  = length(fdata.Q);           % number of pulse moments
nrx = length(fdata.info.rxinfo); % number of ALL receivers

% parameters for quadrature detection
fT = fdata.Q(1).rec(1).info.fT;      % transmitter freq
fS = fdata.Q(1).rec(1).info.fS;      % sampling freq
fW = proclog.LPfilter.fW;            % filter width

for iQ=1:nq % all pulse moments
    nrec = length(fdata.Q(iQ).rec);   % number of recordings (can be different for each q if recording was interrupted)
    iirx = 0;
    for irx=1:nrx % all receivers
        if fdata.info.rxinfo(irx).task == 1 % if channel is receiver            
            iirx = iirx + 1;
            for isig=1:4 % all signals
                if fdata.Q(iQ).rec(1).rx(irx).sig(isig).recorded % if SIG recorded 
                    
                    t    = fdata.Q(iQ).rec(1).rx(irx).sig(isig).t1; % [s]
                    
                    % assemble stack
                    v_all  = zeros(nrec,length(t));
                    u_all  = zeros(nrec,length(t));
%                     if fdata.header.sequenceID == 8 && isig==2 % mod RD: save pulseform for AHP. 
%                         I_all   = zeros(nrec,length(fdata.Q(iQ).rec(1).tx.I));
%                         df_all  = zeros(nrec,length(fdata.Q(iQ).rec(1).tx.df));
%                     end
                    phases = zeros(1,nrec);
                    keep   = zeros(1,nrec);
                    pc     = zeros(1,nrec);
                    for iirec = 1:nrec
                        v_all(iirec,1:length(t)) = fdata.Q(iQ).rec(iirec).rx(irx).sig(isig).v1;
                        keep(iirec) = mrs_getkeep(proclog,iQ,iirec,irx,isig);
                        if strcmp(fdata.info.device,'GMR')
                            if sign(fdata.Q(iQ).rec(iirec).info.phases.phi_gen(isig)) == 0
                                % do nothing - phi_gen is set to 0 for
                                % prepreocessed GMR files
                                phases(iirec) = 0;
                            else     
                                % JW: avoid switch to save time
                                % MMP after implementing CPMG switch is
                                % necessayr because echo phase relates to
                                % p90 phase
                                switch isig
                                    case 2 % FID
                                        v_all(iirec,:)  = v_all(iirec,:).*sign(fdata.Q(iQ).rec(iirec).info.phases.phi_gen(2)); 
                                        if fdata.header.sequenceID == 8 % mod RD: save pulseform for AHP. 
                                            I_all(iirec,:)  = fdata.Q(iQ).rec(iirec).tx.I;
                                            df_all(iirec,:) = fdata.Q(iQ).rec(iirec).tx.df;                            
                                        end
                                    case 3 % 2nd FID (T1)
                                        v_all(iirec,:)  = v_all(iirec,:).*sign(fdata.Q(iQ).rec(iirec).info.phases.phi_gen(3));
                                    case 4 % Echo (T2)
                                        v_all(iirec,:)  = v_all(iirec,:).*sign(fdata.Q(iQ).rec(iirec).info.phases.phi_gen(2));
                                    
                                end
                                pc(iirec)       = sign(fdata.Q(iQ).rec(iirec).info.phases.phi_gen(isig));
                                
                                % force appropriate sign for phase
                                % correction (timing phase)
                                if sign(fdata.Q(iQ).rec(iirec).info.phases.phi_gen(isig)) == 1        % JW: check this for NUMIS
                                    phases(iirec) = fdata.Q(iQ).rec(iirec).info.phases.phi_gen(isig);
                                else
                                    phases(iirec) = fdata.Q(iQ).rec(iirec).info.phases.phi_gen(isig) + pi;
                                end                                
                                
                                % do QD for each record to get stacking error later on
                                % JW: this takes long. can we avoid this by
                                % taking the error of the not-QD'ed FID?
                                % MMP: we need to do QD 
                                if nrec > 1
                                    u_all(iirec,:)  = mrsSigPro_QD(v_all(iirec,:),t,fT,fS,fW,proclog.LPfilter);
                                end
                            end    
                        end
                        if strcmp(fdata.info.device,'NUMISpoly') % MMP: this is not ready yet! phases!
                            if nrec > 1
                                u_all(iirec,:)  = mrsSigPro_QD(v_all(iirec,:),t,fT,fS,fW,proclog.LPfilter);
                            end
                        end
                    end
                    
                    V  = sum(v_all(keep==1,:),1)/size(v_all(keep==1,:),1);
%                     if fdata.header.sequenceID == 8 && isig == 2 % mod RD: save pulseform for AHP. 
%                         I       = sum(I_all(keep==1,:),1)/size(I_all(keep==1,:),1);
%                         STD_I   = std(I_all(keep==1,:),1)/size(I_all(keep==1,:),1);                        
%                         df      = sum(df_all(keep==1,:),1)/size(df_all(keep==1,:),1);     
%                     end
                    
                    % delete nan from QD and get data error after stacking
                    if nrec > 1
                        u_all(isnan(u_all)==1)=0;
                        E  = complex((std(real(u_all(keep==1,:)),1))/sqrt(size(v_all(keep==1,:),1)),... 
                                     (std(imag(u_all(keep==1,:)),1))/sqrt(size(v_all(keep==1,:),1))); 
                    else % don't do this for stacked data (GMR preproc) - cannot calculate std for stack
                        E = zeros(size(v_all));
                    end
                    
                    % get phase for phase correction
                    phase = fdata.Q(iQ).rec(1).info.phases;
                    if strcmp(fdata.info.device,'GMR')
                        % get average generator phase for this pulsemoment
                        phase.phi_gen(isig) = mean(phases);
                    end
                        
                    % get QD signal for stacked signal
                    u = mrsSigPro_QD(V,t,fT,fS,fW,proclog.LPfilter);
                    U = mrs_signalphasecorrection(u,phase,isig,fdata.info.device);
                
                    % Get new dead time after QD (zeros in envelope) and
                    % resampling index (resampling due to filter)
                    zwerg = t(isnan(U(1:round(end/2)))==1);
                    index = length(zwerg)+1;
                                       
                    % assemble all information
                    proclog.Q(iQ).timing.tau_dead1            = fdata.Q(iQ).rec(1).info.timing.tau_dead1 + t(index);
                    proclog.Q(iQ).rx(iirx).sig(isig).t        = t(index:index:end-index) - t(index);
                    proclog.Q(iQ).rx(iirx).sig(isig).V        = U(index:index:end-index);
                    proclog.Q(iQ).rx(iirx).sig(isig).E        = E(index:index:end-index);
                    proclog.Q(iQ).rx(iirx).sig(isig).recorded = 1;
                    if isig==4
                        proclog.Q(iQ).rx(iirx).sig(isig).nE = round(max(proclog.Q(1).rx(1).sig(4).t)/proclog.Q(1).timing.tau_e);
                        echotimes = proclog.Q(1).timing.tau_e/2-proclog.Q(1).timing.tau_p2/2-proclog.Q(1).timing.tau_dead1;
                        for iE=2:proclog.Q(iQ).rx(iirx).sig(isig).nE
                            echotimes=[echotimes echotimes(iE-1) + proclog.Q(1).timing.tau_e];
                        end
                        proclog.Q(iQ).rx(iirx).sig(isig).echotimes = echotimes;
                    end
%                     if fdata.header.sequenceID == 8 && isig == 2% mod RD: average pulseform for AHP. 
%                         proclog.Q(iQ).tx.I      = I;                   
%                         proclog.Q(iQ).tx.STD_I  = STD_I;                        
%                         proclog.Q(iQ).tx.df     = df;
%                         proclog.Q(iQ).tx.t_pulse = fdata.Q(iQ).rec(1).tx.t_pulse;
%                     end
                    
                else
                    proclog.Q(iQ).rx(iirx).sig(isig).recorded = 0;
                end
            end
        else
            % skip if not a signal channel
        end
    end
end
mrs_setguistatus(gui,0)
