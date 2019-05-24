%% FUNCTION GET TRIM ------------------------------------------------------
% get trim user input & determine indices to keep
    function [minRecInd, maxRecInd] = mrs_gettrim(proclog,iQ,irx,isig)
        
        % Time
        t = proclog.Q(iQ).rx(irx).sig(isig).t;
        
        % Index of trim event
        minmaxt = proclog.event(...
                proclog.event(:,1) == 101 & ...
                proclog.event(:,2) == iQ & ...
                proclog.event(:,3) == 0 & ...
                proclog.event(:,4) == irx & ...
                proclog.event(:,5) == isig, 6:7);
        
        % Determine indices corresponding to mint & maxt
        if isempty(minmaxt)  % no trim event
            minRecInd = 1;
            maxRecInd = length(t);
        else            % there is a trim event
            
            % Times
            mint = minmaxt(1);
            maxt = minmaxt(2);
            
            % Minimum time index
            minRecInd = find(t >= mint,1);
            
            % Maximum time index
            if maxt >= t(end)
                maxRecInd = length(t);
            else
                maxRecInd = find(t > maxt,1)-1;
            end            
        end
    end