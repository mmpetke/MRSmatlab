function startMRSmatlab
% function startMRSmatlab
% 
% Sets the MRSmatlab path & starts the program. This function works only if 
% it is started from the MRSmatlab path. It is designed for being called by 
% the shortcut that is created by installMRSmatlab. 
%
% Jan Walbrecker, 30mar2011
% ed. 30mar2010 JW
% =========================================================================

% set MRSmatlab path
addpath(...
   [pwd filesep 'extern'], ...
   [pwd filesep 'extern' filesep 'Factorize'], ...
   [pwd filesep 'extern' filesep 'exp2fit'], ...
   [pwd filesep 'extern' filesep 'pics'], ...
   [pwd filesep 'extern' filesep 'multicore'], ...
   [pwd filesep 'userinterfaces'], ...
   [pwd filesep 'userinterfaces' filesep 'icons'], ...
   [pwd filesep 'functions' filesep 'MRSSigPro'], ... 
   [pwd filesep 'functions' filesep 'FileConverter'], ... 
   [pwd filesep 'functions' filesep 'MRSKernel'], ...
   [pwd filesep 'functions' filesep 'MRSModelling'], ...
   [pwd filesep 'functions' filesep 'MRSInversionQT' filesep 'GA'], ...
   [pwd filesep 'functions' filesep 'MRSInversionQT'], ...
   [pwd filesep 'functions' filesep 'MRSInversionT1'], ...
   [pwd filesep 'functions' filesep 'CommonUsed']);

% GUI Layout has different versions for different matlab versions
if exist('layoutRoot', 'file') == 2, % check if mltbx toolbox is already installed
    disp('Found GUIlayout! Not setting any path for it...')
else  % what about R2015a, R2015b, R2016a ?
    if strcmp(version('-release'),'2016b'),
         addpath([pwd filesep 'extern' filesep 'GUILayout-v2p3']);
    elseif strcmp(version('-release'),'2016a'),
         addpath([pwd filesep 'extern' filesep 'GUILayout-v2p2']);
    elseif strcmp(version('-release'),'2014b'),
        addpath([pwd filesep 'extern' filesep 'GUILayout-v2p1']);
    else
        glpath = [pwd filesep 'extern' filesep 'GUILayout-v1p9'];
        addpath(glpath, ...
            [glpath filesep 'layoutHelp'], ...
            [glpath filesep 'Patch']);
    end
end

% undock windows
status = get(0, 'DefaultFigureWindowStyle');
if strcmp(status,'docked') == 1
    set(0, 'DefaultFigureWindowStyle', 'normal');
    disp('Figures normal')   
end

% check for updates
% current version in inifile
inifile = mrs_readinifile;
if inifile.MRSmatlab.version ~= mrs_version
    msgbox({'MRSmatlab version changed!';' ';...
            'Please run --> installMRSmatlab <-- to update inifile';' ';...
            'You may need to update *.mrsd files --> use MRSupdateProclog for this.'})
end

%MRSWorkflow