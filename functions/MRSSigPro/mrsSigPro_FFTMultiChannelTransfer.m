% h = FFTMultiChannelTransfer(reference,detection,average)
%
% Calculate transfer function of several reference channels R 
% to one detection channel S
% in frequency space with each frequency independently
% h1*R1 + h2*R2 + ... = S
%
% solving e.g. 3 channels by least squares
% | R1'R1 R1'R2 R1'R3|   |h1|   |R1'S|
% | R2'R1 R2'R2 R2'R3| * |h2| = |R2'S|
% | R3'R1 R3'R2 R3'R3|   |h3|   |R3'S|
%
% detection channel is of structure --> detection{measurement}.P1(timerecord)
% reference channel is of structure --> reference{measurement}.R1(channel,timerecord)

function h = mrsSigPro_FFTMultiChannelTransfer(reference,detection)

nC = size(reference(1).R1,1); % number of channels
re = length(reference); % number of measurements (stacks*pulses)


% pre-alocation
output.fft = zeros(re,size(detection(1).P1,2));
for n=1:nC
    input{n}.fft = zeros(re,size(reference(1).R1(1,:),2));
end
h    = zeros(size(output.fft,2),nC);

% fft
for s=1:re
    output.fft(s,:) = fft(detection(s).P1);
    if nargin == 3; output.fft(s,:) = filter(av,1,output.fft(s,:));end
    for n=1:nC
        input{n}.fft(s,:) = fft(reference(s).R1(n,:));
    end
end

% transfer function h
% build matrices to be solved A * H = B
for l=1:size(output.fft,2) % frequency loop
    for n=1:nC 
        for nn=1:nC
            A(n,nn) = input{n}.fft(:,l)'*input{nn}.fft(:,l);    % ' on complex quantity takes also the complex conjugate - is this intended here? Or only reshape?
        end
    end
    for n=1:nC
        B(n,1) = input{n}.fft(:,l)'*output.fft(:,l);
    end    
    h(l,:) = A\B;
end


