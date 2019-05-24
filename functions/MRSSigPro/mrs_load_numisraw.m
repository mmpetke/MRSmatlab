function data = mrs_load_numisraw(sounding_path)
% ex function handles = jOpenSingleData_numisstacker(handles)
% 
% REQUIRES SOME CLEANUP (JW 02dec2010)
% 
% Check if amplifier phase is the same for all receivers (probably not).
% 
% Load NUMIS raw data (Plus & Poly). 
% Requires standard Prodiviner file format:
% <SoundingXXXX> contains .inp file, .0# files and RawData Folder
% 
% Input: 
%   (handles )      - optional: from numisstacker gui
% 
% Output: 
%   fdata.
%       enveloppe   - now includes fref from .0 file
%       datainfo 
%       currentpath
%       recordings  - single recordings (required for numisstacker)
% 
% Calls: 
%   DAT_readPoly (NUMISpoly), readBinaryDataFromFile (NUMISplus)
%
% Jan Walbrecker, 26.oct.2010
% JW 20jun2011
% =========================================================================

%% CHECK INPUT ------------------------------------------------------------

% read all files if singlefile is not passed
if nargin < 2
    singlefile = [];
    read_singlefile = 0;
else
    read_singlefile = 1;
end

% % get path to sounding
if nargin < 1
    sounding_path = uigetdir;
    sounding_path = [sounding_path filesep];
end

if sounding_path == 0   % aborting
    data = 0;
    return
end


%% Sounding path ----------------------------------------------------------

data.info.path = sounding_path;

% old Numis not supported
if isdir([sounding_path, 'RawDataOld'])
    error('Not supported. Call OpenSingleData instead!')
end

% determine NUMIS version
if isdir([sounding_path, 'RawData'])
    if ~isempty(dir([sounding_path,'RawData',filesep,'*#*.Pro']));
        numisversion = 4;  % NUMISpoly (Prodiviner v4)
    elseif ~isempty(dir([sounding_path,'RawData',filesep,'*#*.raw']));
        numisversion = 3;  % NUMISplus (Prodiviner v3)
    end
else
    error('Rawdata are missing!')
end

%% read .inp file: get q and fit startvalues ------------------------------
fidinp = fopen([sounding_path, 'NumisData.inp'],'r');
lines  = 0;                  % count # lines in file
while fgets(fidinp)~= -1
    lines=lines+1;
end
fseek(fidinp,0,'bof');       % return to bof
inp_header = textscan(fidinp, '%*s %f %*1c %f %*[^\n]', 1, 'Headerlines', 1);
inp_data   = textscan(fidinp, '%f %f %f %f %f %f %f %f %*[^\n]', lines-5, 'Headerlines', 4);
fclose(fidinp);

iq = find(inp_data{2} ~= 0 & inp_data{3} ~= 0); % delete skipped q's

qi        = inp_data{1}(iq);          % Pulse moment indices
q         = inp_data{2}(iq)/1000;     % [A.s]  ex pm_vec
% v0_start  = inp_data{3}(iq)/1e9;      % [V]
% T2_start  = inp_data{4}(iq)/1000;     % [s]
% fL_start  = inp_data{7}(iq);          % [Hz]  ex Freq_start
% Phi_start = inp_data{8}(iq)/180*pi;   % [rad]
% Phi_start(Phi_start > pi) = Phi_start(Phi_start > pi) - 2*pi; % phase 180 -> -180

data.info.txinfo.channel   = 0;     % separate from receiver channels in NUMIS
data.info.txinfo.looptype  = inp_header{1};
data.info.txinfo.loopsize  = inp_header{2};

%% read .in2 file (if existent): get q and fit startvalues ----------------
fidin2 = fopen([sounding_path, 'NumisData.in2'],'r');
if (fidin2 ~= -1)
    lines = 0;                  % count # lines in file
    while fgets(fidin2)~= -1
        lines=lines+1;
    end
    fseek(fidin2,0,'bof');
    
    in2_header = textscan(fidin2, '%*s %f %*1c %f %*[^\n]', 1, 'Headerlines', 1);
    in2_data   = textscan(fidin2, '%f %f %f %f %f %f %f %f %*[^\n]', lines-5, 'Headerlines', 4);
    fclose(fidin2);
    
    iq2 = find(in2_data{2} ~= 0 | in2_data{3} ~= 0);     % delete skipped pulsemoments; skipped pulsemoments are identified by the fact that neither q nor the amplitude "e2" are zero
    
    if size(qi) ~= size(in2_data{1}(iq));  % check: # of qi in inp & in2 should be the same!
        error('Error! Different missing-q-indices in .inp & .in2 file!')
    end
    q2         = in2_data{2}(iq2)/1000;     % [A.s]
%     v0_start2  = in2_data{3}(iq2)/1e9;      % [V]
%     T2_start2  = in2_data{4}(iq2)/1000;     % [s]
%     fL_start2  = in2_data{7}(iq2);          % [Hz]
%     Phi_start2 = in2_data{8}(iq2)/180*pi;   % [rad]
%     Phi_start2(Phi_start2 > pi) = Phi_start2(Phi_start2 > pi) - 2*pi; % phase 180 -> -180    
end

%% Assemble output: data ---------------------------------------------

for iQ = 1:length(qi)
    
    % FOR EACH Q!
    % PROBABLY MOST OF .0 FILE CONTENT IS OBSOLETE - phi_gen?
    % determine fT, phi_ampl, phi_gen for this q
    fid0 = fopen([sounding_path, 'NumisData.0', num2str(qi(iQ))],'r');
    A    = textscan(fid0, '%f %f %f %*[^\n]', 1);           % A - like in prodiviner manual
%     B    = textscan(fid0, '%f %f %f %f %f %f %*[^\n]', 1);  % B - like in prodiviner manual
    fclose(fid0);
%     fT = A{1};
%     data.info.fT       = A{1};          % [Hz] CHECK: identisch mit fT in .Pro / .raw files fuer dieses q?
    phi_gen  = A{2}*pi/180;   % [rad]
    phi_amp  = A{3}*pi/180;   % [rad] - OBSOLETE FOR POLY; replace by Proton phase parameters
%     data.info.tau_p    = B{3}*4/fT;     % [s] Pulse duration - OBSOLETE; replace by Proton timing parameters
%     data.info.tau_dead = B{4}*0.25/fT;  % [s] Dead time - OBSOLETE; replace by Proton timing parameters
%     data.info.tau_d    = B{3}*4/fT + B{4}*0.25/fT + B{5}*4/fT + B{6}*0.25/fT; % [s] - OBSOLETE; replace by Proton timing parameters
%     data.info.dt       = 1/(0.25*fT);

    % value of pulse moment
    data.Q(iQ).q = q(iQ);                   % [A.s]
    if (fidin2 ~= -1)
        data.Q(iQ).q2  = q2(iQ);            % [A.s]
    end

    switch numisversion
        
        case 4 % NUMIS POLY
            % get raw data recordings for this q
            data.info.device = 'NUMISpoly';
            nrecs = length(dir([sounding_path,'RawData',filesep,'Q',num2str(qi(iQ)),'#*.Pro'])); % NUMISPOLY
            for irec = 1:nrecs
                data.Q(iQ).rec(irec).info.file = ...
                    [sounding_path,'RawData',filesep,'Q', ...
                                num2str(qi(iQ)),'#',num2str(irec),'.Pro'];
                polyout = mrs_readpoly(data.Q(iQ).rec(irec).info.file);
                
                fT     = polyout.transmitter.FreqReelReg9833;   % CHECK vs LINE 107
                fS     = polyout.receiver(1).SampleFrequency;   % CHECK vs dt LINE 113
                data.info.txinfo.loopturns = polyout.header.TConfig.TurnNumber;
                
                % ASSEMBLING .info
                data.Q(iQ).rec(irec).info.fT = fT;         % transmitter frequency
                data.Q(iQ).rec(irec).info.fS = fS;         % sampling frequency
                
                % collect timing parameters (same for all receivers; maybe different for q?)
                data.Q(iQ).rec(irec).info.timing.tau_p1 = (...        % duration of pulse1
                    polyout.receiver(1).ProtonCount.Pulse1)/4/fS; 
                data.Q(iQ).rec(irec).info.timing.tau_dead1 = (...     % time between end of pulse1 and start of sig1
                    polyout.receiver(1).ProtonCount.Pause2)/4/fS;
                data.Q(iQ).rec(irec).info.timing.tau_d = (...         % delay time between end of pulse1 and start of pulse2
                    polyout.receiver(1).ProtonCount.Pause2 +  ...
                    polyout.receiver(1).ProtonCount.Signal1 + ...
                    polyout.receiver(1).ProtonCount.Pause3 + ...
                    polyout.receiver(1).ProtonCount.Synchro2 + ...
                    polyout.receiver(1).ProtonCount.Pause4 + ...
                    polyout.receiver(1).ProtonCount.Adjust2)/4/fS;
                data.Q(iQ).rec(irec).info.timing.tau_p2 = (...        % duration of pulse2
                    polyout.receiver(1).ProtonCount.Pulse2)/4/fS;
                data.Q(iQ).rec(irec).info.timing.tau_dead2 = (...     % time between end of pulse2 and start of sig2
                    polyout.receiver(1).ProtonCount.Pause5)/4/fS;                
                
                % generator phase (same for all receivers)
                data.Q(iQ).rec(irec).info.phases.phi_gen(1)   = 0; % [rad]; 
                data.Q(iQ).rec(irec).info.phases.phi_gen(2:4) = phi_gen; % [rad]; same for both pulses
                
                % amplifier phase (same for all receivers)
                % this SHOULD be different for all receivers! CHECK.
                data.Q(iQ).rec(irec).info.phases.phi_amp = ...
                    polyout.receiver(1).ProtonModulePhase.Phase; % rad

                % signal phases (same for all receivers)
                % phase of noise
                data.Q(iQ).rec(irec).info.phases.phi_timing(1) = 0;
                
                % phase of fid1
                data.Q(iQ).rec(irec).info.phases.phi_timing(2) = phasewrap_intern(...
                            data.Q(iQ).rec(irec).info.phases.phi_timing(1) + (...
                                polyout.receiver(1).ProtonCount.Noise + ...
                                polyout.receiver(1).ProtonCount.Pause0 + ...
                                polyout.receiver(1).ProtonCount.Synchro1 + ...
                                polyout.receiver(1).ProtonCount.Pause1 + ...
                                polyout.receiver(1).ProtonCount.Adjust1 + ...
                                polyout.receiver(1).ProtonCount.Pulse1 + ...
                                polyout.receiver(1).ProtonCount.Pause2  ...
                                )/4/fS*2*pi*fT);     % check the divide by 4. Always the case? Or only if sampleratedivider = 4?
                
                % phase of fid2
                data.Q(iQ).rec(irec).info.phases.phi_timing(3) = phasewrap_intern(...
                            data.Q(iQ).rec(irec).info.phases.phi_timing(2) + (...
                                polyout.receiver(1).ProtonCount.Signal1 + ...
                                polyout.receiver(1).ProtonCount.Pause3 + ...
                                polyout.receiver(1).ProtonCount.Synchro2 + ...
                                polyout.receiver(1).ProtonCount.Pause4 + ...
                                polyout.receiver(1).ProtonCount.Adjust2 + ...
                                polyout.receiver(1).ProtonCount.Pulse2 + ...
                                polyout.receiver(1).ProtonCount.Pause5 ...
                                )/4/fS*2*pi*fT);

                % phase of echo 
                data.Q(iQ).rec(irec).info.phases.phi_timing(4) = phasewrap_intern(...
                            data.Q(iQ).rec(irec).info.phases.phi_timing(3) + (...
                                polyout.receiver(1).ProtonCount.Pause6 ...
                                )/4/fS*2*pi*fT);     
                    
%                 % determine which receivers are connected
%                 for irx  = 1:length(polyout.receiver)
%                     rx_connected(irx) = ~isempty(polyout.receiver(irx).Signal)
%                 end
                               
                % assembling transmitter data
                data.Q(iQ).rec(irec).tx.t1 = polyout.transmitter.Pulse(1).t;
                data.Q(iQ).rec(irec).tx.I1 = polyout.transmitter.Pulse(1).I;
                if length(polyout.transmitter.Pulse) > 2
                    data.Q(iQ).rec(irec).tx.t2 = polyout.transmitter.Pulse(2).t;
                    data.Q(iQ).rec(irec).tx.I2 = polyout.transmitter.Pulse(2).I;
                end
                
                % assembling receiver data
                irx = 0;
                for ipolyrx  = 1:length(polyout.receiver)   % should be 4
                    if ~isempty(polyout.receiver(ipolyrx).Signal) % check if rx was connected
                        irx = irx + 1;
%                         data.Q(iQ).rec(irec).rx(irx).connected = 1;
                        
                        % set rx info
                        data.info.rxinfo(irx).channel  = ipolyrx;
                        if irx == 1
                            data.info.rxinfo(irx).task = 1; % default task 
                        else
                            data.info.rxinfo(irx).task = 2; % default task 
                        end
                        data.info.rxinfo(irx).looptype  = polyout.receiver(irx).ProtonLoop.Shape;
                        data.info.rxinfo(irx).loopsize  = polyout.receiver(irx).ProtonLoop.Size;
                        data.info.rxinfo(irx).loopturns = polyout.receiver(irx).ProtonLoop.NbTurn;

                        for isig = 1:length(polyout.receiver(ipolyrx).Signal)
                            if ~isempty(polyout.receiver(ipolyrx).Signal(isig).v) % if recorded
                                data.Q(iQ).rec(irec).rx(irx).sig(isig).recorded = 1;
                                data.Q(iQ).rec(irec).rx(irx).sig(isig).t1 = ...
                                    polyout.receiver(ipolyrx).Signal(isig).t;
                                data.Q(iQ).rec(irec).rx(irx).sig(isig).v1 = ...
                                        polyout.receiver(ipolyrx).Signal(isig).v - mean(polyout.receiver(ipolyrx).Signal(isig).v);
                                % backup for undo:
                                data.Q(iQ).rec(irec).rx(irx).sig(isig).t0 = data.Q(iQ).rec(irec).rx(irx).sig(isig).t1;
                                data.Q(iQ).rec(irec).rx(irx).sig(isig).v0 = data.Q(iQ).rec(irec).rx(irx).sig(isig).v1;
                            else
                                data.Q(iQ).rec(irec).rx(irx).sig(isig).recorded = 0;
                                data.Q(iQ).rec(irec).rx(irx).sig(isig).v1 = [];
                            end
                        end
                    end
                end
            end % for all recordings
            
        case 3 % NUMIS PLUS
            
            % get raw data recordings for this q
            data.info.device = 'NUMISplus'; 
            NUMRAWFILE='Q';
            nrecs = length(dir([sounding_path, 'RawData' filesep NUMRAWFILE, num2str(qi(iQ)), '#*.raw'])); % NUMISPLUS
            if ~nrecs
               NUMRAWFILE='q';
               nrecs = length(dir([sounding_path, 'RawData' filesep NUMRAWFILE, num2str(qi(iQ)), '#*.raw'])); % NUMISPLUS 
            end
            
            for irec = 1:nrecs
                data.Q(iQ).rec(irec).info.file = ...
                    [sounding_path,'RawData',filesep,NUMRAWFILE, ...
                                num2str(qi(iQ)),'#',num2str(irec),'.raw'];                
                plusout = mrs_readplus(data.Q(iQ).rec(irec).info.file);
                
                data.info.txinfo.looptype  = plusout.header.TConfig.LoopType;
                data.info.txinfo.loopsize  = plusout.header.TConfig.LoopSize;
                data.info.txinfo.loopturns = plusout.header.TConfig.TurnNumber; 
                
                fT     = plusout.header.TConfig.FLarmorFreq;   % CHECK vs LINE 107
                fS     = 1/diff(plusout.data(1:2,1));
                
                data.Q(iQ).rec(irec).info.fT = fT;         % transmitter frequency
                data.Q(iQ).rec(irec).info.fS = fS;         % sampling frequency
                
                % collect timing parameters (same for all receivers; maybe different for q?)
                data.Q(iQ).rec(irec).info.timing.tau_p1 = ...         % duration of pulse1
                    plusout.header.TTimeConfig.TMPulse1*4/fT; 
                data.Q(iQ).rec(irec).info.timing.tau_dead1 = ...     % time between end of pulse1 and start of sig1
                    plusout.header.TTimeConfig.TDSignal1/4/fT; 
                data.Q(iQ).rec(irec).info.timing.tau_d = (...         % delay time between end of pulse1 and start of pulse2
                    plusout.header.TTimeConfig.TDSignal1/4/fT +  ...
                    plusout.header.TTimeConfig.TMSignal1*4/fT + ...
                    plusout.header.TTimeConfig.TDPulse2*4/fT);
                data.Q(iQ).rec(irec).info.timing.tau_p2 = ...        % duration of pulse2
                    plusout.header.TTimeConfig.TMPulse2*4/fT;
                data.Q(iQ).rec(irec).info.timing.tau_dead2 = ...     % time between end of pulse2 and start of sig2
                    plusout.header.TTimeConfig.TDSignal2/4/fT;
                
                % generator phase (same for all receivers)
                data.Q(iQ).rec(irec).info.phases.phi_gen(1)   = 0; % [rad]; 
                data.Q(iQ).rec(irec).info.phases.phi_gen(2:4) = phi_gen; % [rad]; same for both pulses                
                
                % amplifier phase
                data.Q(iQ).rec(irec).info.phases.phi_amp = phi_amp; % rad
%                 data.Q(iQ).rec(irec).info.phases.phi_ampl = phi_amp; % rad

                % signal phases (same for all receivers)
                % phase of noise
                data.Q(iQ).rec(irec).info.phases.phi_timing(1) = 0;
                
                % phase of fid1
                data.Q(iQ).rec(irec).info.phases.phi_timing(2) = 0;
                
                % phase of fid2
                data.Q(iQ).rec(irec).info.phases.phi_timing(3) = 0;

                % phase of echo 
                data.Q(iQ).rec(irec).info.phases.phi_timing(4) = 0;
                    
                data.info.rxinfo(1).channel = 1;
                data.info.rxinfo(1).task    = 1;  % always 1 for numisplus
                data.info.rxinfo(1).looptype  = plusout.header.TConfig.LoopType; % set same as TX per default
                data.info.rxinfo(1).loopsize  = plusout.header.TConfig.LoopSize; % set same as TX per default
                data.info.rxinfo(1).loopturns = plusout.header.TConfig.TurnNumber; % set same as TX per default
                    
                S    = [2 6 10 12];     % column indices in numis file
                D    = plusout.data;
%                 data.Q(iQ).rec(irec).rx(1).connected = 1;
                for isig = 1:4
                    if ~isnan(D(:,S(isig))) % if recorded
                        data.Q(iQ).rec(irec).rx(1).sig(isig).recorded = 1;
                        data.Q(iQ).rec(irec).rx(1).sig(isig).t1 = D(:,1)';
                        data.Q(iQ).rec(irec).rx(1).sig(isig).v1 = ...
                            D(~isnan(D(:,S(isig))),S(isig))' + 1i*D(~isnan(D(:,S(isig))),S(isig)+1)';
                        % backup for undo:
                        data.Q(iQ).rec(irec).rx(1).sig(isig).t0 = data.Q(iQ).rec(irec).rx(1).sig(isig).t1;
                        data.Q(iQ).rec(irec).rx(1).sig(isig).v0 = data.Q(iQ).rec(irec).rx(1).sig(isig).v1;
                    else
                        data.Q(iQ).rec(irec).rx(1).sig(isig).recorded = 0;
                        data.Q(iQ).rec(irec).rx(1).sig(isig).v1 = [];
                    end
                end
            end % for all recordings            
    end
end

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