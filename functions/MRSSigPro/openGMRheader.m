function header = openGMRheader(hfile)
% adapted from = mrs_read_gmrheader(hfile)
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
% mod. may 2014 MMP
% =========================================================================

% open header file
fidh    = fopen(hfile,'r');     % open header file for read
hform1  = '%f ';                % format of header entry

% determine DAQ version (entry 10 in header file)
hform      = repmat(hform1,1,10);          % header format 
fcontent   = textscan(fidh, hform, 1);     % read 11 header entries (11 is the minimum # of entries for all DAQ versions)
DAQversion = ext_roundn(fcontent{10},-2);

% exit if DAQ version is not supported
supported  = [0.00 1.00 2.00 2.08 2.40 2.50 2.90 2.93 2.95 2.97 2.99];
if ~ismember(DAQversion,supported)
    error('Unknown DAQ version!')
end

% read in common part of all header types
header.sequenceID = fcontent{1};        % Pulse Sequence ID	1:FID; 2:90-90 T1; 3:Spin Echo; 4:4-phase T1; 
header.fT         = fcontent{2};        % Transmit Frequency (Hz)	e.g. 2000; (0)
header.max_DC_bus = fcontent{3};        % 3	 Max DC Bus Voltage (V)	e.g. 225
header.tau_p      = fcontent{4}*1e-3;   % 4	 Transmit Pulse Length (ms)	e.g. 20; (40)
header.tau_d      = fcontent{5}*1e-3;   % 5	 Interpulse Delay (ms)	e.g. 300; (150)
header.tau_rep    = fcontent{6};        % 6	 Repetition Time (s)	e.g. 6; (8)
header.nrecords   = fcontent{7};        % 7	 # Data records per file: For Auto q: # Pulse moments; For Custom q: # Stacks 	e.g. 12; (16)
header.tuning_C   = fcontent{8}*1e-6;   % 8	 Tuning Capacitance (uF)	e.g. 7.5 (15.5)
header.TXversion  = fcontent{9};        % 9	 Transmitter Version 1 to 3, determines TX gains 
header.DAQversion = DAQversion;         % GMR DAQ Software Version	1.0 – 2.0


% handle read in of different headers for different GMR versions
switch header.DAQversion
    
    case 0.00               % header has 10 entries
        
        fclose(fidh);       % close header file
        
        header.expUnt     = 0;         % expansion unit (0=4channels, 1=8channels)
        header.preampgain = 500;       % preamplifier gain for receiver
        header.fS         = 50e3;      % sampling frequency
        header.tau_dead   = 8e-3;
        header.Qsampling  = 0;
        header.ileaves    = NaN;
        header.te         = 0;         % no CPMG echo spacing (tau=te/2) for DAQv<2
        for ic = 1:8
            header.coil(ic).task = NaN;
            header.coil(ic).shape = NaN;
            header.coil(ic).size = NaN;
            header.coil(ic).nturns = NaN;
            header.coil(ic).incl = NaN;
            header.coil(ic).decl = NaN;
        end
    
    case 1.00               % header has 11 entries
        
        % reread header
        fseek(fidh,0,'bof');                % return to begin of header file
        hform    = repmat(hform1,1,11);     % 11 header entries in vers 1.0
        fcontent = textscan(fidh, hform, 1); 
        fclose(fidh);       % close header file
        
        header.expUnt     = 0;         % expansion unit (0=4channels, 1=8channels)
        header.preampgain = 500;       % preamplifier gain for receiver
        header.fS         = 50e3;      % sampling frequency
        header.tau_dead   = 8e-3;
        header.Qsampling  = 0;
        header.ileaves    = fcontent{11};   % 11	# Interleaves   1-3
        header.te         = 0;         % no CPMG echo spacing (tau=te/2) for DAQv<2
        for ic = 1:8
            header.coil(ic).task = NaN;
            header.coil(ic).shape = NaN;
            header.coil(ic).size = NaN;
            header.coil(ic).nturns = NaN;
            header.coil(ic).incl = NaN;
            header.coil(ic).decl = NaN;
        end
        
    case {2.00, 2.08, 2.40, 2.50, 2.90 2.93 2.95 2.97 } % header has 68 entries (V 2.99 has 70 entries!!)
        
        % reread header
        fseek(fidh,0,'bof');                % return to begin of header file
        hform    = repmat(hform1,1,68);     % 68 header entries in vers > 2.0
        fcontent = textscan(fidh, hform, 1); 
        fclose(fidh);

        % extract info
        header.ileaves    = fcontent{11};       % 11	# Interleaves   1-3
        header.tau_dead   = fcontent{12}*1e-3;  % 12	Rx Dead Time (ms)	4-8 (5)      
        header.Qsampling  = fcontent{13};       % 13	Pulse Moment Sampling Method	0: Auto q-sampling; 1: Custom q-sampling (0)
        header.preampgain = fcontent{14};       % 14	Preamp Gain	500; 
        header.fS         = fcontent{15};
        header.expUnt     = fcontent{16};
        header.te         = fcontent{18}*1e-3;       % 18 CPMG echo spacing (tau=te/2)
          
        for ic = 1:8
            header.coil(ic).task = fcontent{(ic-1)*6+21}; % 21	Coil 1 Function	0: Detection; 1: Noise; 2: None (0)
            header.coil(ic).shape = fcontent{(ic-1)*6+22};% 22	Coil 1 Geometry	1: Square; 2: Circle; 3: Figure 8
            header.coil(ic).size = fcontent{(ic-1)*6+23};% 23	Coil 1 Diameter (m)	e.g. 100; (0)
            header.coil(ic).nturns = fcontent{(ic-1)*6+24};% 24	Coil 1 # Turns	e.g. 2; (1)
            header.coil(ic).incl = fcontent{(ic-1)*6+25};% 25	Coil 1 Inclination Angle	e.g. 68; (0)
            header.coil(ic).decl = fcontent{(ic-1)*6+26};% 26	Coil 1 Declination Angle	e.g. 5; (0)
        end

    case {2.99} % header has 68 entries (V 2.99 has 70 entries!!)
        
        % reread header
        fseek(fidh,0,'bof');                % return to begin of header file
        hform    = repmat(hform1,1,68);     % 68 header entries in vers > 2.0
        fcontent = textscan(fidh, hform, 1); 
        fclose(fidh);

        % extract info
        header.ileaves    = fcontent{11};       % 11	# Interleaves   1-3
        header.tau_dead   = fcontent{12}*1e-3;  % 12	Rx Dead Time (ms)	4-8 (5)      
        header.Qsampling  = fcontent{13};       % 13	Pulse Moment Sampling Method	0: Auto q-sampling; 1: Custom q-sampling (0)
        header.preampgain = fcontent{14};       % 14	Preamp Gain	500; 
        header.fS         = fcontent{15};
        header.expUnt     = fcontent{16};
%        header.expUnt     = 0;  
%        msgbox('DAQ version 2.99 has error in header! expUni is set to 4 Ch. To change edit openGMRheader line165') 
        header.te         = fcontent{18}*1e-3;       % 18 CPMG echo spacing (tau=te/2)
          
        for ic = 1:8
            header.coil(ic).task = fcontent{(ic-1)*6+21}; % 21	Coil 1 Function	0: Detection; 1: Noise; 2: None (0)
            header.coil(ic).shape = fcontent{(ic-1)*6+22};% 22	Coil 1 Geometry	1: Square; 2: Circle; 3: Figure 8
            header.coil(ic).size = fcontent{(ic-1)*6+23};% 23	Coil 1 Diameter (m)	e.g. 100; (0)
            header.coil(ic).nturns = fcontent{(ic-1)*6+24};% 24	Coil 1 # Turns	e.g. 2; (1)
            header.coil(ic).incl = fcontent{(ic-1)*6+25};% 25	Coil 1 Inclination Angle	e.g. 68; (0)
            header.coil(ic).decl = fcontent{(ic-1)*6+26};% 26	Coil 1 Declination Angle	e.g. 5; (0)
        end
        
        
    otherwise
        msgbox('unknown DAQ version') 
        %error('unknown DAQ version')   
end

% number of receiver channels
switch header.expUnt   % expansion unit: 0 = 4 rx channels, 1 = 8 rx channels
    case 0
        header.nrx = 4;
    case 1
        header.nrx = 8;
end

% receiver task (GMR: 0=sig, 1=ref, 2=not connected)
switch header.DAQversion
    case {0.00, 1.00}
        header.rxt    = [0 1 1 1]; % rx task not assigned in version <1.00
    case {2.00, 2.08, 2.40, 2.50, 2.90, 2.93 2.95 2.97 2.99}
        header.rxt    = [fcontent{21+6*(0:header.nrx-1)}];
    otherwise
        msgbox('unknown DAQ version') 
        error('unknown DAQ version') 
end

% transmitter gain
switch header.TXversion    % Transmitter version (defines Tx & Rx gains)
    case 0
        header.gain_I = 150;
    case {1,2,3,6}
        header.gain_I = 180;  
    case 4
        header.gain_I = 150;
    otherwise
        msgbox('unknown transmitter version')
        error('unknown transmitter version')
end

% final receiver gain including circuit gain
C      = header.tuning_C;
wT     = 2*pi*header.fT;
L      = 1/(C*wT^2);
Z1     = 0.5 + 1i*0.5*wT;
Z2     = 1/(1i*0.0000016*wT);
Z3     = 1/((1/Z1) + (1/Z2));
Z4     = 1 + 1i*wT*L;
header.circuit_gain = abs(Z3/(Z3 + Z4));
header.gain_V = header.preampgain*header.circuit_gain;        


%% check for number of files in folder
% GMR data files start with name of headerfile, followed by underscore
[sounding_path,filebase] = fileparts(hfile);
% collect all files in dir
afiles        = dir([sounding_path,filesep,filebase,'_*']);   
% drop files that are not recordings (e.g., *_bad_idx.mat)
dropfile = zeros(1,length(afiles));
for irec = 1:length(afiles)
    if isnan(str2double(afiles(irec).name(length(filebase)+2))) % underscore is not followed by a number
        dropfile(irec) = 1;
    else
        dropfile(irec) = 0;
    end
end
afiles(dropfile == 1) = [];

% determine # pulse moments and # recordings
switch header.Qsampling
    case 0
        header.nrec = length(afiles);     % # recordings
        header.nQ   = header.nrecords;    % # pulse moments
    case 1
        header.nrec = header.nrecords;
        header.nQ   = length(afiles);
end

% sort filenames
recN = zeros(1,length(afiles));
if header.DAQversion < 2.4
    for irec = 1:length(afiles)
        recN(irec) = str2double(afiles(irec).name(length(filebase)+2:end));  % get ID: number after underscore
    end
else
    for irec = 1:length(afiles)
        recN(irec) = str2double(afiles(irec).name(length(filebase)+2:end-3));  % get ID: number after underscore
    end
end
[dummy,recID] = sort(recN);
header.files  = afiles(recID); % now indices irec correspond to file ID
header.fileID = recN(recID);





        
