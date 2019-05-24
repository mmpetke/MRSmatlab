function LPfilter = mrs_makefilter(passFreq,stopFreq,sampleFreq)
% function coeff = mrs_makefilter(passFreq,stopFreq,sampleFreq)
%
% Create filter coefficients a,b for: V = mrs_filtfilt(b,a,ehv);
% This function is executed only once during initialization of proclog.
% CAN IT BE CHANGED BY THE FILTER SETTINGS IN MRSSIGPROC GUI?
%
% MMP 29sep2011
% mod. 29sep2011 JW
% =========================================================================

% The idee was to avoid signal processing toolbox. 
% If the toolbox is not present the file should be loaded. 
% There is not much used from this toolbox so we can avoid pushing people
% to get it from matlab :-)
% coefficients.mat is also optionally used in writePolyData.m for decimating GMR data

% At some stage when filter properties are completely understood we can even stop calculating
% here and only load from file. I am preaty fine with the parameters below
% and filter settings in mrsSigPro_QD but you never know :-)

if ~exist('buttord')
%if 1
    % get filter coefficient from precalculation
    LPfilter = load('coefficient.mat');
else
    for ipass=1:length(passFreq)
        for istop=1:length(stopFreq)
            for isample=1:length(sampleFreq)
                if stopFreq(istop) > passFreq(ipass)+50
                    if sampleFreq(isample)/2 > stopFreq(istop)
                        
                        % Attenuation parameters
                        Apass       = 1;     % Passband Ripple (dB)
                        Astop       = 50;    % Stopband Attenuation (dB)
                        
                        % Calculate the order from the parameters using BUTTORD.
                        [N,Fc] = buttord(passFreq(ipass)/(sampleFreq(isample)/2),...
                            stopFreq(istop)/(sampleFreq(isample)/2),...
                            Apass, Astop);
                        
                        % Use standard filter that allows for filtfilt
                        [b,a]       = butter(N, Fc);
                        
                        % Write into structure
                        LPfilter.coeff.passFreq(ipass).stopFreq(istop).sampleFreq(isample).a=a;
                        LPfilter.coeff.passFreq(ipass).stopFreq(istop).sampleFreq(isample).b=b;
                        
                       
                    end
                end
            end
        end
    end
    % Just for tracking the filter
    LPfilter.Apass = 1;
    LPfilter.Astop = 50;
    
    % Save the parameter for later search in mrsSigPro_QD
    LPfilter.passFreq = passFreq;
    LPfilter.stopFreq = stopFreq;
    LPfilter.sampleFreq = sampleFreq;   
end
