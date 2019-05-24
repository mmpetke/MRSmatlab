function proclog = mrsSigPro_adjust_keep_phasecycle(fdata,proclog)
% function proceed = mrsSigPro_check_keep_phasecycle(fdata,proclog)
% 
% Check if there are an equal number of odd and even recording indices. If
% not (proceed=0), return and prompt user to make them even so that 
% phase-cycling can be carried out.
% 
% THIS MIGHT HAVE TO BE ADJUSTED FOR THE 4PHASE-CYCLING SCHEME.
% 
% Jan Walbrecker 16may2012
% ed. 06jun2012
% =========================================================================    

% initialize
proceed = 1;
count   = 0;

% define time series to check
srx = ([fdata.info.rxinfo(:).task] == 1);   % check signal receivers
sig = [2 3];                                % check signals fid & fid2

% number of Q's, receivers, signals
nQ   = length(fdata.Q);
nrx  = length(srx);
nsig = length(sig);

% no phasecycling if not GMR - exit
if strcmp(proclog.device,'GMR') == 0
    return
end

% no phasecycling if only 1 recording for each q (this occurs only for preprocessed data)
n = zeros(1,nQ);
for iQ = 1:nQ
    n(iQ) = length(fdata.Q(iQ).rec);
end
if sum(n) == nQ
    return
end

% browse all time series
complaints = zeros(1,5);    % initialize complaints
for isig = 1:nsig
    for irx = 1:nrx
        for iQ = 1:nQ
            
            % number of recordings (can be different for each q if recording was interrupted)
            nrec = length(fdata.Q(iQ).rec);   
            
            % determine which recordings for iQ,isig,irx are kept
            keep = zeros(1,nrec);
            for irec = 1:nrec
                keep(irec) = mrs_getkeep(proclog,iQ,irec,irx,sig(isig));
            end
            
            % check if # of odd record indices does not equal # even ones
            isodd = mod(find(keep==1),2);
            ind   = find(keep==1); 
            neven  = length(find(isodd==0));
            nodd   = length(find(isodd==1));
            
             % add additional record to unkeep
            if neven ~= nodd
                if neven > nodd
                    index = find(isodd==0);
                    for ii=1:neven-nodd
                        proclog.event(end+1,:) = [1 iQ ind(index(ii)) irx sig(isig) 0 0 0];
                    end
                else
                    index = find(isodd==1);
                    for ii=1:nodd-neven
                        proclog.event(end+1,:) = [1 iQ ind(index(ii)) irx sig(isig) 0 0 0];
                    end
                end
            end
        end
    end
end



