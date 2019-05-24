%% create filter coefficients a,b to be used as
% V           = mrs_filtfilt(b,a,ehv);
% 

clear all

passFreq   = [200:50:1000 3000];
stopFreq   = [300:50:3000 5000];
sampleFreq = [10000 50000];

for ipass=1:length(passFreq)
    for istop=1:length(stopFreq)
        for isample=1:length(sampleFreq)
            if stopFreq(istop) > passFreq(ipass)+50
                if sampleFreq(isample)/2 > stopFreq(istop)
                    Apass       = 1;     % Passband Ripple (dB)
                    Astop       = 50;    % Stopband Attenuation (dB)
                    % Calculate the order from the parameters using BUTTORD.
                    [N,Fc] = buttord(passFreq(ipass)/(sampleFreq(isample)/2),...
                        stopFreq(istop)/(sampleFreq(isample)/2),...
                        Apass, Astop);
                    % using standard filter taht allows for filtfilt
                    [b,a]       = butter(N, Fc);
                    
                    % write into structure
                    coeff.passFreq(ipass).stopFreq(istop).sampleFreq(isample).a=a;
                    coeff.passFreq(ipass).stopFreq(istop).sampleFreq(isample).b=b;
                end
            end
        end
    end
end

clear ipass istop isample N Fc a b
save('coefficient.mat')

