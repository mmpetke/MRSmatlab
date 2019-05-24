%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function fs = writePolyData(data,header,fdata,iq,irec,nq)
%
% save data in NUMISPoly style and return sampling frequency fs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function fs = writePolyData(data,fdata,iq,irec,nq)
dofilter=0;
if dofilter
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
    rate        = (Fs/2)/Fstop; % reduce rate ,i.e., re-samling
    fs          = Fs/rate;
    
    % apply filter first FID
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
    
    % resample first FID
    for irx=1:fdata.header.nrx
        if ~fdata.UserData(irx).looptask==0
            polyout.receiver(irx).signal(2).V     = tmp.receiver(irx).signal(100+rate:rate:end-rate-100); % 50 arises from filter spike test
            polyout.receiver(irx).SampleFrequency = fdata.header.fS/rate;
            polyout.receiver(irx).deadtime        = fdata.header.tau_dead + (100+rate)/Fs;
            nsample.sig2                          = length(polyout.receiver(irx).signal(2).V);
            nsample.dead1                         = polyout.receiver(irx).deadtime*fs; % be aware must be integer
        end
    end
    
    switch fdata.header.sequenceID
        case 4
            % apply filter second FID
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
            
            % resample second FID
            for irx=1:fdata.header.nrx
                if ~fdata.UserData(irx).looptask==0
                    polyout.receiver(irx).signal(3).V     = tmp.receiver(irx).signal(100+rate:rate:end-rate-100);
                    nsample.sig3                          = length(polyout.receiver(irx).signal(3).V);
                    nsample.dead2                         = polyout.receiver(irx).deadtime*fs; % be aware must be integer
                    nsample.pause                         = 10e-3*fs; % 10ms between end of fid1 and second pulse
                end
            end
    end
else
    %do not decimate from 50kHz sampling down to 10kHz to reduce data

    fs          = fdata.header.fS;
    
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
            polyout.receiver(irx).signal(2).V     = tmp.receiver(irx).signal; 
            polyout.receiver(irx).SampleFrequency = fdata.header.fS;
            polyout.receiver(irx).deadtime        = fdata.header.tau_dead;
            nsample.sig2                          = length(polyout.receiver(irx).signal(2).V);
            nsample.dead1                         = polyout.receiver(irx).deadtime*fs; % be aware must be integer
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
                    polyout.receiver(irx).signal(3).V     = tmp.receiver(irx).signal;
                    nsample.sig3                          = length(polyout.receiver(irx).signal(3).V);
                    nsample.dead2                         = polyout.receiver(irx).deadtime*fs; % be aware must be integer
                    nsample.pause                         = 10e-3*fs; % 10ms between end of fid1 and second pulse
                end
            end
    end
end

% transmitter
% be aware transmitter is written in full 50kHz sampling rate
polyout.transmitter.FreqReelReg9833 = fdata.header.fT;

% which channel is transmitting
for irx=1:fdata.header.nrx
    if fdata.UserData(irx).looptask==1
        fdata.looptype = fdata.UserData(irx).looptype;
        fdata.loopsize = fdata.UserData(irx).loopsize;
        fdata.nturns   = fdata.UserData(irx).nturns;
        switch fdata.header.sequenceID
            case 1
                polyout.transmitter.Pulse(1).I = data.pulseI1{iq};
                nsample.pulse1                 = length(polyout.transmitter.Pulse(1).I);
            case {2,4}
                polyout.transmitter.Pulse(1).I = data.pulseI1{iq};
                polyout.transmitter.Pulse(2).I = data.pulse2I1{iq};
                nsample.pulse1                 = length(polyout.transmitter.Pulse(1).I);
                nsample.pulse2                 = length(polyout.transmitter.Pulse(2).I);
        end
        
    end
end


%% BUILDING .Pro DATA
filedir = [fdata.convpath 'converted']; % directory for converted data
myfile  = fopen([filedir filesep 'Q' num2str(nq) '#' num2str(irec) '.Pro'], 'w');

%% Writing header: TConfig, TTimeConfig, TParameter
fwrite(myfile, -1,'int32');
fwrite(myfile, -1,'int32');
fwrite(myfile, -1,'int32');
% TConfig.FLarmorFreq
fwrite(myfile, polyout.transmitter.FreqReelReg9833,'float32');   
% TConfig.c6 
fwrite(myfile, -1,'int32');
% TConfig.c5
fwrite(myfile, -1,'int32');
% TConfig.LoopType 
fwrite(myfile, fdata.looptype,'int32');
% TConfig.LoopSize
fwrite(myfile, fdata.loopsize,'float32');
% TConfig.TurnNumber
fwrite(myfile, fdata.nturns,'int32'); 
% TConfig.c4
fwrite(myfile, -1,'int32');
% TConfig.FlagStackMax
fwrite(myfile, -1,'int32');
% TConfig.c3
fwrite(myfile, -1,'int32');
% TConfig.PulseMoment
fwrite(myfile, length(data.q1),'int32');
% TConfig.SignalRecTime
fwrite(myfile, -1,'int32');
%TConfig.DelayTime 
fwrite(myfile, -1,'int32'); 
% TConfig.PulseDuration
fwrite(myfile, fdata.header.tau_p*1e3,'int32');
switch fdata.header.sequenceID % 1: FID; 2: 90-90; 3:  ; 4: 4phase T1
            case 1
                fwrite(myfile, 0,'int32'); % TConfig.NbPulse         = fread(myfile, 1,'int32') +1; % 0 = 1 pulse; 1 = 2 pulses
            case {2,4}
                fwrite(myfile, 1,'int32');               
end

fwrite(myfile, -1,'int32');%TTimeConfig.TMNoise     = fread(myfile, 1,'int32');
fwrite(myfile, -1,'int32');%TTimeConfig.TDPulse1    = fread(myfile, 1,'int32');
fwrite(myfile, -1,'int32');%TTimeConfig.TMPulse1    = fread(myfile, 1,'int32');
fwrite(myfile, -1,'int32');%TTimeConfig.TDSignal1   = fread(myfile, 1,'int32');
fwrite(myfile, -1,'int32');%TTimeConfig.TMSignal1   = fread(myfile, 1,'int32');
fwrite(myfile, -1,'int32');%TTimeConfig.TDPulse2    = fread(myfile, 1,'int32');
fwrite(myfile, -1,'int32');%TTimeConfig.TMPulse2    = fread(myfile, 1,'int32');
fwrite(myfile, -1,'int32');%TTimeConfig.TDSignal2   = fread(myfile, 1,'int32');
fwrite(myfile, -1,'int32');%TTimeConfig.TMSignal2   = fread(myfile, 1,'int32');
fwrite(myfile, -1,'int32');%TTimeConfig.TDSignal3   = fread(myfile, 1,'int32');
fwrite(myfile, -1,'int32');%TTimeConfig.TMSignal3   = fread(myfile, 1,'int32');
fwrite(myfile, -1,'int32');%TConfig.c0              = fread(myfile, 1,'int32');
fwrite(myfile, -1,'int32');%TConfig.c1              = fread(myfile, 1,'int32');
fwrite(myfile, -1,'int32');%TConfig.c2              = fread(myfile, 1,'int32');
fwrite(myfile, -1,'int32');%TConfig.c8              = fread(myfile, 1,'int32');
fwrite(myfile, -1,'float32');% TConfig.c9              = fread(myfile, 1,'float32');
fwrite(myfile, -1,'int32');%TConfig.c10             = fread(myfile, 1,'int32');
fwrite(myfile, -1,'float32');%TConfig.c11             = fread(myfile, 1,'float32');
fwrite(myfile, -1,'float32');%TConfig.c12             = fread(myfile, 1,'float32');
DirectoryName = [fullfile(fdata.convpath) repmat(' ',1,256-length(fullfile(fdata.convpath)))]; % EXTENDING DIRNAME TO 256 CHARACTERS
for ix = 1:256 % WRITE DIRECTORY NAME, FILL 256 CHARACTERS
    fwrite(myfile, DirectoryName(ix),'char*1'); % TConfig.DirectoryName   = deblank(fread(myfile, 256,'*char')');
end
for ix = 1:512  % WRITE 512 CHARACTERS EMPTY COMMENT
    fwrite(myfile, ' ','char*1'); % TConfig.Comment         = deblank(fread(myfile, 512,'*char')');
end
fwrite(myfile, -1,'int32'); % TConfig.c13             = fread(myfile, 1,'int32');
for ix = 1:7
    fwrite(myfile, -1,'int32');%TConfig.c14             = fread(myfile, 7,'int32');
end
fwrite(myfile, -1,'int32');%TConfig.c15             = fread(myfile, 1,'int32');         % void


% TParameter.KAmpl
fwrite(myfile, data.RXgain,'float32');
%TParameter.x0
fwrite(myfile, -1,'float32');
%TParameter.Noise
fwrite(myfile, -1,'float32');
% TParameter.PhCalib
fwrite(myfile, -1,'int32');
%TParameter.PhSignal 
fwrite(myfile, data.q1phase(iq),'int32');
% TParameter.RangeReel
fwrite(myfile, -1,'float32');
%TParameter.AdcToTension
fwrite(myfile, -1,'float32');
%TParameter.AdcToCurren
fwrite(myfile, -1,'float32');
% TParameter.UAnt
fwrite(myfile, -1,'float32');
% TParameter.Loop_Imped
fwrite(myfile, fdata.header.tuning_C,'float32');
% TParameter.UGen
fwrite(myfile, -1,'float32');
% TParameter.x6
fwrite(myfile, -1,'int32');
% TParameter.StackCorrect
fwrite(myfile, -1,'int32');
% TParameter.x1
fwrite(myfile, -1,'int32');
% TParameter.PulseNumber
fwrite(myfile, nq,'int32'); 
fwrite(myfile, -1,'int32');% TParameter.x2           = fread(myfile, 1,'int32');
fwrite(myfile, -1,'float32');% TParameter.x3           = fread(myfile, 1,'float32');
fwrite(myfile, -1,'float32');% TParameter.Batterie     = fread(myfile, 1,'float32');
for ix = 1:7
    fwrite(myfile, -1,'int32');% TParameter.x4           = fread(myfile, 7,'int32');
end
fwrite(myfile, -1,'int32');% TParameter.x5           = fread(myfile, 1,'int32');         % void




%% Writing receiver information
for irx = 1:fdata.header.nrx    % for each receiver
    if ~fdata.UserData(irx).looptask==0      % connected 
        % again some heading
        fwrite(myfile, 1,'int32'); % blocksize = fread(myfile, 1,'int32');
        fwrite(myfile, -1,'int32');% Receiver(irx).Proton.TProtonVersion = fread(myfile, 1,'int32');
        fwrite(myfile, -1,'int32');% Receiver(irx).Proton.Version        = fread(myfile, 1,'int32');
        fwrite(myfile, fdata.UserData(irx).loopsize,'float32');% Receiver(irx).ProtonLoop.Size       = fread(myfile, 1,'float32');
        fwrite(myfile, fdata.UserData(irx).looptype,'int32');%Receiver(irx).ProtonLoop.Shape      = fread(myfile, 1,'int32');
        fwrite(myfile, fdata.UserData(irx).nturns,'int32');%Receiver(irx).ProtonLoop.NbTurn     = fread(myfile, 1,'int32');
        fwrite(myfile, polyout.transmitter.FreqReelReg9833,'float32');% Receiver(irx).ProtonConfig.FLarmor  = fread(myfile, 1,'float32');
        fwrite(myfile, -1,'float32');% Receiver(irx).ProtonConfig.Gain     = fread(myfile, 1,'float32'); USED?
        
        % ProtonCount Parameter
        % order of counts: Noise Pause0 Syncro1 Pause1 Adjust1 Pulse1 Pause2 Signal1 Pause3 Syncro2 Pause4 Adjust2 Pulse2 Pause5 Signal2 
        fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Noise     = fread(myfile, 1,'int32');
        fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Pause0    = fread(myfile, 1,'int32');
        fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Synchro1  = fread(myfile, 1,'int32');
        fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Pause1    = fread(myfile, 1,'int32');
        fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Adjust1   = fread(myfile, 1,'int32');        
        
        switch fdata.header.sequenceID
            case 1
                fwrite(myfile, nsample.pulse1,'int32');%         Receiver(irx).ProtonCount.Pulse1    = fread(myfile, 1,'int32');
                fwrite(myfile, nsample.dead1,'int32');%         Receiver(irx).ProtonCount.Pause2    = fread(myfile, 1,'int32');
                fwrite(myfile, nsample.sig2,'int32');%         Receiver(irx).ProtonCount.Signal1   = fread(myfile, 1,'int32');
                fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Pause3    = fread(myfile, 1,'int32');
                fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Synchro2  = fread(myfile, 1,'int32');
                fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Pause4    = fread(myfile, 1,'int32');
                fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Adjust2   = fread(myfile, 1,'int32');
                fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Pulse2    = fread(myfile, 1,'int32');
                fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Pause5    = fread(myfile, 1,'int32');
                fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Signal2   = fread(myfile, 1,'int32');
                fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Pause6    = fread(myfile, 1,'int32');
                fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Signal3   = fread(myfile, 1,'int32');
                fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Polarite  = fread(myfile, 1,'int32');
            case 2
                fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Pulse1    = fread(myfile, 1,'int32');
                fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Pause2    = fread(myfile, 1,'int32');
                fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Signal1   = fread(myfile, 1,'int32');
                fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Pause3    = fread(myfile, 1,'int32');
                fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Synchro2  = fread(myfile, 1,'int32');
                fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Pause4    = fread(myfile, 1,'int32');
                fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Adjust2   = fread(myfile, 1,'int32');
                fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Pulse2    = fread(myfile, 1,'int32');
                fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Pause5    = fread(myfile, 1,'int32');
                fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Signal2   = fread(myfile, 1,'int32');
                fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Pause6    = fread(myfile, 1,'int32');
                fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Signal3   = fread(myfile, 1,'int32');
                fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Polarite  = fread(myfile, 1,'int32');
            case 4
                fwrite(myfile, nsample.pulse1,'int32');%         Receiver(irx).ProtonCount.Pulse1    = fread(myfile, 1,'int32');
                fwrite(myfile, nsample.dead1,'int32');%         Receiver(irx).ProtonCount.Pause2    = fread(myfile, 1,'int32');
                fwrite(myfile, nsample.sig2,'int32');%         Receiver(irx).ProtonCount.Signal1   = fread(myfile, 1,'int32');
                fwrite(myfile, nsample.pause,'int32');%         Receiver(irx).ProtonCount.Pause3    = fread(myfile, 1,'int32');
                fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Synchro2  = fread(myfile, 1,'int32');
                fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Pause4    = fread(myfile, 1,'int32');
                fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Adjust2   = fread(myfile, 1,'int32');
                fwrite(myfile, nsample.pulse2,'int32');%         Receiver(irx).ProtonCount.Pulse2    = fread(myfile, 1,'int32');
                fwrite(myfile, nsample.dead2,'int32');%         Receiver(irx).ProtonCount.Pause5    = fread(myfile, 1,'int32');
                fwrite(myfile, nsample.sig3,'int32');%         Receiver(irx).ProtonCount.Signal2   = fread(myfile, 1,'int32');
                fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Pause6    = fread(myfile, 1,'int32');
                fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Signal3   = fread(myfile, 1,'int32');
                fwrite(myfile, -1,'int32');%         Receiver(irx).ProtonCount.Polarite  = fread(myfile, 1,'int32');
        end
        
        
        fwrite(myfile, 1,'int32'); % Receiver(irx).ProtonConfig.SampleRateDivider = fread(myfile, 1,'int32');
        fwrite(myfile, 1,'uint');% Receiver(irx).ProtonConfig.Crc      = fread(myfile, 1,'uint');
        for ix = 1:7
            fwrite(myfile, -1,'float32');  % SKIPPING UNUSED PARAMETERS; TAKE CARE OF PROTONCOUNT PARAMETERS WHEN READING IN DATA
        end        
        fwrite(myfile, -1,'int32'); % Receiver(irx).TRxTxCablePara.length     = fread(myfile, 1,'int32');
        fwrite(myfile, -1,'float32');  % Receiver(irx).TRxTxCablePara.unused     = fread(myfile, 1,'float32');
        fwrite(myfile, -1,'int32'); % Receiver(irx).ProtonMeasPara.RxNum      = fread(myfile, 1,'int32');
        for ix = 1:6
            fwrite(myfile, -1,'float32');  % SKIPPING UNUSED PARAMETERS; TAKE CARE OF PROTONCOUNT PARAMETERS WHEN READING IN DATA
        end
        fwrite(myfile, -1,'int32'); % Receiver(irx).Proton.ParameterSize  = fread(myfile, 1,'int32');
        
        % signals
        % NUMIS saves data as nanoV, mrs_readpoly therefore uses
        % Receiver(irx).Signal(isig).v = sig*1e-9;     % voltage [V]
        % GMR data are Voltages convert to nanoV for saving as numis files
        % a factor of 4 for blocksizes is needed since in mrs_readpoly the blocksize is divided
        % by factor of 4 which is somehow in the orig. poly files :-)
        
        % sig(1): No GMR Noise record
        fwrite(myfile, 0,'int32');% blocksize  = fread(myfile, 1,'int32');
        switch fdata.header.sequenceID
            case 1             
                % sig(2): FID
                blocksize = length(polyout.receiver(irx).signal(2).V)*4;
                fwrite(myfile, blocksize,'int32');% blocksize  = fread(myfile, 1,'int32');
                for ispl = 1:length(polyout.receiver(irx).signal(2).V)
                    fwrite(myfile,polyout.receiver(irx).signal(2).V(ispl)*1e9,'float32'); % sig(1,1:blocksize/4) = fread(myfile,blocksize/4,'float32');
                end
                % no sig 3 (T1)
                fwrite(myfile, 0,'int32');
                % no sig 4 (Echo)
                fwrite(myfile, 0,'int32');
            case 4
                % sig(2): FID
                blocksize = length(polyout.receiver(irx).signal(2).V)*4;
                fwrite(myfile, blocksize,'int32');% blocksize  = fread(myfile, 1,'int32');
                for ispl = 1:length(polyout.receiver(irx).signal(2).V)
                    fwrite(myfile,polyout.receiver(irx).signal(2).V(ispl)*1e9,'float32'); % sig(1,1:blocksize/4) = fread(myfile,blocksize/4,'float32');
                end
                % sig(3): FID 2
                blocksize = length(polyout.receiver(irx).signal(3).V)*4;
                fwrite(myfile, blocksize,'int32');% blocksize  = fread(myfile, 1,'int32');
                for ispl = 1:length(polyout.receiver(irx).signal(3).V) % 
                    fwrite(myfile,polyout.receiver(irx).signal(3).V(ispl)*1e9,'float32'); % sig(1,1:blocksize/4) = fread(myfile,blocksize/4,'float32');
                end
                % no sig 4 (Echo)
                fwrite(myfile, 0,'int32');
        end
        
    else % not connected
        fwrite(myfile, 0,'int32'); 
        fwrite(myfile, -1,'int32');
        fwrite(myfile, -1,'int32');
        fwrite(myfile, -1,'float32');
        fwrite(myfile, -1,'int32');
        fwrite(myfile, -1,'int32');
        fwrite(myfile, -1,'float32');
        fwrite(myfile, -1,'float32');
        for ix = 1:19
            fwrite(myfile, -1,'int32');  
        end
        fwrite(myfile, 1,'uint');
        for ix = 1:7
            fwrite(myfile, -1,'float32'); 
        end       
        fwrite(myfile, -1,'int32'); 
        fwrite(myfile, -1,'float32');  
        fwrite(myfile, -1,'int32'); 
        for ix = 1:6
            fwrite(myfile, -1,'float32'); 
        end
        fwrite(myfile, -1,'int32'); 
        
        fwrite(myfile, 0,'int32');% sig 1
        fwrite(myfile, 0,'int32');% sig 2
        fwrite(myfile, 0,'int32');% sig 3
        fwrite(myfile, 0,'int32');% sig 4
    end
end % irx (receiver)

% Write transmitter information
fwrite(myfile, 1,'int32');% blocksize = fread(myfile, 1,'int32');

fwrite(myfile, polyout.transmitter.FreqReelReg9833,'float32');% Transmitter.FreqReelReg9833                 = fread(myfile, 1,'float32');
for ix = 1:2
    fwrite(myfile, -1,'int32'); % Transmitter.ProtonTx.DcVersion              = fread(myfile, 2,'int32');
end
fwrite(myfile, -1,'float32');% Transmitter.BatterieTemperatureDCDC1.PwrBat = fread(myfile, 1,'float32');
fwrite(myfile, -1,'float32');% Transmitter.BatterieTemperatureDCDC1.Temp   = fread(myfile, 1,'float32');
fwrite(myfile, -1,'int32');% Transmitter.BatterieTemperatureDCDC1.Cmd    = fread(myfile, 1,'int32');
fwrite(myfile, -1,'float32');% Transmitter.BatterieTemperatureDCDC2.PwrBat = fread(myfile, 1,'float32');
fwrite(myfile, -1,'float32');% Transmitter.BatterieTemperatureDCDC2.Temp   = fread(myfile, 1,'float32');
fwrite(myfile, -1,'int32');% Transmitter.BatterieTemperatureDCDC2.Cmd    = fread(myfile, 1,'int32');
fwrite(myfile, -1,'int32');% Transmitter.TxVersionCoeff.VersionHard      = fread(myfile, 1,'int32');
fwrite(myfile, -1,'int32');% Transmitter.TxVersionCoeff.VersionSoft      = fread(myfile, 1,'int32');
fwrite(myfile, -1,'float32');% Transmitter.TxVersionCoeff.V_Coeff          = fread(myfile, 1,'float32');
fwrite(myfile, -1,'float32');% Transmitter.TxVersionCoeff.I_Coeff          = fread(myfile, 1,'float32');
fwrite(myfile, -1,'float32');% Transmitter.MeasValue.V_Ant                 = fread(myfile, 1,'float32');
fwrite(myfile, -1,'float32');% Transmitter.MeasValue.Z_Ant                 = fread(myfile, 1,'float32');
fwrite(myfile, -1,'float32');% Transmitter.MeasValue.RLoop                 = fread(myfile, 1,'float32');
fwrite(myfile, -1,'float32');% Transmitter.MeasValue.TempInd               = fread(myfile, 1,'float32');
fwrite(myfile, -1,'int32');% Transmitter.ProtonTx.ParameterSize          = fread(myfile, 1,'int32');

switch fdata.header.sequenceID
    case 1
        % first puls
        blocksize = length(polyout.transmitter.Pulse(1).I)*4;
        fwrite(myfile, blocksize,'int32');
        for ispl = 1:length(polyout.transmitter.Pulse(1).I)
            fwrite(myfile,polyout.transmitter.Pulse(1).I(ispl),'float32');
        end
        % no second puls
        fwrite(myfile, 0,'int32');
    case 4
        % first puls
        blocksize = length(polyout.transmitter.Pulse(1).I)*4;
        fwrite(myfile, blocksize,'int32');
        for ispl = 1:length(polyout.transmitter.Pulse(1).I)
            fwrite(myfile,polyout.transmitter.Pulse(1).I(ispl),'float32');
        end
        % no second puls
        blocksize = length(polyout.transmitter.Pulse(2).I)*4;
        fwrite(myfile, blocksize,'int32');
        for ispl = 1:length(polyout.transmitter.Pulse(2).I)
            fwrite(myfile,polyout.transmitter.Pulse(2).I(ispl),'float32');
        end
end

fclose(myfile);


