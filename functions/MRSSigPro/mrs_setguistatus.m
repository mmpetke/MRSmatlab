function mrs_setguistatus(gui,active,message)
% function mrs_setguistatus(gui,active,message)
% 
% Sets the gui status (gui.panel_controls.edit_status).
% At some point: replace input "gui" by handle.
% 
% 27oct2010
% ed. 20jan2011 JW
% =====================================================================

if nargin < 3
    message = 'Idle...';
end

switch active
    case 1
        set(gui.panel_controls.edit_status,...
            'Enable', 'on', ...
            'BackgroundColor', [1 0 0], ...
            'String', message);
    case 0
        set(gui.panel_controls.edit_status,...
            'Enable', 'off', ...
            'BackgroundColor', [0 1 0], ...
            'String', message);
end
drawnow
