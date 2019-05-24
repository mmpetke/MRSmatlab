function [fdata,proclog] = mrsSigPro_DelHarmonic(fdata,proclog,hSource,removeCof,fastHNC, iQ,irec,irx,isig,iB)

t  = fdata.Q(iQ).rec(irec).rx(irx).sig(isig).t1; % [s]
v  = fdata.Q(iQ).rec(irec).rx(irx).sig(isig).v1; % [V]
fT = fdata.Q(iQ).rec(irec).info.fT;
%fT=2000;

%%
st = t(:);
sr = v(:);

if ~fastHNC     % approach after Mueller-Petke et al. 2016 in GEOPHYSICS
    %% determine baseband via brute force search and parameter by matrix inversion  

        if hSource==1 % train
            fH  = 90; % first nth-harmonic
            nH  = 75; % number of harmonics
            bfs = [16.6:.015:16.8]; % band to look for baseband
        elseif hSource==2 %powerline 50 Hz
            fH  = 20; % first nth-harmonic
            nH  = 40; % number of harmonics
            bfs = [49.9:.015:50.1]; % band to look for baseband
        elseif hSource==3 %powerline 60 Hz
            fH  = 20; % first nth-harmonic
            nH  = 40; % number of harmonics
            bfs = [59.9:.015:60.1]; % band to look for baseband
        end

    %% only one base frequency per run
    if ~iB
        for n=1:2
            fprintf(1,'%.1f',0.0)
            for ibf=1:length(bfs)
                iB     = bfs(ibf);
                e(ibf) = norm(sr - HNM(st, sr, fH, nH, iB, fT));
                fprintf(1, '\b\b\b');
                fprintf(1,'%.1f',round(10*n/2)/10)
            end
            fprintf(1, '\b\b\b');
            [~,b] = min(e);
            iB    = bfs(b);
            bfs = [iB-0.01:.001:iB+0.01];
        end
        disp(['base frequency estimated: ' num2str(iB)])
        fdata.Q(iQ).rec(irec).rx(irx).bf=iB;
    else
        disp(['external base frequency used: ' num2str(iB)])
    end
     
else % approach after Wang 2018 in GJI
    %% get the dictionary first
    global D16 D50 D60
    if hSource==1 % train
        fH  = 65; % first nth-harmonic
        nH  = 100; % number of harmonics
        bfs = [16.55:.001:16.75]; % band to look for baseband
        if size(D16,1) ~= length(st)
            D16=[];
        end
        if isempty(D16)==1   %create ditionary
            for ibf=1:length(bfs)
                iB     = bfs(ibf);
                f    = fH*iB + iB*[1:nH];
                F    = repmat(f,length(st),1); 
                T    = repmat(st,1,nH);                       
                A    = [cos(T.*2.*pi.*F) sin(T.*2.*pi.*F)];
                B    = sum(A,2);
                B    = B./norm(B);
                D16(:,ibf) = B;
            end
        end
        D = D16;
    elseif hSource==2 %powerline 50 Hz
        fH  = 20; % first nth-harmonic
        nH  = 40; % number of harmonics
        bfs = [49.9:.001:50.1]; % band to look for baseband
        if size(D50,1) ~= length(st)
            D50=[];
        end
        if isempty(D50)==1   %create ditionary
           for ibf=1:length(bfs)
                iB     = bfs(ibf);
                f    = fH*iB + iB*[1:nH];
                F    = repmat(f,length(st),1); 
                T    = repmat(st,1,nH);                       
                A    = [cos(T.*2.*pi.*F) sin(T.*2.*pi.*F)];
                B    = sum(A,2);
                B    = B./norm(B);
                D50(:,ibf) = B;
            end
        end 
        D = D50;
    elseif hSource==3 %powerline 60 Hz
        fH  = 20; % first nth-harmonic
        nH  = 40; % number of harmonics
        bfs = [59.9:.0001:60.1]; % band to look for baseband
        if size(D60,1) ~= length(st)
            D60=[];
        end
        if isempty(D60)==1   %creat ditionary
            for ibf=1:length(bfs)
                iB     = bfs(ibf);
                f    = fH*iB + iB*[1:nH];
                F    = repmat(f,length(st),1); 
                T    = repmat(st,1,nH);                       
                A    = [cos(T.*2.*pi.*F) sin(T.*2.*pi.*F)];
                B    = sum(A,2);
                B    = B./norm(B);
                D60(:,ibf) = B;
            end
        end
        D = D60;
    end
    
    if ~iB
        % search for the basic frequency
        v  = fdata.Q(iQ).rec(irec).rx(irx).sig(isig).v1; % [V]
        sr1 = v(:);
        ms = abs(sum(mscohere(sr1,D,hanning(1024),512,1024)));  %calculate coherence
        ms(ms<0.25) = 0;
        C= ms;
        iB = bfs(abs(C)==max(abs(C)));   %iB is the basic frequency
        disp(['B:    base frequency estimated: ' num2str(iB)])
        fdata.Q(iQ).rec(irec).rx(irx).bf=iB;
    else
        disp(['external base frequency used: ' num2str(iB)])
    end

end

% finally apply and check for cofrequencies
if removeCof
    signal_co = fdata.Q(iQ).rec(irec).rx(irx).sig(isig).v1 - HNM(st, sr, fH, nH, iB, fT).';
    fs        = fdata.Q(1).rec(1).info.fS;
    LPfilter  = proclog.LPfilter;
    fdata.Q(iQ).rec(irec).rx(irx).sig(isig).v1 = signal_co-CFHNM(st,signal_co,fs,fT,iB,LPfilter);
else
    fdata.Q(iQ).rec(irec).rx(irx).sig(isig).v1 = fdata.Q(iQ).rec(irec).rx(irx).sig(isig).v1 - HNM(st, sr, fH, nH, iB, fT).';
end

% create log entry
proclog.event(end+1,:) = [2 iQ irec irx isig hSource iB 0];



function [ms,f,a,p] = HNM(time, signal, fH, nH, iB, fT)
% determine amplitude and phase for each frequeny by inversion
% the problem is overdetermined and linear so we do that directly
f    = fH*iB + iB*[1:nH];
f(abs(f-fT)<5)=[]; % check if transmitter frequency is close to harmonic to avoid NMR cancelling
nH   = length(f);
F    = repmat(f,length(time),1); 
T    = repmat(time,1,nH);                       
A    = [cos(T.*2.*pi.*F) sin(T.*2.*pi.*F)];
fit  = A\signal;

a  = sqrt(fit(1:nH).^2 + fit(nH+1:end).^2);
p  = atan(fit(nH+1:end)./fit(1:nH));
ms = A*fit;


function [ms,f,a,p] = HNM_all(time, signal, fH, nH, iB, fT)
fH  = 20; % first nth-harmonic
nH  = 40; % number of harmonics
bfs = [49.9:.015:50.1]; % band to look for baseband
for ibf=1:length(bfs)
    iB     = bfs(ibf);
    f    = fH*iB + iB*[1:nH];
    F    = repmat(f,length(st),1);
    T    = repmat(st,1,nH);
    A    = [cos(T.*2.*pi.*F) sin(T.*2.*pi.*F)];
    B    = sum(A,2);
    B    = B./norm(B);
    D50(:,ibf) = B;
end



function [CFmodel]=CFHNM(time,signal_CO,fs,fL,iB,LPfilter)
%co-frequency harmonic model
nf = round(fL/iB);
fT = iB*nf;
fW = 200;
sigh = mrsSigPro_QD(signal_CO,time.',fT,fs,fW,LPfilter);

ini = [1e-8, 0.5, fL-fT, pi/4,0,0];
lb = [1e-10, 0.01, -50, -pi,-5e-6,-5e-6];
ub = [1e-5,1, 50, pi,5e-6,5e-6];

t = time;
t(isnan(sigh)) =[];
sigh(isnan(sigh)) =[];
sigh = sigh(t<=1);
t = t(t<=1);
[fitpar,~] = fitFID_CoF(t,sigh,lb,ini,ub);
e0_fit = fitpar(1);
t2s_fit = fitpar(2);
f0_fit = fitpar(3);
phi0_fit = fitpar(4);
af = fitpar(5)+1i*fitpar(6);
%realpart = e0_fit*cos(2*pi*f0_fit*t+phi0_fit).*exp(-t/t2s_fit) + fitpar(5);
%imagpart = e0_fit*sin(2*pi*f0_fit*t+phi0_fit).*exp(-t/t2s_fit) + fitpar(6);

%sigf = realpart + 1i*imagpart;
%abs(af)*1e9
CFmodel=abs(af)*cos(2*pi*iB*nf*time+angle(af))';
