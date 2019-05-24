function [inifile] = mrs_readinifile
% function [inifile] = mrs_readinifile
%
% Read information from MRSmatlab.ini file. The ini file should be in the 
% current matlab path.
%
% Output:
%   inifile.        - [struct] with history:
%     .MRSWorkflow. - MRSWorkflow info
%       .path  
%       .file  
%     .MRSData.     - MRSData info
%       .path  
%       .file  
%       .filter_passFreq
%       .filter_stopFreq
%       .filter_sampleFreq
%     .MRSKernel.   - MRSKernel info
%       .path          - path to last kernel (.mrsk file)
%       .file          - filename of last kernel (.mrsk file)
%     .MRSInversion.   - MRSInversion info
%       .QT.
%         .path          - path to last QT inversion result (.mrsi file)
%         .file          - filename of last QT inversion result (.mrsi file)
%       .T1.
%         .path          - path to last T1 inversion result (.mrsi file)
%         .file          - filename of last T1 inversion result (.mrsi file)
%
% 19jan2011
% mod. 19jul2012 JW
% =========================================================================
    
%% open .ini-file file
myinifile = which('MRSmatlab.ini');
fid       = fopen(myinifile,'r');

%% count # lines
nlines  = 0;
while fgets(fid)~= -1
    nlines = nlines+1;
end
frewind(fid);

%% read file-content linewise
ini = cell(nlines,1);
for n = 1:nlines
    ini{n} = fgetl(fid);
end

%% identify sections in .ini file
lines         = 1:nlines;
line_mrs      = lines(strcmp(ini,'[MRSMatlab]'));
line_workflow = lines(strcmp(ini,'[MRSWorkflow]'));
line_data     = lines(strcmp(ini,'[MRSData]'));
line_kernel   = lines(strcmp(ini,'[MRSKernel]'));
line_inv      = lines(strcmp(ini,'[MRSInversion]'));

% check if .ini-file is ok
chk = [isempty(line_mrs) isempty(line_workflow) isempty(line_data) isempty(line_kernel) isempty(line_inv)];
if any(chk==1)
    fclose(fid);
    response = questdlg('MRSmatlab.ini file is corrupted or outdated. Reset it?', ...
        '.ini file corruption', ...
        'Yes','No','No');
    switch response
        case 'Yes'
            mrs_makeinifile;
            fid = fopen(myinifile,'r');
            
            % reread new inifile (i.e.: GoTo line 32 above)
            nlines  = 0;
            while fgets(fid)~= -1
                nlines = nlines+1;
            end
            frewind(fid);
            ini = cell(nlines,1);
            for n = 1:nlines
                ini{n} = fgetl(fid);
            end
            lines         = 1:nlines;
            line_mrs      = lines(strcmp(ini,'[MRSMatlab]'));
            line_workflow = lines(strcmp(ini,'[MRSWorkflow]'));
            line_data     = lines(strcmp(ini,'[MRSData]'));
            line_kernel   = lines(strcmp(ini,'[MRSKernel]'));
            line_inv      = lines(strcmp(ini,'[MRSInversion]'));

        case 'No'
            return  % may cause problems
    end            
end

%% MRSMatlab - get version
frewind(fid);
for n = 1:line_mrs+1   % forward to [MRSMatlab] section in .ini file
    vers = fgetl(fid);
end
iequal = find(vers == '=');

% read version string and convert to double
MRSversion = vers(iequal+1:end);
inifile.MRSmatlab.version = str2double(MRSversion);

%% MRSWorkflow - get last project

% forward to [MRSWorkflow] section in .ini file
frewind(fid);
for n = 1:line_workflow+1
    lprj = fgetl(fid);
end
iequal = find(lprj == '=');

% read last project entry
[pathstr, name, ext] = fileparts(lprj(iequal+1:end));
inifile.MRSWorkflow.path = [pathstr filesep];
inifile.MRSWorkflow.file = [name ext];

%% MRSData - get last data

% forward to [MRSData] section in .ini file
frewind(fid);
for n = 1:line_data+1   
    ldat = fgetl(fid);
end

% read last data entry
iequal = find(ldat == '=');
[pathstr, name, ext] = fileparts(ldat(iequal+1:end));
inifile.MRSData.path = [pathstr filesep];
inifile.MRSData.file = [name ext];

% read filter coefficient: pass frequency
fpass = fgetl(fid);
iequal = find(fpass == '=');
inifile.MRSData.filter_passFreq = eval(fpass(iequal+1:end));

% read filter coefficient: stop frequency
fstop = fgetl(fid);
iequal = find(fstop == '=');
inifile.MRSData.filter_stopFreq = eval(fstop(iequal+1:end));

% read filter coefficient: sample frequency
fsample = fgetl(fid);
iequal = find(fsample == '=');
inifile.MRSData.filter_sampleFreq = eval(fsample(iequal+1:end));


% %% MRST1 - get T1 path, directories, and filenames (assemble mrsproject)
% 
% % forward to [MRST1] section in ini file
% frewind(fid);
% for n = 1:line_T1+1
%     spath = fgetl(fid);
% end
% 
% % read path
% iequal = find(spath == '=');
% inifile.MRST1.path = spath(iequal+1:end);  % pathname
% 
% % read file
% sfile = fgetl(fid);
% iequal = find(sfile == '=');
% inifile.MRST1.file = sfile(iequal+1:end);  % filename
% 
% % read names of T1 soundings
% snd = fgetl(fid);       % ignore line "mrsproject.dir_file={" 
% iS = 0;
% while ~strcmp(snd,'}')  % cycle through all soundings (lines)
%     iS = iS+1;
%     snd = fgetl(fid);
%     [pathstr, name, ext]     = fileparts(snd);
%     islash = find(pathstr == filesep, 1, 'last');
%     inifile.MRST1.data(iS).dir  = pathstr(islash+1:end);
%     inifile.MRST1.data(iS).file = [name ext];
% end
% inifile.MRST1.data(end) = []; % delete last entry ( =='}' )


%% MRSKernel - get last kernel

% forward to [MRSKernel] section in .ini file
frewind(fid);
for n = 1:line_kernel+1
    lkernel = fgetl(fid);
end

% read last kernel entry
iequal = find(lkernel == '=');
[pathstr, name, ext] = fileparts(lkernel(iequal+1:end));
inifile.MRSKernel.path = [pathstr filesep];
inifile.MRSKernel.file = [name ext];

%% MRSInversion - get last inversion files

% forward to [MRSInversion] section in .ini file
frewind(fid);
for n = 1:line_inv+1
    lQT = fgetl(fid);   % QT inversion file
end
lT1 = fgetl(fid);       % T1 inversion file

% read last QT inversion entry
iequal = find(lQT == '=');
[pathstr, name, ext] = fileparts(lQT(iequal+1:end));
inifile.MRSInversion.QT.path = [pathstr filesep];
inifile.MRSInversion.QT.file = [name ext];

% read last T1 inversion entry
iequal = find(lT1 == '=');
[pathstr, name, ext] = fileparts(lT1(iequal+1:end));
inifile.MRSInversion.T1.path = [pathstr filesep];
inifile.MRSInversion.T1.file = [name ext];


%% exit
fclose(fid);

