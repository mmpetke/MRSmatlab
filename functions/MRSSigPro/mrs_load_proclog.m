
function [proclog] = mrs_load_proclog(filepath, filename)

% initialize proclog structure
proclog = struct();
load([filepath filename] , '-mat')  % load proclog file
proclog.path = filepath;            % update path
