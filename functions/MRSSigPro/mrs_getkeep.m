function keep = mrs_getkeep(proclog,iQ,irec,irx,isig)
% function keep = mrs_getkeep(proclog,iQ,irec,irx,isig)
% 
% Retrieve from proclog if current time series is kept (keep=1) or not
% (keep=0).
% 
% Jan Walbrecker
% ed. 04 oct 2011 JW
% =========================================================================    

% workaround for mrs_reprocess_proclog (passes proclog.event instead of proclog)
if ~isstruct(proclog)
    relog = proclog;
    clear proclog
    proclog.event = relog;
end

% find all keep events for current FID
keep = proclog.event(proclog.event(:,1) == 1 & ...
    proclog.event(:,2) == iQ & ...
    proclog.event(:,3) == irec & ...
    proclog.event(:,4) == irx & ...
    proclog.event(:,5) == isig, 6);

% determine last keep status
if isempty(keep)        % if no entry -> set keep to 1
    keep = 1;
else
    keep = keep(end);   % if entry -> set to last log entry
end
