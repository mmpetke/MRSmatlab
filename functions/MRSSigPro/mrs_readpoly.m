%% Numis Poly RAW Data read in
% =========================================================================

function [polydata] = mrs_readpoly(varargin)
% ex function [polydata] = DAT_readPoly_ed(argin)
% 
% Read single NumisPoly data file (*.Pro binary file)
%
% Input options:
% 	( )              - no input -> read single file from user interface
%   ('dir\file.Pro') - read 'f.Pro' in 'dir' 
%                      (dir should be sth like...\Soounding0003\Rawdata)
%   ('dir\file.Pro',FREQ_MEAS)- read 'f.Pro' in 'dir' 
%                      (dir should be sth like...\Soounding0003\Rawdata)
%                       FREQ_MEAS is the sampling frequency
% Output: 
%  polydata.
%   .Header          -
%   .Transmitter     - contains pulses
%   .Receiver        - contains signals: Receiver(irx).Signal(isig).U
%                       irx:  receiver # 
%                       isig: 1 noise, 2 sig1, 3 sig2, 4 echo
%
% Fabian Neyer, 19.04.2010
%               mod. 21.05.2010
%               MMP 7 Apr 2011
%               JW  7 Oct 2011
% =========================================================================

%% Default NumisPoly parameters -------------------------------------------
NB_Proton_Rx_max = 4;       % number of receivers
NB_Signal_max    = 4;       % number of signals (noise,sig1,sig2,echo)
FREQ_MEAS        = 76800;   % sampling frequency > IT IS NOT IN FILE!! 
% For GMR taken from varargin input
isGMR = 0;

%% Choose file ------------------------------------------------------------
if nargin == 0      % read one file selected from ui
    [file,filedir] = uigetfile({ ...
            '*.Pro', 'Poly files(*.Pro)'; ...
            '*.Pro', 'NumisPoly data file (*.Pro)'}, ...
            'Load NumisPoly datafile');
elseif nargin == 1  % read file from input argument
    [filedir, filename, fileext] = fileparts(varargin{1}); % check input
    if strcmp(fileext,'.Pro')
        file = [filename fileext];
    else
        error('Input file is not a .Pro file!')
    end  
elseif nargin == 2  % read file and get FREQ_MEAS from input argument 
    [filedir, filename, fileext] = fileparts(varargin{1}); % check input
    if strcmp(fileext,'.Pro')
        file = [filename fileext];
    else
        error('Input file is not a .Pro file!')
    end    
    FREQ_MEAS = varargin{2};
elseif nargin == 3  % read file, get FREQ_MEAS and NB_Proton_Rx_max from input argument -> happens only for converted GMR files
    [filedir, filename, fileext] = fileparts(varargin{1}); % check input
    if strcmp(fileext,'.Pro')
        file = [filename fileext];
    else
        error('Input file is not a .Pro file!')
    end    
    FREQ_MEAS = varargin{2};
    NB_Proton_Rx_max = varargin{3};
    isGMR = 1;
end
disp(['Reading <', file, '>...']);                 
myfile  = fopen([filedir filesep file], 'r');

%% Read header: TConfig, TTimeConfig, TParameter
fread(myfile, 1,'int32');     % skip version
fread(myfile, 1,'int32');     % skip blocksize
TConfig.c7              = fread(myfile, 1,'int32');
TConfig.FLarmorFreq     = fread(myfile, 1,'float32');
TConfig.c6              = fread(myfile, 1,'int32');
TConfig.c5              = fread(myfile, 1,'int32');
TConfig.LoopType        = fread(myfile, 1,'int32');
TConfig.LoopSize        = fread(myfile, 1,'float32');
TConfig.TurnNumber      = fread(myfile, 1,'int32');
TConfig.c4              = fread(myfile, 1,'int32');
TConfig.FlagStackMax    = fread(myfile, 1,'int32');
TConfig.c3              = fread(myfile, 1,'int32');
TConfig.PulseMoment     = fread(myfile, 1,'int32');
TConfig.SignalRecTime   = fread(myfile, 1,'int32');
TConfig.DelayTime       = fread(myfile, 1,'int32');
TConfig.PulseDuration   = fread(myfile, 1,'int32');
TConfig.NbPulse         = fread(myfile, 1,'int32') +1; % 0 = 1 pulse; 1 = 2 pulses
TTimeConfig.TMNoise     = fread(myfile, 1,'int32');
TTimeConfig.TDPulse1    = fread(myfile, 1,'int32');
TTimeConfig.TMPulse1    = fread(myfile, 1,'int32');
TTimeConfig.TDSignal1   = fread(myfile, 1,'int32');
TTimeConfig.TMSignal1   = fread(myfile, 1,'int32');
TTimeConfig.TDPulse2    = fread(myfile, 1,'int32');
TTimeConfig.TMPulse2    = fread(myfile, 1,'int32');
TTimeConfig.TDSignal2   = fread(myfile, 1,'int32');
TTimeConfig.TMSignal2   = fread(myfile, 1,'int32');
TTimeConfig.TDSignal3   = fread(myfile, 1,'int32');
TTimeConfig.TMSignal3   = fread(myfile, 1,'int32');
TConfig.c0              = fread(myfile, 1,'int32');
TConfig.c1              = fread(myfile, 1,'int32');
TConfig.c2              = fread(myfile, 1,'int32');
TConfig.c8              = fread(myfile, 1,'int32');
TConfig.c9              = fread(myfile, 1,'float32');
TConfig.c10             = fread(myfile, 1,'int32');
TConfig.c11             = fread(myfile, 1,'float32');
TConfig.c12             = fread(myfile, 1,'float32');
TConfig.DirectoryName   = deblank(fread(myfile, 256,'*char')');
TConfig.Comment         = deblank(fread(myfile, 512,'*char')');
TConfig.c13             = fread(myfile, 1,'int32');
TConfig.c14             = fread(myfile, 7,'int32');
TConfig.c15             = fread(myfile, 1,'int32');         % void
TParameter.KAmpl        = fread(myfile, 1,'float32');
TParameter.x0           = fread(myfile, 1,'float32');
TParameter.Noise        = fread(myfile, 1,'float32');
TParameter.PhCalib      = fread(myfile, 1,'int32');
TParameter.PhSignal     = fread(myfile, 1,'int32');
TParameter.RangeReel    = fread(myfile, 1,'float32');
TParameter.AdcToTension = fread(myfile, 1,'float32');
TParameter.AdcToCurren  = fread(myfile, 1,'float32');
TParameter.UAnt         = fread(myfile, 1,'float32');
TParameter.Loop_Imped   = fread(myfile, 1,'float32');
TParameter.UGen         = fread(myfile, 1,'float32');
TParameter.x6           = fread(myfile, 1,'int32');
TParameter.StackCorrect = fread(myfile, 1,'int32');
TParameter.x1           = fread(myfile, 1,'int32');
TParameter.PulseNumber  = fread(myfile, 1,'int32');
TParameter.x2           = fread(myfile, 1,'int32');
TParameter.x3           = fread(myfile, 1,'float32');
TParameter.Batterie     = fread(myfile, 1,'float32');
TParameter.x4           = fread(myfile, 7,'int32');
TParameter.x5           = fread(myfile, 1,'int32');         % void

TConfig    = orderfields(TConfig);
TParameter = orderfields(TParameter);
Header = struct('TConfig',TConfig,'TTimeConfig',TTimeConfig, ...
                'TParameter',TParameter);      % assemble output

%% Read receiver parameters -----------------------------------------------

Receiver(NB_Proton_Rx_max).Proton = [];       % initialize structure
for irx = 1:NB_Proton_Rx_max    % for each receiver
    blocksize = fread(myfile, 1,'int32');
    if blocksize ~= 0   % receiver was connected
        Receiver(irx).Proton.TProtonVersion = fread(myfile, 1,'int32');
        Receiver(irx).Proton.Version        = fread(myfile, 1,'int32');
        Receiver(irx).ProtonLoop.Size       = fread(myfile, 1,'float32');
        Receiver(irx).ProtonLoop.Shape      = fread(myfile, 1,'int32');
        Receiver(irx).ProtonLoop.NbTurn     = fread(myfile, 1,'int32');
        Receiver(irx).ProtonConfig.FLarmor  = fread(myfile, 1,'float32');
        Receiver(irx).ProtonConfig.Gain     = fread(myfile, 1,'float32');
        Receiver(irx).ProtonCount.Noise     = fread(myfile, 1,'int32');
        Receiver(irx).ProtonCount.Pause0    = fread(myfile, 1,'int32');
        Receiver(irx).ProtonCount.Synchro1  = fread(myfile, 1,'int32');
        Receiver(irx).ProtonCount.Pause1    = fread(myfile, 1,'int32');
        Receiver(irx).ProtonCount.Adjust1   = fread(myfile, 1,'int32');
        Receiver(irx).ProtonCount.Pulse1    = fread(myfile, 1,'int32');
        Receiver(irx).ProtonCount.Pause2    = fread(myfile, 1,'int32');
        Receiver(irx).ProtonCount.Signal1   = fread(myfile, 1,'int32');
        Receiver(irx).ProtonCount.Pause3    = fread(myfile, 1,'int32');
        Receiver(irx).ProtonCount.Synchro2  = fread(myfile, 1,'int32');
        Receiver(irx).ProtonCount.Pause4    = fread(myfile, 1,'int32');
        Receiver(irx).ProtonCount.Adjust2   = fread(myfile, 1,'int32');
        Receiver(irx).ProtonCount.Pulse2    = fread(myfile, 1,'int32');
        Receiver(irx).ProtonCount.Pause5    = fread(myfile, 1,'int32');
        Receiver(irx).ProtonCount.Signal2   = fread(myfile, 1,'int32');
        Receiver(irx).ProtonCount.Pause6    = fread(myfile, 1,'int32');
        Receiver(irx).ProtonCount.Signal3   = fread(myfile, 1,'int32');
        Receiver(irx).ProtonCount.Polarite  = fread(myfile, 1,'int32');
        Receiver(irx).ProtonConfig.SampleRateDivider = fread(myfile, 1,'int32');    % Jan W: should be the same for all receivers
        Receiver(irx).ProtonConfig.Crc      = fread(myfile, 1,'uint');
        Receiver(irx).ProtonModulePhase.Module  = fread(myfile, 1,'float32');
        Receiver(irx).ProtonModulePhase.Phase   = fread(myfile, 1,'float32');
        Receiver(irx).ProtonModulePhase2.Module = fread(myfile, 1,'float32');   % Jan W: Phase2? Does this mean phase of receiver 2? Or of signal 2?
        Receiver(irx).ProtonModulePhase2.Phase  = fread(myfile, 1,'float32');
        Receiver(irx).ProtonModulePhase3.Module = fread(myfile, 1,'float32');
        Receiver(irx).ProtonModulePhase3.Phase  = fread(myfile, 1,'float32');
        Receiver(irx).ProtonMeasPara.GainProg   = fread(myfile, 1,'float32');
        Receiver(irx).TRxTxCablePara.length     = fread(myfile, 1,'int32');
        Receiver(irx).TRxTxCablePara.unused     = fread(myfile, 1,'float32');
        Receiver(irx).ProtonMeasPara.RxNum      = fread(myfile, 1,'int32');
        Receiver(irx).ProtonBatterieTemperature.BatteriePos = fread(myfile, 1,'float32');
        Receiver(irx).ProtonBatterieTemperature.BatterieNeg = fread(myfile, 1,'float32');
        Receiver(irx).ProtonBatterieTemperature.Plus5A      = fread(myfile, 1,'float32');
        Receiver(irx).ProtonBatterieTemperature.Minus5A     = fread(myfile, 1,'float32');
        Receiver(irx).ProtonBatterieTemperature.Temperature = fread(myfile, 1,'float32');
        Receiver(irx).ProtonMeasValue.Noise = fread(myfile, 1,'float32');
        Receiver(irx).Proton.ParameterSize  = fread(myfile, 1,'int32');
        Receiver(irx).SampleFrequency = FREQ_MEAS/Receiver(irx).ProtonConfig.SampleRateDivider;     % SFreq_Rx

%% Read signal (for each receiver)
%         SFreq_Rx = FREQ_MEAS/Receiver(1).ProtonConfig.SampleRateDivider;    % SampleRateDivider should be the same for all receivers
        Receiver(irx).Signal(NB_Signal_max).v = []; % initialize
        for isig = 1:NB_Signal_max  % signal 1:4 (noise,sig1,sig2,echo)
            blocksize  = fread(myfile, 1,'int32');
            sig = zeros(1,blocksize/4);
            if blocksize ~= 0   % signaltype was recorded 
                sig(1,1:blocksize/4) = fread(myfile,blocksize/4,'float32'); 
                Receiver(irx).Signal(isig).v = sig*1e-9;     % voltage [V]
                Receiver(irx).Signal(isig).t = (0:length(sig)-1)/Receiver(irx).SampleFrequency;     % time [s]
            end
        end
    else    % receiver not connected 
        if isGMR == 0
            % if numis: blocksize is zero, nothing must be read.
            % skip
        else
            % if converted gmr: entries must be read and ignored.
            fread(myfile, 1,'int32');
            fread(myfile, 1,'int32');
            fread(myfile, 1,'float32');
            fread(myfile, 1,'int32');
            fread(myfile, 1,'int32');
            fread(myfile, 1,'float32');
            fread(myfile, 1,'float32');
            for ix = 1:19
                fread(myfile, 1,'int32');
            end
            fread(myfile, 1,'uint');
            for ix = 1:7
                fread(myfile, 1,'float32');
            end
            fread(myfile, 1,'int32');
            fread(myfile, 1,'float32');
            fread(myfile, 1,'int32');
            for ix = 1:6
                fread(myfile, 1,'float32');
            end
            fread(myfile, 1,'int32');
            fread(myfile, 1,'int32');% sig 1
            fread(myfile, 1,'int32');% sig 2
            fread(myfile, 1,'int32');% sig 3
            fread(myfile, 1,'int32');% sig 4
        end
    end
end % irx (receiver)
Receiver = orderfields(Receiver);

%% Read Transmitter parameters
blocksize = fread(myfile, 1,'int32');
if blocksize ~= 0   % (== 0) should be impossible
    Transmitter.FreqReelReg9833                 = fread(myfile, 1,'float32');
    Transmitter.ProtonTx.DcVersion              = fread(myfile, 2,'int32');
    Transmitter.BatterieTemperatureDCDC1.PwrBat = fread(myfile, 1,'float32');
    Transmitter.BatterieTemperatureDCDC1.Temp   = fread(myfile, 1,'float32');
    Transmitter.BatterieTemperatureDCDC1.Cmd    = fread(myfile, 1,'int32');
    Transmitter.BatterieTemperatureDCDC2.PwrBat = fread(myfile, 1,'float32');
    Transmitter.BatterieTemperatureDCDC2.Temp   = fread(myfile, 1,'float32');
    Transmitter.BatterieTemperatureDCDC2.Cmd    = fread(myfile, 1,'int32');
    Transmitter.TxVersionCoeff.VersionHard      = fread(myfile, 1,'int32');
    Transmitter.TxVersionCoeff.VersionSoft      = fread(myfile, 1,'int32');
    Transmitter.TxVersionCoeff.V_Coeff          = fread(myfile, 1,'float32');
    Transmitter.TxVersionCoeff.I_Coeff          = fread(myfile, 1,'float32');
    Transmitter.MeasValue.V_Ant                 = fread(myfile, 1,'float32');
    Transmitter.MeasValue.Z_Ant                 = fread(myfile, 1,'float32');
    Transmitter.MeasValue.RLoop                 = fread(myfile, 1,'float32');
    Transmitter.MeasValue.TempInd               = fread(myfile, 1,'float32');
    Transmitter.ProtonTx.ParameterSize          = fread(myfile, 1,'int32');
    
    Transmitter.Pulse(2).I = nan;    % initialize
    for ipulse = 1:2
        blocksize = fread(myfile, 1,'int32');
        if blocksize ~= 0
            pl(1,1:blocksize/4) = fread(myfile,blocksize/4,'float32');
            Transmitter.Pulse(ipulse).I = pl;   % current [A]
            if isGMR == 0   % numis file
                Transmitter.Pulse(ipulse).t = (0:length(pl)-1)/Receiver(1).SampleFrequency;  % time [s] For numis, pulse is sampled at SampleFrequency
            else            % converted GMR file
                Transmitter.Pulse(ipulse).t = (0:length(pl)-1)/FREQ_MEAS*5;  % time [s] --> pulse is saved with original full sampling rate of 50kHz
            end
        end
    end
end
Transmitter = orderfields(Transmitter);
fclose(myfile);

polydata = struct('receiver',Receiver,...
                  'transmitter',Transmitter,...
                  'header',Header);                 % assemble output
