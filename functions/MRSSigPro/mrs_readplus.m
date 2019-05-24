function plusdata = mrs_readplus(numisplusfile)
% ex readBinaryDataFromFile
% 
% Read single NumisPoly data file (*.Pro binary file)
%
% Input:
%   numisplusfile   - path+name of file to read 
%                      (e.g. 'D:\data\Sounding0003\Rawdata\Q1#1.raw)
% Output: 
%  plusdata.
%   .Header          -
%   .Transmitter     - contains pulses
%   .Receiver        - contains signals: Receiver(irx).Signal(isig).U
%                       irx:  receiver # 
%                       isig: 1 noise, 2 sig1, 3 sig2, 4 echo
%
% 25aug2008
% mod. 27jan2011 JW
% =========================================================================
[filedir, filename, fileext] = fileparts(numisplusfile); % check input
if strcmp(fileext,'.raw')
    file = [filename fileext];
else
    error('Input file is not a .raw file!')
end

myfile = fopen(numisplusfile,'r');
disp(['Reading <', file, '>...']);   

%% HEADER -----------------------------------------------------------------

% TConfig (1)
TConfig.c7              = fread(myfile,1,'int32');      % int c7
TConfig.FLarmorFreq     = fread(myfile,1,'float32');    % float FLarmorFreq (A1)
TConfig.c6              = fread(myfile, 1,'int32');     % int c6
TConfig.c5              = fread(myfile, 1,'int32');     % int c5
TConfig.LoopType        = fread(myfile, 1,'int32');     % int LoopType(A4) //  antenna type  1 - circular, 2 - square, 3 - eight, 4 - eight square,5 - long eight, 6 - long eight square, 7 - multi-eight square, 8 - virtual eight, 9 - virtual eight square, 10 - other
TConfig.LoopSize        = fread(myfile, 1,'float32');   % float LoopSize //  antenna size (m) (diameter for circular or side for square)
TConfig.TurnNumber      = fread(myfile, 1,'int32');     % int TurnNumber
TConfig.c4              = fread(myfile, 1,'int32');     % int c4
TConfig.FlagStackMax    = fread(myfile, 1,'int32');     % int FlagStackMax
TConfig.c3              = fread(myfile, 1,'int32');     % int c3
TConfig.PulseMoment     = fread(myfile, 1,'int32');     % int PulseMoment  // number of pulse moments = Q (5-40)
TConfig.SignalRecTime   = fread(myfile, 1,'int32');     % int SignalRecTime// signals recording (ms) (240-1040)  <FID1>
TConfig.DelayTime       = fread(myfile, 1,'int32');     % int DelayTime    //delay
TConfig.PulseDuration   = fread(myfile, 1,'int32');     % int PulseDuration// duration of the pulse (ms) (10-80)
TConfig.NbPulse         = fread(myfile, 1,'int32')+1;   % int NbPulse // 

% TTimeConfig (Timing)
TTimeConfig.TMNoise     = fread(myfile, 1,'int32');     % int TMNoise   //  0 mesure du bruit
TTimeConfig.TDPulse1    = fread(myfile, 1,'int32');     % int t0 
TTimeConfig.TMPulse1    = fread(myfile, 1,'int32');     % int TMPulse1  //  2 dur�e premier pulse
TTimeConfig.TDSignal1   = fread(myfile, 1,'int32');     % int t1
TTimeConfig.TMSignal1   = fread(myfile, 1,'int32');     % int TMSignal1 //  4 dur�� premi�re mesure
TTimeConfig.TDPulse2    = fread(myfile, 1,'int32');     % int t2
TTimeConfig.TMPulse2    = fread(myfile, 1,'int32');     % int TMPulse2  //  6 dur�e deuxi�me pulse
TTimeConfig.TDSignal2   = fread(myfile, 1,'int32');     % int t3
TTimeConfig.TMSignal2   = fread(myfile, 1,'int32');     % int TMSignal2 //  8 dur�e signal 2
TTimeConfig.TDSignal3   = fread(myfile, 1,'int32');     % int t4
TTimeConfig.TMSignal3   = fread(myfile, 1,'int32');     % int t5

% TConfig (2)
TConfig.c0              = fread(myfile, 1,'int32');     % int c0
TConfig.c1              = fread(myfile, 1,'int32');     % int c1
TConfig.c2              = fread(myfile, 1,'int32');     % int c2
TConfig.c8              = fread(myfile, 1,'int32');     % int c8
TConfig.c9              = fread(myfile, 1,'float32');   % float c9
TConfig.c10             = fread(myfile, 1,'int32');     % int c10
TConfig.c11             = fread(myfile, 1,'float32');   % float c11
TConfig.c12             = fread(myfile, 1,'float32');   % float c12
% ---> start
% % Header(36) = fread(file,256,'schar');% char DirectoryName[256]; evtl. uchar !!!!
% fread(file,256,'schar');
% Header(36) = ' ';
% % Header(37) = fread(file,512,'schar');% char Comment[512];
% fread(file,512,'schar');
% Header(37) = ' ';
TConfig.DirectoryName   = deblank(fread(myfile, 256,'*char')'); % char DirectoryName[256]; evtl. uchar
TConfig.Comment         = deblank(fread(myfile, 512,'*char')'); % char Comment[512]
% <--- end
TConfig.c13             = fread(myfile, 1,'int32'); % int c13;
TConfig.c14             = fread(myfile, 7,'int32'); % int c14[7];
TConfig.c15             = fread(myfile, 1,'int32'); % void *c15;  ???? 

% TParameter 
TParameter.KAmpl        = fread(myfile, 1,'float32'); % float KAmpl // coeff. of amplification(A7)
TParameter.x0           = fread(myfile, 1,'float32'); % float x0
TParameter.Noise        = fread(myfile, 1,'float32'); % float Noise(A5)
TParameter.PhCalib      = fread(myfile, 1,'int32');   % int PhCalib // phase signal calibration
TParameter.PhSignal     = fread(myfile, 1,'int32');   % int PhSignal // phase signal
TParameter.RangeReel    = fread(myfile, 1,'float32'); % float RangeReel
TParameter.AdcToTension = fread(myfile, 1,'float32'); % float AdcToTension
TParameter.AdcToCurren  = fread(myfile, 1,'float32'); % float AdcToCurrent
TParameter.UAnt         = fread(myfile, 1,'float32'); % float UAnt // tension d'antenne  pour udctst
TParameter.Loop_Imped   = fread(myfile, 1,'float32'); % float ZAnt // impedance d'antenne  pour udctst
TParameter.UGen         = fread(myfile, 1,'float32'); % float UGen // power generator
TParameter.x6           = fread(myfile, 1,'int32');   % int x6
TParameter.StackCorrect = fread(myfile, 1,'int32');   % int StackCorrect
TParameter.x1           = fread(myfile, 1,'int32');   % int x1
TParameter.PulseNumber  = fread(myfile, 1,'int32');   % int PulseNumber
TParameter.x2           = fread(myfile, 1,'int32');   % int x2
TParameter.x3           = fread(myfile, 1,'float32'); % float x3
TParameter.Batterie     = fread(myfile, 1,'float32'); % float Batterie
TParameter.x4           = fread(myfile, 7,'int32');   % int x4[7]
TParameter.x5           = fread(myfile, 1,'int32');   % void *x5

% assemble output
TConfig    = orderfields(TConfig);
TParameter = orderfields(TParameter);
Header = struct('TConfig',TConfig,'TTimeConfig',TTimeConfig, ...
                'TParameter',TParameter);

%% SIGNAL -----------------------------------------------------------------

% time
% rectime = TTimeConfig.TMSignal1 *4 / TConfig.FLarmorFreq;  % [s] % WHY LARMOR? BETTER TX FREQ. 
dt = 4 / TConfig.FLarmorFreq; % [s]

% timeseries, columns: 1-noise, 2-pulse1, 3-fid1, 4-pulse2, 5-sig2, 6-sig3
n = zeros(1,6);      
x = cell(1,6); y = x;
for icol = 1:6  % 1-noise, 2-pulse1, 3-fid1, 4-pulse2, 5-sig2, 6-sig3
    n(icol)            = fread(myfile,1,'int32');         % # samples
    x{icol}(1:n(icol)) = fread(myfile,n(icol),'float32'); % real part
    y{icol}(1:n(icol)) = fread(myfile,n(icol),'float32'); % imag part
end
fclose(myfile);

maxn = max([n(3) n(5)]);  % max # samples to write to Data. Noise record
                          % n(1) can have more samples, but these are
                          % not required.

Data           = nan(maxn,13);                % initialize
Data(1:maxn,1) = (1:maxn) * dt - dt;          % time from 0 to n_max*dt
scale          = [1e-9 1 1e-9 1 1e-9 1e-9]; % output in [s, A, V]
for icol = 1:6
    NS = 1:min([maxn n(icol)]);
    Data(NS,icol*2)   = x{icol}(NS).*scale(icol);
    Data(NS,icol*2+1) = y{icol}(NS).*scale(icol);
end

plusdata = struct('data', Data, 'header', Header);  % assemble output

% [pathstr,name,ext,versn] = fileparts(numisplusfile);
% fid = fopen ([name,'.dat'], 'w');
% fprintf (fid, 'Moment: %g \n', Header2(15)+1);
% fprintf (fid, 'Stack: %g\n', Header2(13));
% fprintf (fid, 'Larmor frequency [Hz]: %.1f\n', Header(2));
% fprintf (fid, 'Rx gain factor: %.2f\n', Header2(1));
% fprintf (fid, 'Loop impedance: %.1f\n', Header2(10));
% fprintf (fid, 'Noise  [nV]: %.1f\n', Header2(3));
% fprintf (fid, 'Batteries  [V]: %.1f\n', Header2(18));
% fprintf (fid, 'Tx Loop voltage [V]: %.1f\n', Header2(9));
% fprintf (fid, 'Nb pulse: %g\n', Header(16)+1);
% fprintf (fid, '%g\t%g\t%g\t%g\t%g\t%g\t%g\t%g\t%g\t%g\t%g\n', Header(17),Header(18),Header(19),Header(20),Header(21),Header(22),Header(23),Header(24),Header(25),Header(26),Header(27));
% fprintf (fid, '%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\n', Data');
% fclose(fid);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%