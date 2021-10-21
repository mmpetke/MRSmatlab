function data = mrs_load_midiraw(sounding_path)
% function data = mrs_load_midiraw(sounding_path)
% 
% ISSUE: HANDLE DATA AFTER SECOND PULSE (I.E. INDEX D > 0).
% 
% Load MIDI raw data. Requires standard MIDI file format:
%   (1) filename convention after renaming:
%       <FOLDER> contains data in subfolders fids, noise, stacked
%   (2) filename convention after Software rev. 291208;
%       <FOLDER> contains .dat files: FID_*,  FID+*, and NOIS*
% 
% Input: 
%   sounding_path - path to sounding folder (from MRSImport)
% 
% Output: 
%   data          - see MRSmatlab documentation
% 
% 25jan2011
% ed. 30sep2011 JW
% =========================================================================

%% Sounding path & filenames ----------------------------------------------

data.info.path = sounding_path;

% filename format
if isdir([sounding_path 'fids'])                % after rename
    fid_str = ['fids' filesep '*_fid_*'];
    rec_str = ['fids' filesep '*_q*'];
    nse_str = ['noise' filesep '*_q*'];
    q_str   = 'q';
    d_str   = 'd';
    r_str   = 'r';
    fo1_str = 'fids\';
    fo2_str = 'noise\';
elseif ~isempty(dir([sounding_path 'FID_*']))   % Software rev. 291208
    fid_str = 'FID_*';
    rec_str = 'FID_Q';
    nse_str = 'NOISE_Q';
    q_str   = 'Q';
    d_str   = 'D';
    r_str   = 'R';
    fo1_str = '';
    fo2_str = '';
else
    error('Unknown filename format. Probably old unsupported MIDI version')
end

% determine min & max Q (index) from filenames
allFID = dir([sounding_path fid_str]);          % raw data files
Q      = zeros(1,length(allFID)); D = Q; R = Q;
for iallFID = 1:length(allFID)
    
    iQ = find(allFID(iallFID).name == q_str);
    if length(iQ) > 1; error('bad filename - contains two Q'); end
    q = allFID(iallFID).name(iQ+1:iQ+2);
    if strcmp(q(end),'_'); q(end) = []; end
    Q(iallFID) = str2double(q);
    
%     iD = find(allFID(iallFID).name == 'D',1,'last');
    iD = find(allFID(iallFID).name == d_str,1,'last');
    d = allFID(iallFID).name(iD+1:iD+2);
    if strcmp(d(end),'_'); d(end) = []; end
    D(iallFID) = str2double(d);
    
end
Q = sort(unique(Q), 'descend'); % Q=0 is the largest pulsemoment
D = sort(unique(D), 'ascend');

% DELAY = -1 -> single pulse
% NOISE -> sig1
% FID -> sig2 & sig3

data.info.txinfo.channel   = 0;
data.info.txinfo.looptype  = 2;     %default loop layout of midi tool!
data.info.txinfo.loopsize  = 10;    %default loop layout of midi tool!
data.info.txinfo.loopturns = 1;    %default loop layout of midi tool!

%% Assemble output: data --------------------------------------------------
data.info.device = 'MIDI';

for iQ = 1:length(Q)
    
    % determine # recordings for this Q
    allREC = dir([sounding_path rec_str num2str(Q(iQ)) '_D*_R*.dat']);
    allNSE = dir([sounding_path nse_str num2str(Q(iQ)) '_D*_R*.dat']);
    if isempty(allNSE)
        nosig1 = 1;
    else
        nosig1 = 0;
    end

    for irec = 1:length(allREC)
        iR = find(allREC(irec).name == r_str);
        if length(iR) > 1; error('bad filename - contains two R'); end
        r = allREC(irec).name(iR+1:iR+2);
        if strcmp(r(end),'.'); r(end) = []; end
        R(irec) = str2double(r);
        % multiples can exist if >1 D
        
        data.Q(iQ).rec(irec).info.file = ...
            [sounding_path fo1_str allREC(irec).name];
        disp(['read file:' data.Q(iQ).rec(irec).info.file]);
        midiout  = mrs_readmidi(data.Q(iQ).rec(irec).info.file);
        if nosig1 == 0
            noiseout = mrs_readmidi([sounding_path fo2_str allNSE(irec).name]);
        end
        
        data.Q(iQ).q = [];                  % defined later as mean(qvalue)
        qvalue(irec) = midiout.info.q;      % value of pulse moment [A.s]
        numRx        = size(midiout.v,2);
%         if (fidin2 ~= -1)
%             data.Q(iQ).q2 = q2(iQ); % [A.s]
%         end                

        data.Q(iQ).rec(irec).info.fS = midiout.info.samplfreq;   % sampling frequency
        data.Q(iQ).rec(irec).info.fT = midiout.info.f_ref;       % transmitter frequency
        if data.Q(iQ).rec(irec).info.fT == 0    % no excitation
            data.Q(iQ).rec(irec).info.fT = 2030;
        end
        
        data.Q(iQ).rec(irec).info.timing.tau_p1 = ...       % duration of pulse1
            midiout.info.P1/data.Q(iQ).rec(irec).info.fT; 
        data.Q(iQ).rec(irec).info.timing.tau_dead1 = ...    % time between end of pulse1 and start of sig1
            midiout.info.tdead-midiout.info.P1/data.Q(iQ).rec(irec).info.fT;
        data.Q(iQ).rec(irec).info.timing.tau_d = ...        % delay time between end of pulse1 and start of pulse2
            midiout.info.delay;
        data.Q(iQ).rec(irec).info.timing.tau_p2 = ...       % duration of pulse2
            midiout.info.P2/data.Q(iQ).rec(irec).info.fT; 
        data.Q(iQ).rec(irec).info.timing.tau_dead2 = ...    % time between end of pulse2 and start of sig2
            midiout.info.tdead-midiout.info.P2/data.Q(iQ).rec(irec).info.fT;

        % generator phase (same for all receivers)
        data.Q(iQ).rec(irec).info.phases.phi_gen(1)   = 0; % [rad]
        data.Q(iQ).rec(irec).info.phases.phi_gen(2:4) = midiout.info.phase; % [rad]

        % amplifier phase (get from MIDI.ini-file. Unclear if already included!)
        data.Q(iQ).rec(irec).info.phases.phi_protonph1 = 0; % rad
        
        % signal phases (same for all receivers)
        % phase of noise
        data.Q(iQ).rec(irec).info.phases.phi(1) = 0;

        % phase of fid1
        data.Q(iQ).rec(irec).info.phases.phi(2) = 0;

        % phase of fid2
        data.Q(iQ).rec(irec).info.phases.phi(3) = 0;

        % phase of echo 
        data.Q(iQ).rec(irec).info.phases.phi(4) = 0;
        
        % signal phases (same for all receivers)
                % phase of noise
        data.Q(iQ).rec(irec).info.phases.phi_timing(1) = 0;
        data.Q(iQ).rec(irec).info.phases.phi_timing(2) = 0;
        
        irx = 0;
        for imidirx  = 1:numRx
            if length(unique(midiout.v(:,imidirx))) > 1 % if connected
                irx = irx + 1;  % index of connected receiver
%                 data.Q(iQ).rec(irec).rx(irx).connected = 1;

                data.info.rxinfo(imidirx).channel = imidirx;
                if imidirx == 1
                    %Channel 1 is for detection by default
                    data.info.rxinfo(imidirx).task    = 1;      
                else
                    %consider all channels > 1 to be reference channel 
                    %and make NC available in MRSMatlab
                    data.info.rxinfo(imidirx).task    = 2;       
                end
                data.info.rxinfo(imidirx).looptype  = 2;   % default loop layout of midi tool!
                data.info.rxinfo(imidirx).loopsize  = 10;   % default loop layout of midi tool!
                data.info.rxinfo(imidirx).loopturns = 12;   %number of turns is actually 12, but the voltage is corrected in mrs_readmidi.m
                
                isig = 2;    % only sig2 here
                data.Q(iQ).rec(irec).rx(irx).sig(isig).recorded = 1;
                data.Q(iQ).rec(irec).rx(irx).sig(isig).t1 = midiout.t';
                data.Q(iQ).rec(irec).rx(irx).sig(isig).v1 = midiout.v(:,imidirx)';
                % backup for undo:
                data.Q(iQ).rec(irec).rx(irx).sig(isig).t0 = data.Q(iQ).rec(irec).rx(irx).sig(isig).t1;
                data.Q(iQ).rec(irec).rx(irx).sig(isig).v0 = data.Q(iQ).rec(irec).rx(irx).sig(isig).v1;
                
                isig = 1;    % only sig1 here
                if nosig1 == 1
                    data.Q(iQ).rec(irec).rx(irx).sig(isig).recorded = 0;
                else
                    data.Q(iQ).rec(irec).rx(irx).sig(isig).recorded = 1;
                    data.Q(iQ).rec(irec).rx(irx).sig(isig).t1 = noiseout.t';
                    data.Q(iQ).rec(irec).rx(irx).sig(isig).v1 = noiseout.v(:,imidirx)';
                    % backup for undo:
                    data.Q(iQ).rec(irec).rx(irx).sig(isig).t0 = data.Q(iQ).rec(irec).rx(irx).sig(isig).t1;
                    data.Q(iQ).rec(irec).rx(irx).sig(isig).v0 = data.Q(iQ).rec(irec).rx(irx).sig(isig).v1;
                end
                
                % at the moment set to zero
                % LATER: collect sig3 from _d1,_d2,... data files
                data.Q(iQ).rec(irec).rx(irx).sig(3).recorded = 0;
                data.Q(iQ).rec(irec).rx(irx).sig(4).recorded = 0;
            end
        end
    end % for all recordings
    data.Q(iQ).q = mean(qvalue);      % value of pulse moment [A.s]
    clear qvalue
end

