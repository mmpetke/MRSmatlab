function H = mrs_shapefilter(R1,P1,lH)
% function H = fshapefilter(R1,P1,lH)

% Shape filter function
%
% Input:    R1 - noise record reference (matrix: R1(channels,lengthTS))
%           P1 - noise record primary (d)
%           lH - filter length
%
% |R(1) . . R(lH)| |H(1) |   |r(1) |
% | .         .  | |  .  |   |  .  |
% | .         .  | |  .  | = |  .  |
% | .         .  | |  .  |   |  .  |
% |R(lH) . . R(1)| |H(lH)|   |r(lH)|

% cross-correlation (r)
% P1 = primary noise record, full length
% R1 = reference noise record, increased length: length(R1) +length(H) -1
% 0 0 0 0 * * * * * * * * * P1 -length (full), R1 -length (*)
% * * * * * . . . . . . . . lH -length
%
% Fabian Neyer, 20.August 2010


lengthRS = size(R1,2);         % common length of reference records
numCh    = size(R1,1);


% Check if R1 and P1 have the same length
if lengthRS ~= length(P1)
    display(' ')
    display('ERROR: Input signals have different lengths!')
    return
end
       


% Define filter length according to data-length and #reference channels
% based on Treitel 1974 and Treitel 1970

%     if numCh > 1
%         lH = floor((lengthRS-1)/((numCh-1)));
%     end
%
%     lH = 90;%floor(lH/10);
akm = zeros(lH,numCh,numCh);
kkm = zeros(lH,numCh);

for l=1:lH          % for every lag
    for m=1:numCh   % for every channel

        R1_temp = zeros(1,lengthRS+lH-1);
        R1_temp(lH:end) = R1(m,:);

        % multichannel auto-correlation for lag 0 to l-1
        % ----------------------------------------------
        for n=1:numCh
            akm(l,n,m) = R1(n,:)*R1_temp(lH-(l-1):lH-(l-1)+lengthRS-1)';
        end

        % multichannel cross-correlation for lag 0 to l-1
        % -----------------------------------------------
        kkm(l,m) = P1*R1_temp(lH-(l-1):lH-(l-1)+lengthRS-1)';
    end
end

% build autocorrelation matrix
RR = zeros(numCh*lH,numCh*lH);
TM = zeros(numCh,numCh);

for m=1:lH          % for every row assembledge
    for n=1:lH      % for every column assembledge
        if n >= m
            RR((m-1)*numCh+1:m*numCh,(n-1)*numCh+1:n*numCh) = akm(n-m+1,:,:);   % upper triangle
        elseif n < m && m > 1
            TM(1:numCh,1:numCh) = akm(m-n+1,:,:);
            RR((m-1)*numCh+1:m*numCh,(n-1)*numCh+1:n*numCh) = TM';              % lower triangle
        end
    end
end

% build crosscorrelation vector
KK = zeros(numCh*lH,1);

for m=1:lH
    KK((m-1)*numCh+1:m*numCh) = kkm(m,:);
end

% filter
S = RR\KK;
H = zeros(lH,numCh);

for l=1:lH
    H(l,:) = S(numCh*(l-1)+1:numCh*l);
end



