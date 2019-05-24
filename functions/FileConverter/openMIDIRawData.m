%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function rawData = openMIDIRawData(header,rec)
% 
% function to read in MRS-MIDI data, i.e., all records of one pulse moment,
% every single record is stored in an individual file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function rawData = openMIDIRawData(fdata,rec)

for nost = 1:fdata.filenumber(rec)
    %change sorting of pulse moments to ascending order
    rec2 = length(fdata.pulsemoments)-rec+1;
    [data,info]=import_MIDIdata([fdata.header.path fdata.pulsemoments(rec2).fid{nost}],1);
    
    

% %% record properties
% % circuit gain
% F_nmr = fdata.header.frequency;
% C     = fdata.header.capacitance;
% w     = 2*pi*F_nmr;
% L     = 1/(C*w^2);
% Z1    = 0.5 + 1i*0.5*w;
% Z2    = 1/(1i*0.0000016*w);
% Z3    = 1/((1/Z1) + (1/Z2));
% Z4    = 1 + 1i*w*L;
% circuit_gain = abs(Z3/(Z3 + Z4));
% 
% gain  = fdata.header.preampgain*circuit_gain;
rawData.RXgain = 1;
rawData.TXgain = 1;

%read data
    rawData = transferData(data,info,rawData,fdata,nost);

end

function rawData = transferData(data,info,rawData,fdata,nexp)
switch fdata.header.pulsesequence % 1: FID; 2: 90-90; 3:  ; 4: 4phase T1
    case 1
        % second pulse
        rawData.q2(nexp)       = 0;
        rawData.q2phase(nexp)  = 0;
        
        % first pulse
        rawData.timepulse   = info.pulse_length;
        rawData.pulseI1{nexp}  = data.pulse;
        rawData.pulseI2{nexp}  = imag(data.pulse);
        rawData.q1(nexp)       = info.pulse_moment;
        rawData.q1phase(nexp)  = info.pulse_phase;                            

        % first 4 data channels
        if ~fdata.UserData(1).looptask==0; 
            rawData.recordC1{nexp}.sig2 = data.ch1*1e-9;
        end
        if ~fdata.UserData(2).looptask==0; 
            rawData.recordC2{nexp}.sig2 = data.ch2*1e-9;
        end
        if ~fdata.UserData(3).looptask==0; 
            rawData.recordC3{nexp}.sig2 = data.ch3*1e-9;
        end
%         if ~fdata.UserData(4).looptask==0; 
%             rawData.recordC4{nexp}.sig2 = data.ch4;
%         end


%         % second set of 4 data channels
%         if fdata.header.connectedchannels == 8
%             if ~fdata.UserData(5).looptask==0;
%                 rawData.recordC5{nexp}.sig2 = data{10}(FID1_index)./rawData.RXgain;
%             end
%             if ~fdata.UserData(6).looptask==0;
%                 rawData.recordC6{nexp}.sig2 = data{11}(FID1_index)./rawData.RXgain;
%             end
%             if ~fdata.UserData(7).looptask==0;
%                 rawData.recordC7{nexp}.sig2 = data{12}(FID1_index)./rawData.RXgain;
%             end
%             if ~fdata.UserData(8).looptask==0;
%                 rawData.recordC8{nexp}.sig2 = data{13}(FID1_index)./rawData.RXgain;
%             end
%         end
    case 2
       disp('So far, only FID experiments are considered in this software...')
end