function proceed = mrsSigPro_check_keep_phasecycle(fdata,proclog)
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
            neven  = length(find(isodd==0));
            nodd   = length(find(isodd==1));
            
             % collect complaint if # odd indices is not equal to # even indices
            if neven ~= nodd
                count = count+1;
                complaints(count,1:5) = [iQ irx sig(isig) neven nodd];
                proceed = 0;
            end
        end
    end
end

% display which datasets need to be adjusted
if proceed == 0
    style = struct('WindowStyle', 'non-modal', 'Interpreter', 'tex');
    Cstring = {...
        '{\bfData are NOT saved.}';
        'For phase-cycling, there must be the same number of ';
        'even and odd recordings. Adjust the following data sets:';
        ' ';
        'iQ       irx      isig    {\bf#even}  {\bf#odd}: ';
        num2str(complaints,  '       %1.0f '); 
        ' ';
        'Keep or drop additional recordings to make {\bf#even=#odd} before saving data.';
        };
	msgbox(Cstring, 'Adjust "keep" before saving', style);
end

