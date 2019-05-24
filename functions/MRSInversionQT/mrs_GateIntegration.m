% function [gateV,gateT] = mrs_GateIntegration(V,t,nsamples[,dt])
%
% function to resample exponential signal within logarithmically spaced
% intervals
% gates. Average of the signal is done in logarithm to get exact mean of the signal
%
%
% Output:
%   gateV = gate averaged signal
%   gateT = time vector for averaged signal
%   gateL = length of each gate
%
% Input:
%   V = signal 
%   t = time
%   nsamples = number of logarithmically spaces gates
%
% Explanations:
%
% y=exp(x)
% For some interval x(a:b) the exact mean within exp(x(a:b))
% yAverage    = exp(mean(log(y(a:b))))
% t(yAverage) = mean(t(a:b))
%
% Problem: Logarithm is nice for exact average of exponential function. But
% signals are noise contaminated. 1. Logarithm of gaussian noise changes 
% noise structure from gaussian to lorenzian. Averaging of lorenzian 
% distributed noise is not zero. 2. Since noise can make signal negative
% a dc shift is added to make signals positive. This deminishes the 
% accurancy of averaging in logspace. For large constant shift averaging 
% in logspace becomes equivalent to average in linspace. However this is
% nice for noise structure.
% So we have a tradeoff.
% Finally, from some amount of intervals on, e.g. 20 within interval [0 1]/s
% averaging is sufficiently exact in any case.
%
% MMP 18/10/2011

function [gateV,gateT,gateL] = mrs_GateIntegration(V,t,nsamples,dt)

if nargin<4, dt=0; end

VbaseCorr = abs(10*min(V)); % necessary for log to be real
V         = V + VbaseCorr;    % shift signal into positive

% some t values sometimes are strange :-) --> round by 1e-10 
t=round(t*1e10)*1e-10;

% get gates in log spacing
tNew = abs(logspace(log10(t(2)+dt),log10(t(end)+t(2)+dt),nsamples) - t(2))-dt;
% get indices
tInd = ones(1,length(tNew));
for n=2:length(tNew)-1
    tInd(n) = find(tNew(n)<=t,1);
end
if ~isempty(find(tNew(end)<=t,1))           % avoid crash
    tInd(end) = find(tNew(end)<=t,1);
else
    tInd(end) = length(tNew);
end

tInd = unique(tInd);
tInd = cumsum([0 sort(diff(tInd))])+1;

gateV = zeros(1,length(tInd)-1);
gateT = zeros(1,length(tInd)-1);
gateL = zeros(1,length(tInd)-1);

% calculate mean within a gate in logspace
for n=2:length(tInd)
    gateV(n-1) = exp(mean(log(V(tInd(n-1):tInd(n)-1))));
    gateT(n-1) = mean(t(tInd(n-1):tInd(n)-1));
    gateL(n-1) = length(t(tInd(n-1):tInd(n)-1));
end

% subtract shift
gateV = gateV - VbaseCorr;




%% example
% clear all
% t = [0:1/1000:1];
% V_true = -(exp(-t/0.01) + exp(-t/0.1) + exp(-t/1));
% V      = V_true + 0.5*randn(1,length(t));
% VbaseCorr = abs(1000*min(V)); %necessary for log to be real
% V      = V + VbaseCorr;
% 
% nsamples=50;
% tNew = logspace(log10(t(2)),log10(t(end)+t(2)),nsamples) - t(2);
% 
% tInd = ones(1,length(tNew));
% for n=2:length(tNew)
%     tInd(n) = find(tNew(n)<t,1);
% end
% tInd = unique(tInd);
% 
% gateV = zeros(1,length(tInd)-1);
% gateT = zeros(1,length(tInd)-1);
% 
% for n=2:length(tInd)
%     gateV(n-1) = exp(mean(log(V(tInd(n-1):tInd(n)-1))));
%     gateT(n-1) = mean(t(tInd(n-1):tInd(n)-1));
% end
% 
% clf
% plot(gateT,gateV - VbaseCorr,'ko')
% hold on
% plot(t,V- VbaseCorr,'x')
% plot(t,V_true,'r')
