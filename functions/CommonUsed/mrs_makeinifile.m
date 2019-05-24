function mrs_makeinifile
% function mrs_makeinifile
%
% Build default MRSmatlab.ini file. Only called when installMRSmatlab is
% executed, or when file is corrupted/outdated & needs to be repaired.
%
% 20jan2011
% mod. 19jul2012 JW
% =========================================================================

MRSvers = mrs_version;
MRSpath = which('MRSWorkflow.m');   % change location to startMRSmatlab?
inifile = [fileparts(MRSpath) filesep 'MRSmatlab.ini'];

fid = fopen(inifile,'w');
default_content = { ...
    '[MRSMatlab]';
    ['version=', num2str(MRSvers, '%4.2f')];
    ' ';
    '[MRSWorkflow]';
    'lastproject=none';
    ' ';
    '[MRSData]';
    'lastdata=none';
    'filter_passFreq=[200:50:1000 3000];';
    'filter_stopFreq=[300:50:3000 5000];';
    'filter_sampleFreq=[5000 10000 50000];';
    ' ';
    '[MRSKernel]';
    'lastkernel=none';
    ' ';
    '[MRSInversion]';
    'lastQT=none';
    'lastT1=none';    
    };
for ln = 1:length(default_content)
    fprintf(fid,'%s\n',default_content{ln});
end
fclose(fid);
