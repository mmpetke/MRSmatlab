clear all;
if ~exist('proclog')
     load('D:\Mueller-Petke.M\data\140922_Schillerslage_offRes\AssumedONRES_2099Hz\2016Test.mrsr','-mat');
%    load('D:\Mueller-Petke.M\data\140922_Schillerslage_offRes\AssumedONRES_2099Hz\matlab.mat');
end
%%
% get a signal
iQ   = 5;
irec = 3;
irx  = 1;
isig = 2;

fT = fdata.Q(iQ).rec(irec).info.fT; % transmitter freq
fS = fdata.Q(1).rec(1).info.fS;     % sampling freq
fW = 500;

v  = fdata.Q(iQ).rec(irec).rx(irx).sig(isig).v0; % [V]
t  = fdata.Q(iQ).rec(irec).rx(irx).sig(isig).t0;

[dummy,ipass]   = find(proclog.LPfilter.passFreq <= fW,1,'last');
[dummy,istop]   = find(proclog.LPfilter.stopFreq <= 3*fW,1,'last'); %<-- this might be checked if this is a good default, I think so.
[dummy,isample] = find(proclog.LPfilter.sampleFreq <= fS,1,'last');
a = proclog.LPfilter.coeff.passFreq(ipass).stopFreq(istop).sampleFreq(isample).a;
b = proclog.LPfilter.coeff.passFreq(ipass).stopFreq(istop).sampleFreq(isample).b;
hv          = mrs_hilbert(v);
ehv         = hv.*exp(-1i*2*pi*fT.*t);
V           = mrs_filtfilt(b,a,ehv);
%sig         = real(V);



%%
% real part
xspike  = zeros(1000,1); xspike(500)=1;
fx      = mrs_filtfilt(b,a,xspike);
[ix,ipR] = max(abs(xcorr(real(V),fx)));
[ix,ipI] = max(abs(xcorr(imag(V),fx)));

xspikeR  = zeros(size(ehv)); xspikeR(ipR+500-length(t)) = 1;
fxR      = mrs_filtfilt(b,a,xspikeR);
vxR      = fxR.'\real(V).';
vxI      = fxR.'\imag(V).';

xsR = zeros(size(ehv)); xsR(ipR+500-length(t)) = vxR;
xsI = zeros(size(ehv)); xsI(ipI+500-length(t)) = vxI;

Fs          = 50000;
Fpass       = [3000];   % Passband Frequency
Fstop       = [5000];  % Stopband Frequency
Apass       = 1;     % Passband Ripple (dB)
Astop       = 50;    % Stopband Attenuation (dB)
[N,Fc]      = buttord(Fpass/(Fs/2), Fstop/(Fs/2), Apass, Astop);
[b,a]       = butter(N, Fc);

%xehv = complex(xsR,xsI);
%xhv  = xehv.*exp(1i*2*pi*fT.*t);
xhv  = complex(real(xsR.*exp(1i*2*pi*fT.*t)) + real(xsI.*exp(1i*2*pi*fT.*t)),...
               imag(xsR.*exp(1i*2*pi*fT.*t)) + imag(xsI.*exp(1i*2*pi*fT.*t)));
v2   = real(xhv); 
%ehv_c  = complex(real(ehv)-xsR,imag(ehv)-xsI);
%hv_c = ehv_c.*exp(1i*2*pi*fT.*t);
%v2   = real(hv_c);

hv2   = mrs_hilbert(v2);
ehv2  = hv2.*exp(-1i*2*pi*fT.*t);
V2    = mrs_filtfilt(b,a,ehv2);

%%
clf
subplot(411)
plot(t,vxR)
subplot(412)
plot(t,real(ehv2))
subplot(413)
plot(t,vxI)
subplot(414)
plot(t,imag(ehv2))

% subplot(211)
% plot(t,real(V))
% hold on
% plot(t,real(V) - mrs_filtfilt(b,a,xsR))
% subplot(212)
% plot(t,imag(V))
% hold on
% plot(t,imag(V)-mrs_filtfilt(b,a,xsI))

 
% hold on
% plot(t,fx2)
% subplot(413)
% plot(t,sig-vx*fx,'o')
% hold on
% plot(t,sig2)
% subplot(414)
% plot(xcorr(sig,fx))