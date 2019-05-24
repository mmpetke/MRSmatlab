%% Function: replace detected spike by average

function [fdata,proclog] = mrsSigPro_replaceSpike(fdata,proclog,iQ,irec,irx,isig,threshold,cutcenter,width,type)

% determine wether single record is used for determination of spikes (i.e. statistic over time) or all
% records of one q (i.e. statistic over number of stacks)
%type='single rec'; case 2
%type='q stack'; case 1

%% type 3 aware testing
if type==3
    
else
%% get average signal first

t1         = fdata.Q(iQ).rec(irec).rx(irx).sig(isig).t1;
dt         = mean(diff(t1)); % t1(2)-t1(1); - for AK Caribou snd4: dt varies!!!
rec        = 1:length(fdata.Q(iQ).rec);

% to build average of remaining records take care of phase cycling!
switch isig
    case {2,4} % phase cycle for p90 is relevant
        if irec == length(fdata.Q(iQ).rec)
            rec([irec irec-1]) = [];
        else 
            rec([irec irec+1]) = [];
        end  
    case 3 % phase cycle for p90 and second p90 -> pcpsr!
        if irec == length(fdata.Q(iQ).rec)
            rec([irec irec-1 irec-2 irec-3]) = [];
        elseif irec == length(fdata.Q(iQ).rec)-1
            rec([irec+1 irec irec-1 irec-2]) = [];
        elseif irec == length(fdata.Q(iQ).rec)-2
            rec([irec+2 irec-1 irec irec-1]) = [];
        else
            rec([irec+3 irec-2 irec+1 irec]) = [];
        end
end

v_all  = zeros(length(rec),length(t1));     % use v1 instead of v0 to include previous processing steps
keep   = zeros(1,length(rec));
for iirec = rec
    v_all(iirec,:) = fdata.Q(iQ).rec(iirec).rx(irx).sig(isig).v1;
    keep(iirec) = mrs_getkeep(proclog,iQ,iirec,irx,isig);
    if strcmp(fdata.info.device,'GMR')
        if sign(fdata.Q(iQ).rec(iirec).info.phases.phi_gen(isig)) == 0
            % do nothing - phi_gen is set to 0 for
            % preprocessed GMR files
        else
%             v_all(iirec,:)  = v_all(iirec,:).*sign(fdata.Q(iQ).rec(iirec).info.phases.phi_gen(isig));%exp(1i*fdata.Q(iQ).rec(iirec).info.phases.phi_gen);
            switch isig
                case 2
                    v_all(iirec,:)  = v_all(iirec,:).*sign(fdata.Q(iQ).rec(iirec).info.phases.phi_gen(2));
                case 3
                    v_all(iirec,:)  = v_all(iirec,:).*sign(fdata.Q(iQ).rec(iirec).info.phases.phi_gen(3));
                case 4
                    v_all(iirec,:)  = v_all(iirec,:).*sign(fdata.Q(iQ).rec(iirec).info.phases.phi_gen(2));
            end
        end    
    end
end
V  = sum(v_all(keep==1,:),1)/size(v_all(keep==1,:),1);

%% check if input in fixme is already a window or automatic detection is selected

if threshold == -1 % manual
    
    % determine samples to be muted
    fixme = round(( max([cutcenter-width/2,t1(2)]) : dt : ...   % t(2)/dt -> index 2 because first sample is 1 and not 0. (?)
                    min([cutcenter+width/2,max(t1)]) )/dt);     % max / min to prevent window being larger than timeserie    
    
    % update fdata
%    fdata.Q(iQ).rec(irec).rx(irx).sig(isig).v1(fixme) = V(fixme)*sign(fdata.Q(iQ).rec(irec).info.phases.phi_gen(isig));   % correct phase for stacking: 4pc?
    switch isig
        case 2
            fdata.Q(iQ).rec(irec).rx(irx).sig(isig).v1(fixme) = V(fixme)*sign(fdata.Q(iQ).rec(irec).info.phases.phi_gen(2));   % correct phase for stacking: 4pc?
        case 3
            fdata.Q(iQ).rec(irec).rx(irx).sig(isig).v1(fixme) = V(fixme)*sign(fdata.Q(iQ).rec(irec).info.phases.phi_gen(3));   % correct phase for stacking: 4pc?
        case 4
            fdata.Q(iQ).rec(irec).rx(irx).sig(isig).v1(fixme) = V(fixme)*sign(fdata.Q(iQ).rec(irec).info.phases.phi_gen(2));
    end
    
    % update proclog
    despiketype  = 2;             % replace spike by average
    proclog.event(end+1,:) = [3 iQ irec irx isig despiketype width cutcenter];
    
else % automatic detection by threshold
    wlength       = round(width/dt);
    v             = fdata.Q(iQ).rec(irec).rx(irx).sig(isig).v1;
    t             = fdata.Q(iQ).rec(irec).rx(irx).sig(isig).t1; 
    switch type
        case 2 % 'single rec'
            % JW: it might make sense to run the autodespike on the QD signal so
            %     that high-frequency spikes are ignored here
            % MMP: to my feeling a spike does not vanish after QD and low-pass,
            % it seems that the frequency spectrum of a spike, or wavelet, is mostly large.
            % Even more I think they are much easier to detect in raw data due to its large
            % energy ??? Firstly, I was kind a surprised that this simple scheme on
            % only one stack works but I guess that the reason           
            v             = abs(v) - mean(abs(v));
            %     v             = v - mean(v);
            outlier       = v > threshold*std(v);

            index_outlier = (1:length(outlier))';
            hit           = index_outlier(outlier==1);
        case 1 % 'q stack'
            
            % filter
            fS          = fdata.Q(1).rec(1).info.fS;     % sampling freq
            fT          = fdata.Q(iQ).rec(irec).info.fT; % transmitter freq
            [dummy,ipass]   = find(proclog.LPfilter.passFreq <= 500,1,'last');
            [dummy,istop]   = find(proclog.LPfilter.stopFreq <= 1500,1,'last'); 
            [dummy,isample] = find(proclog.LPfilter.sampleFreq <= fS,1,'last');
            a = proclog.LPfilter.coeff.passFreq(ipass).stopFreq(istop).sampleFreq(isample).a;
            b = proclog.LPfilter.coeff.passFreq(ipass).stopFreq(istop).sampleFreq(isample).b;
            
            % stack
            rec        = 1:length(fdata.Q(iQ).rec);
            v_all      = zeros(length(rec),length(t1));
            for iirec = rec
                hv             = mrs_hilbert(fdata.Q(iQ).rec(iirec).rx(irx).sig(isig).v1);
                ehv            = hv.*exp(-1i*2*pi*fT.*t);
                v_all(iirec,:) = mrs_filtfilt(b,a,ehv);
                if strcmp(fdata.info.device,'GMR')
%                     v_all(iirec,:)  = v_all(iirec,:).*sign(fdata.Q(iQ).rec(iirec).info.phases.phi_gen);
%                     v_all(iirec,:)  = v_all(iirec,:).*sign(fdata.Q(iQ).rec(iirec).info.phases.phi_gen(isig));
                    switch isig
                        case 2
                            v_all(iirec,:)  = v_all(iirec,:).*sign(fdata.Q(iQ).rec(iirec).info.phases.phi_gen(2));
                        case 3
                            v_all(iirec,:)  = v_all(iirec,:).*sign(fdata.Q(iQ).rec(iirec).info.phases.phi_gen(3));
                        case 4
                            v_all(iirec,:)  = v_all(iirec,:).*sign(fdata.Q(iQ).rec(iirec).info.phases.phi_gen(4));
                    end
                end
            end
            outlier        = abs(v_all(irec,:)) > (mean(abs(v_all)) + threshold*median(std(abs(v_all)))); % single data point
            %outlier2       = std(v_all(:,:).') > threshold*median(std(v_all(:,:).')); % complete record 
            index_outlier  = (1:length(outlier))';
            %index_outlier2 = (1:length(outlier2))';
            hit            = index_outlier(outlier==1);
            %hit2           = index_outlier2(outlier2==1);
    end
    
    if std(v_all(irec,:).') > threshold*median(std(v_all(:,:).'))
        proclog.event(end+1,:) = [1 iQ irec irx isig 0 0 0];
    else
        if ~isempty(hit)
            % delete overlap, i.e. separate unique events
            ievent = 1;
            [dummy,event]  = max(v(hit(1):1:min(hit(1)+wlength,length(v)))); % detect maximum and use as center
            for io = 2:length(hit)
                if t1(event(ievent))+width/2 < t1(hit(io)) % new event
                    ievent = ievent+1;
                    [dummy,event(ievent)] = max(v(hit(io):1:min(hit(io)+wlength,length(v))));
                    event(ievent)     = event(ievent) + hit(io) -1;
                end
            end
            earlyNoDespike=0.005;
            % check for first x ms --> currently no despiking
            event(event < earlyNoDespike/dt)=[];
            % check for last x ms --> currently no despiking
            event(event > (t1(end) - earlyNoDespike)/dt)=[];
            
            % apply despike
            if length(event) > 0 && length(hit) < round(length(t)/10)% check for false event (spike within early time or too many spikes)
                for io = 1:length(event)
                    cutcenter = event(io);    % here cutcenter is in samples
                    fixme     = round(max([cutcenter-wlength/2,1])) : ...
                        round(min([cutcenter+wlength/2,length(v)]));     % max / min to prevent window being larger than timeserie; t(2) -> first sample is 1 and not 0.
                    % update fdata
                    switch isig
                        case 2
                            fdata.Q(iQ).rec(irec).rx(irx).sig(isig).v1(fixme) = V(fixme)*sign(fdata.Q(iQ).rec(irec).info.phases.phi_gen(2));
                        case 3
                            fdata.Q(iQ).rec(irec).rx(irx).sig(isig).v1(fixme) = V(fixme)*sign(fdata.Q(iQ).rec(irec).info.phases.phi_gen(3));
                        case 4
                            fdata.Q(iQ).rec(irec).rx(irx).sig(isig).v1(fixme) = V(fixme)*sign(fdata.Q(iQ).rec(irec).info.phases.phi_gen(4));
                    end
                    
                    
                    % update proclog --> log each spike on its own --> changed to
                    % log only complete run of despiking
                    % type  = 2;             % replace spike by average
                    % proclog.event(end+1,:) = [3 iQ irec irx isig type wlength*dt cutcenter*dt];
                end
                % update proclog
                type  = 2;             % replace spike by average
                proclog.event(end+1,:) = [3 iQ irec irx isig type io 0];
                
            elseif length(hit) > round(length(t)/10) % many spikes --> unkeep the record
                keep=0;
                proclog.event(end+1,:) = [1 iQ irec irx isig keep 0 0];
            end
        end
    end
end
end
