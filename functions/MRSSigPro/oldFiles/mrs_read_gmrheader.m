function header = mrs_read_gmrheader(hfile)
% function header = mrs_read_gmrheader(hfile)
%
% Read GMR header file. 
% 
% Vista Clara header format:
% 1	 Pulse Sequence ID	1:FID; 2:90-90 T1; 3: Spin Echo; 4: 4-phase T1; (1)
% 2	 Transmit Frequency (Hz)	e.g. 2000; (0)
% 3	 Max DC Bus Voltage (V)	e.g. 225
% 4	 Transmit Pulse Length (ms)	e.g. 20; (40)
% 5	 Interpulse Delay (ms)	e.g. 300; (150)
% 6	 Repetition Time (s)	e.g. 6; (8)
% 7	 # Data records per file: For Auto q: # Pulse moments
%                            For Custom q: # Stacks 	e.g. 12; (16)
% 8	 Tuning Capacitance (uF)	e.g. 7.5 (15.5)
% 9	 Transmitter Version 1 to 3, Determines TX & RX gains (any hardware)
% 10 GMR DAQ Software Version	1.0 – 2.0
%                               If 1 -> dead time (instr) = 8ms
%                               Otherwise RX deadtime in col 12
%                               Determines firmware / software / acquisition changes
% 11	# Interleaves   1-3
% 12	Rx Dead Time (ms)	4-8 (5)
% 13	Pulse Moment Sampling Method	0: Auto q-sampling; 1: Custom q-sampling (0)
% 14	Preamp Gain	500; 1000 (500)
% 15	Raw Data Sample Rate (Hz)	(50000)
% 16	TX/RX Expansion unit  % Could be replaced by “Number of Channels”	0=4 channels 1=8channels
% 17	Blank	
% 18	Blank	
% 19	Blank	
% 20	Blank	
% 21	Coil 1 Function	0: Detection; 1: Noise; 2: None (0)
% 22	Coil 1 Geometry	1: Square; 2: Circle; 3: Figure 8
% 23	Coil 1 Diameter (m)	e.g. 100; (0)
% 24	Coil 1 # Turns	e.g. 2; (1)
% 25	Coil 1 Inclination Angle	e.g. 68; (0)
% 26	Coil 1 Declination Angle	e.g. 5; (0)
% 27	Coil 2 Function	0: Detection; 1: Noise; 2: None
% 28	…	
% …	…	
% 68	Coil 8 Declination Angle	e.g. 5; (0)
% 
% Input:
%   hfile - full path to file
%
% 10jun2011
% mod. 23mar2012 JW
% =========================================================================

if nargin < 1
    hfile = 'c:\Users\Jan\Documents\su\matlab\nmr\data\gmr_NE_8apr_2009\apr_8_09_site58b_40msfid_225vdc';
end

% open header file
fidh    = fopen(hfile,'r');     % open header file for read
hform1  = '%f ';                % format of header entry

% determine DAQ version (entry 10 in header file)
hform      = repmat(hform1,1,10);          % header format 
fcontent   = textscan(fidh, hform, 1);     % read 11 header entries (11 is the minimum # of entries for all DAQ versions)
DAQversion = ext_roundn(fcontent{10},-2);

% exit if DAQ version is not supported
supported  = [0.00 1.00 2.00 2.08 2.50 2.90 2.93 2.97];
if ~ismember(DAQversion,supported)
    error('Unknown DAQ version!')
end

% handle read in of different headers for different GMR versions
switch DAQversion
    
    case 0.00               % header has 10 entries
        
        fclose(fidh);       % close header file
        
        expUnt     = 0;         % expansion unit (0=4channels, 1=8channels)
        preampgain = 500;       % preamplifier gain for receiver
        fS         = 50e3;      % sampling frequency
    
    case 1.00               % header has 11 entries
        
        % reread header
        fseek(fidh,0,'bof');                % return to begin of header file
        hform    = repmat(hform1,1,11);     % 11 header entries in vers 1.0
        fcontent = textscan(fidh, hform, 1); 
        fclose(fidh);       % close header file
        
        expUnt     = 0;         % expansion unit (0=4channels, 1=8channels)
        preampgain = 500;       % preamplifier gain for receiver
        fS         = 50e3;      % sampling frequency
    
    case {2.00, 2.08, 2.50, 2.90, 2.93, 2.97} % header has 68 entries
        
        % reread header
        fseek(fidh,0,'bof');                % return to begin of header file
        hform    = repmat(hform1,1,68);     % 68 header entries in vers > 2.0
        fcontent = textscan(fidh, hform, 1); 
        fclose(fidh);

        % extract info
        expUnt     = fcontent{16};
        preampgain = fcontent{14};
        fS         = fcontent{15};
end

% transmitter frequency
fT = fcontent{2};     

% number of receiver channels
switch expUnt   % expansion unit: 0 = 4 rx channels, 1 = 8 rx channels
    case 0
        nrx = 4;
    case 1
        nrx = 8;
end

% receiver task (GMR: 0=sig, 1=ref, 2=not connected)
switch DAQversion
    case {0.00, 1.00}
        rxt    = [0 1 1 1]; % rx task not assigned in version <1.00
    case {2.00, 2.08, 2.50, 2.90, 2.93, 2.97}
        rxt    = [fcontent{21+6*(0:nrx-1)}];
end

% transmitter gain
switch fcontent{9}    % Transmitter version (defines Tx & Rx gains)
    case 0
        gain_I = 150;
    case {1,2,3}
        gain_I = 180;  
    case 4
        gain_I = 150;
end

% final receiver gain including circuit gain
C      = fcontent{8}*1e-6;
wT     = 2*pi*fT;
L      = 1/(C*wT^2);
Z1     = 0.5 + 1i*0.5*wT;
Z2     = 1/(1i*0.0000016*wT);
Z3     = 1/((1/Z1) + (1/Z2));
Z4     = 1 + 1i*wT*L;
circuit_gain = abs(Z3/(Z3 + Z4));
gain_V = preampgain*circuit_gain;        

% assemble output
header.sequenceID = fcontent{1};    % 1 Pulse Sequence ID	1:FID; 2:90-90 T1; 3:Spin Echo; 4:4-phase T1; 
header.expUnt     = expUnt;
header.DAQversion = DAQversion;     % 10 GMR DAQ Software Version	1.0 – 2.0
header.fT         = fT;             % 2  Transmit Frequency (Hz)	e.g. 2000; (0)
header.fS         = fS;             % 15 Raw Data Sample Rate (Hz)	(50000)
header.nQ         = fcontent{7};    % number of pulse moments 
if DAQversion > 1
    if fcontent{13} == 1 
        header.nQ = NaN;            % for custom-q, fcontent{7} means # recordings instead of #q
    end
end
header.nrx        = nrx;
header.gain_I     = gain_I;
header.gain_V     = gain_V;
header.rxt        = rxt;
header.max_DC_bus = fcontent{3};        % 3	 Max DC Bus Voltage (V)	e.g. 225
header.tau_p      = fcontent{4}*1e-3;   % 4	 Transmit Pulse Length (ms)	e.g. 20; (40)
header.tau_d      = fcontent{5}*1e-3;   % 5	 Interpulse Delay (ms)	e.g. 300; (150)
header.tau_rep    = fcontent{6};        % 6	 Repetition Time (s)	e.g. 6; (8)
header.nrecords   = fcontent{7};        % 7	 # Data records per file: For Auto q: # Pulse moments; For Custom q: # Stacks 	e.g. 12; (16)
header.tuning_C   = fcontent{8}*1e-6;   % 8	 Tuning Capacitance (uF)	e.g. 7.5 (15.5)
header.TXversion  = fcontent{9};        % 9	 Transmitter Version 1 to 3, determines TX gains 

if DAQversion > 0.00
    header.ileaves    = fcontent{11};% 11	# Interleaves   1-3
end

if DAQversion > 1.00
    header.tau_dead   = fcontent{12}*1e-3;% 12	Rx Dead Time (ms)	4-8 (5)
    header.q_sampling = fcontent{13};% 13	Pulse Moment Sampling Method	0: Auto q-sampling; 1: Custom q-sampling (0)
    header.preampGain = fcontent{14};% 14	Preamp Gain	500; 1000 (500)
    header.tau_rep    = fcontent{16};% 16	TX/RX Expansion unit  % Could be replaced by “Number of Channels”	0=4 channels 1=8channels
    for ic = 1:8
        header.coil(ic).task = fcontent{(ic-1)*6+21}; % 21	Coil 1 Function	0: Detection; 1: Noise; 2: None (0)
        header.coil(ic).shape = fcontent{(ic-1)*6+22};% 22	Coil 1 Geometry	1: Square; 2: Circle; 3: Figure 8
        header.coil(ic).size = fcontent{(ic-1)*6+23};% 23	Coil 1 Diameter (m)	e.g. 100; (0)
        header.coil(ic).nturns = fcontent{(ic-1)*6+24};% 24	Coil 1 # Turns	e.g. 2; (1)
        header.coil(ic).incl = fcontent{(ic-1)*6+25};% 25	Coil 1 Inclination Angle	e.g. 68; (0)
        header.coil(ic).decl = fcontent{(ic-1)*6+26};% 26	Coil 1 Declination Angle	e.g. 5; (0)
    end
else
    header.q_sampling = 0;
end
        
