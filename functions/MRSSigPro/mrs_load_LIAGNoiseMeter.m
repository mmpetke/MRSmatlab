function data = mrs_load_LIAGNoiseMeter(sounding_path)
% function data = mrs_load_LIAGNoiseMeter(sounding_path)
% 
% Load LIAG Noise Meter data data. 

% Input: 
%   sounding_path - path to sounding folder (from MRSImport)
% 
% Output: 
%   data          - see MRSmatlab documentation
% 
% Oct2018
% MMP
% =========================================================================

%% Sounding path & filenames ----------------------------------------------

data.info.path = sounding_path;
filename = uigetfile(...
                    [sounding_path,'\*.txt'], ...
                    'Pick a the noise data file (*.txt)');

rawdata     = dlmread([sounding_path '\' filename],';');

% some parameter
parameter.fS    = 51200;
parameter.gain  = 500;
parameter.turns = 12;
parameter.size  = 10;

% LIAG Noise Meter records just one record --> separate into single
% recordings of one second
nS              = 51200; % select just one second 
% check for how many seconds been recorded
nsec            = floor(size(rawdata,1)/parameter.fS);
% check if two loops were recorded
nloops          = size(rawdata,2);



Q = 0;

data.info.txinfo.channel   = 0;
data.info.txinfo.looptype  = -1;
data.info.txinfo.loopsize  = -1;
data.info.txinfo.loopturns = -1;    % not relevant

%% Assemble output: data --------------------------------------------------
data.info.device = 'LIAGNoiseMeter';

for iQ = 1:length(Q)
    
    % determine # recordings for this Q
    allREC = [1:1:nsec];
    allNSE = [];
    if isempty(allNSE)
        nosig1 = 1;
    else
        nosig1 = 0;
    end

    for irec = 1:length(allREC)
        data.Q(iQ).q = 0;                  % just noise one record
        data.Q(iQ).rec(irec).info.fS = parameter.fS;   % sampling frequency
        data.Q(iQ).rec(irec).info.fT = 2000;       % transmitter frequency
        data.Q(iQ).rec(irec).info.timing.tau_p1 = 0;       % duration of pulse1
        data.Q(iQ).rec(irec).info.timing.tau_dead1 = 0;    % time between end of pulse1 and start of sig1
        data.Q(iQ).rec(irec).info.timing.tau_d = 0;        % delay time between end of pulse1 and start of pulse2
        data.Q(iQ).rec(irec).info.timing.tau_p2 = 0;       % duration of pulse2
        data.Q(iQ).rec(irec).info.timing.tau_dead2 = 0;    % time between end of pulse2 and start of sig2

        % generator phase (same for all receivers)
        data.Q(iQ).rec(irec).info.phases.phi_gen(1)   = 0; % [rad]
        data.Q(iQ).rec(irec).info.phases.phi_gen(2:4) = 0; % [rad]

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
        
        data.Q(iQ).rec(irec).info.phases.phi_timing(1:4)=0;
           
        % get first loop
        irx  = 1;  
            data.info.rxinfo(irx).channel = irx;
            data.info.rxinfo(irx).task    = 1;      % default
            data.info.rxinfo(irx).looptype  = -1;   % n/a
            data.info.rxinfo(irx).loopsize  = -1;   % n/a
            data.info.rxinfo(irx).loopturns = -1;   % n/a
            
            isig = 2;    % only sig2 here
            data.Q(iQ).rec(irec).rx(irx).sig(isig).recorded = 1;
            data.Q(iQ).rec(irec).rx(irx).sig(isig).t1 = ([0:1:length(rawdata(1:nS,1))-1]/parameter.fS);
            data.Q(iQ).rec(irec).rx(irx).sig(isig).v1 = (rawdata(1+(irec-1)*nS:irec*nS,1)/parameter.gain/parameter.turns/(parameter.size^2)).';
            % backup for undo:
            data.Q(iQ).rec(irec).rx(irx).sig(isig).t0 = data.Q(iQ).rec(irec).rx(irx).sig(isig).t1;
            data.Q(iQ).rec(irec).rx(irx).sig(isig).v0 = data.Q(iQ).rec(irec).rx(irx).sig(isig).v1;
            
            data.Q(iQ).rec(irec).rx(irx).sig(1).recorded = 0;
            data.Q(iQ).rec(irec).rx(irx).sig(3).recorded = 0;
            data.Q(iQ).rec(irec).rx(irx).sig(4).recorded = 0;
            
        if nloops==2
            irx=2;
            data.info.rxinfo(irx).channel = irx;
            data.info.rxinfo(irx).task    = 2;      % default
            data.info.rxinfo(irx).looptype  = -1;   % n/a
            data.info.rxinfo(irx).loopsize  = -1;   % n/a
            data.info.rxinfo(irx).loopturns = -1;   % n/a
            
            isig = 2;    % only sig2 here
            data.Q(iQ).rec(irec).rx(irx).sig(isig).recorded = 1;
            data.Q(iQ).rec(irec).rx(irx).sig(isig).t1 = ([0:1:length(rawdata(1:nS,1))-1]/parameter.fS);
            data.Q(iQ).rec(irec).rx(irx).sig(isig).v1 = (rawdata(1+(irec-1)*nS:irec*nS,2)/parameter.gain/parameter.turns/(parameter.size^2)).';
            % backup for undo:
            data.Q(iQ).rec(irec).rx(irx).sig(isig).t0 = data.Q(iQ).rec(irec).rx(irx).sig(isig).t1;
            data.Q(iQ).rec(irec).rx(irx).sig(isig).v0 = data.Q(iQ).rec(irec).rx(irx).sig(isig).v1;
            
            data.Q(iQ).rec(irec).rx(irx).sig(1).recorded = 0;
            data.Q(iQ).rec(irec).rx(irx).sig(3).recorded = 0;
            data.Q(iQ).rec(irec).rx(irx).sig(4).recorded = 0;
        end
    end
end 
end

