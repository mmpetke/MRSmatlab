%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function rawData = openGMRRawData(header,rec)
% 
% function to read in GMR data
% a record (file) is separated into stack/or pulsemoment (depends on measurement scheme)
% for each channel
% calculate pulse moments
% calculate pulse phase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function rawData = openGMRRawData(fdata,rec)

 
switch fdata.header.expUnt
    case 0
        if fdata.header.DAQversion<2.4 % ascii read in
            fid  = fopen([fullfile(fdata.header.path, fdata.header.filename) '_' num2str(rec)]);
            data = textscan(fid,'%n %n %n %n %n %n %n %n %n');
            fclose(fid);
        else % binary reader
            fpath = fdata.header.path;
            fname = [fdata.header.filename '_' num2str(rec) '.lvm'];
            data  = mrs_readgmr_binary(fpath, fname, fdata.header.nrecords);
        end
    case 1
        if fdata.header.DAQversion<2.4 % ascii read in
            fid  = fopen([fullfile(fdata.header.path, fdata.header.filename) '_' num2str(rec)]);
            data = textscan(fid,'%n %n %n %n %n %n %n %n %n %n %n %n %n');
            fclose(fid);
        else
            fpath = fdata.header.path;
            fname = [fdata.header.filename '_' num2str(rec) '.lvm'];
            data  = mrs_readgmr_binary(fpath, fname, fdata.header.nrecords);
        end
end


%% record properties
% circuit gain
% F_nmr = fdata.header.frequency;
% C     = fdata.header.capacitance;
% w     = 2*pi*F_nmr;
% L     = 1/(C*w^2);
% Z1    = 0.5 + 1i*0.5*w;
% Z2    = 1/(1i*0.0000016*w);
% Z3    = 1/((1/Z1) + (1/Z2));
% Z4    = 1 + 1i*w*L;
% circuit_gain = abs(Z3/(Z3 + Z4));

% gain  = fdata.header.preampgain*circuit_gain;
% switch fdata.header.TXversion
%     case 1
%         txgain = 1/150;
%     case {2,3}
%         txgain = 1/180;
% end

rawData.RXgain = fdata.header.gain_V;
rawData.TXgain = 1/fdata.header.gain_I;

% measurement scheme


switch fdata.header.sequenceID % 1: FID; 2: 90-90; 3: single Echo  ; 4: 4phase T1; 7: CPMG; 8: AHP
    case 1
        tprePulse = 50e-3; % fixed time before pulse                
  
        trecord   = 1; % GMR has alway 1s of data for FID
        time      = [0:1/fdata.header.fS:trecord-1/fdata.header.fS]; % time vector for one experiment 
        nex       = length(data{1})/length(time); % total number of experiments (either pulsemoments or stacks)

        % no need for floor but for some reason matlab creates non integer numbers 
        pulse1_index  = floor([(1+tprePulse*fdata.header.fS):1:(1 + (tprePulse+fdata.header.tau_p)*fdata.header.fS)]); % index to extract puls
        pulse2_index  = [];
        
        FID1_index(1) = 4 + find(data{6}(5:length(time))~=0,1); % receiver channel contains zeros before channel is open
        FID1_index    = [FID1_index(1):1:length(time)];
        
        FID2_index    = [];
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
%    case 3 % ! only for test purpose!!!!!!!!!!!!!!!!!!!!!!!!!
%         tprePulse  = 50e-3; % fixed time before pulse
%         Nrfpulses  = floor((1-tprePulse)/fdata.header.te);
%         trecord    = 1;
%         time       = [0:1/fdata.header.fS:trecord-1/fdata.header.fS]; % time vector for one experiment
%         nex        = length(data{1})/length(time); % total number of experiments (either pulsemoments or stacks)
%         fdata.header.te = 0.12;
%         
%         pulse1_index  = floor(tprePulse*fdata.header.fS + ...
%                         [1:1:(fdata.header.tau_p*fdata.header.fS)]); % index to extract puls
%         pulse2_index  = floor((tprePulse + fdata.header.te/2 - fdata.header.tau_p/2)*fdata.header.fS + ...
%                         [1:1:(2*fdata.header.tau_p)*fdata.header.fS]); % index to extract second pulse after time tau
%         
%         % handle the fid
%         FID2_index     = []; 
%         FID1_index(1)  = 4 + find(data{6}(5:length(time))~=0,1); % receiver channel contains zeros before channel is open
%         FID1_index    = [FID1_index(1):1:length(time)]; % echo is recorded until end of experiment  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    case 4
        tprePulse  = 10e-3; % fixed time before pulse
        trecord    = 1 + fdata.header.tau_d; % total time T1 for experiment: 1s plus tau
        time       = [0:1/fdata.header.fS:trecord-1/fdata.header.fS]; % time vector for one experiment 
        nex        = length(data{1})/length(time); % total number of experiments (either pulsemoments or stacks)
        
        pulse1_index  = floor([(1+tprePulse*fdata.header.fS):1:(1 + (tprePulse+fdata.header.tau_p)*fdata.header.fS)]); % index to extract puls
        pulse2_index = fdata.header.tau_d*fdata.header.fS + pulse1_index; % index to extract second pulse after time tau
        
        FID1_index(1)  = 4 + find(data{6}(5:length(time))~=0,1); % receiver channel contains zeros before channel is open
        FID1_index(2)  = pulse2_index(1) - find(flipud(data{6}(FID1_index(1):pulse2_index(1)-1))~=0,1); % receiver channel contains zeros after channel is closed
        FID1_index     = [FID1_index(1):1:FID1_index(2)];
        
        FID2_index(1) = FID1_index(end) + find(data{6}(FID1_index(end)+1:length(time))~=0,1); % receiver channel contains zeros before channel is open
        FID2_index    = [FID2_index(1):1:length(time)]; % second FID is recorded until end of experiment

    case 7
        tprePulse  = 10e-3; % fixed time before pulse
        Nrfpulses  = floor((1-tprePulse)/fdata.header.te);
        trecord    = 1;
        time       = [0:1/fdata.header.fS:trecord-1/fdata.header.fS]; % time vector for one experiment
        nex        = length(data{1})/length(time); % total number of experiments (either pulsemoments or stacks)
        
        pulse1_index  = floor(tprePulse*fdata.header.fS + ...
                        [1:1:(fdata.header.tau_p*fdata.header.fS)]); % index to extract puls
        pulse2_index  = floor((tprePulse + fdata.header.te/2 - fdata.header.tau_p/2)*fdata.header.fS + ...
                        [1:1:(2*fdata.header.tau_p)*fdata.header.fS]); % index to extract second pulse after time tau
        
        % handle the fid 
        FID1_index(1)  = 4 + find(data{6}(5:length(time))~=0,1); % receiver channel contains zeros before channel is open
        FID1_index(2)  = pulse2_index(1) - find(flipud(data{6}(FID1_index(1):pulse2_index(1)-1))~=0,1); % receiver channel contains zeros after channel is closed
        FID1_index     = [FID1_index(1):1:FID1_index(2)];
        
        % handle the echo train as one record
        FID2_index(1) = FID1_index(end) + find(data{6}(FID1_index(end)+1:length(time))~=0,1); % receiver channel contains zeros before channel is open
        FID2_index    = [FID2_index(1):1:length(time)]; % echo is recorded until end of experiment
   
    case 8
        switch fdata.header.DAQversion % check for which DAQ versions and AHP this changed!!!
            case {2.99}
                tprePulse = 10e-3; % fixed time before pulse                   
            otherwise
                msgbox('check tprePulse'); return               
        end
  
        trecord   = 1; % GMR has alway 1s of data for FID
        time      = [0:1/fdata.header.fS:trecord-1/fdata.header.fS]; % time vector for one experiment 
        nex       = length(data{1})/length(time); % total number of experiments (either pulsemoments or stacks)

        % no need for floor but for some reason matlab creates non integer numbers 
        pulse1_index  = floor([(1+tprePulse*fdata.header.fS):1:(1 + (tprePulse+fdata.header.tau_p)*fdata.header.fS)]); % index to extract puls
        pulse2_index  = [];
        
        FID1_index(1) = 4 + find(data{6}(5:length(time))~=0,1); % receiver channel contains zeros before channel is open
        FID1_index    = [FID1_index(1):1:length(time)];
        
        FID2_index    = [];        
    otherwise
        error('unknown pulse sequence')
        msgbox('unknown pulse sequence')
end


%% read data
for nn=1:nex
    rawData = transferData(data,rawData,fdata,pulse1_index + (nn-1)*length(time),time(pulse1_index)-tprePulse,...
                                              pulse2_index + (nn-1)*length(time),time(pulse2_index)-tprePulse,...
                                              FID1_index + (nn-1)*length(time),...
                                              FID2_index + (nn-1)*length(time),nn);
end


function rawData = transferData(data,rawData,fdata,pulse1_index,pulse1_time,pulse2_index,pulse2_time,FID1_index,FID2_index,nexp)                   
switch fdata.header.sequenceID % 1: FID; 2: 90-90; 3:  ; 4: 4phase T1; 7: CPMG; 8:AHP
    case 1
        % second pulse
        rawData.q2(nexp)       = 0;
        rawData.q2phase(nexp)  = 0;
        
        % first pulse
        rawData.timepulse   = pulse1_time;
        rawData.pulseI1{nexp}  = data{2}(pulse1_index);
        rawData.pulseI2{nexp}  = data{3}(pulse1_index);
        % calculate pulse moments and phase of first puls
        ref                 = exp(-1i*2*pi*fdata.header.fT.*rawData.timepulse);
        rawData.q1(nexp)       = 1/rawData.TXgain*(sqrt(mean(rawData.pulseI1{nexp}.^2))*sqrt(2)*fdata.header.tau_p + ...
                                                   sqrt(mean(rawData.pulseI2{nexp}.^2))*sqrt(2)*fdata.header.tau_p)/2;
        rawData.q1phase(nexp)  = median(angle(mrs_hilbert(rawData.pulseI1{nexp}).*ref.'));                            

        % first 4 data channels
        if ~fdata.UserData(1).looptask==0; 
            rawData.recordC1{nexp}.sig2 = data{6}(FID1_index)./rawData.RXgain;
        end
        if ~fdata.UserData(2).looptask==0; 
            rawData.recordC2{nexp}.sig2 = data{7}(FID1_index)./rawData.RXgain;
        end
        if ~fdata.UserData(3).looptask==0; 
            rawData.recordC3{nexp}.sig2 = data{8}(FID1_index)./rawData.RXgain;
        end
        if ~fdata.UserData(4).looptask==0; 
            rawData.recordC4{nexp}.sig2 = data{9}(FID1_index)./rawData.RXgain;
        end
        % second set of 4 data channels
        if fdata.header.expUnt
            if ~fdata.UserData(5).looptask==0;
                rawData.recordC5{nexp}.sig2 = data{10}(FID1_index)./rawData.RXgain;
            end
            if ~fdata.UserData(6).looptask==0;
                rawData.recordC6{nexp}.sig2 = data{11}(FID1_index)./rawData.RXgain;
            end
            if ~fdata.UserData(7).looptask==0;
                rawData.recordC7{nexp}.sig2 = data{12}(FID1_index)./rawData.RXgain;
            end
            if ~fdata.UserData(8).looptask==0;
                rawData.recordC8{nexp}.sig2 = data{13}(FID1_index)./rawData.RXgain;
            end
        end
    case 4
        % second pulse
        rawData.timepulse   = pulse2_time;
        rawData.pulse2I1{nexp}  = data{2}(pulse2_index);
        rawData.pulse2I2{nexp}  = data{3}(pulse2_index);
        % calculate pulse moments and phase of second puls
        ref                    = exp(-1i*2*pi*fdata.header.fT.*rawData.timepulse);
        rawData.q2(nexp)       = 1/rawData.TXgain*(sqrt(mean(rawData.pulse2I1{nexp}.^2))*sqrt(2)*fdata.header.tau_p + ...
                                                   sqrt(mean(rawData.pulse2I2{nexp}.^2))*sqrt(2)*fdata.header.tau_p)/2;
        rawData.q2phase(nexp)  = median(angle(mrs_hilbert(rawData.pulse2I1{nexp}).*ref.'));  
        
        % first pulse
        rawData.timepulse   = pulse1_time;
        rawData.pulseI1{nexp}  = data{2}(pulse1_index);
        rawData.pulseI2{nexp}  = data{3}(pulse1_index);
        % calculate pulse moments and phase of first puls
        ref                    = exp(-1i*2*pi*fdata.header.fT.*rawData.timepulse);
        rawData.q1(nexp)       = 1/rawData.TXgain*(sqrt(mean(rawData.pulseI1{nexp}.^2))*sqrt(2)*fdata.header.tau_p + ...
                                                   sqrt(mean(rawData.pulseI2{nexp}.^2))*sqrt(2)*fdata.header.tau_p)/2;
        rawData.q1phase(nexp)  = median(angle(mrs_hilbert(rawData.pulseI1{nexp}).*ref.'));                            

        % first 4 data channels
        if ~fdata.UserData(1).looptask==0; 
            rawData.recordC1{nexp}.sig2 = data{6}(FID1_index)./rawData.RXgain;
            rawData.recordC1{nexp}.sig3 = data{6}(FID2_index)./rawData.RXgain;
        end
        if ~fdata.UserData(2).looptask==0; 
            rawData.recordC2{nexp}.sig2 = data{7}(FID1_index)./rawData.RXgain;
            rawData.recordC2{nexp}.sig3 = data{7}(FID2_index)./rawData.RXgain;
        end
        if ~fdata.UserData(3).looptask==0; 
            rawData.recordC3{nexp}.sig2 = data{8}(FID1_index)./rawData.RXgain;
            rawData.recordC3{nexp}.sig3 = data{8}(FID2_index)./rawData.RXgain;
        end
        if ~fdata.UserData(4).looptask==0; 
            rawData.recordC4{nexp}.sig2 = data{9}(FID1_index)./rawData.RXgain;
            rawData.recordC4{nexp}.sig3 = data{9}(FID2_index)./rawData.RXgain;
        end
        % second set of 4 data channels
        if fdata.header.expUnt
            if ~fdata.UserData(5).looptask==0;
                rawData.recordC5{nexp}.sig2 = data{10}(FID1_index)./rawData.RXgain;
                rawData.recordC5{nexp}.sig3 = data{10}(FID2_index)./rawData.RXgain;
            end
            if ~fdata.UserData(6).looptask==0;
                rawData.recordC6{nexp}.sig2 = data{11}(FID1_index)./rawData.RXgain;
                rawData.recordC6{nexp}.sig3 = data{11}(FID2_index)./rawData.RXgain;
            end
            if ~fdata.UserData(7).looptask==0;
                rawData.recordC7{nexp}.sig2 = data{12}(FID1_index)./rawData.RXgain;
                rawData.recordC7{nexp}.sig3 = data{12}(FID2_index)./rawData.RXgain;
            end
            if ~fdata.UserData(8).looptask==0;
                rawData.recordC8{nexp}.sig2 = data{13}(FID1_index)./rawData.RXgain;
                rawData.recordC8{nexp}.sig3 = data{13}(FID2_index)./rawData.RXgain;
            end
        end
    case {3,7}
        % first pulse
        rawData.timepulse      = pulse1_time;
        rawData.pulseI1{nexp}  = data{2}(pulse1_index);
        rawData.pulseI2{nexp}  = data{3}(pulse1_index);
        % calculate pulse moments and phase of first puls
        ref                    = exp(-1i*2*pi*fdata.header.fT.*rawData.timepulse);
        rawData.q1(nexp)       = 1/rawData.TXgain*(sqrt(mean(rawData.pulseI1{nexp}.^2))*sqrt(2)*fdata.header.tau_p + ...
                                                   sqrt(mean(rawData.pulseI2{nexp}.^2))*sqrt(2)*fdata.header.tau_p)/2;
        rawData.q1phase(nexp)  = median(angle(mrs_hilbert(rawData.pulseI1{nexp}).*ref.')); 
        
        % second pulse
        rawData.timepulse       = pulse2_time;
        rawData.pulse2I1{nexp}  = data{2}(pulse2_index);
        rawData.pulse2I2{nexp}  = data{3}(pulse2_index);
        % calculate pulse moments and phase of second puls
        ref                    = exp(-1i*2*pi*fdata.header.fT.*rawData.timepulse);
        rawData.q2(nexp)       = 1/rawData.TXgain*(sqrt(mean(rawData.pulse2I1{nexp}.^2))*sqrt(2)*2*fdata.header.tau_p + ...
                                                   sqrt(mean(rawData.pulse2I2{nexp}.^2))*sqrt(2)*2*fdata.header.tau_p)/2;
        rawData.q2phase(nexp)  = median(angle(mrs_hilbert(rawData.pulse2I1{nexp}).*ref.'));                                   

        % first 4 data channels
        if ~fdata.UserData(1).looptask==0; 
            rawData.recordC1{nexp}.sig2 = data{6}(FID1_index)./rawData.RXgain;
            rawData.recordC1{nexp}.sig4 = data{6}(FID2_index)./rawData.RXgain;
        end
        if ~fdata.UserData(2).looptask==0; 
            rawData.recordC2{nexp}.sig2 = data{7}(FID1_index)./rawData.RXgain;
            rawData.recordC2{nexp}.sig4 = data{7}(FID2_index)./rawData.RXgain;
        end
        if ~fdata.UserData(3).looptask==0; 
            rawData.recordC3{nexp}.sig2 = data{8}(FID1_index)./rawData.RXgain;
            rawData.recordC3{nexp}.sig4 = data{8}(FID2_index)./rawData.RXgain;
        end
        if ~fdata.UserData(4).looptask==0; 
            rawData.recordC4{nexp}.sig2 = data{9}(FID1_index)./rawData.RXgain;
            rawData.recordC4{nexp}.sig4 = data{9}(FID2_index)./rawData.RXgain;
        end
        % second set of 4 data channels
        if fdata.header.expUnt
            if ~fdata.UserData(5).looptask==0;
                rawData.recordC5{nexp}.sig2 = data{10}(FID1_index)./rawData.RXgain;
                rawData.recordC5{nexp}.sig4 = data{10}(FID2_index)./rawData.RXgain;
            end
            if ~fdata.UserData(6).looptask==0;
                rawData.recordC6{nexp}.sig2 = data{11}(FID1_index)./rawData.RXgain;
                rawData.recordC6{nexp}.sig4 = data{11}(FID2_index)./rawData.RXgain;
            end
            if ~fdata.UserData(7).looptask==0;
                rawData.recordC7{nexp}.sig2 = data{12}(FID1_index)./rawData.RXgain;
                rawData.recordC7{nexp}.sig4 = data{12}(FID2_index)./rawData.RXgain;
            end
            if ~fdata.UserData(8).looptask==0;
                rawData.recordC8{nexp}.sig2 = data{13}(FID1_index)./rawData.RXgain;
                rawData.recordC8{nexp}.sig4 = data{13}(FID2_index)./rawData.RXgain;
            end
        end
    case 8 % adiabatic half-passage (AHP)
        % second pulse
        rawData.q2(nexp)       = 0;
        rawData.q2phase(nexp)  = 0;
        
%         pulse1_index = pulse1_index+50;
        
        % first pulse
        rawData.timepulse       = pulse1_time;
        rawData.pulseI1{nexp}   = data{2}(pulse1_index);
        rawData.pulseI2{nexp}   = data{3}(pulse1_index);

        % estimate Hilbert of pulse
        
        % extend record of pulse by 1ms to avoid artifacts 
        N_long = 50; % 50 = 1ms 
        % make long index
        pulse1_index_long = [min(pulse1_index)-N_long:1:max(pulse1_index)+N_long];
        % make new time vector
%         dt                  = pulse1_time(2)-pulse1_time(1);
%         rawData.timepulse   = 0:dt:(length(pulse1_index)+N_long)*dt;
        
        % save current envelop and clip ends
        temp_I1a = mrs_hilbert(data{2}(pulse1_index_long));
        I1a = temp_I1a(N_long+1:end-N_long); % clip to original pulse length
        temp_I1b = mrs_hilbert(data{3}(pulse1_index_long));  
        I1b = temp_I1b(N_long+1:end-N_long); % clip to original pulse length  
        
        rawData.recordI1{nexp}      = (abs(I1a)+abs(I1b))./2./rawData.TXgain; % currently used in kernel calculation    
        
        if 0
        figure(10)
        clf
        plot(pulse1_time, rawData.pulseI1{nexp},'g-'); hold on
        plot(rawData.timepulse, abs(I1a),'r-'); hold on     
        plot(rawData.timepulse, abs(I1b),'b-'); hold on  
        plot(rawData.timepulse, abs(rawData.recordI1{nexp}),'k-'); hold on            
        end

        % save max current instead of pm, Use average over last 5ms i.e. 250 samples
        rawData.maxI1(nexp)    = mean(rawData.recordI1{nexp}(end-250:end)); 
        rawData.q1(nexp)       = rawData.maxI1(nexp); % not TRUE!! only used for convenient processing/sorting!!!

        
        % calculate pulse moments and phase of first puls
         ref                    = exp(-1i*2*pi*fdata.header.fT.*rawData.timepulse);
%         rawData.q1(nexp)       = 1/rawData.TXgain*(sqrt(mean(rawData.pulseI1{nexp}.^2))*sqrt(2)*fdata.header.tau_p + ...
%                                                    sqrt(mean(rawData.pulseI2{nexp}.^2))*sqrt(2)*fdata.header.tau_p)/2;
         rawData.q1phase(nexp)  = median(angle(I1a(end-50:end).*ref(end-50:end).'));       % estimate the phase for the last 50 point (1ms)
         
            
        % first 4 data channels
        if ~fdata.UserData(1).looptask==0; 
            rawData.recordC1{nexp}.sig2 = data{6}(FID1_index)./rawData.RXgain;
        end
        if ~fdata.UserData(2).looptask==0; 
            rawData.recordC2{nexp}.sig2 = data{7}(FID1_index)./rawData.RXgain;
        end
        if ~fdata.UserData(3).looptask==0; 
            rawData.recordC3{nexp}.sig2 = data{8}(FID1_index)./rawData.RXgain;
        end
        if ~fdata.UserData(4).looptask==0; 
            rawData.recordC4{nexp}.sig2 = data{9}(FID1_index)./rawData.RXgain;
        end
        % second set of 4 data channels
        if fdata.header.expUnt
            if ~fdata.UserData(5).looptask==0;
                rawData.recordC5{nexp}.sig2 = data{10}(FID1_index)./rawData.RXgain;
            end
            if ~fdata.UserData(6).looptask==0;
                rawData.recordC6{nexp}.sig2 = data{11}(FID1_index)./rawData.RXgain;
            end
            if ~fdata.UserData(7).looptask==0;
                rawData.recordC7{nexp}.sig2 = data{12}(FID1_index)./rawData.RXgain;
            end
            if ~fdata.UserData(8).looptask==0;
                rawData.recordC8{nexp}.sig2 = data{13}(FID1_index)./rawData.RXgain;
            end
        end        
        
end