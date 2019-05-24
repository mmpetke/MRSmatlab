function [P2_NoiseRed,H] = mrs_noisereduction(P1,R1,P2,R2,fl,H)
% function data = mrs_noisereduction(data,proclog,ref,prx,fl)

% Main program to do noise-cancellation using different approaches
%
%
% Input:    P1  - noise at time1 in primary receiver
%           R1  - noise at time1 in reference receiver(s)
%           P2  - signal+noise at time2 in primary receiver
%           R2  - noise at time2 in reference receiver(s)
%           fl  - filter length (in # samples)
% 
% Outpu:    P2_NoiseRed  - noise at time1 in primary receiver
%
% Fabian Neyer, Oct 2010
% JW 26nov2010

if nargin < 6
    H = mrs_shapefilter(R1,P1,fl);
end

if isempty(H)   % might by input as empty
    H = mrs_shapefilter(R1,P1,fl);
end

PredNoise2  = mrs_shapenoise(R2,H);
P2_NoiseRed = P2 - PredNoise2;

noisefig = findobj('Name', 'Noise reduction');
if isempty(noisefig)
    noisefig = figure('Name', 'Noise reduction');
end 
set(0,'CurrentFigure', noisefig)
clf(noisefig)
plot(1:length(P2),P2)
hold on
plot(1:length(P2),P2_NoiseRed,'r')
hold off
axis tight
drawnow


% nQ       = length(data.Q);         % determine number of Q values
% 
% 
% for iQ = 1:nQ                       % for every q
%     for irec = 1:length(data.Q(iQ).rec)  % for every record 
%         for iprx = 1:length(prx)    % for every primary receiver (usually just one)
%             
%             
%             % KEEP wird KOMPLIZIERT.
%             % check for keep == 0
%             % if primary keep == 0 -> next rec; if secondary keep == 0 -> do not use.            
%             REF = ref;  % reset REF            
%             % collect keep
%             keep_prx = getkeep(proclog,iQ,irec,prx(iprx),isig);
%             for iref = 1: length(ref)
%                 keep_ref(iref) = getkeep(proclog,iQ,irec,ref(iref),isig);
%             end
% 
%             if keep_prx == 0
%                 % skip
%             elseif ~any(keep_ref) == 1  % all receivers off
%                 % skip
%             else
%                 REF = REF(keep_ref==1);     % delete disabled rx
%                 
%                 % assemble P - P1->n, P2->v ?
%                 P1 = data.Q(iQ).rec(irec).rx(prx(iprx)).sig(1).v1;  % noise
%                 P2 = data.Q(iQ).rec(irec).rx(prx(iprx)).sig(2).v1;  % fid1
%                 if data.Q(iQ).rec(irec).rx(prx(iprx)).sig(3).recorded == 1
%                     P3 = data.Q(iQ).rec(irec).rx(prx(iprx)).sig(3).v1; % fid2
%                 end
%                 if data.Q(iQ).rec(irec).rx(prx(iprx)).sig(4).recorded == 1
%                     P4 = data.Q(iQ).rec(irec).rx(prx(iprx)).sig(4).v1; % fid2
%                 end
% 
%                 % initialize R1, R2, and R3
%                 R1 = zeros(length(REF),length(P1));
%                 R2 = zeros(length(REF),length(P2));
%                 if data.Q(1).rec(1).rx(prx(1)).sig(3).recorded
%                     R3 = zeros(length(REF),length(P3));
%                 end
%                 if data.Q(1).rec(1).rx(prx(1)).sig(4).recorded
%                     R4 = zeros(length(REF),length(P4));
%                 end
% 
%                 for iref = 1:length(REF)    % for each reference channel
%                     % Write noise, first and second signal of all reference
%                     % receivers in matrices R1 R2 R3
%                     R1(iref,:) = data.Q(iQ).rec(irec).rx(REF(iref)).sig(1).v1;
%                     R2(iref,:) = data.Q(iQ).rec(irec).rx(REF(iref)).sig(2).v1;
%                     if data.Q(iQ).rec(irec).rx(prx(iprx)).sig(3).recorded == 1
%                         R3(iref,:) = data.Q(iQ).rec(irec).rx(REF(iref)).sig(3).v1;
%                     end
%                     if data.Q(iQ).rec(irec).rx(prx(iprx)).sig(4).recorded == 1
%                         R4(iref,:) = data.Q(iQ).rec(irec).rx(REF(iref)).sig(4).v1;
%                     end                
%                 end
%                 H           = mrs_shapefilter(R1,P1,fl);    % H is used for all signals
%                 PredNoise2  = mrs_shapenoise(R2,H);
%                 P2_NoiseRed = P2 - PredNoise2;
% 
%                 if data.Q(iQ).rec(irec).rx(prx(iprx)).sig(3).recorded == 1
%                     PredNoise3  = mrs_shapenoise(R3,H);     % uses same filter function as for signal 1
%                     P3_NoiseRed = P3 - PredNoise3;
%                 end
% 
%                 if data.Q(iQ).rec(irec).rx(prx(iprx)).sig(4).recorded == 1
%                     PredNoise4  = mrs_shapenoise(R4,H);     % uses same filter function as for signal 1
%                     P4_NoiseRed = P4 - PredNoise4;
%                 end
% 
%                 figure(10)
%                 clf(10)
%                 t=data.Q(iQ).rec(irec).rx(REF(iref)).sig(2).t1;
%                 plot(t,P2)
%                 hold on
%                 plot(t,P2_NoiseRed,'r')
%                 hold off
%                 axis tight
% 
%                 % Save filtered data
%                 data.Q(iQ).rec(irec).rx(prx(iprx)).sig(2).v2 = P2_NoiseRed;
%                 if data.Q(iQ).rec(irec).rx(prx(iprx)).sig(3).recorded == 1
%                     data.Q(iQ).rec(irec).rx(prx(iprx)).sig(3).v2 = P3_NoiseRed;
%                 end
%                 if data.Q(iQ).rec(irec).rx(prx(iprx)).sig(4).recorded == 1
%                     data.Q(iQ).rec(irec).rx(prx(iprx)).sig(4).v2 = P4_NoiseRed;
%                 end
%             end
%         end     % end primary receiver
%     end     % end record
% end     % end q
% 
% end

% %% GET KEEP -----------------------------------------------------------
% % get current keep value
% function keep = getkeep(proclog,iQ,irec,irx,isig)
%     keep = proclog.event(proclog.event(:,1) == 1 & ...   
%                          proclog.event(:,2) == iQ & ...   
%                          proclog.event(:,3) == irec & ...
%                          proclog.event(:,4) == irx & ...
%                          proclog.event(:,5) == isig, 6);
%     if isempty(keep)
%         keep = 1;
%     else
%         keep = keep(end);   % last log entry
%     end
% end