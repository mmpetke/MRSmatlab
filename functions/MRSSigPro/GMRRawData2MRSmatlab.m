function fdata = GMRRawData2MRSmatlab(data,fdata,iq,irec,nq)

dofilter=1;
if dofilter
    % filtering causes some time cut at the beginnning of the record to
    % avoid artifact (currently 100 samples)
    % take into this into account 
    % resampling starts 100 samples --> dt = 100/fdata.header.fS
    % dphase = sin(2*pi*fT.*dt) ?!?!?
    % current approach: adapt timevector for QD to include deadtime
    
    % decimate from 50kHz sampling down to 10kHz to reduce data
    % filter definition
    if ~exist('buttord')
        % take filter coefficient from precalculation
        load('coefficient.mat')
        Fs          = fdata.header.fS;
        Fpass       = [3000];   % Passband Frequency
        Fstop       = [5000];  % Stopband Frequency
        Apass       = 1;     % Passband Ripple (dB)
        Astop       = 50;    % Stopband Attenuation (dB)
        [dummy,ipass]   = find(passFreq <= Fpass,1,'last');
        [dummy,istop]   = find(stopFreq <= Fstop,1,'last');
        [dummy,isample] = find(sampleFreq <= Fs,1,'last');
        a = coeff.passFreq(ipass).stopFreq(istop).sampleFreq(isample).a;
        b = coeff.passFreq(ipass).stopFreq(istop).sampleFreq(isample).b;
    else
        Fs          = fdata.header.fS;
        Fpass       = [3000];   % Passband Frequency
        Fstop       = [5000];  % Stopband Frequency
        Apass       = 1;     % Passband Ripple (dB)
        Astop       = 50;    % Stopband Attenuation (dB)
        [N,Fc]      = buttord(Fpass/(Fs/2), Fstop/(Fs/2), Apass, Astop);
        [b,a]       = butter(N, Fc);
    end
    rate            = (Fs/2)/Fstop; % reduce rate ,i.e., re-samling
    fs              = Fs/rate;
    deadtime        = fdata.header.tau_dead + (100 + rate)/Fs;
    
    if ~fdata.UserData(1).looptask==0; tmp.receiver(1).signal = mrs_filtfilt(b,a,data.recordC1{iq}.sig2);end
    if ~fdata.UserData(2).looptask==0; tmp.receiver(2).signal = mrs_filtfilt(b,a,data.recordC2{iq}.sig2);end
    if ~fdata.UserData(3).looptask==0; tmp.receiver(3).signal = mrs_filtfilt(b,a,data.recordC3{iq}.sig2);end
    if ~fdata.UserData(4).looptask==0; tmp.receiver(4).signal = mrs_filtfilt(b,a,data.recordC4{iq}.sig2);end
    if fdata.header.nrx == 8
        if ~fdata.UserData(5).looptask==0; tmp.receiver(5).signal = mrs_filtfilt(b,a,data.recordC5{iq}.sig2);end
        if ~fdata.UserData(6).looptask==0; tmp.receiver(6).signal = mrs_filtfilt(b,a,data.recordC6{iq}.sig2);end
        if ~fdata.UserData(7).looptask==0; tmp.receiver(7).signal = mrs_filtfilt(b,a,data.recordC7{iq}.sig2);end
        if ~fdata.UserData(8).looptask==0; tmp.receiver(8).signal = mrs_filtfilt(b,a,data.recordC8{iq}.sig2);end
    end
    
    for irx=1:fdata.header.nrx
        if ~fdata.UserData(irx).looptask==0
            polyout.receiver(irx).signal(1).V     = [];
            polyout.receiver(irx).signal(2).V     = tmp.receiver(irx).signal(100+rate:rate:end-rate-100).'; % 50 arises from filter spike test
            polyout.receiver(irx).signal(3).V     = [];
            polyout.receiver(irx).signal(4).V     = [];
            %polyout.receiver(irx).SampleFrequency = fdata.header.fS/rate;
            polyout.receiver(irx).signal(2).t     = (0:length(polyout.receiver(irx).signal(2).V)-1)/(fdata.header.fS/rate);     % time [s]
        end
    end
    
    switch fdata.header.sequenceID
        case 4
            if ~fdata.UserData(1).looptask==0; tmp.receiver(1).signal = mrs_filtfilt(b,a,data.recordC1{iq}.sig3);end
            if ~fdata.UserData(2).looptask==0; tmp.receiver(2).signal = mrs_filtfilt(b,a,data.recordC2{iq}.sig3);end
            if ~fdata.UserData(3).looptask==0; tmp.receiver(3).signal = mrs_filtfilt(b,a,data.recordC3{iq}.sig3);end
            if ~fdata.UserData(4).looptask==0; tmp.receiver(4).signal = mrs_filtfilt(b,a,data.recordC4{iq}.sig3);end
            if fdata.header.nrx == 8
                if ~fdata.UserData(5).looptask==0; tmp.receiver(5).signal = mrs_filtfilt(b,a,data.recordC5{iq}.sig3);end
                if ~fdata.UserData(6).looptask==0; tmp.receiver(6).signal = mrs_filtfilt(b,a,data.recordC6{iq}.sig3);end
                if ~fdata.UserData(7).looptask==0; tmp.receiver(7).signal = mrs_filtfilt(b,a,data.recordC7{iq}.sig3);end
                if ~fdata.UserData(8).looptask==0; tmp.receiver(8).signal = mrs_filtfilt(b,a,data.recordC8{iq}.sig3);end
            end
            
            for irx=1:fdata.header.nrx
                if ~fdata.UserData(irx).looptask==0
                    polyout.receiver(irx).signal(3).V = tmp.receiver(irx).signal(100+rate:rate:end-rate-100).';
                    polyout.receiver(irx).signal(3).t = (0:length(polyout.receiver(irx).signal(3).V)-1)/(fdata.header.fS/rate);     % time [s]
                end
            end
        case {3,7}
            if ~fdata.UserData(1).looptask==0; tmp.receiver(1).signal = mrs_filtfilt(b,a,data.recordC1{iq}.sig4);end
            if ~fdata.UserData(2).looptask==0; tmp.receiver(2).signal = mrs_filtfilt(b,a,data.recordC2{iq}.sig4);end
            if ~fdata.UserData(3).looptask==0; tmp.receiver(3).signal = mrs_filtfilt(b,a,data.recordC3{iq}.sig4);end
            if ~fdata.UserData(4).looptask==0; tmp.receiver(4).signal = mrs_filtfilt(b,a,data.recordC4{iq}.sig4);end
            if fdata.header.nrx == 8
                if ~fdata.UserData(5).looptask==0; tmp.receiver(5).signal = mrs_filtfilt(b,a,data.recordC5{iq}.sig4);end
                if ~fdata.UserData(6).looptask==0; tmp.receiver(6).signal = mrs_filtfilt(b,a,data.recordC6{iq}.sig4);end
                if ~fdata.UserData(7).looptask==0; tmp.receiver(7).signal = mrs_filtfilt(b,a,data.recordC7{iq}.sig4);end
                if ~fdata.UserData(8).looptask==0; tmp.receiver(8).signal = mrs_filtfilt(b,a,data.recordC8{iq}.sig4);end
            end
            
            for irx=1:fdata.header.nrx
                if ~fdata.UserData(irx).looptask==0
                    polyout.receiver(irx).signal(4).V = tmp.receiver(irx).signal(100+rate:rate:end-rate-100).';
                    polyout.receiver(irx).signal(4).t = (0:length(polyout.receiver(irx).signal(4).V)-1)/(fdata.header.fS/rate);     % time [s]
                end
            end
    end
    
else %% read in data without filter
    
    rate=1;
    deadtime = fdata.header.tau_dead;
    
    if ~fdata.UserData(1).looptask==0; tmp.receiver(1).signal = data.recordC1{iq}.sig2;end
    if ~fdata.UserData(2).looptask==0; tmp.receiver(2).signal = data.recordC2{iq}.sig2;end
    if ~fdata.UserData(3).looptask==0; tmp.receiver(3).signal = data.recordC3{iq}.sig2;end
    if ~fdata.UserData(4).looptask==0; tmp.receiver(4).signal = data.recordC4{iq}.sig2;end
    if fdata.header.nrx == 8
        if ~fdata.UserData(5).looptask==0; tmp.receiver(5).signal = data.recordC5{iq}.sig2;end
        if ~fdata.UserData(6).looptask==0; tmp.receiver(6).signal = data.recordC6{iq}.sig2;end
        if ~fdata.UserData(7).looptask==0; tmp.receiver(7).signal = data.recordC7{iq}.sig2;end
        if ~fdata.UserData(8).looptask==0; tmp.receiver(8).signal = data.recordC8{iq}.sig2;end
    end
    
    for irx=1:fdata.header.nrx
        if ~fdata.UserData(irx).looptask==0
            polyout.receiver(irx).signal(1).V     = [];
            polyout.receiver(irx).signal(2).V     = tmp.receiver(irx).signal.';
            polyout.receiver(irx).signal(3).V     = [];
            polyout.receiver(irx).signal(4).V     = [];
            %polyout.receiver(irx).SampleFrequency = fdata.header.fS;
            polyout.receiver(irx).signal(2).t     = (0:length(tmp.receiver(irx).signal)-1)/fdata.header.fS;     % time [s]
        end
    end
    
    switch fdata.header.sequenceID
        case 4
            if ~fdata.UserData(1).looptask==0; tmp.receiver(1).signal = data.recordC1{iq}.sig3;end
            if ~fdata.UserData(2).looptask==0; tmp.receiver(2).signal = data.recordC2{iq}.sig3;end
            if ~fdata.UserData(3).looptask==0; tmp.receiver(3).signal = data.recordC3{iq}.sig3;end
            if ~fdata.UserData(4).looptask==0; tmp.receiver(4).signal = data.recordC4{iq}.sig3;end
            if fdata.header.nrx == 8
                if ~fdata.UserData(5).looptask==0; tmp.receiver(5).signal = data.recordC5{iq}.sig3;end
                if ~fdata.UserData(6).looptask==0; tmp.receiver(6).signal = data.recordC6{iq}.sig3;end
                if ~fdata.UserData(7).looptask==0; tmp.receiver(7).signal = data.recordC7{iq}.sig3;end
                if ~fdata.UserData(8).looptask==0; tmp.receiver(8).signal = data.recordC8{iq}.sig3;end
            end
            
            for irx=1:fdata.header.nrx
                if ~fdata.UserData(irx).looptask==0
                    polyout.receiver(irx).signal(3).V = tmp.receiver(irx).signal.';
                    polyout.receiver(irx).signal(3).t = (0:length(tmp.receiver(irx).signal)-1)/fdata.header.fS;     % time [s]
                end
            end
        case {3,7}
            if ~fdata.UserData(1).looptask==0; tmp.receiver(1).signal = data.recordC1{iq}.sig4;end
            if ~fdata.UserData(2).looptask==0; tmp.receiver(2).signal = data.recordC2{iq}.sig4;end
            if ~fdata.UserData(3).looptask==0; tmp.receiver(3).signal = data.recordC3{iq}.sig4;end
            if ~fdata.UserData(4).looptask==0; tmp.receiver(4).signal = data.recordC4{iq}.sig4;end
            if fdata.header.nrx == 8
                if ~fdata.UserData(5).looptask==0; tmp.receiver(5).signal = data.recordC5{iq}.sig4;end
                if ~fdata.UserData(6).looptask==0; tmp.receiver(6).signal = data.recordC6{iq}.sig4;end
                if ~fdata.UserData(7).looptask==0; tmp.receiver(7).signal = data.recordC7{iq}.sig4;end
                if ~fdata.UserData(8).looptask==0; tmp.receiver(8).signal = data.recordC8{iq}.sig4;end
            end
            
            for irx=1:fdata.header.nrx
                if ~fdata.UserData(irx).looptask==0
                    polyout.receiver(irx).signal(4).V = tmp.receiver(irx).signal.';
                    polyout.receiver(irx).signal(4).t = (0:length(tmp.receiver(irx).signal)-1)/fdata.header.fS;     % time [s]
                end
            end
    end
end

%% REARRANGE FOR MRSmatlab format -----------------------------------------
fdata.Q(nq).q  = data.q1(iq); 
fdata.Q(nq).q2 = data.q2(iq);
fdata.Q(nq).rec(irec).info.fT = fdata.header.fT;         % transmitter frequency
fdata.Q(nq).rec(irec).info.fS = fdata.header.fS/rate;         % sampling frequency
% if fdata.header.sequenceID == 8 % mod RD AHP; NOT USED!!! USE Q instead!
% 	fdata.Q(nq).maxI = data.maxI1(iq);
% end
    
% save pulse shape and make df vector for AHP 
if fdata.info.sequence==8
    tmp.recordI1                   = mrs_filtfilt(b,a,data.recordI1{iq});
%     fdata.Q(nq).rec(irec).tx.I     = tmp.recordI1(100+rate:rate:end-rate-100).'; % 50 arises from filter spike test
    fdata.Q(nq).rec(irec).tx.I     = tmp.recordI1(rate:rate:end-rate).'; % do not clip pulse record
    fdata.Q(nq).rec(irec).tx.t_pulse = (0:length(fdata.Q(nq).rec(irec).tx.I)-1)/(fdata.header.fS/rate);
    startdf = fdata.info.txinfo.Fmod.startdf; % make df-shape
    enddf   = fdata.info.txinfo.Fmod.enddf; 
    shape   = fdata.info.txinfo.Fmod.shape;
    fdata.Q(nq).rec(irec).tx.df = Funfmod(fdata.Q(nq).rec(irec).tx.t_pulse, startdf, enddf, shape); % save df-shape   
end

% timing parameters
fdata.Q(nq).rec(irec).info.timing.tau_p1    = fdata.header.tau_p;
fdata.Q(nq).rec(irec).info.timing.tau_dead1 = deadtime;
fdata.Q(nq).rec(irec).info.timing.tau_d     = fdata.header.tau_d;
fdata.Q(nq).rec(irec).info.timing.tau_e     = fdata.header.te;
fdata.Q(nq).rec(irec).info.timing.tau_p2    = fdata.header.tau_p;
fdata.Q(nq).rec(irec).info.timing.tau_dead2 = deadtime;

% generator phase 
fdata.Q(nq).rec(irec).info.phases.phi_gen(1)   = 0; % rad
fdata.Q(nq).rec(irec).info.phases.phi_gen(2)   = data.q1phase(iq); % rad
fdata.Q(nq).rec(irec).info.phases.phi_gen(3)   = 0;
fdata.Q(nq).rec(irec).info.phases.phi_gen(4)   = 0; % rad

switch fdata.info.sequence
    case 4
        fdata.Q(nq).rec(irec).info.phases.phi_gen(3)   = data.q2phase(iq); % rad
    case 7
        fdata.Q(nq).rec(irec).info.phases.phi_gen(4)   = data.q2phase(iq); % rad
        fdata.Q(nq).rec(irec).info.timing.tau_p2       = 2*fdata.header.tau_p;
end

% amplifier phase 
fdata.Q(nq).rec(irec).info.phases.phi_amp = 0; % rad

% signal phases (same for all receivers)
% time lag between Tx AD and Rx AD is 200us
fdata.Q(nq).rec(irec).info.phases.phi_timing(1:4) = -200e-6*2*pi*fdata.header.fT;

irx = 0;
for ipolyrx  = 1:length(polyout.receiver)
    if ~isempty(polyout.receiver(ipolyrx).signal) % if connected
        irx = irx + 1;
        for isig = 1:length(polyout.receiver(ipolyrx).signal)
            if ~isempty(polyout.receiver(ipolyrx).signal(isig).V) % if recorded
                fdata.Q(nq).rec(irec).rx(irx).sig(isig).recorded = 1;
                fdata.Q(nq).rec(irec).rx(irx).sig(isig).t1 = ...
                    polyout.receiver(ipolyrx).signal(isig).t;
                fdata.Q(nq).rec(irec).rx(irx).sig(isig).v1 = ...
                    polyout.receiver(ipolyrx).signal(isig).V - mean(polyout.receiver(ipolyrx).signal(isig).V);
                % backup for undo:
                fdata.Q(nq).rec(irec).rx(irx).sig(isig).t0 = fdata.Q(nq).rec(irec).rx(irx).sig(isig).t1;
                fdata.Q(nq).rec(irec).rx(irx).sig(isig).v0 = fdata.Q(nq).rec(irec).rx(irx).sig(isig).v1;
            else
                fdata.Q(nq).rec(irec).rx(irx).sig(isig).recorded = 0;
                fdata.Q(nq).rec(irec).rx(irx).sig(isig).v1 = [];
            end
        end
     end
end
%fdata.info.rxtask = zeros(1,irx); % initialize rx task



