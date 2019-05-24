function installMRSmatlab
% function installMRSmatlab
% 
% Generate a shortcut in the matlab toolbar, which starts MRSmatlab.
% Build default MRSmatlab.ini file. 
%
% MH
% ed. 30mar2010 JW
% =========================================================================

% determine MRSmatlab path
pfad = uigetdir(pwd,'Select MRSmatlab path (e.g. "d:\matlab\MRSmatlab\current\")');

% set temporary paths to execute AddShortcut
addpath([pfad filesep 'userinterfaces'], ...
        [pfad filesep 'extern' filesep 'shortcut_tools'], ...
        [pfad filesep 'functions' filesep 'CommonUsed']);

% add shortcut button that starts MRSmatlab
AddShortcut(...
    'MRSmatlab', ...
    ['run ' pfad filesep 'startMRSmatlab'], ...
    'MATLAB icon', ...
    'Toolbar Shortcuts', ...
    'false', ...
    'true');

% build MRSmatlab.ini file
mrs_makeinifile;

% remove temporary paths
rmpath([pfad filesep 'userinterfaces'], ...
       [pfad filesep 'extern' filesep 'shortcut_tools'], ...
       [pfad filesep 'functions' filesep 'CommonUsed']);
