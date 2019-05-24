function SetDefaultValue(position, argName, defaultValue)
%SETDEFAULTVALUE Initialise a missing or empty value in the caller.
% 
% SETDEFAULTVALUE(POSITION, ARGNAME, DEFAULTVALUE) checks to see if the
% argument named ARGNAME in position POSITION of the caller function is
% missing or empty, and if so, assigns it the value DEFAULTVALUE.
% 
% Example:
% function x = TheCaller(x)
% SetDefaultValue(1, 'x', 10);
% end
% TheCaller()    % 10
% TheCaller([])  % 10
% TheCaller(99)  % 99

% $Author: rcotton $  $Date: 2010/10/01 13:58:35 $ $Revision: 1.1 $
% Copyright: Health and Safety Laboratory 2010

if evalin('caller', 'nargin') < position || ...
      isempty(evalin('caller', argName))
   assignin('caller', argName, defaultValue);
end
end