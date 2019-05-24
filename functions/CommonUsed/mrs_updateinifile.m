function mrs_updateinifile(newentry, update)
% function mrs_updateinifile(newentry, update)
%
% Update history in the MRSmatlab.ini file (save last *.mrsp project / 
% *.mrsd data). The ini file should be in the current matlab path. 
% History in ini file is updated when:
%   - a new project is started in MRSWorkflow (update: lastproject)
%   - a project is opened in MRSWorkflow (update: lastproject)
%   - a datafile is saved in MRSImport (update: lastdata)
%   - a datafile is saved in MRSFit (update: lastdata)
%   - a kernelfile is saved in MRSKernel (update: lastkernel)
%
% JW: MAYBE UPDATE INI-FILE ALSO WHEN LOADING DATA/PROJECT/KERNEL?
% 
% Input:
%   newentry - MRSWorkflow structure; required to update to current path 
%              and file names
%   update   - flag:  0 - update lastproject (MRSWorkflow)
%                     1 - update lastdata (MRSImport, MRSFit)
%                     2 - update lastkernel (MRSImport, MRSFit)
%
% 19jan2011
% mod. 19jul2012 JW
% =========================================================================

%% open .ini-file file
inifile = which('MRSmatlab.ini');
fid     = fopen(inifile,'r');

%% count # lines
nlines  = 0;
while fgets(fid)~= -1
    nlines = nlines+1;
end
frewind(fid);

%% read file content linewise
ini = cell(nlines,1);
for n = 1:nlines
    ini{n} = fgetl(fid);
end
fclose(fid);

%% identify sections in .ini-file
lines         = 1:nlines;
line_workflow = lines(strcmp(ini,'[MRSWorkflow]'));
line_data     = lines(strcmp(ini,'[MRSData]'));
line_kernel   = lines(strcmp(ini,'[MRSKernel]'));
line_inv      = lines(strcmp(ini,'[MRSInversion]'));

% check file health
chk = [isempty(line_workflow) ...
       isempty(line_data) ...
       isempty(line_kernel)...
       isempty(line_inv)];
if any(chk==1)
    errordlg('MRSmatlab.ini file is corrupted. Cannot write.', ...
        '.ini file corruption');
    return
end    

%% replace the entry & save .ini-file
fid     = fopen(inifile,'w');
switch update 
    case 0  % replace lastproject
        ini{line_workflow+1} = ['lastproject=', newentry];
    case 1  % replace lastdata
        ini{line_data+1} = ['lastdata=', newentry];
    case 2  % replace lastkernel
        ini{line_kernel+1} = ['lastkernel=', newentry];
    case 31 % replace lastQT
        ini{line_inv+1} = ['lastQT=', newentry];
    case 32 % replace lastT1
        ini{line_inv+2} = ['lastT1=', newentry];
end
for ln = 1:length(ini)
    fprintf(fid,'%s\n', ini{ln});
end    
fclose(fid);

