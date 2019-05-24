function data = mrs_load_gmrraw(sounding_path, singlefile)
% function data = mrs_load_gmrraw(sounding_path)
% 
% UNDER CONSTRUCTION - DEBUGGING REQUIRED
% Load GMR sounding data (load multiple raw data files in one folder).
%
% Input:
%   sounding_path - path to files
%                      (e.g. 'c:\Users\GMR_mar2010\100m_T1_150ms\')
%   singlefile    - optional: if passed, then only the one passed file is 
%                   read (e.g. 'ch1_sig_c50m_ch2_ref_c10m_4.lvm')
% Output: 
%  data (MRSmatlab structure)
%
% Jan Walbrecker, 7 Jun 2011
% JW 14may2012
% =========================================================================


%% CHECK INPUT ------------------------------------------------------------

% read all files if singlefile is not passed
if nargin < 2
    singlefile = [];
    read_singlefile = 0;
else
    read_singlefile = 1;
end

% get path to sounding from ui if not passed
if nargin < 1   
    sounding_path = 'c:\Users\Jan\Documents\su\matlab\nmr\data\test_gmr_binary_4pcT1\';
end

% aborting if called with 0 input
if sounding_path == 0   
    data = 0;
    return
end

%% GET SOUNDING PATH ------------------------------------------------------

data.info.path   = sounding_path;
data.info.device = 'GMR';

disp('UNDER CONSTRUCTION - DEBUGGING REQUIRED')

%% READ HEADER FILE -------------------------------------------------------

% locate header file
if read_singlefile
   idash = find(singlefile == '_', 1, 'last');
   hfile = singlefile(1:idash-1); 
else 
    hfile = uigetfile([sounding_path '*'],'Select the GMR header file');
    if hfile == 0   % aborting if uigetfile was cancelled
        data = 0;
        return
    end
end

% read header file
header = mrs_read_gmrheader([sounding_path hfile]);

%% REQUEST MISSING SURVEY INFORMATION -------------------------------------

% check if information has been entered previously
chk = exist([sounding_path 'GMRuserinfo.mrs'],'file');
if chk ~= 2
    mrs_request_gmruserinfo(sounding_path, hfile);
end
uival = mrs_read_gmruserinfo([sounding_path 'GMRuserinfo.mrs']);

% retrieve missing parameters
fS                         = uival{2};          % [from header] 
tnoise                     = uival{3}*1e-3;     % noise recording (prepulse delay)
tdead                      = uival{4}*1e-3;     % dead time
gain_I                     = uival{5};          % [from header]
gain_V                     = uival{6};          % [from header]
chtask                     = uival{10};         % channel task (MRSmatlab format)
iTX                        = find(uival{11}==1);
data.info.txinfo.channel   = iTX;
data.info.txinfo.looptype  = uival{7}(iTX);
data.info.txinfo.loopsize  = uival{8}(iTX);
data.info.txinfo.loopturns = uival{9}(iTX);

%% ASSEMBLE TIMING PARAMETERS

switch header.sequenceID    % switch sequenceID
    
    case 1 % FID
        
        % durations
        tau(1) = tnoise;            % noise before pulse (meaningless)
        tau(2) = header.tau_p;      % pulse duration 
        tau(3) = tdead;             % dead time
        tau(4) = 1-sum(tau(1:3));   % FID recording
        
        % indices
        it(1) = tau(1) * fS;        % start of pulse
        it(2) = sum(tau(1:2)) * fS; % end of pulse
        it(3) = sum(tau(1:3)) * fS; % start of FID
        it(4) = sum(tau(1:4)) * fS; % end of FID
        
    case 2 % 90-90 T1
        
        % durations 
        tau(1) = tnoise;             % noise before pulse (meaningless)
        tau(2) = header.tau_p;       % duration pulse 1
        tau(3) = tdead;              % dead time
        tau(4) = header.tau_d - sum(tau(1:3));    % fid1 recording
        tau(5:8) = tau(1:4);        % repeat for fid2

        % indices
        it(1) = tau(1) * fS;            % start of pulse 1
        it(2) = sum(tau(1:2)) * fS;     % end of pulse 1
        it(3) = sum(tau(1:3)) * fS;     % start of fid 1
        it(4) = sum(tau(1:4)) * fS;     % end of fid 1
        it(5:8) = it(1:4) + sum(tau(1:4))*fS;   % second pulse block
        
    case 4 % 4pc T1
 
        % durations
        tau(1) = tnoise;            % noise before pulse; 10ms for GMR sequence 4 (Elliot, 10jun2011)
        tau(2) = header.tau_p;      % pulse duration 
        tau(3) = tdead;             % dead time
        tau(4) = header.tau_d - sum(tau(1:3));    % FID1 recording
        tau(5) = tnoise;            % noise before 2nd pulse; 10ms for GMR sequence 4 (Elliot, 10jun2011)
        tau(6) = header.tau_p;      % pulse duration (tp1=tp2)
        tau(7) = tdead;             % dead time
        tau(8) = 1-sum(tau(5:7));   % FID2 recording
        
        % indices
        it(1) = tau(1) * fS;        % start of pulse1
        it(2) = sum(tau(1:2)) * fS; % end of pulse1
        it(3) = sum(tau(1:3)) * fS; % start of FID1
        it(4) = sum(tau(1:4)) * fS; % end of FID1
        it(5) = sum(tau(1:5)) * fS; % start of pulse2
        it(6) = sum(tau(1:6)) * fS; % end of pulse2
        it(7) = sum(tau(1:7)) * fS; % start of FID2
        it(8) = sum(tau(1:8)) * fS; % end of FID2
        
    otherwise 
        error('UNKNOWN GMR PULSE SEQUENCE')
end

%% COLLECT TX, RX AND REF CHANNELS

irx = 0;            % receiver index
for iCh = 1:length(chtask)
    switch chtask(iCh)
        case {0}      % not connected > skip
        case {1,2,3}  % TX/RX, RX, or REF
            irx = irx + 1;
            data.info.rxinfo(irx).channel = iCh;
            data.info.rxinfo(irx).task    = chtask(iCh);
    end
end

%% PREPARE READ -----------------------------------------------------------

% GMR data files start with name of headerfile, followed by underscore
switch read_singlefile
    case 0
        afiles = dir([sounding_path,hfile,'_*']);   
    case 1
        afiles.name = singlefile;
end

% drop files that are not recordings (e.g., *_bad_idx.mat)
dropfile = zeros(1,length(afiles));
for irec = 1:length(afiles)
    if isnan(str2double(afiles(irec).name(length(hfile)+2))) % underscore is not followed by a number
        dropfile(irec) = 1;
    else
        dropfile(irec) = 0;
    end
end
afiles(dropfile == 1) = [];

% determine # pulse moments and # recordings
switch header.q_sampling
    case 0
        nrec = length(afiles);     % # recordings
        nQ   = header.nrecords;    % # pulse moments
    case 1
        nrec = header.nrecords;
        nQ   = length(afiles);
end

% sort filenames
recN = zeros(1,nrec);
for irec = 1:nrec
%     idx = strfind(afiles(irec).name,hfile)    
    recN(irec) = str2double(afiles(irec).name(length(hfile)+2:end));  % get ID: number after underscore
end
[dummy,recID] = sort(recN);
afiles        = afiles(recID); % now indices irec correspond to file ID

% determine format of datafiles
switch header.GMRversion
    case 1.00
%         ncol = 5; % # columns in data file - DETERMINED BY EXPANSION UNIT?
        ncol = 9; % # columns in data file - DETERMINED BY EXPANSION UNIT?
        disp('Check # columns in data file! Used to be 5 for GMRversion 1')
    otherwise
        ncol = 9; % # columns in data file
end
dform  = repmat('%f ',1,ncol);  % data file format

%% READ DATA FILES --------------------------------------------------------

% read data into gmrout structure
gmrout = struct([]);
switch header.q_sampling
    case 0  % auto-q
        for irec = 1:nrec
            for iQ = 1:nQ 
                data.Q(iQ).rec(irec).info.file = afiles(irec).name; % filenames of all q's are the same (all q's are in one file for GMR)
            end
            if header.GMRversion < 2.5  % use ascii reader
                fid          = fopen([data.info.path, data.Q(1).rec(irec).info.file], 'r'); 
                disp(['reading file: ', [data.info.path, data.Q(1).rec(irec).info.file]])
                gmrout{irec} = textscan(fid,dform);
                fclose(fid);
            else    % use binary reader
                gmrout{irec} = mrs_readgmr_binary(data.info.path, data.Q(1).rec(irec).info.file, nQ);
            end
        end
    case 1  % custom-q
        for iQ = 1:nQ 
            for irec = 1:nrec
                data.Q(iQ).rec(irec).info.file = afiles(iQ).name; % filenames of all rec's are the same (all rec's for 1 q are in one file)
            end
            error('CUSTOM-Q NOT YET IMPLEMENTED')
%             fid        = fopen([data.info.path, data.Q(iQ).rec(1).info.file], 'r'); 
%             gmrout{iQ} = textscan(fid,dform);   % CHANGE HERE!
%             fclose(fid);
        end
end


%% ASSEMBLE MRSMATLAB STRUCTURE (fdata) -----------------------------------

% [FC_a,FC_b,FC_rate] = make_filter(fS); % FILTER IN MRSSIGPRO
% inifile = mrs_readinifile;
% LPfilter = mrs_makefilter(...
%             inifile.MRSData.filter_passFreq, ...
%             inifile.MRSData.filter_stopFreq, ...
%             inifile.MRSData.filter_sampleFreq); 

switch header.sequenceID    % switch sequenceID
    
    %% READ FID
    case 1
        for irec = 1:nrec
            % for checkplot
            ifig = figure;
            plot(gmrout{irec}{1},gmrout{irec}{3},'Color',[0.7 0.7 0.7])
            title(data.Q(1).rec(irec).info.file, 'Interpreter', 'None')
            for iQ = 1:nQ
                
                % Get transmitter current
                ip1  = round(1+it(1)+(iQ-1)*sum(tau)*fS:it(2)+(iQ-1)*sum(tau)*fS);     % samples pulse1 (rounding off numerical effects)
                t1   = gmrout{irec}{1}(ip1) - gmrout{irec}{1}(ip1(1));
                I1  = gain_I*gmrout{irec}{3}(ip1);  % toss column 2 - col2&3 are not in- and out-of-phase, but have some random phase correlation; col2 contains 2*envelope for GMRversion 0
%                 I1   = gain_I/sqrt(2)*(gmrout{irec}{2}(ip1) + 1i*gmrout{irec}{3}(ip1));                 
                
                % determine q value
                switch header.GMRversion
                    case 0.00
%                         q1   = gain_I*tau(2) * sqrt(2*mean((gmrout{irec}{3}(ip1)).^2)); % pulse 1 current envelope
                        q1   = gain_I*tau(2) * mean(gmrout{irec}{2}(ip1)) / 2; % pulse 1 current envelope
                    otherwise
                        q1   = gain_I*tau(2)/sqrt(2) * (sqrt(mean((gmrout{irec}{2}(ip1)).^2))+sqrt(mean((gmrout{irec}{3}(ip1)).^2))); % pulse 1 current envelope
                end
                data.Q(iQ).q  = q1; % value of pulse moment   [A.s]
%                 data.Q(iQ).q2 = -1; % value of pulse moment 2 [A.s]

                % determine phase
                ref        = exp(-1i*2*pi*header.fT * t1);
                phi_gen1 = median(angle(mrs_hilbert(I1).*ref));

                % Signal indices
                ifid1 = round(1+it(3)+(iQ-1)*sum(tau)*fS:it(4)+(iQ-1)*sum(tau)*fS);
                checkplot_fid(gmrout,iQ,irec,tau,it,fS,ifig)

                data.Q(iQ).rec(irec).info.fT = header.fT; % transmitter frequency
                data.Q(iQ).rec(irec).info.fS = fS;        % sampling frequency - reset after downsampling
                
                % collect timing parameters
                data.Q(iQ).rec(irec).info.timing.tau_p1 = tau(2);       % duration of pulse1
                data.Q(iQ).rec(irec).info.timing.tau_dead1 = tau(3);    % time between end of pulse1 and start of sig1
%                 data.Q(iQ).rec(irec).info.timing.tau_d = sum(tau(3:5)); % delay time between end of pulse1 and start of pulse2
%                 data.Q(iQ).rec(irec).info.timing.tau_p2 = tau(6);       % duration of pulse2
%                 data.Q(iQ).rec(irec).info.timing.tau_dead2 = tau(7);    % time between end of pulse2 and start of sig2

                % generator phase
                data.Q(iQ).rec(irec).info.phases.phi_gen([1 3 4]) = 0; % rad
                data.Q(iQ).rec(irec).info.phases.phi_gen(2)       = phi_gen1; % rad
                
%                 if mod(iQ,2) + mod(irec,2) == 1 % (irec even & iq odd) OR (irec odd & iq even)
%                     data.Q(iQ).rec(irec).info.phases.phi_gen = pi; % rad
%                 else % irec & iQ are both even or both odd
%                     data.Q(iQ).rec(irec).info.phases.phi_gen = 0; % rad
%                 end

                % amplifier phase (PROBABLY VARIES WITH RX CHANNEL)
                data.Q(iQ).rec(irec).info.phases.phi_amp = 0; % rad

                % signal phases(noise, fid1, fid2, echo)
                data.Q(iQ).rec(irec).info.phases.phi_timing(1:4) = 0;
                
                % assembling transmitter data
                data.Q(iQ).rec(irec).tx.t1 = t1;
                data.Q(iQ).rec(irec).tx.I1 = I1;
%                     data.Q(iQ).rec(irec).tx.t2 = polyout.transmitter.Pulse(2).t;
%                     data.Q(iQ).rec(irec).tx.I2 = polyout.transmitter.Pulse(2).I;
                
                % receiver 
                irx = 0;
                for iGMRrx  = 1:length(data.info.rxinfo)     % for all signal & reference channels
                    irx = irx + 1;

                    % Signal1 - not recorded by GMR
                    data.Q(iQ).rec(irec).rx(irx).sig(1).recorded = 0;
                    
                    % Signal2 - FID
                    data.Q(iQ).rec(irec).rx(irx).sig(2).recorded = 1;
%                     [T,V,FS] = filter_gmrrawdata((ifid1-ifid1(1))/fS,gmrout{irec}{iGMRrx+5}(ifid1)*gain_V,fS,FC_a,FC_b,FC_rate);
                    T        = gmrout{irec}{1}(ifid1) - gmrout{irec}{1}(ifid1(1));
                    V        = gmrout{irec}{iGMRrx+5}(ifid1)/gain_V;
                    FS       = fS;
                    data.Q(iQ).rec(irec).rx(irx).sig(2).t1 = reshape(T,1,numel(T));
                    data.Q(iQ).rec(irec).rx(irx).sig(2).v1 = reshape(V,1,numel(V)); % - mean() ?
                    data.Q(iQ).rec(irec).rx(irx).sig(2).t0 = data.Q(iQ).rec(irec).rx(irx).sig(2).t1; % backup for undo:
                    data.Q(iQ).rec(irec).rx(irx).sig(2).v0 = data.Q(iQ).rec(irec).rx(irx).sig(2).v1; 
                    
                    % Signal3 - fid2 not recorded in this scheme (FID)
                    data.Q(iQ).rec(irec).rx(irx).sig(3).recorded = 0;
                    data.Q(iQ).rec(irec).rx(irx).sig(3).v1 = []; % necessary?
                    
                    % Signal4 - echo not recorded in this scheme (FID)
                    data.Q(iQ).rec(irec).rx(irx).sig(4).recorded = 0;
                    data.Q(iQ).rec(irec).rx(irx).sig(4).v1 = []; % necessary?
                end
                data.Q(iQ).rec(irec).info.fS = FS;  % set to reduced sample frequency 
            end
        end
        
    %% READ 90-90 T1
    case 2          % 90-90 T1
        for irec = 1:nrec
            for iQ = 1:nQ
                
                disp('JW: NOT READY YET; ASSEMBLE TX DATA!')
                disp('No longer supported by Vista Clara')

                % determine q value
                ip1 = round(it(1)+(iQ-1)*sum(tau)*fS:it(2)+(iQ-1)*sum(tau)*fS);     % samples pulse1 (rounding off numerical effects)
                ip2 = round(it(5)+(iQ-1)*sum(tau)*fS:it(6)+(iQ-1)*sum(tau)*fS);     % samples pulse2 (rounding off numerical effects)
                q1  = gain_I*tau(2)/sqrt(2) * (sqrt(mean((gmrout{irec}{2}(ip1)).^2))+sqrt(mean((gmrout{irec}{3}(ip1)).^2))); % pulse 1 current envelope
                q2  = gain_I*tau(6)/sqrt(2) * (sqrt(mean((gmrout{irec}{2}(ip2)).^2))+sqrt(mean((gmrout{irec}{3}(ip2)).^2))); % pulse 2 current envelope
                data.Q(iQ).q  = q1; % value of pulse moment   [A.s]
                data.Q(iQ).q2 = q2; % value of pulse moment 2 [A.s]
                
                % Signal indices
                ifid1 = round(it(3)+(iQ-1)*sum(tau)*fS:it(4)+(iQ-1)*sum(tau)*fS);
                ifid2 = round(it(7)+(iQ-1)*sum(tau)*fS:it(8)+(iQ-1)*sum(tau)*fS);

%                 checkplot(gmrout,iQ,tau,fS,it,gain_I)

                data.Q(iQ).rec(irec).info.fT = fT;   % transmitter frequency
                data.Q(iQ).rec(irec).info.fS = fS;   % sampling frequency - resetted later after downsampling
                
                % collect timing parameters
                data.Q(iQ).rec(irec).info.timing.tau_p1 = tau(2);       % duration of pulse1
                data.Q(iQ).rec(irec).info.timing.tau_dead1 = tau(3);    % time between end of pulse1 and start of sig1
                data.Q(iQ).rec(irec).info.timing.tau_d = sum(tau(3:5)); % delay time between end of pulse1 and start of pulse2
                data.Q(iQ).rec(irec).info.timing.tau_p2 = tau(6);       % duration of pulse2
                data.Q(iQ).rec(irec).info.timing.tau_dead2 = tau(7);    % time between end of pulse2 and start of sig2

                % generator phase 
                data.Q(iQ).rec(irec).info.phases.phi_gen(1:4) = 0; % rad

                % amplifier phase (PROBABLY VARIES WITH RX CHANNEL)
                data.Q(iQ).rec(irec).info.phases.phi_amp = 0; % rad

                % signal phases(noise, fid1, fid2, echo)
                data.Q(iQ).rec(irec).info.phases.phi_timing(1:4) = 0;
                
                irx = 0;
                for iGMRrx  = 1:nrx     % for all channels
                    if ismember(data.info.rxinfo(iGMRrx).task,[1 2]) % if signal or reference channel
                        irx = irx + 1;
%                         data.Q(iQ).rec(irec).rx(irx).connected = 1;

                        % assemble sig1-4
                        data.Q(iQ).rec(irec).rx(irx).sig(1).recorded = 0;   % not recorded by GMR

                        data.Q(iQ).rec(irec).rx(irx).sig(2).recorded = 1;   % FID1 always recorded
                        [T,V,FS] = filter_gmrrawdata((ifid1-ifid1(1))/fS,gmrout{irec}{iGMRrx+5}(ifid1)*gain_V,fS,FC_a,FC_b,FC_rate);
                        data.Q(iQ).rec(irec).rx(irx).sig(2).t1 = reshape(T,1,numel(T));
                        data.Q(iQ).rec(irec).rx(irx).sig(2).v1 = reshape(V,1,numel(V)); % - mean() ?
                        data.Q(iQ).rec(irec).rx(irx).sig(2).t0 = data.Q(iQ).rec(irec).rx(irx).sig(2).t1; % backup for undo:
                        data.Q(iQ).rec(irec).rx(irx).sig(2).v0 = data.Q(iQ).rec(irec).rx(irx).sig(2).v1; 

                        data.Q(iQ).rec(irec).rx(irx).sig(3).recorded = 1;
                        [T,V] = filter_gmrrawdata((ifid2-ifid2(1))/fS,gmrout{irec}{iGMRrx+5}(ifid2)*gain_V,fS,FC_a,FC_b,FC_rate);
                        data.Q(iQ).rec(irec).rx(irx).sig(3).t1 = reshape(T,1,numel(T));
                        data.Q(iQ).rec(irec).rx(irx).sig(3).v1 = reshape(V,1,numel(V)); % - mean() ?
                        data.Q(iQ).rec(irec).rx(irx).sig(3).t0 = data.Q(iQ).rec(irec).rx(irx).sig(3).t1; % backup for undo:
                        data.Q(iQ).rec(irec).rx(irx).sig(3).v0 = data.Q(iQ).rec(irec).rx(irx).sig(3).v1;

                        data.Q(iQ).rec(irec).rx(irx).sig(4).recorded = 0;
                        data.Q(iQ).rec(irec).rx(irx).sig(4).v1 = [];
%                     else
%                         data.Q(iQ).rec(irec).rx(irx).connected = 0;
                    end   
                end
                data.Q(iQ).rec(irec).info.fS = FS;  % set to reduced sample frequency 
            end
        end

    %% READ 4PC T1
    case 4          % 4pc T1
        
        for irec = 1:nrec
            % for checkplot
            ifig = figure;
            plot(gmrout{irec}{1},gmrout{irec}{3},'Color',[0.7 0.7 0.7])
            title(['File: ' data.Q(1).rec(irec).info.file], 'Interpreter', 'None')
            
            for iQ = 1:nQ
                
                % Get transmitter current
                ip1  = round(1+it(1)+(iQ-1)*sum(tau)*fS:it(2)+(iQ-1)*sum(tau)*fS);     % samples pulse1 (rounding off numerical effects)
                t1   = gmrout{irec}{1}(ip1) - gmrout{irec}{1}(ip1(1));
                I1  = gain_I*gmrout{irec}{3}(ip1);  % toss column 2 - col2&3 are not in- and out-of-phase, but have some random phase correlation; col2 contains 2*envelope for GMRversion 0
%                 I1   = gain_I/sqrt(2)*(gmrout{irec}{2}(ip1) + 1i*gmrout{irec}{3}(ip1));
                ip2  = round(1+it(5)+(iQ-1)*sum(tau)*fS:it(6)+(iQ-1)*sum(tau)*fS);     % samples pulse2 (rounding off numerical effects)
                t2   = gmrout{irec}{1}(ip2) - gmrout{irec}{1}(ip2(1));
                I2   = gain_I*gmrout{irec}{3}(ip2);  % toss column 2 - col2&3 are not in- and out-of-phase, but have some random phase correlation; col2 contains 2*envelope for GMRversion 0
%                 I2   = gain_I/sqrt(2)*(gmrout{irec}{2}(ip2) + 1i*gmrout{irec}{3}(ip2));                
                
                % determine q values
                switch header.GMRversion
                    case 0.00
%                         q1   = gain_I*tau(2) * sqrt(2*mean((gmrout{irec}{3}(ip1)).^2)); % pulse 1 current envelope
                        q1   = gain_I*tau(2) * mean(gmrout{irec}{2}(ip1)) / 2; % pulse 1 current envelope
                        q2   = gain_I*tau(6) * mean(gmrout{irec}{2}(ip2)) / 2; % pulse 2 current envelope
                    otherwise
                        q1   = gain_I*tau(2)/sqrt(2) * (sqrt(mean((gmrout{irec}{2}(ip1)).^2))+sqrt(mean((gmrout{irec}{3}(ip1)).^2))); % pulse 1 current envelope
                        q2   = gain_I*tau(6)/sqrt(2) * (sqrt(mean((gmrout{irec}{2}(ip2)).^2))+sqrt(mean((gmrout{irec}{3}(ip2)).^2))); % pulse 2 current envelope
                end
                data.Q(iQ).q  = q1; % value of pulse moment   [A.s]
                data.Q(iQ).q2 = q2; % value of pulse moment 2 [A.s]

                % determine phases
                phi_gen(1)   = 0;
                ref          = exp(-1i*2*pi*header.fT * t1);
                phi_gen(2)   = median(angle(mrs_hilbert(I1).*ref));   % column3 (col4 is ignored...) - JW: not sure if this is OK
                ref2         = exp(-1i*2*pi*header.fT * t2);
                phi_gen(3:4) = median(angle(mrs_hilbert(I2).*ref2));

                % Signal indices
                ifid1 = round(1+it(3)+(iQ-1)*sum(tau)*fS:it(4)+(iQ-1)*sum(tau)*fS);
                ifid2 = round(1+it(7)+(iQ-1)*sum(tau)*fS:it(8)+(iQ-1)*sum(tau)*fS);
                checkplot_fid2(gmrout,iQ,irec,tau,it,fS,ifig)

                data.Q(iQ).rec(irec).info.fT = header.fT; % transmitter frequency
                data.Q(iQ).rec(irec).info.fS = fS;        % sampling frequency - reset after downsampling
                
                % collect timing parameters
                data.Q(iQ).rec(irec).info.timing.tau_p1    = tau(2);        % duration of pulse1
                data.Q(iQ).rec(irec).info.timing.tau_dead1 = tau(3);        % time between end of pulse1 and start of sig2 (=fid1)
                data.Q(iQ).rec(irec).info.timing.tau_d     = sum(tau(3:5)); % delay time between end of pulse1 and start of pulse2
                data.Q(iQ).rec(irec).info.timing.tau_p2    = tau(6);        % duration of pulse2
                data.Q(iQ).rec(irec).info.timing.tau_dead2 = tau(7);        % time between end of pulse2 and start of sig3 (=fid2)

                % generator phase
                data.Q(iQ).rec(irec).info.phases.phi_gen = phi_gen; % rad
%                 if mod(iQ,2) + mod(irec,2) == 1 % (irec even & iq odd) OR (irec odd & iq even)
%                     data.Q(iQ).rec(irec).info.phases.phi_gen = pi; % rad
%                 else % irec & iQ are both even or both odd
%                     data.Q(iQ).rec(irec).info.phases.phi_gen = 0; % rad
%                 end

                % amplifier phase - 0 for GMR
                data.Q(iQ).rec(irec).info.phases.phi_amp = 0; % rad

                % signal phases(noise, fid1, fid2, echo)
                % phase of "noise" (prepulse delay) - account for 200us
                % time lag here                
                data.Q(iQ).rec(irec).info.phases.phi_timing(1) = -200e-6*2*pi*header.fT;
                
                % phase of fid1
                data.Q(iQ).rec(irec).info.phases.phi_timing(2) = ...
                    phasewrap_intern(...
                        data.Q(iQ).rec(irec).info.phases.phi_timing(1) + ...
                        sum(tau(1:3)*2*pi*header.fT));

                % phase of fid2
                data.Q(iQ).rec(irec).info.phases.phi_timing(3) = ...
                    phasewrap_intern(...
                        data.Q(iQ).rec(irec).info.phases.phi_timing(1) + ...
                        data.Q(iQ).rec(irec).info.phases.phi_timing(2) + ...
                        sum(tau(4:7)*2*pi*header.fT));
                    
                % phase of echo - irrelevant here
                data.Q(iQ).rec(irec).info.phases.phi_timing(4) = 0;
                  
                % assembling transmitter data
                data.Q(iQ).rec(irec).tx.t1 = t1;
                data.Q(iQ).rec(irec).tx.I1 = I1;
                data.Q(iQ).rec(irec).tx.t2 = t2;
                data.Q(iQ).rec(irec).tx.I2 = I2;
                
                % receiver 
                irx = 0;
                for iGMRrx  = 1:length(data.info.rxinfo)     % for all signal & reference channels
                    irx = irx + 1;

                    % Signal1 - not recorded by GMR
                    data.Q(iQ).rec(irec).rx(irx).sig(1).recorded = 0;
                    
                    % Signal2 - FID
                    data.Q(iQ).rec(irec).rx(irx).sig(2).recorded = 1;
%                     [T,V,FS] = filter_gmrrawdata((ifid1-ifid1(1))/fS,gmrout{irec}{iGMRrx+5}(ifid1)*gain_V,fS,FC_a,FC_b,FC_rate);
                    T        = gmrout{irec}{1}(ifid1) - gmrout{irec}{1}(ifid1(1));
                    V        = gmrout{irec}{iGMRrx+5}(ifid1)/gain_V;        % +5 to accomodate data structure (col 1-5=time/currentX/currentY/voltageX/voltageY)
                    FS       = fS;
                    data.Q(iQ).rec(irec).rx(irx).sig(2).t1 = reshape(T,1,numel(T));
                    data.Q(iQ).rec(irec).rx(irx).sig(2).v1 = reshape(V,1,numel(V)); % - mean() ?
                    data.Q(iQ).rec(irec).rx(irx).sig(2).t0 = data.Q(iQ).rec(irec).rx(irx).sig(2).t1; % backup for undo
                    data.Q(iQ).rec(irec).rx(irx).sig(2).v0 = data.Q(iQ).rec(irec).rx(irx).sig(2).v1; 
                    
                    % Signal3 - FID2
                    data.Q(iQ).rec(irec).rx(irx).sig(3).recorded = 1;
                    T        = gmrout{irec}{1}(ifid2) - gmrout{irec}{1}(ifid2(1));  % start at time 0
                    V        = gmrout{irec}{iGMRrx+5}(ifid2)/gain_V;
                    FS       = fS;
                    data.Q(iQ).rec(irec).rx(irx).sig(3).t1 = reshape(T,1,numel(T));
                    data.Q(iQ).rec(irec).rx(irx).sig(3).v1 = reshape(V,1,numel(V)); % - mean() ?
                    data.Q(iQ).rec(irec).rx(irx).sig(3).t0 = data.Q(iQ).rec(irec).rx(irx).sig(3).t1; % backup for undo
                    data.Q(iQ).rec(irec).rx(irx).sig(3).v0 = data.Q(iQ).rec(irec).rx(irx).sig(3).v1;
                   
                    % Signal4 - not recorded in this scheme (4pcT1)
                    data.Q(iQ).rec(irec).rx(irx).sig(4).recorded = 0;
                    data.Q(iQ).rec(irec).rx(irx).sig(4).v1 = []; % necessary?
                end
                data.Q(iQ).rec(irec).info.fS = FS;  % set to reduced sample frequency 
            end
        end
end % sequenceID

% % throw out unconnected receivers
% data.info.rxtask(data.info.rxtask==2) = [];

% sort q's in ascending order
q = zeros(1,length(data.Q));
for iQ = 1:length(data.Q)
    q(iQ) = data.Q(iQ).q;
end
[dummy,qID]   = sort(q);
data.Q(1:end) = data.Q(qID);

end


%% CHECKPLOT FUNCTIONS ----------------------------------------------------
function checkplot_fid(gmrout,iQ,irec,tau,it,fS,ifig)
% temporary piece of code for debugging
    
    ipre = round(1+(iQ-1)*sum(tau)*fS:it(1)+(iQ-1)*sum(tau)*fS);
    ip   = round(1+it(1)+(iQ-1)*sum(tau)*fS:it(2)+(iQ-1)*sum(tau)*fS);     % samples pulse1 (rounding off numerical effects)
    ided = round(1+it(2)+(iQ-1)*sum(tau)*fS:it(3)+(iQ-1)*sum(tau)*fS);
    ifid = round(1+it(3)+(iQ-1)*sum(tau)*fS:it(4)+(iQ-1)*sum(tau)*fS);    

    % noise
    figure(ifig)
    hold on    
%     plot(gmrout{irec}{1}(ipre), gmrout{irec}{2}(ipre),'k--')
%     plot(gmrout{irec}{1}(ip), gmrout{irec}{2}(ip),'b--')
%     plot(gmrout{irec}{1}(ided), gmrout{irec}{2}(ided),'r--')    
%     plot(gmrout{irec}{1}(ifid), gmrout{irec}{2}(ifid),'g--')
    plot(gmrout{irec}{1}(ipre), gmrout{irec}{7}(ipre),'k')
    plot(gmrout{irec}{1}(ip), gmrout{irec}{7}(ip),'b')
    plot(gmrout{irec}{1}(ided), gmrout{irec}{7}(ided),'r')    
    plot(gmrout{irec}{1}(ifid), gmrout{irec}{7}(ifid),'g')    
    hold off
end


function checkplot_fid2(gmrout,iQ,irec,tau,it,fS,ifig)
% temporary piece of code for debugging
    
% ifid2 = round(1+it(7)+(iQ-1)*sum(tau)*fS:it(8)+(iQ-1)*sum(tau)*fS);

    ipre  = round(1+(iQ-1)*sum(tau)*fS:it(1)+(iQ-1)*sum(tau)*fS);
    ip    = round(1+it(1)+(iQ-1)*sum(tau)*fS:it(2)+(iQ-1)*sum(tau)*fS);     % samples pulse1 (rounding off numerical effects)
    ided  = round(1+it(2)+(iQ-1)*sum(tau)*fS:it(3)+(iQ-1)*sum(tau)*fS);
    ifid  = round(1+it(3)+(iQ-1)*sum(tau)*fS:it(4)+(iQ-1)*sum(tau)*fS);    
    ipre2 = round(1+it(4)+(iQ-1)*sum(tau)*fS:it(5)+(iQ-1)*sum(tau)*fS);
    ip2   = round(1+it(5)+(iQ-1)*sum(tau)*fS:it(6)+(iQ-1)*sum(tau)*fS);
    ided2 = round(1+it(6)+(iQ-1)*sum(tau)*fS:it(7)+(iQ-1)*sum(tau)*fS);
    ifid2 = round(1+it(7)+(iQ-1)*sum(tau)*fS:it(8)+(iQ-1)*sum(tau)*fS);    

    % noise
    figure(ifig)
    hold on    
%     plot(gmrout{irec}{1}(ipre), gmrout{irec}{2}(ipre),'k--')
%     plot(gmrout{irec}{1}(ip), gmrout{irec}{2}(ip),'b--')
%     plot(gmrout{irec}{1}(ided), gmrout{irec}{2}(ided),'r--')    
%     plot(gmrout{irec}{1}(ifid), gmrout{irec}{2}(ifid),'g--')
    plot(gmrout{irec}{1}(ipre), gmrout{irec}{7}(ipre),'k')
    plot(gmrout{irec}{1}(ip), gmrout{irec}{7}(ip),'b')
    plot(gmrout{irec}{1}(ided), gmrout{irec}{7}(ided),'r')    
    plot(gmrout{irec}{1}(ifid), gmrout{irec}{7}(ifid),'g')
    plot(gmrout{irec}{1}(ipre2), gmrout{irec}{7}(ipre2),'k')
    plot(gmrout{irec}{1}(ip2), gmrout{irec}{7}(ip2),'b')
    plot(gmrout{irec}{1}(ided2), gmrout{irec}{7}(ided2),'r')    
    plot(gmrout{irec}{1}(ifid2), gmrout{irec}{7}(ifid2),'g')    
    hold off
end

function checkplot(gmrout,iQ,tau,fS,it,gain_I)
% temporary piece of code for debugging
    ipre1 = round(1+(iQ-1)*sum(tau)*fS:it(1)+(iQ-1)*sum(tau)*fS);
    ipre2 = round(it(4)+1+(iQ-1)*sum(tau)*fS:it(5)+(iQ-1)*sum(tau)*fS);

    id1   =  round(it(2)+1+(iQ-1)*sum(tau)*fS:it(3)-1+(iQ-1)*sum(tau)*fS);
    id2   =  round(it(6)+1+(iQ-1)*sum(tau)*fS:it(7)-1+(iQ-1)*sum(tau)*fS);

    % check
    % pulses
    plot((1:length(gmrout{irec}{2}))/fS,gmrout{irec}{2}*gain_I)
    hold on
    t1 = ip1/fS;
    t2 = ip2/fS;
    plot(t1,gmrout{irec}{2}(ip1)*gain_I,'r--')
    plot(t1,gmrout{irec}{3}(ip1)*gain_I,'r--')
    plot(t1,I1,'k--','Linewidth',2)
    plot(t2,gmrout{irec}{2}(ip2)*gain_I,'g--')
    plot(t2,gmrout{irec}{3}(ip2)*gain_I,'g--')
    plot(t2,I2,'k--','Linewidth',2)        

    % fids
    %         plot((1:length(gmrout{irec}{6}))/fS,gmrout{irec}{6}*gain_I)
    t1 = ifid1/fS;
    t2 = ifid2/fS;
    plot(t1,gmrout{irec}{6}(ifid1)*gain_I,'k-')
    plot(t2,gmrout{irec}{6}(ifid2)*gain_I,'g-')

    plot(id1/fS,zeros(size(id1)),'y-')
    plot(id2/fS,zeros(size(id2)),'y-')
    plot(ipre1/fS,zeros(size(ipre1)),'y-')
    plot(ipre2/fS,zeros(size(ipre2)),'y-')
    % dead times

    xlim([ipre1(1)/fS t2(end)])
    ylim([-1 1])

    hold off
end

%% FILTER (NOT USED) ------------------------------------------------------
function [a,b,rate] = make_filter(fs)
    n     = 6;
    r     = 50;
    Wn    = 5000/(fs/2);
    ftype = 'low';
    [b,a] = cheby2(n,r,Wn,ftype);
    rate  = 1/Wn;
end

function [T,V,FS] = filter_gmrrawdata(t,v,fs,a,b,rate)

% apply filter
vf = filtfilt(b,a,v);

% resample
V  = vf(rate:rate:end-rate);            % JW: use decimate?
T  = t(rate:rate:end-rate) - t(rate);   
FS = fs/rate;

end

%% PHASEWRAP --------------------------------------------------------------
function p = phasewrap_intern(phi)
% ex function p = jwrap_pipi(phi)
%
% Wrap angle phi to interval [-pi;pi].
% Angle phi can be rewritten as:
% phi = sign(phi)*[r*(2pi) + n*(2pi)], r real [0 1], n integer
% with
% multiple of 2pi: n = floor(|phi|/(2pi))
% rest             r = |phi|/(2pi) - n
% Remove period:
% p   = sign(phi)*r*(2pi)
%
% Input: 
% 	phi - angle in radian
%
% Output: 
%   p   - angle in radian wrapped in interval [-pi pi]
%
% Jan Walbrecker, 29mar2010
% ed. 29mar2010
% =========================================================================

% map to [-2pi 2pi]
p = 2*pi*sign(phi).*(abs(phi/(2*pi)) - floor(abs(phi)/(2*pi)));

% map to [-pi pi]
p(p>pi)  = -2*pi + p(p>pi);
p(p<-pi) =  2*pi + p(p<-pi);

% % test
% x = -5*pi:1e-4:5*pi;
% patch([-pi -pi pi pi -pi], [-1 1 1 -1 -1], [0.8 0.8 0.8])
% hold on
% plot(x,sin(x),'k-')
% plot(phi,sin(phi),'rx')
% plot(p,sin(p),'go')
% hold off

if ~isequal(ext_roundn(sin(p),-5),ext_roundn(sin(phi),-5))
    error('something wrong')
end

end
