function data = mrs_reprocess_proclog(data, proclog, id)
% function data = mrs_reprocess_proclog(data, proclog, id)
% 
% Reprocess raw data (data) according to processing log (proclog.event).
% Only the specified event id's (id) are redone.
% 
% Input:     
%   data    - MRSmatlab data structure from mrs_load_*
%   proclog - MRSmatlab processing log
%   id      - event id of relevant processing steps
% 
% Output:     
%   data    - structure containing the reprocessed data
% 
% Jan Walbrecker 
% ed. 04 oct 2011 JW
% =========================================================================

relog = proclog.event(id,:);

% reprocess all relevant id's in proclog event
for ilog = 1:size(relog,1)
    iQ   = relog(ilog,2);
    irec = relog(ilog,3);
    irx  = relog(ilog,4);
    isig = relog(ilog,5);
    switch relog(ilog,1)     % event type
        case 1 % keep
            % nothing to do.
        case 2 % trim ( in MRSSignalProc - not implemented yet)
            error('Trim has been moved to MRSFit')
            irec = 1;   % trim is done for all recordings.
            switch relog(ilog,6)
                case 0 % reset
                    % reload only trimmed part from v0 (keep despiking of active part)
                    trim  = relog(ilog,6:8);
                    tmin  = trim(2);    % reset from 1 to tmin
                    tmax  = trim(3);    % reset from tmax to end
                    t0    = data.Q(iQ).rec(irec).rx(irx).sig(isig).t0;
                    imint = find(abs(tmin-t0) == min(abs(tmin-t0)));
                    imaxt = find(abs(tmax-t0) == min(abs(tmax-t0)));
                    
                    % restore fid from 3 parts:
                    % load deleted part 1:mint-1 from backup,
                    % keep current part, replace 1 sample of current part (othwse
                    % crash due to 3rd part)
                    % load deleted part imax+1:end from backup. Prevent imax+1 >
                    % length(t) by using min([length(t) imax]).
                    
                    for iirec = 1:length(data.Q(iQ).rec)
                        data.Q(iQ).rec(iirec).rx(irx).sig(isig).t1 = t0;
                        data.Q(iQ).rec(iirec).rx(irx).sig(isig).v1 = ...
                            [data.Q(iQ).rec(iirec).rx(irx).sig(isig).v0(1:imint) ...
                            data.Q(iQ).rec(iirec).rx(irx).sig(isig).v1(2:end-1) ...
                            data.Q(iQ).rec(iirec).rx(irx).sig(isig).v0(min([length(data.Q(iQ).rec(irec).rx(irx).sig(isig).v0) imaxt]):end)];
                    end
                    
                    %                     for iirec = 1:length(data.Q(iQ).rec)
                    %                         for iirx = 1:length(data.Q(iQ).rec(iirec).rx)   % for all recordings at receiver irx and signal isig
                    %                             if data.Q(iQ).rec(iirec).rx(iirx).connected
                    %                                 for iisig = 1:length(data.Q(iQ).rec(iirx).isig)   % for all recordings at receiver irx and signal isig
                    %                                     if data.Q(iQ).rec(iirec).rx(iirx).isig(iisig).recorded
                    %
                    %                                         data.Q(iQ).rec(iirec).rx(iirx).sig(iisig).t1 = t0;
                    %                                         data.Q(iQ).rec(iirec).rx(iirx).sig(iisig).v1 = ...
                    %                                             [data.Q(iQ).rec(iirec).rx(iirx).sig(iisig).v0(1:imint) ...
                    %                                             data.Q(iQ).rec(iirec).rx(iirx).sig(iisig).v1(2:end-1) ...
                    %                                             data.Q(iQ).rec(iirec).rx(iirx).sig(iisig).v0(min([length(data.Q(iQ).rec(irec).rx(irx).sig(isig).v0) imaxt]):end)];
                    %                                     end
                    %                                 end
                    %                             end
                    %                         end
                    %                     end
                    
                case 1 % do trim
                    if relog(ilog,8) == -1      % set mint
                        tmin = relog(ilog,7);   % determine min(t)
                        % delete samples
                        imint = find(abs(tmin-data.Q(iQ).rec(irec).rx(irx).sig(isig).t1) == ...
                            min(abs(tmin-data.Q(iQ).rec(irec).rx(irx).sig(isig).t1)));
                        for iirec = 1:length(data.Q(iQ).rec)   % for all recordings at receiver irx and signal isig
                            data.Q(iQ).rec(iirec).rx(irx).sig(isig).t1(1:imint-1) = [];
                            data.Q(iQ).rec(iirec).rx(irx).sig(isig).v1(1:imint-1) = [];
                        end
                    elseif relog(ilog,7) == -1  % set maxt
                        tmax = relog(ilog,8);   % determine max(t)
                        
                        % delete samples & update proclog
                        imaxt = find(abs(tmax-data.Q(iQ).rec(irec).rx(irx).sig(isig).t1) == ...
                            min(abs(tmax-data.Q(iQ).rec(irec).rx(irx).sig(isig).t1)));
                        if imaxt == length(data.Q(iQ).rec(irec).rx(irx).sig(isig).t1)
                            % nothing to do...
                        else
                            for iirec = 1:length(data.Q(iQ).rec)   % for all recordings at receiver irx and signal isig
                                data.Q(iQ).rec(iirec).rx(irx).sig(isig).t1(imaxt+1:end) = [];
                                data.Q(iQ).rec(iirec).rx(irx).sig(isig).v1(imaxt+1:end) = [];
                            end
                        end
                    else
                        disp('sth is wrong with the proclog. Please start to cry.')
                        pause(3)
                        error('Now.')
                    end
            end
        case 3 % despike
            
            t   = data.Q(iQ).rec(irec).rx(irx).sig(isig).t1;
            v   = data.Q(iQ).rec(irec).rx(irx).sig(isig).v1;
            dt  = mean(diff(t)); % t1(2)-t1(1); - for AK Caribou snd4: dt varies!!!
            width     = relog(ilog,7);  % [s]
            cutcenter = relog(ilog,8);  % [s] - mint?
            switch relog(ilog,6) % despike type
                case 1  % mute window
                    
                    % create mute window
                    N  = length(cutcenter-width/2:dt:cutcenter+width/2);
                    w  = 1-window(@flattopwin,N)';
                    tw = cutcenter-width/2:dt:cutcenter+width/2;
                    
                    % determine samples to be muted
                    fixme = round(( max([cutcenter-width/2,t(2)]) : dt : ...   % t(2)/dt -> index 2 because first sample is 1 and not 0.
                        min([cutcenter+width/2,max(t)]) )/dt);     % max / min to prevent window being larger than timeserie
                    
                    % adapt size of mute window
                    w(tw<t(1))   = [];   tw(tw<t(1)) = [];    % index 1 because time of 1st sample
                    w(tw>max(t)) = [];
                    if length(w) > length(fixme) % avoid rounding effect - correct 1 sample
                        w(end) = [];
                    elseif length(w) < length(fixme)
                        w = [w 1]; %#ok<AGROW>
                    end
                    if length(w) ~= length(fixme)
                        error('This should not happen')
                    end
                    
                    % calculate muted signal
                    newsignal        = v;
                    newsignal(fixme) = v(fixme).*w;
                    
                case 2  % average window
                    %                     fixme     = round(( max([cutcenter-width/2,t(2)-mint]) : dt : ...
                    %                                         min([cutcenter+width/2,max(t)-mint]) )/dt);     % max / min to prevent window being larger than timeserie; t(2) -> first sample is 1 and not 0.
                    fixme     = round(( max([cutcenter-width/2,t(2)-t(2)+dt]) : dt : ...
                                        min([cutcenter+width/2,max(t)-t(2)+dt]) )/dt);     % max / min to prevent window being larger than timeserie; t(2) -> first sample is 1 and not 0.
                    newsignal        = v;
                    newsignal(fixme) = NaN;
                    
                    % interpolate
                    relog(end+1,:) = [1 iQ irec irx isig 0 -1 -1]; %#ok<AGROW> % set to 0 temporarily to prevent from being stacked
                    nrec  = length(data.Q(iQ).rec);
                    v_all = zeros(nrec,length(t));
                    keep  = zeros(1,nrec);
                    for iirec = 1:nrec
                        v_all(iirec,1:length(t)) = data.Q(iQ).rec(iirec).rx(irx).sig(isig).v1;
%                         temp.event  = relog;
                        keep(iirec) = mrs_getkeep(relog,iQ,iirec,irx,isig);
                        if strcmp(data.info.device,'GMR')
                            if sign(data.Q(iQ).rec(iirec).info.phases.phi_gen(isig)) == 0
                                % do nothing - phi_gen is set to 0 for
                                % preprocessed GMR files
                            else
                                v_all(iirec,:)  = v_all(iirec,:).*sign(data.Q(iQ).rec(iirec).info.phases.phi_gen(isig));%exp(1i*fdata.Q(iQ).rec(iirec).info.phases.phi_gen);
%                                 switch isig
%                                     case 2
%                                         v_all(iirec,:)  = v_all(iirec,:).*sign(data.Q(iQ).rec(iirec).info.phases.phi_gen(1));%exp(1i*fdata.Q(iQ).rec(iirec).info.phases.phi_gen);
%                                     case 3
%                                         v_all(iirec,:)  = v_all(iirec,:).*sign(data.Q(iQ).rec(iirec).info.phases.phi_gen(2));%exp(1i*fdata.Q(iQ).rec(iirec).info.phases.phi_gen);
%                                 end
                            end    
                        end                        
                    end
                    newsignal(fixme) = sum(v_all(keep==1,fixme),1)/size(v_all(keep==1,fixme),1)*sign(data.Q(iQ).rec(irec).info.phases.phi_gen(isig));
%                     switch isig
%                         case 2
%                             newsignal(fixme) = sum(v_all(keep==1,fixme),1)/size(v_all(keep==1,fixme),1)*sign(data.Q(iQ).rec(irec).info.phases.phi_gen(1));
%                         case 3
%                             newsignal(fixme) = sum(v_all(keep==1,fixme),1)/size(v_all(keep==1,fixme),1)*sign(data.Q(iQ).rec(irec).info.phases.phi_gen(2));
%                     end
                    relog(end,:) = [ ]; % delete temporary log
                    
                case 3
                    %                     cutcenter = cutcenter(1,1);
                    fixme = round((cutcenter-width/2     : dt : cutcenter+width/2)   /dt);
                    int1  = round((cutcenter-3*width/2  : dt : cutcenter-width/2-dt)/dt);
                    int2  = round((cutcenter+width/2+dt : dt : cutcenter+3*width/2) /dt);
                    
                    newsignal        = v;
                    newsignal(fixme) = NaN;
                    
                    % replace samples by interpolated values
                    fT = proclog.Q(iQ).fT;
                    H  = proclog.LPfilter;
                    V  = mrs_quadraturedetection(v,t,fT,H);
                    V(fixme) = NaN;
                    V(fixme) = interp1([mean(t(int1)) mean(t(int2))],...
                        [mean(V(int1)) mean(V(int2))],t(fixme),'linear');
                    newsignal(fixme) = abs(V(fixme)).*cos(2*pi*fT*t(fixme)-angle(V(fixme)));
            end
            
            % update data
            data.Q(iQ).rec(irec).rx(irx).sig(isig).v1 = newsignal;            
             
        case 4 % Do local NC
            
            % obtain info
            A = relog(ilog,6);  % # channels
            B = relog(ilog,7);  % reference channels (bin2dec)

            % do noise cancellation
            ref  = dec2bin(B,A);
            rx   = 1:A;
            data = mrsSigPro_NCDo(data,proclog,iQ,irec,irx,isig,2,rx(ref=='1'));
            
% %             % determine detection receivers
% %             BD  = dec2bin(relog(ilog,5),relog(ilog,4));    % detection channels
% %             dect = str2num(BD(:));
% %             % determine reference receivers
% %             BR  = dec2bin(relog(ilog,7),relog(ilog,6));    % reference channels
% %             ref = str2num(BR(:));
% %             % type of transfer Calculation
% %             C = relog(ilog,8);  % 1 Global, 2 Local   
% %             data    = mrsSigPro_NCDo(data,iQ,irec,irx,isig,C,ref==1,dect==1);

        case 5 % Do global NC
            
            % obtain info
            A = relog(ilog,6);  % # channels
            B = relog(ilog,7);  % reference channels (bin2dec)
            
            % cancel noise
            ref  = dec2bin(B,A);
            rx   = 1:A;
            data = mrsSigPro_NCDo(data,proclog,iQ,irec,irx,isig,1,rx(ref=='1'));
            
        case 6 % Calculate global TF
            
            % Nothing to do. TF is saved in proclog.
            
%             A = relog(ilog,6);  % # channels
%             B = relog(ilog,7);  % reference channels (bin2dec)
%             C = relog(ilog,8);  % signal channels (bin2dec)
%             
%             ref  = dec2bin(B,A);
%             fid  = dec2bin(C,A);
%             rx   = 1:A;
%             
% %             % determine detection receivers
% %             BD  = dec2bin(relog(ilog,5),relog(ilog,4));    % detection channels
% %             dect = str2num(BD(:));
% %             % determine reference receivers
% %             BR  = dec2bin(relog(ilog,7),relog(ilog,6));    % reference channels
% %             ref = str2num(BR(:));
% %             % type of transfer Calculation
% %             C = relog(ilog,8);  % 1 Global, 2 Local
% %             rxnumber=[1:1:length(ref)];
%             
%             data = mrsSigPro_NCGetTransfer(data,proclog,rx(ref=='1'),rx(fid=='1'));         
            
        
        case 101 % trim (in MRSFit)
            % Nothing to do. Trim events are handled in MRSFit.
              
    end
end

