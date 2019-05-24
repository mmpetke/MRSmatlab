function data = mrs_load_gmrconverted(sounding_path)
% based on mrs_load_numisraw
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
% ed. 20jan2010 JW
% =========================================================================

%% Sounding path ----------------------------------------------------------
% % get path to sounding
if nargin < 1
    sounding_path = uigetdir;
end

if sounding_path == 0   % aborting
    data = 0;
    return
end

data.info.path = sounding_path;

% check if GMR data have been converted
if isdir([sounding_path, 'converted'])
    % proceed
else
    error('Folder "converted" is missing!')
end

%% get .inp info ----------------------------------------------------------
fidinp = fopen([sounding_path, 'GMRdata.inp'],'r');
nchannels = fscanf(fidinp, '%*s %*s %d \n',1);
itable = textscan(fidinp,'%*f\t %f\t %f\t %f\t %f \n',nchannels,'Headerlines',1);

tmp = zeros(nchannels,4);
for n=1:4
    tmp(1:nchannels,n)=cell2mat(itable(n));
end

irx = 0;
for iCh=1:nchannels     % JW: This means that one irx is the transmitter, right? MMP:Yes
    
    if tmp(iCh,1)==1  % Tx/Rx
        irx = irx + 1;
        data.info.rxinfo(irx).channel   = iCh;
        data.info.rxinfo(irx).task      = 1;
        data.info.rxinfo(irx).looptype  = tmp(iCh,2);
        data.info.rxinfo(irx).loopsize  = tmp(iCh,3);
        data.info.rxinfo(irx).loopturns = tmp(iCh,4);
        data.info.txinfo.channel   = iCh;
        data.info.txinfo.looptype  = tmp(iCh,2);
        data.info.txinfo.loopsize  = tmp(iCh,3);
        data.info.txinfo.loopturns = tmp(iCh,4);
    elseif tmp(iCh,1)==2 % Rx
        irx = irx + 1;
        data.info.rxinfo(irx).channel   = iCh;
        data.info.rxinfo(irx).task      = 1;
        data.info.rxinfo(irx).looptype  = tmp(iCh,2);
        data.info.rxinfo(irx).loopsize  = tmp(iCh,3);
        data.info.rxinfo(irx).loopturns = tmp(iCh,4);
    elseif tmp(iCh,1)==3 % NC
        irx = irx + 1;
        data.info.rxinfo(irx).channel   = iCh;
        data.info.rxinfo(irx).task      = 2;
        data.info.rxinfo(irx).looptype  = tmp(iCh,2);
        data.info.rxinfo(irx).loopsize  = tmp(iCh,3);
        data.info.rxinfo(irx).loopturns = tmp(iCh,4);
    else    % unconnected
%         data.info.rxinfo(irx).channel = iCh;
%         data.info.rxinfo(irx).task    = 0;
    end
end

fS     = fscanf(fidinp, '%*s %*s %d \n',1);
nq     = fscanf(fidinp, '%*s %*s %d \n',1);
nrecs  = fscanf(fidinp, '%*s %*s %d \n',1);
qtable = textscan(fidinp,'%f %f %f ',nq,'Headerlines',1);

qi        = qtable{1}; % Pulse moment indices
q         = qtable{2}; % [A.s]
q2        = qtable{3}; % [A.s] 

% get detailed pulse parameter

a = []; 
while ~strcmp('q1 ',a);
    a = fgetl(fidinp);
end
q1pulse =  fscanf(fidinp, '%f', [length(qi),nrecs])'; 

a = []; while ~strcmp('q1phase ',a);a = fgetl(fidinp);end
q1phase =  fscanf(fidinp, '%f', [length(qi),nrecs])'; 

a = []; while ~strcmp('q2 ',a);a = fgetl(fidinp);end
q2pulse =  fscanf(fidinp, '%f', [length(qi),nrecs])'; 

a = []; while ~strcmp('q2phase ',a);a = fgetl(fidinp);end
q2phase =  fscanf(fidinp, '%f', [length(qi),nrecs])'; 

fclose(fidinp);



%% Assemble output: data ---------------------------------------------
TX = data.info.txinfo.channel; %transmitter used later
for iQ = 1:length(qi)
    data.Q(iQ).q = q(iQ);           % value of pulse moment [A.s]
    if q2 ~= q
        data.Q(iQ).q2 = q2(iQ);     % value of pulse moment 2 [A.s]
    end

       
            % get raw data recordings for this q
            data.info.device = 'GMR';
            nrecs = length(dir([sounding_path,'converted',filesep,'Q',num2str(qi(iQ)),'#*.Pro'])); % GMR data converted to numispoly format
            for irec = 1:nrecs
                data.Q(iQ).rec(irec).info.file = ...
                    [sounding_path,'converted',filesep,'Q', ...
                                num2str(qi(iQ)),'#',num2str(irec),'.Pro'];
                polyout = mrs_readpoly(data.Q(iQ).rec(irec).info.file, fS, nchannels);
                
                fT     = polyout.transmitter.FreqReelReg9833;   % CHECK vs LINE 107
                fS     = polyout.receiver(TX).SampleFrequency;   % CHECK vs dt LINE 113
                %data.info.loopturns = polyout.header.TConfig.TurnNumber;
                data.Q(iQ).rec(irec).info.fT = fT;         % transmitter frequency
                data.Q(iQ).rec(irec).info.fS = fS;         % sampling frequency
                
                % collect timing parameters (same for all receivers; maybe different for q?)
                data.Q(iQ).rec(irec).info.timing.tau_p1 = (...        % duration of pulse1 (pulse is saved with 50kHz sampling)
                    polyout.receiver(TX).ProtonCount.Pulse1)/1/fS/5; 
                data.Q(iQ).rec(irec).info.timing.tau_dead1 = (...     % time between end of pulse1 and start of sig1
                    polyout.receiver(TX).ProtonCount.Pause2)/1/fS;
                data.Q(iQ).rec(irec).info.timing.tau_d = (...         % delay time between end of pulse1 and start of pulse2
                    polyout.receiver(TX).ProtonCount.Pause2 +  ...
                    polyout.receiver(TX).ProtonCount.Signal1 + ...
                    polyout.receiver(TX).ProtonCount.Pause3 + ...
                    polyout.receiver(TX).ProtonCount.Synchro2 + ...
                    polyout.receiver(TX).ProtonCount.Pause4 + ...
                    polyout.receiver(TX).ProtonCount.Adjust2)/1/fS;
                data.Q(iQ).rec(irec).info.timing.tau_p2 = (...        % duration of pulse2
                    polyout.receiver(TX).ProtonCount.Pulse2)/1/fS/5;
                data.Q(iQ).rec(irec).info.timing.tau_dead2 = (...     % time between end of pulse2 and start of sig2
                    polyout.receiver(TX).ProtonCount.Pause5)/1/fS;                
                
                % generator phase (same for all receivers & signals)
                data.Q(iQ).rec(irec).info.phases.phi_gen(1)   = 0; % rad
                data.Q(iQ).rec(irec).info.phases.phi_gen(2)   = q1phase(irec,iQ); % rad
                data.Q(iQ).rec(irec).info.phases.phi_gen(3:4) = q2phase(irec,iQ); % rad
                
                % amplifier phase (same for all receivers)
                % this SHOULD be different for all receivers! CHECK.
                data.Q(iQ).rec(irec).info.phases.phi_amp = ...
                    polyout.receiver(TX).ProtonModulePhase.Phase; % rad

                % signal phases (same for all receivers)
                % phase of noise
                % time lag between Tx AD and Rx AD is 200us
                data.Q(iQ).rec(irec).info.phases.phi_timing(1) = -200e-6*2*pi*fT;
                
                % phase of fid1
                % take care pulse sampling is still 50kHz
                data.Q(iQ).rec(irec).info.phases.phi_timing(2) = phasewrap_intern(...
                            data.Q(iQ).rec(irec).info.phases.phi_timing(1) + (...
                                fS/50000*polyout.receiver(TX).ProtonCount.Pulse1 + ...
                                polyout.receiver(TX).ProtonCount.Pause2  ...
                                )/1/fS*2*pi*fT);     
                
                % phase of fid2
                data.Q(iQ).rec(irec).info.phases.phi_timing(3) = phasewrap_intern(...
                            data.Q(iQ).rec(irec).info.phases.phi_timing(2) + (...
                                polyout.receiver(TX).ProtonCount.Signal1 + ...
                                polyout.receiver(TX).ProtonCount.Pause3 + ...
                                fS/50000*polyout.receiver(TX).ProtonCount.Pulse2 + ...
                                polyout.receiver(TX).ProtonCount.Pause5 ...
                                )/1/fS*2*pi*fT);

                % phase of echo 
                data.Q(iQ).rec(irec).info.phases.phi_timing(4) = phasewrap_intern(...
                            data.Q(iQ).rec(irec).info.phases.phi_timing(3) + (...
                                polyout.receiver(TX).ProtonCount.Pause6 ...
                                )/1/fS*2*pi*fT);     
                    
                irx = 0;               
                for ipolyrx  = 1:length(polyout.receiver)
                    if ~isempty(polyout.receiver(ipolyrx).Signal) % if connected
                        irx = irx + 1;
%                         data.Q(iQ).rec(irec).rx(irx).connected = 1;
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
%                     else
%                         data.Q(iQ).rec(irec).rx(irx).connected = 0;
                    end
                end
                data.info.rxtask = zeros(1,irx); % initialize rx task
            end % for all recordings
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