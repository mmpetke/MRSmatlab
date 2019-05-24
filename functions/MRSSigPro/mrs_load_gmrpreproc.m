function data = mrs_load_gmrpreproc(sounding_path, singlefile)
% function data = mrs_load_gmrpreproc(sounding_path)
% 
% TO BE FIXED: ISSUE WHEN Q'S HAVE BEEN DELETED BY GMR-QC SOFTWARE
% 
% Load GMR sounding data that have been preprocessed using the GMR
% software. 
% 
% Supported GMR versions:
%   * expansion unit: 0, 1 (4 or 8 channels)
%   * GMRversion: 1, 2, 2.08
%
% Input:
%   sounding_path - path to files
%                      (e.g. 'c:\Users\GMR_mar2010\100m_T1_150ms\')
% Output: 
%  data (MRSmatlab structure)
%
% Jan Walbrecker, 17aug2011
% JW 23mar2012
% =========================================================================

%% CHECK INPUT ------------------------------------------------------------

% read all files if singlefile is not passed
if nargin < 2
    singlefile = [];
    read_singlefile = 0;
else
    read_singlefile = 1;
end

% path to sounding is retrieved from gui - no input only for bugfixing
if nargin < 1   % only for bugfixing - remove later.
    sounding_path = 'c:\Users\Jan\Documents\su\matlab\nmr\data\gmr_NE_8apr_2009\';
end

% aborting if called with input 0
if sounding_path == 0 
    data = 0;
    return
end

%% GET SOUNDING PATH ------------------------------------------------------

data.info.path   = sounding_path;   
data.info.device = 'GMR';

%% REQUEST MISSING SURVEY INFORMATION -------------------------------------

% check if information has been entered previously
chk = exist([sounding_path 'GMRuserinfo.mrs'],'file');
if chk ~= 2
    mrs_request_gmruserinfo(sounding_path);
% else
%     disp('GMRuserinfo file found. Use it?')
end
uival = mrs_read_gmruserinfo([sounding_path 'GMRuserinfo.mrs']);

% retrieve missing parameters
iTX                        = find(uival{11}==1);
data.info.txinfo.channel   = iTX;
data.info.txinfo.looptype  = uival{7}(iTX);
data.info.txinfo.loopsize  = uival{8}(iTX);
data.info.txinfo.loopturns = uival{9}(iTX);

% collect only signal channels - noise cancellation has already been done
rxtask = uival{10};         % receiver task (MRSmatlab format)
irx = 0;              % receiver index
for iCh = 1:length(rxtask)
    switch rxtask(iCh)
        case {0,2}    % not connected or reference rx > skip
        case 1        % signal receiver
            irx = irx + 1;
            data.info.rxinfo(irx).channel   = iCh; % channel ID on instrument
            data.info.rxinfo(irx).task      = rxtask(iCh);
            data.info.rxinfo(irx).looptype  = uival{7}(iCh);
            data.info.rxinfo(irx).loopsize  = uival{8}(iCh);
            data.info.rxinfo(irx).loopturns = uival{9}(iCh);
    end
end
nrx = irx;  % number of signal receivers

%% COLLECT DATA FILES -----------------------------------------------------

% Select preprocessed files
if read_singlefile % get prepfile from input
    prepfiles = singlefile;
    preppath = sounding_path;
else % ask user to select preprocessed files
    [prepfiles, preppath] = uigetfile( ...
        {'*.mat','Preprocessed GMR files (*.mat)';
         '*.mat','MAT-files (*.mat)'; ...
         '*.*',  'All Files (*.*)'}, ...
       'Select all relevant preprocessed files',...
       'MultiSelect', 'on', ...
       sounding_path);
end

% aborting load if gui is cancelled
if preppath == 0   
    data = 0;
    return
end

% If only 1 file is selected in uigetfile, matlab returns a char, otherwise 
% a cell. Any char is converted to cell here for code consistency.
hu = whos('prepfiles');
switch hu.class
    case 'char'
        nrec = 1;
        prepfiles = {prepfiles};
    case 'cell'
        nrec = length(prepfiles);
end

% determine number of pulse moments
temp = load([preppath cell2mat(prepfiles(1))]);
nQ   = length(temp.pulse_moment);

% build data structure gmrout from gmr files
gmrout   = cell(1,length(prepfiles));
for irec = 1:nrec
    for iQ = 1:nQ    
        data.Q(iQ).rec(irec).info.file = cell2mat(prepfiles(irec)); % filenames of all q's are the same (all q's are in one file for GMR)
    end
    gmrout{irec} = load([preppath cell2mat(prepfiles(irec))]);
end

% handle deleted pulse moments ?


%% ASSEMBLE MRSMATLAB STRUCTURE (fdata) -----------------------------------

% switch GMR sequenceID
switch gmrout{1}.pulse_sequence   % sequence is the same for all files
    case 1  % FID 
        for irec = 1:nrec
            for iQ = 1:nQ
                
                % read pulse moments
                data.Q(iQ).q  = gmrout{irec}.pulse_moment(iQ);   % value of pulse moment [A.s]
%                 data.Q(iQ).q2 = -1; % [A.s]
                
                % read frequencies
                data.Q(iQ).rec(irec).info.fT = gmrout{irec}.detect_frequency;   % transmitter frequency
                data.Q(iQ).rec(irec).info.fS = gmrout{irec}.fs;  % set to reduced sample frequency 
                
                % collect timing parameters
                data.Q(iQ).rec(irec).info.timing.tau_p1    = gmrout{irec}.T_pulse;          % duration of pulse1
                data.Q(iQ).rec(irec).info.timing.tau_dead1 = gmrout{irec}.T_dead_time;      % time between end of pulse1 and start of sig1
%                 data.Q(iQ).rec(irec).info.timing.tau_d     = gmrout{irec}.interpulse_delay; % delay time between end of pulse1 and start of pulse2
%                 data.Q(iQ).rec(irec).info.timing.tau_p2    = gmrout{irec}.T_pulse;          % duration of pulse2
%                 data.Q(iQ).rec(irec).info.timing.tau_dead2 = gmrout{irec}.T_dead_time;      % time between end of pulse2 and start of sig2

                % generator phase
                data.Q(iQ).rec(irec).info.phases.phi_gen(1:4) = 0; % [rad]

                % amplifier phase (PROBABLY VARIES WITH RX CHANNEL)
                data.Q(iQ).rec(irec).info.phases.phi_amp = 0; % [rad]

                % signal phases(noise, fid1, fid2, echo)
                data.Q(iQ).rec(irec).info.phases.phi_timing([1 3 4]) = 0;
                data.Q(iQ).rec(irec).info.phases.phi_timing(2)       = gmrout{irec}.pulse_moment_phase(iQ);
                
                % collect data for for all relevant receiver channels
                % only rxtask=1 coils are relevant, since noise cancellation
                % has been done already on preproc data
                for irx  = 1:nrx
                    
                    % eval necessary because of vista clara handling of variables
                    
                    str  = ['gmrout{irec}.coil_' num2str(data.info.rxinfo(irx).channel) '_fid(:,iQ)'';'];     % column vector format
%                     str  = ['gmrout{irec}.coil_' num2str(rx_fid(irx)) '_fid(:,iQ)'';'];     % column vector format

                    % sig1 (noise) is not recorded in GMR
                    data.Q(iQ).rec(irec).rx(irx).sig(1).recorded = 0;
                    
                    % sig2 (FID1) is always recorded
                    v1 = eval(str);
                    data.Q(iQ).rec(irec).rx(irx).sig(2).recorded = 1;
                    data.Q(iQ).rec(irec).rx(irx).sig(2).t1 = reshape(gmrout{irec}.time_fid,1,numel(gmrout{irec}.time_fid)) - gmrout{irec}.time_fid(1);     % same for all rx; gmrout{irec}.time_fid starts with 1st time sample at end of dead time (i.e. time_fid(1) = 0.011 if Tdead = 0.011). MRSmatlab is setup such that t(1) = 0.
                    data.Q(iQ).rec(irec).rx(irx).sig(2).v1 = reshape(v1,1,numel(v1));                % reshape necessary because GMR preproc files vary (see HaddamMeadows vs Alaska)
                    data.Q(iQ).rec(irec).rx(irx).sig(2).t0 = data.Q(iQ).rec(irec).rx(irx).sig(2).t1; % backup for undo
                    data.Q(iQ).rec(irec).rx(irx).sig(2).v0 = data.Q(iQ).rec(irec).rx(irx).sig(2).v1; 
                    
                    % sig3 (FID2) is not recorded in FID sequence
                    data.Q(iQ).rec(irec).rx(irx).sig(3).recorded = 0;
                    
                    % sig4 (ECHO) is not recorded in FID sequence
                    data.Q(iQ).rec(irec).rx(irx).sig(4).recorded = 0;
                end
            end
        end
    case 2  % 90-90 T1
        for irec = 1:nrec
            for iQ = 1:nQ
                
                % read pulse moments
                data.Q(iQ).q  = gmrout{irec}.pulse_moment(iQ);   % value of pulse moment [A.s]
                data.Q(iQ).q2 = gmrout{irec}.pulse_moment_2(iQ); % [A.s]
                
                % read frequencies
                data.Q(iQ).rec(irec).info.fT = gmrout{irec}.detect_frequency;   % transmitter frequency
                data.Q(iQ).rec(irec).info.fS = gmrout{irec}.fs;  % set to reduced sample frequency 
                
                % collect timing parameters
                data.Q(iQ).rec(irec).info.timing.tau_p1    = gmrout{irec}.T_pulse;          % duration of pulse1
                data.Q(iQ).rec(irec).info.timing.tau_dead1 = gmrout{irec}.T_dead_time;      % time between end of pulse1 and start of sig1
                data.Q(iQ).rec(irec).info.timing.tau_d     = gmrout{irec}.interpulse_delay; % delay time between end of pulse1 and start of pulse2
                data.Q(iQ).rec(irec).info.timing.tau_p2    = gmrout{irec}.T_pulse;          % duration of pulse2
                data.Q(iQ).rec(irec).info.timing.tau_dead2 = gmrout{irec}.T_dead_time;      % time between end of pulse2 and start of sig2

                % generator phase
                data.Q(iQ).rec(irec).info.phases.phi_gen(1:4) = 0; % [rad]

                % amplifier phase (PROBABLY VARIES WITH RX CHANNEL)
                data.Q(iQ).rec(irec).info.phases.phi_amp = 0; % [rad]

                % signal phases(noise, fid1, fid2, echo)
                data.Q(iQ).rec(irec).info.phases.phi_timing([1 4]) = 0;
                data.Q(iQ).rec(irec).info.phases.phi_timing(2)     = gmrout{irec}.pulse_moment_phase(iQ);
                data.Q(iQ).rec(irec).info.phases.phi_timing(3)     = gmrout{irec}.pulse_moment_phase_2(iQ);
                
                % collect data for for all relevant receiver channels
                % only rxtask=1 coils are relevant, since noise cancellation
                % has been done already on preproc data
                for irx  = 1:nrx
                    
%                     data.Q(iQ).rec(irec).rx(irx).connected = 1;
                    
                    % eval necessary because of vista clara variable handling
                    str  = ['gmrout{irec}.coil_' num2str(data.info.rxinfo(irx).channel) '_fid(:,iQ)'';'];     % column vector format
                    str2 = ['gmrout{irec}.coil_' num2str(data.info.rxinfo(irx).channel) '_fid_2(:,iQ)'';'];     % column vector format

                    % sig1 (noise) is not recorded in GMR
                    data.Q(iQ).rec(irec).rx(irx).sig(1).recorded = 0;
                    
                    % sig2 (FID1) is always recorded
                    v1 = eval(str);
                    data.Q(iQ).rec(irec).rx(irx).sig(2).recorded = 1;
                    data.Q(iQ).rec(irec).rx(irx).sig(2).t1 = reshape(gmrout{irec}.time_fid,1,numel(gmrout{irec}.time_fid)) - gmrout{irec}.time_fid(1);     % same for all rx; gmrout{irec}.time_fid starts with 1st time sample at end of dead time (i.e. time_fid(1) = 0.011 if Tdead = 0.011). MRSmatlab is setup such that t(1) = 0.                    
                    data.Q(iQ).rec(irec).rx(irx).sig(2).v1 = reshape(v1,1,numel(v1));                % reshape necessary because GMR preproc files vary (see HaddamMeadows vs Alaska)                    
                    data.Q(iQ).rec(irec).rx(irx).sig(2).t0 = data.Q(iQ).rec(irec).rx(irx).sig(2).t1; % backup for undo
                    data.Q(iQ).rec(irec).rx(irx).sig(2).v0 = data.Q(iQ).rec(irec).rx(irx).sig(2).v1; 
                    
                    % sig3 (FID2) is always recorded in the 90-90 sequence
                    v2 = eval(str2);                    
                    data.Q(iQ).rec(irec).rx(irx).sig(3).recorded = 1;
                    data.Q(iQ).rec(irec).rx(irx).sig(3).t1 = reshape(gmrout{irec}.time_fid,1,numel(gmrout{irec}.time_fid)) - gmrout{irec}.time_fid(1);     % same for all rx; gmrout{irec}.time_fid starts with 1st time sample at end of dead time (i.e. time_fid(1) = 0.011 if Tdead = 0.011). MRSmatlab is setup such that t(1) = 0.                    
                    data.Q(iQ).rec(irec).rx(irx).sig(3).v1 = reshape(v2,1,numel(v2));                % reshape necessary because GMR preproc files vary (see HaddamMeadows vs Alaska)                                        
                    data.Q(iQ).rec(irec).rx(irx).sig(3).t0 = data.Q(iQ).rec(irec).rx(irx).sig(3).t1; % backup for undo
                    data.Q(iQ).rec(irec).rx(irx).sig(3).v0 = data.Q(iQ).rec(irec).rx(irx).sig(3).v1;
                    
                    % no sig4
                    data.Q(iQ).rec(irec).rx(irx).sig(4).recorded = 0;
                    data.Q(iQ).rec(irec).rx(irx).sig(4).v1 = [];    % JW: WHY NECESSARY?
                end
            end
        end
    case 4
        for irec = 1:nrec
            for iQ = 1:nQ
                
                % read pulse moments
                data.Q(iQ).q  = gmrout{irec}.pulse_moment(iQ);   % value of pulse moment [A.s]
                data.Q(iQ).q2 = gmrout{irec}.pulse_moment_2(iQ); % value of pulse moment 2 [A.s]
                
                % read frequencies
                data.Q(iQ).rec(irec).info.fT = gmrout{irec}.detect_frequency;   % transmitter frequency
                data.Q(iQ).rec(irec).info.fS = gmrout{irec}.fs;  % set to reduced sample frequency 
                
                % collect timing parameters
                data.Q(iQ).rec(irec).info.timing.tau_p1    = gmrout{irec}.T_pulse;          % duration of pulse1
                data.Q(iQ).rec(irec).info.timing.tau_dead1 = gmrout{irec}.T_dead_time;      % time between end of pulse1 and start of sig1
                data.Q(iQ).rec(irec).info.timing.tau_d     = gmrout{irec}.interpulse_delay; % delay time between end of pulse1 and start of pulse2
                data.Q(iQ).rec(irec).info.timing.tau_p2    = gmrout{irec}.T_pulse;          % duration of pulse2 (same as for pulse 1)
                data.Q(iQ).rec(irec).info.timing.tau_dead2 = gmrout{irec}.T_dead_time;      % time between end of pulse2 and start of sig2 (same as for pulse 1)

                % generator phase
                data.Q(iQ).rec(irec).info.phases.phi_gen(1:4) = 0; % [rad]

                % amplifier phase (PROBABLY VARIES WITH RX CHANNEL)
                data.Q(iQ).rec(irec).info.phases.phi_amp = 0; % [rad]

                % signal phases(noise, fid1, fid2, echo)
                data.Q(iQ).rec(irec).info.phases.phi_timing([1 4]) = 0;
                data.Q(iQ).rec(irec).info.phases.phi_timing(2) = gmrout{irec}.pulse_moment_phase(iQ);
                data.Q(iQ).rec(irec).info.phases.phi_timing(3) = gmrout{irec}.pulse_moment_phase_2(iQ);
                
                % collect data for for all relevant receiver channels
                % only rxtask=1 coils are relevant, since noise cancellation
                % has been done already on preproc data
                for irx  = 1:nrx
                    
                    % eval necessary because of vista clara handling of variables
                    
                    str  = ['gmrout{irec}.coil_' num2str(data.info.rxinfo(irx).channel) '_fid(:,iQ)'';'];     % column vector format
%                     str  = ['gmrout{irec}.coil_' num2str(rx_fid(irx)) '_fid(:,iQ)'';'];     % column vector format
                    str2 = ['gmrout{irec}.coil_' num2str(data.info.rxinfo(irx).channel) '_fid_2(:,iQ)'';'];     % column vector format

                    % sig1 (noise) is not recorded in GMR
                    data.Q(iQ).rec(irec).rx(irx).sig(1).recorded = 0;
                    
                    % sig2 (FID1) is always recorded
                    v1 = eval(str);
                    data.Q(iQ).rec(irec).rx(irx).sig(2).recorded = 1;
                    data.Q(iQ).rec(irec).rx(irx).sig(2).t1 = reshape(gmrout{irec}.time_fid,1,numel(gmrout{irec}.time_fid)) - gmrout{irec}.time_fid(1);     % same for all rx; gmrout{irec}.time_fid starts with 1st time sample at end of dead time (i.e. time_fid(1) = 0.011 if Tdead = 0.011). MRSmatlab is setup such that t(1) = 0.
                    data.Q(iQ).rec(irec).rx(irx).sig(2).v1 = reshape(v1,1,numel(v1));                % reshape necessary because GMR preproc files vary (see HaddamMeadows vs Alaska)
                    data.Q(iQ).rec(irec).rx(irx).sig(2).t0 = data.Q(iQ).rec(irec).rx(irx).sig(2).t1; % backup for undo
                    data.Q(iQ).rec(irec).rx(irx).sig(2).v0 = data.Q(iQ).rec(irec).rx(irx).sig(2).v1; 
                    
                    % sig3 (FID2) 
                    s2 = eval(str2);
                    data.Q(iQ).rec(irec).rx(irx).sig(3).recorded = 1;
                    data.Q(iQ).rec(irec).rx(irx).sig(3).t1 = ( 0:1:numel(s2)-1 ) / gmrout{irec}.fs;
                    data.Q(iQ).rec(irec).rx(irx).sig(3).v1 = reshape(s2,1,numel(s2));                % reshape necessary because GMR preproc files vary (see HaddamMeadows vs Alaska)
                    data.Q(iQ).rec(irec).rx(irx).sig(3).t0 = data.Q(iQ).rec(irec).rx(irx).sig(3).t1; % backup for undo
                    data.Q(iQ).rec(irec).rx(irx).sig(3).v0 = data.Q(iQ).rec(irec).rx(irx).sig(3).v1; 
                    
                    
                    % sig4 (ECHO) is not recorded in FID sequence
                    data.Q(iQ).rec(irec).rx(irx).sig(4).recorded = 0;
                end
            end
        end
    otherwise
        error('NOT YET IMPLEMENTED')
end % sequenceID

% sort q's in ascending order
q = zeros(1,length(data.Q));
for iQ = 1:length(data.Q)
    q(iQ) = data.Q(iQ).q;
end
[dummy,qID]       = sort(q);
data.Q(1:end) = data.Q(qID);

