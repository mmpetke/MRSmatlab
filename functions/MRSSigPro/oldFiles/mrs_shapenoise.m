function [PredNoise] = mrs_shapenoise(R2,H)
% function PredNoise = fshapedNoise(R2,H)

% Applying shaping filter H --> Multichannel-Convolution
% 
% Input:    R2 - Second noise record from reference loop
%           H  - filter
% 
% Fabian Neyer, 20.August 2010

lengthRS2 = size(R2,2);         % length of reference records
numCh     = size(R2,1);

% H_temp                                    = zeros(2*lengthRS2-1,numCh);
% H_temp(lengthRS2:lengthRS2+size(H,1)-1,:) = H;                          % fills in filter at right position
% PredNoise                                 = zeros(1,lengthRS2);

% tic
x = zeros(numCh,lengthRS2);

for ch = 1:numCh
    x(ch,:)  = conv(R2(ch,:),[zeros(size(H,1),1); H(:,ch)],'same');
%     y  = conv(R2(ch,:),[zeros(size(H,1),1); H(:,ch)],'same');
%     PredNoise = x+y;
end
PredNoise = sum(x,1);
% toc

% % tic
% for m=1:lengthRS2
%     for n=1:numCh
% %         PredNoise(m) = PredNoise(m) + R2(n,:)*flipud(H_temp(m:m+lengthRS2-1,n));
%         PredNoise(m) = PredNoise(m) + R2(n,:)*(H_temp(m+lengthRS2-1:-1:m,n));
%         % JW: PredNoise(m) wird für jeden Channel n geupdated /
%         % überschrieben
%     end
% end
% % toc


% clf
% plot(abs(PredNoise)-abs(P))
% drawnow
% pause(1)