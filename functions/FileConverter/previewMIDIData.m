function previewGMRData(gui,fdata,fileID)

figure;  

%% read in all files containing single stacks of one pulse moment:
    mrs_setguistatus(gui,1,'prepare preview')
    rec   = fileID;
    data  = openMIDIRawData(fdata, rec); 

%% do processing
    % get filter coefficient from precalculation
    LPfilter = load('coefficient.mat');
    fW       = 500;
    fS       = fdata.header.sampleFreq;
    fT       = fdata.header.frequency;
    
    for nC = 1:fdata.header.connectedchannels % check channel
        if ~fdata.UserData(nC).looptask==0 % check connected
            for nS=1:length(data.q1) % number of either stacks or pulses
                switch nC
                    case 1
                        v(nS,:) = data.recordC1{nS}.sig2;
                    case 2
                        v(nS,:) = data.recordC2{nS}.sig2;
                    case 3
                        v(nS,:) = data.recordC3{nS}.sig2;
                    case 4
                        v(nS,:) = data.recordC4{nS}.sig2;
                    case 5
                        v(nS,:) = data.recordC5{nS}.sig2;
                    case 6
                        v(nS,:) = data.recordC6{nS}.sig2;
                    case 7
                        v(nS,:) = data.recordC7{nS}.sig2;
                    case 8
                        v(nS,:) = data.recordC8{nS}.sig2;
                end
            end
            t = (0:size(v,2)-1)/fS;
            V = sum(v,1)/nS;
            % do QD
            U = mrsSigPro_QD(V,t,fT,fS,fW,LPfilter);
            U(isnan(U)==1)=0;
            % plot
            subplot(fdata.header.connectedchannels,2,2*nC-1) % data
                plot(t,real(U),'b',t,imag(U),'r')
%                 plot(t,V,'b')
                xlim([0 max(t)])
                xlabel('t/s');ylabel('amp/V');title(['channel ' num2str(nC)]);
                %set(gca,'Color',[0 0 0])
            subplot(fdata.header.connectedchannels,2,2*nC) % FFT   
                a = mod(length(U),2); % check for even number of samples for fft
                [freq_range,spec] = mrs_sfft(t(1:end-a),U(1:end-a));
                MinMax = [min(abs(spec(freq_range > -1000 & freq_range < 1000)))...
                          max(abs(spec(freq_range > -1000 & freq_range < 1000)))];
                xl = [-1000 1000];   % xlimits
                plot(freq_range,abs(spec),'r')
                set(gca,'xlim',xl,'yscale','log')
                ylim(MinMax)
                xlabel('f/Hz');ylabel('amp');
        end
    end
    
mrs_setguistatus(gui,0);


