function welldone = MRSFit(sounding_pathdirfile)
% function MRSFit
%
% Open MRSFit gui to
%   + Fit MRS data
%
% Called functions:
%
%
%
% Input options:
%   sounding_pathdirfile - optional: Path to sounding (passed by MRSmatlab)
%
% Output:
%   fdata   - field data structure
%   proclog - processing logbook
%
% 27nov2010
% mod. 19aug2011
% =========================================================================

% allow only one instance of MRSFit
ffig = findobj('Name', 'MRS Fit');
if ~isempty(ffig)
    delete(ffig)
end
ffig = findobj('Name', 'MRSFit - Sounding window');
if ~isempty(ffig)
    delete(ffig)
end
ffig = findobj('Name', 'MRSFit - FID window');
if ~isempty(ffig)
    delete(ffig)
end
% set globals
gui       = createInterface();
fdata     = struct();
proclog   = struct();

if nargin > 0   % i.e. command comes from MRSWorkflow
    standalone = 0;
    % set path & execute initialize
    [d, file, ext] = fileparts(sounding_pathdirfile);
    set(gui.panel_controls.edit_path,'String', file);
    set(gui.panel_controls.menu_file, 'Enable', 'off');    
    onLoad(0,0);
else
    set(gui.panel_controls.menu_quit_saveandquit, 'Enable', 'off');    
    standalone = 1;
end

    function gui = createInterface()
        
        gui = struct();
        
        %% GENERATE PLOT PANEL SOUNDINGS ----------------------------------
        gui.panel_sounding.figureid = figure( ...
            'Name', 'MRSFit - Sounding window', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'Toolbar', 'none', ...
            'HandleVisibility', 'on', ...
            'KeyPressFcn',@dokeyboardshortcut); % enable shortcuts
        
        screensz = get(0,'ScreenSize');
        set(gui.panel_sounding.figureid, 'Position', [570 screensz(4)-395 600 350])
        
        % + File menu
        gui.panel_sounding.menu_view = uimenu(gui.panel_sounding.figureid, ...
                'Label', 'View');
        gui.panel_sounding.menu_view_rdp = ...
            uimenu(gui.panel_sounding.menu_view, ...
                'Label', 'V: rdp-corr', ...
                'Checked', 'off', ...
                'Callback', @onViewRDPcorr);
        gui.panel_sounding.menu_view_df = ...
            uimenu(gui.panel_sounding.menu_view, ...
                'Label', 'phi: df-corr', ...
                'Checked', 'off', ...
                'Callback', @onViewDFcorr);
        
        %gui.panel_sounding.sndbox = uiextras.HBox('Parent', gui.panel_sounding.figureid, 'Spacing', 3);
        
        % ampl
        gui.panel_sounding.snd(1) = subplot(141);%, 'Parent', gui.panel_sounding.sndbox);
        title('Amplitude')
        xlabel('[nV]')
        ylabel('pulse moment q [As]')
        
        % T2*
        gui.panel_sounding.snd(2) = subplot(142);%axes('Parent', gui.panel_sounding.sndbox, 'ActivePositionProperty', 'OuterPosition');
        title('T2*')
        xlabel('ms')
        
        % df
        gui.panel_sounding.snd(3) = subplot(143);%axes('Parent', gui.panel_sounding.sndbox, 'ActivePositionProperty', 'OuterPosition');
        title('df')
        xlabel('Hz')
        
        % phase
        gui.panel_sounding.snd(4) = subplot(144);%axes('Parent', gui.panel_sounding.sndbox, 'ActivePositionProperty', 'OuterPosition');
        title('Phase')
        xlabel('deg')
        
        %% GENERATE PLOT PANEL FID ----------------------------------------
        gui.panel_fid.figureid = figure( ...
            'Name', 'MRSFit - FID window', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'Toolbar', 'none', ...
            'HandleVisibility', 'on', ...
            'KeyPressFcn',@dokeyboardshortcut); % enable shortcuts
        
        screensz = get(0,'ScreenSize');
        set(gui.panel_fid.figureid, 'Position', [570 screensz(4)-350-400 600 400])
        
        % window geometry
        t0 = [0 1]; v0 = [-1000 1000];  % dummy values
        
        % re(stk)
        gui.panel_fid.stk(1) = subplot(211);
        plot(t0,v0,'w-',t0,-v0,'w-')
        set(gca,'Color',[0 0 0])
        gui.panel_fid.txt_fid(1) = uicontrol( ...
            'Style', 'Text',...
            'String', 'Re',...
            'Units','normalized',...
            'Position', [1-0.075 1-0.125 0.05 0.05]);
        
        % im(stk)
        gui.panel_fid.stk(2) = subplot(212);
        plot(t0,v0,'w-',t0,-v0,'w-')
        set(gca,'Color',[0 0 0])
        gui.panel_fid.txt_fid(2) = uicontrol( ...
            'Style', 'Text',...
            'String', 'Im',...
            'Units','normalized',...
            'Position',[1-0.075 0.5-0.1 0.05 0.05]);
        
        %% GENERATE CONTROLS PANEL ----------------------------------------
        % Open a window and add some menus
        gui.panel_controls.figureid = figure( ...
            'Name', 'MRS Fit', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'Toolbar', 'none', ...
            'HandleVisibility', 'on', ....
            'KeyPressFcn',@dokeyboardshortcut); % enable shortcuts
        
        set(gui.panel_controls.figureid, 'Position', [1 screensz(4)-350-400 570 400])
        % Set default panel settings
        %         uiextras.set( gui.panel_controls.figureid, 'DefaultBoxPanelTitleColor', [0.7 0.7 0.7] );
        %uiextras.set( gui.panel_controls.figureid, 'DefaultBoxPanelFontSize', 12);
        %uiextras.set( gui.panel_controls.figureid, 'DefaultBoxPanelFontWeight', 'bold')
        %uiextras.set( gui.panel_controls.figureid, 'DefaultBoxPanelPadding', 5)
        %uiextras.set( gui.panel_controls.figureid, 'DefaultHBoxPadding', 2)
        
        % + Quit menu
        gui.panel_controls.menu_quit = uimenu(gui.panel_controls.figureid, ...
            'Label', 'Quit');
        gui.panel_controls.menu_quit_saveandquit = uimenu(gui.panel_controls.menu_quit, ...
            'Label', 'Save and Quit', ...
            'Callback', @onSaveAndQuit);
        uimenu(gui.panel_controls.menu_quit, ...
            'Label', 'Quit without saving', ...
            'Callback', @onQuitWithoutSave);
        
        % + File menu
        gui.panel_controls.menu_file = uimenu(gui.panel_controls.figureid, ...
            'Label', 'File');
        uimenu(gui.panel_controls.menu_file, ...
            'Label', 'Load', ...
            'Callback', @onLoad);
        uimenu(gui.panel_controls.menu_file, ...
            'Label', 'Save', ...
            'Callback', @onSave);
        
        % + Help menu
        gui.panel_controls.menu_help = uimenu(gui.panel_controls.figureid, 'Label', 'Help' );
        uimenu(gui.panel_controls.menu_help, ...
            'Label', 'Documentation', ...
            'Callback', @onHelp);
        
        % + Create boxes for the parameters
        mainbox = uiextras.HBox('Parent', gui.panel_controls.figureid);
        
        % + File & control parameters
        p1 = uiextras.BoxPanel('Parent', mainbox, 'Title', 'Data');
        
        box_p1v1 = uiextras.VBox('Parent', p1);
        gui.panel_controls.edit_path = uicontrol(...
            'Style', 'Edit', ...
            'Parent', box_p1v1, ...
            'Enable', 'on', ...
            'BackgroundColor', [1 1 1], ...
            'String', 'Enter path here', ...
            'Callback', @onEditPath);
        
        gui.panel_controls.edit_status = uicontrol(...
            'Style', 'Edit', ...
            'Parent', box_p1v1, ...
            'Enable', 'off', ...
            'BackgroundColor', [0 1 0], ...
            'String', 'Idle...');
        
        % popupmenu Q
        box_p1v1h1 = uiextras.HBox('Parent', box_p1v1);
        uicontrol('Style', 'Text', ...
            'HorizontalAlignment', 'right', ...
            'Parent', box_p1v1h1, ...
            'String', 'q  ');
        gui.panel_controls.popupmenu_Q = uicontrol(...
            'Style', 'popupmenu', ...
            'Parent', box_p1v1h1, ...
            'String', {'1', '2', '3'}, ...
            'Callback', @onSelectQ);
        gui.panel_controls.edit_Qvalue = uicontrol(...
            'Style', 'edit', ...
            'Enable', 'off',...
            'Parent', box_p1v1h1, ...
            'String', '0 As');
        
        % popupmenu RX
        box_p1v1h2 = uiextras.HBox('Parent', box_p1v1);
        uicontrol('Style', 'Text', ...
            'HorizontalAlignment', 'right', ...
            'Parent', box_p1v1h2, ...
            'String', 'rx  ');
        gui.panel_controls.popupmenu_RX = uicontrol(...
            'Style', 'popupmenu', ...
            'Parent', box_p1v1h2, ...
            'String', {'1', '2', '3', '4'}, ...
            'Callback', @onSelectRX);
        gui.panel_controls.edit_RXchannel = uicontrol(...
            'Style', 'edit', ...
            'Enable', 'off',...
            'Parent', box_p1v1h2, ...
            'String', 'CH 1');        
%         uicontrol(...
%             'Style', 'text', ...
%             'Enable', 'off',...
%             'Parent', box_p1v1h2);   
        
        % popupmenu SIG
        box_p1v1h3 = uiextras.HBox('Parent', box_p1v1);
        uicontrol('Style', 'Text', ...
            'HorizontalAlignment', 'right', ...
            'Parent', box_p1v1h3, ...
            'String', 'sig ');
        gui.panel_controls.popupmenu_SIG = uicontrol(...
            'Style', 'popupmenu', ...
            'Parent', box_p1v1h3, ...
            'String', {'1', '2', '3', '4'}, ...
            'Callback', @onSelectSIG);
        uicontrol(...
            'Style', 'text', ...
            'Enable', 'off',...
            'Parent', box_p1v1h3);
        
        uiextras.HBox('Parent', box_p1v1);  % emtpy box
        
        % Edit trim
        box_p1v1h4 = uiextras.HBox('Parent', box_p1v1);
        uicontrol('Style', 'Text', ...
            'HorizontalAlignment', 'right', ...
            'Parent', box_p1v1h4, ...
            'String', 'trim rec. time (min/max) [s]');
        uicontrol('Style', 'Text', ...
            'HorizontalAlignment', 'right', ...
            'Parent', box_p1v1h4, ...
            'String', '');
        gui.panel_controls.edit_minRec = uicontrol(...
            'Style', 'edit', ...
            'Enable', 'on',...
            'Parent', box_p1v1h4, ...
            'String', '-');
        gui.panel_controls.edit_maxRec = uicontrol(...
            'Style', 'edit', ...
            'Enable', 'on',...
            'Parent', box_p1v1h4, ...
            'String', '-');
        set(box_p1v1h4, 'Sizes', [70 -1 50 50])
        
        % pushbutton trim
        box_p1v1h5 = uiextras.HBox('Parent', box_p1v1);
         gui.panel_controls.pushbutton_trim = uicontrol(...
            'Style', 'Pushbutton', ...
            'HorizontalAlignment', 'center', ...
            'FontWeight','bold',...
            'Parent', box_p1v1h5, ...
            'String', 'Do Trim',...
            'Callback',@onDoTrim);
         gui.panel_controls.pushbutton_undotrim = uicontrol(...
            'Style', 'Pushbutton', ...
            'HorizontalAlignment', 'center', ...
            'FontWeight','bold',...
            'Parent', box_p1v1h5, ...
            'String', 'Undo',...
            'Callback',@onUndoTrim);
        
        % togglebutton trim
        box_p1v1h6 = uiextras.HBox('Parent', box_p1v1);
            uicontrol(...
                'Style', 'Text', ...
                'Parent', box_p1v1h6, ...
                'HorizontalAlignment', 'left', ...
                'String', 'Apply to: ');
            gui.panel_controls.togglebutton_q = uicontrol(...
                'Style', 'Togglebutton', ...
                'Parent', box_p1v1h6, ...
                'String', 'q',...
                'Tag','q',...                
                'Callback', @ontogglebutton_trim);
            gui.panel_controls.togglebutton_sig = uicontrol(...
                'Style', 'Togglebutton', ...
                'Parent', box_p1v1h6, ...
                'String', 'sig',...
                'Tag','sig',...                
                'Callback', @ontogglebutton_trim);
            gui.panel_controls.togglebutton_rx = uicontrol(...
                'Style', 'Togglebutton', ...
                'Parent', box_p1v1h6, ...
                'String', 'rx',...
                'Tag','rx',...
                'Callback', @ontogglebutton_trim);
        uiextras.HBox('Parent', box_p1v1);  % emtpy box        
        
        set(box_p1v1, 'Sizes', [28 28 28 28 28 -1 38 28 28 -1])
        
        % assign primary and reference receivers ???
        p2 = uiextras.BoxPanel('Parent', mainbox, 'Title', 'Fitting');
        
        box_p2v1 = uiextras.VBox('Parent', p2);
        
        box_p2v1h1 = uiextras.HBox('Parent', box_p2v1);
        uicontrol('Style', 'Text', ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h1, ...
            'String', ' ');
        uicontrol('Style', 'Text', ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h1, ...
            'String', 'min');
        uicontrol('Style', 'Text', ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h1, ...
            'String', 'ini');
        uicontrol('Style', 'Text', ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h1, ...
            'String', 'max');
        uicontrol('Style', 'Text', ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h1, ...
            'String', 'fit');
        
        box_p2v1h2 = uiextras.HBox('Parent', box_p2v1);
        gui.panel_controls.edit_v0label = uicontrol('Style', 'Text', ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h2, ...
            'String', 'V0 [nV]');
        gui.panel_controls.edit_v0min = uicontrol(...
            'Style', 'Edit', ...
            'Enable', 'on', ...
            'BackgroundColor', [1 1 1], ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h2, ...
            'String', '-',...
            'Callback', @onEditFitpar);
        gui.panel_controls.edit_v0ini = uicontrol(...
            'Style', 'Edit', ...
            'Enable', 'on', ...
            'BackgroundColor', [1 1 1], ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h2, ...
            'String', '-',...
            'Callback', @onEditFitpar);
        gui.panel_controls.edit_v0max = uicontrol(...
            'Style', 'Edit', ...
            'Enable', 'on', ...
            'BackgroundColor', [1 1 1], ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h2, ...
            'String', '-',...
            'Callback', @onEditFitpar);
        gui.panel_controls.edit_v0fit = uicontrol(...
            'Style', 'Edit', ...
            'Enable', 'on', ...
            'FontWeight', 'bold', ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h2, ...
            'String', '-');
        
        box_p2v1h3 = uiextras.HBox('Parent', box_p2v1);
        gui.panel_controls.edit_t2slabel = uicontrol('Style', 'Text', ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h3, ...
            'String', 'T2* [ms]');
        gui.panel_controls.edit_t2smin = uicontrol(...
            'Style', 'Edit', ...
            'Enable', 'on', ...
            'BackgroundColor', [1 1 1], ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h3, ...
            'String', '-',...
            'Callback', @onEditFitpar);
        gui.panel_controls.edit_t2sini = uicontrol(...
            'Style', 'Edit', ...
            'Enable', 'on', ...
            'BackgroundColor', [1 1 1], ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h3, ...
            'String', '-',...
            'Callback', @onEditFitpar);
        gui.panel_controls.edit_t2smax = uicontrol(...
            'Style', 'Edit', ...
            'Enable', 'on', ...
            'BackgroundColor', [1 1 1], ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h3, ...
            'String', '-',...
            'Callback', @onEditFitpar);
        gui.panel_controls.edit_t2sfit = uicontrol(...
            'Style', 'Edit', ...
            'Enable', 'on', ...
            'FontWeight', 'bold', ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h3, ...
            'String', '-');
        
        box_p2v1h4 = uiextras.HBox('Parent', box_p2v1);
        uicontrol('Style', 'Text', ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h4, ...
            'String', 'df [Hz]');
        gui.panel_controls.edit_dfmin = uicontrol(...
            'Style', 'Edit', ...
            'Enable', 'on', ...
            'BackgroundColor', [1 1 1], ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h4, ...
            'String', '-',...
            'Callback', @onEditFitpar);
        gui.panel_controls.edit_dfini = uicontrol(...
            'Style', 'Edit', ...
            'Enable', 'on', ...
            'BackgroundColor', [1 1 1], ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h4, ...
            'String', '-',...
            'Callback', @onEditFitpar);
        gui.panel_controls.edit_dfmax = uicontrol(...
            'Style', 'Edit', ...
            'Enable', 'on', ...
            'BackgroundColor', [1 1 1], ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h4, ...
            'String', '-',...
            'Callback', @onEditFitpar);
        gui.panel_controls.edit_dffit = uicontrol(...
            'Style', 'Edit', ...
            'Enable', 'on', ...
            'FontWeight', 'bold', ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h4, ...
            'String', '-');
        
        box_p2v1h5 = uiextras.HBox('Parent', box_p2v1);
        uicontrol('Style', 'Text', ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h5, ...
            'String', 'phi [rad]');
        gui.panel_controls.edit_phimin = uicontrol(...
            'Style', 'Edit', ...
            'Enable', 'on', ...
            'BackgroundColor', [1 1 1], ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h5, ...
            'String', '-',...
            'Callback', @onEditFitpar);
        gui.panel_controls.edit_phiini = uicontrol(...
            'Style', 'Edit', ...
            'Enable', 'on', ...
            'BackgroundColor', [1 1 1], ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h5, ...
            'String', '-',...
            'Callback', @onEditFitpar);
        gui.panel_controls.edit_phimax = uicontrol(...
            'Style', 'Edit', ...
            'Enable', 'on', ...
            'BackgroundColor', [1 1 1], ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h5, ...
            'String', '-',...
            'Callback', @onEditFitpar);
        gui.panel_controls.edit_phifit = uicontrol(...
            'Style', 'Edit', ...
            'Enable', 'on', ...
            'FontWeight', 'bold', ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h5, ...
            'String', '-');
        
        uiextras.HBox('Parent', box_p2v1);   % empty
        
        box_p2v1h6 = uiextras.HBox('Parent', box_p2v1);
        uicontrol('Style', 'Text', ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h6, ...
            'String', 'Fix fit parameters');
        
        box_p2v1h7 = uiextras.HBox('Parent', box_p2v1);
        gui.panel_controls.toggle_v0min = uicontrol(...
            'Style', 'Togglebutton', ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h7, ...
            'String', 'V0 min',...
            'Tag','v0min',...
            'Callback',@ontogglebutton_fit);
        gui.panel_controls.toggle_v0ini = uicontrol(...
            'Style', 'Togglebutton', ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h7, ...
            'String', 'V0 ini',...
            'Tag','v0ini',...
            'Callback',@ontogglebutton_fit);
        gui.panel_controls.toggle_v0max = uicontrol(...
            'Style', 'Togglebutton', ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h7, ...
            'String', 'V0 max',...
            'Tag','v0max',...
            'Callback',@ontogglebutton_fit);
        
        box_p2v1h8 = uiextras.HBox('Parent', box_p2v1);
        gui.panel_controls.toggle_t2smin = uicontrol(...
            'Style', 'Togglebutton', ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h8, ...
            'String', 'T2* min',...
            'Tag','t2smin',...
            'Callback',@ontogglebutton_fit);
        gui.panel_controls.toggle_t2sini = uicontrol(...
            'Style', 'Togglebutton', ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h8, ...
            'String', 'T2* ini',...
            'Tag','t2sini',...
            'Callback',@ontogglebutton_fit);
        gui.panel_controls.toggle_t2smax = uicontrol(...
            'Style', 'Togglebutton', ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h8, ...
            'String', 'T2* max',...
            'Tag','t2smax',...
            'Callback',@ontogglebutton_fit);
        
        box_p2v1h9 = uiextras.HBox('Parent', box_p2v1);
        gui.panel_controls.toggle_dfmin = uicontrol(...
            'Style', 'Togglebutton', ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h9, ...
            'String', 'df min',...
            'Tag','dfmin',...
            'Callback',@ontogglebutton_fit);
        gui.panel_controls.toggle_dfini = uicontrol(...
            'Style', 'Togglebutton', ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h9, ...
            'String', 'df ini',...
            'Tag','dfini',...
            'Callback',@ontogglebutton_fit);
        gui.panel_controls.toggle_dfmax = uicontrol(...
            'Style', 'Togglebutton', ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h9, ...
            'String', 'df max',...
            'Tag','dfmax',...
            'Callback',@ontogglebutton_fit);
        
        box_p2v1h10 = uiextras.HBox('Parent', box_p2v1);
        gui.panel_controls.toggle_phimin = uicontrol(...
            'Style', 'Togglebutton', ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h10, ...
            'String', 'phi min',...
            'Tag','phimin',...
            'Callback',@ontogglebutton_fit);
        gui.panel_controls.toggle_phiini = uicontrol(...
            'Style', 'Togglebutton', ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h10, ...
            'String', 'phi ini',...
            'Tag','phiini',...
            'Callback',@ontogglebutton_fit);
        gui.panel_controls.toggle_phimax = uicontrol(...
            'Style', 'Togglebutton', ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_p2v1h10, ...
            'String', 'phi max',...
            'Tag','phimax',...
            'Callback',@ontogglebutton_fit);
        
        box_p2v1h11 = uiextras.HBox('Parent', box_p2v1);
        gui.panel_controls.pushbutton_fit = uicontrol(...
            'Style', 'Pushbutton', ...
            'HorizontalAlignment', 'center', ...
            'FontWeight','bold',...
            'Parent', box_p2v1h11, ...
            'String', 'Fit',...
            'Callback',@onFit);
        gui.panel_controls.pushbutton_fitall = uicontrol(...
            'Style', 'Pushbutton', ...
            'HorizontalAlignment', 'center', ...
            'FontWeight','bold',...
            'Parent', box_p2v1h11, ...
            'String', 'Fit all',...
            'Callback',@onFitall);
        
        set(mainbox, 'Sizes', [-2 -3])
    end

%% MENU LOAD --------------------------------------------------------------
    function onLoad(a,call)
        
        if ~isnumeric(call)% workaround for matlab 2014b
            call=0;
        end
        % get MRSMatlab *.mrsd file
        if standalone == 1  % MRSFit standalone (not started by MRSWorkflow)
            if call == 1    % command comes from edit path
                file = get(gui.panel_controls.edit_path,'String');
                [pathstr, name, ext] = fileparts(file);
                filename = [name ext];
                filepath = [pathstr filesep];
            else            % command comes from menu selection
                inifile = mrs_readinifile;  % read ini file and get last .mrsd file (if exist)
                if strcmp(inifile.MRSData.file,'none') == 1
                    inifile.MRSData.path = [pwd filesep];
                    inifile.MRSData.file = 'mrs_project';                    
                end
                [filename,filepath] = uigetfile(...
                    {'*.mrsd','MRSData File (*.mrsd)';
                    '*.*',  'All Files (*.*)'}, ...
                    'Pick a MRSData file',...
                    [inifile.MRSData.path inifile.MRSData.file]);                
                if filepath == 0  % exit if aborted (CANCEL in uigetfile)
                    disp('Aborting...'); 
                    drawnow
                    return
                end
            end                
        else    % MRSFit started from MRSworkflow - load proclog from inputfile delivered by MRSWorkflow
            [pathstr, name, ext] = fileparts(sounding_pathdirfile);
            filepath = [pathstr filesep];
            filename = [name ext];
        end
        
        % reset structures & load proclog
        fdata   = struct();
        proclog = struct();  
        proclog = mrs_load_proclog(filepath, filename);
        
        % check version
        savedversion    = proclog.MRSversion;
%         softwareversion = mrs_version;
        if ~isequal(savedversion,mrs_version)
            msgbox('The selected .mrsd-file is outdated. Running MRSUpdate is recommended.','Outdated .mrsd file')
            mrs_setguistatus(gui,0)
            %return
        end
        
        % reprocess data
        mrs_setguistatus(gui,1,'Reprocessing data...')
        id    = find(proclog.event(:,1) > 100);   % reprocess all events of type >100 (<100 is done in MRSSigPro)
        fdata = mrs_reprocess_proclog(fdata, proclog, id); 
        mrs_setguistatus(gui,0)
        
        if standalone == 1
            % set path to sounding; if not standalone: only display file
            set(gui.panel_controls.edit_path,'String',[filepath, filename])
        end
        
        % check available signal
        for isig=4:-1:2
            if proclog.Q(1).rx(1).sig(isig).recorded == 1
                set(gui.panel_controls.popupmenu_SIG, 'Value',isig);
            end
        end
        %set(gui.panel_controls.popupmenu_SIG,'Value',2)
        
        % find out q's in path and pipe to q dropdown menu
        set(gui.panel_controls.popupmenu_Q,'String',mrs_getX('Q',proclog))
        set(gui.panel_controls.popupmenu_Q,'Value',1)
        
        % find out number of channels and pipe to rx menu
        set(gui.panel_controls.popupmenu_RX,'String',num2str((1:length(proclog.rxinfo))'))
        
        if proclog.status < 3   % if not a reload
            proclog = initializefitparameters(proclog); % set initial fitpars
            onFitall(0,0);      % fit all data
        end
        refreshtrim;
        refreshfitparameters;
        mrs_plotfit(gui,proclog);
    end


%% MENU SAVE & QUIT -------------------------------------------------------
% --- Executes on menu selection save & quit.
    function onSaveAndQuit(a,b)
        proclog.status = 3;     % set status:processed in MRSFit
        save(sounding_pathdirfile, 'proclog');
        fprintf(1,'proclog saved to %s\n', sounding_pathdirfile);
        mrs_updateinifile(sounding_pathdirfile,1);
        welldone = 1;
        uiresume;
        delete(gui.panel_controls.figureid)
        delete(gui.panel_sounding.figureid)
        delete(gui.panel_fid.figureid)
    end

%% MENU SAVE --------------------------------------------------------------
% --- Executes on menu selection save. Saves proclog structure.
    function onSave(a,b)
        
        [filename,filepath] = uiputfile({...
            '*.mrsd','MRSmatlab data file'; '*.*','All Files' },...
            'Save MRSMatlab data file',...
            [proclog.path]);
        
        if filepath == 0;
            disp('Aborting...')
            return
        end
        
        % save
        outfile = [filepath filename];
        proclog.status = 3;
        save(outfile,'proclog');
        fprintf(1,'proclog saved to %s\n', outfile);        
        mrs_updateinifile(outfile,1);
        welldone = 1;
    end

%% MENU QUIT WITHOUT SAVE -------------------------------------------------
% --- Executes on menu selection Quit.
    function onQuitWithoutSave(a,b)
        uiresume
        delete(gui.panel_controls.figureid)
        delete(gui.panel_sounding.figureid)
        delete(gui.panel_fid.figureid)
        welldone = 0;        
    end

%% MENU VIEW RDP CORRECTION -----------------------------------------------
% --- Executes on menu selection Quit.
    function onViewRDPcorr(a,b)
        switch get(gui.panel_sounding.menu_view_rdp, 'Checked');
            case 'off'  % turn on
                set(gui.panel_sounding.menu_view_rdp, 'Checked','On');
                mrs_plotfit(gui,proclog);
            case 'on'   % turn off
                set(gui.panel_sounding.menu_view_rdp, 'Checked','Off');
                mrs_plotfit(gui,proclog);
        end
    end

%% MENU VIEW DF CORRECTION ------------------------------------------------
% --- Executes on menu selection View df corr.
    function onViewDFcorr(a,b)
        switch get(gui.panel_sounding.menu_view_df, 'Checked');
            case 'off'  % turn on
                set(gui.panel_sounding.menu_view_df, 'Checked','On');
                mrs_plotfit(gui,proclog);
            case 'on'  % turn off
                set(gui.panel_sounding.menu_view_df, 'Checked','Off');
                mrs_plotfit(gui,proclog);
        end
    end

%% SELECT Q ---------------------------------------------------------------
% --- Executes on selection change in popupmenu_Q.
    function onSelectQ(a,b)
        refreshtrim;
        refreshfitparameters;
        mrs_plotfit(gui,proclog);
    end

%% SELECT RX --------------------------------------------------------------
% --- Executes on selection change in popupmenu_RX.
    function onSelectRX(a,b)
        releasetogglebuttons;
        refreshfitparameters;
        mrs_plotfit(gui,proclog);
    end

%% SELECT SIG -------------------------------------------------------------
% --- Executes on selection change in popupmenu_Q.
    function onSelectSIG(a,b)
        
        iQ   = get(gui.panel_controls.popupmenu_Q, 'Value');
        isig = get(gui.panel_controls.popupmenu_SIG, 'Value');
        
        % block signal switch if sig not recorded
        if proclog.Q(iQ).rx(1).sig(isig).recorded == 0
            set(gui.panel_controls.popupmenu_SIG, 'Value',2);
        end
        releasetogglebuttons;
        refreshfitparameters;
        switch isig
            case {2,3}
                set(gui.panel_controls.edit_v0label,'string', 'V0 (nV)');   % [nV]
                set(gui.panel_controls.edit_t2slabel,'string', 'T2* [ms]');  % [ms]
                set(gui.panel_controls.edit_dfmin,'enable', 'on');   % [Hz]
                set(gui.panel_controls.edit_dfmax,'enable', 'on');   % [Hz]
                set(gui.panel_controls.edit_dfini,'enable', 'on');  % [Hz]
                set(gui.panel_controls.edit_phimin,'enable', 'on');  % [rad]
                set(gui.panel_controls.edit_phimax,'enable', 'on');  % [rad]
                set(gui.panel_controls.edit_phiini,'enable', 'on'); % [rad]
                % rebuild sounding figure + File menu
                figure(gui.panel_sounding.figureid);
                gui.panel_sounding.menu_view = uimenu(gui.panel_sounding.figureid, ...
                    'Label', 'View');
                gui.panel_sounding.menu_view_rdp = ...
                    uimenu(gui.panel_sounding.menu_view, ...
                    'Label', 'V: rdp-corr', ...
                    'Checked', 'off', ...
                    'Callback', @onViewRDPcorr);
                gui.panel_sounding.menu_view_df = ...
                    uimenu(gui.panel_sounding.menu_view, ...
                    'Label', 'phi: df-corr', ...
                    'Checked', 'off', ...
                    'Callback', @onViewDFcorr);
                
                %gui.panel_sounding.sndbox = uiextras.HBox('Parent', gui.panel_sounding.figureid, 'Spacing', 3);
                
                % ampl
                gui.panel_sounding.snd(1) = subplot(141);%, 'Parent', gui.panel_sounding.sndbox);
                title('Amplitude')
                xlabel('[nV]')
                ylabel('pulse moment q [As]')
                
                % T2*
                gui.panel_sounding.snd(2) = subplot(142);%axes('Parent', gui.panel_sounding.sndbox, 'ActivePositionProperty', 'OuterPosition');
                title('T2*')
                xlabel('ms')
                
                % df
                gui.panel_sounding.snd(3) = subplot(143);%axes('Parent', gui.panel_sounding.sndbox, 'ActivePositionProperty', 'OuterPosition');
                title('df')
                xlabel('Hz')
                
                % phase
                gui.panel_sounding.snd(4) = subplot(144);%axes('Parent', gui.panel_sounding.sndbox, 'ActivePositionProperty', 'OuterPosition');
                title('Phase')
                xlabel('deg')
            case {4}
                set(gui.panel_controls.edit_v0label,'string', 'V0 echo [nV]');   % [nV]
                set(gui.panel_controls.edit_t2slabel,'string', 'T2* echo [ms]');  % [ms]
                set(gui.panel_controls.edit_dfmin,'enable', 'off');   % [Hz]
                set(gui.panel_controls.edit_dfmax,'enable', 'off');   % [Hz]
                set(gui.panel_controls.edit_dfini,'enable', 'off');  % [Hz]
                set(gui.panel_controls.edit_phimin,'enable', 'off');  % [rad]
                set(gui.panel_controls.edit_phimax,'enable', 'off');  % [rad]
                set(gui.panel_controls.edit_phiini,'enable', 'off'); % [rad]
        end
        mrs_plotfit(gui,proclog);
    end

%% EDIT FITPAR ------------------------------------------------------------
% --- Executes on edit in fitparameters.
    function onEditFitpar(a,b)
        releasetogglebuttons
        getuserstartvalues;
        refreshfitparameters;
    end

%% EDIT PATH --------------------------------------------------------------
% --- Executes on selection in menu_file or directly when called 
%     from MRSWorkflow.
    function onEditPath(a,b)
        onLoad(0,1);
    end

%% PUSHBUTTON FIT ---------------------------------------------------------
% --- Executes on button press in pushbutton_fit.
% Fit FID for currently selected Q & SIG
    function onFit(a,b)
        
        % Determine current FID
        iQ      = get(gui.panel_controls.popupmenu_Q, 'Value');
        irx     = get(gui.panel_controls.popupmenu_RX, 'Value');
        isig    = get(gui.panel_controls.popupmenu_SIG, 'Value');
        
        % Obtain trim indices
        [it1, it2] = mrs_gettrim(proclog,iQ,irx,isig);
        
        % Assemble parameters
        t   = proclog.Q(iQ).rx(irx).sig(isig).t(it1:it2);
        v   = proclog.Q(iQ).rx(irx).sig(isig).V(it1:it2);
        lb  = proclog.Q(iQ).rx(irx).sig(isig).lb;
        ini = proclog.Q(iQ).rx(irx).sig(isig).ini;
        ub  = proclog.Q(iQ).rx(irx).sig(isig).ub;
        
        switch isig
            case {2,3}
                % Fit
                [f,e]  = mrs_fitFID(t,v,lb,ini,ub);
                fc     = mrs_fitcorrections(f,iQ,isig);

                % Assemble output
                proclog.Q(iQ).rx(irx).sig(isig).fit  = f;
                proclog.Q(iQ).rx(irx).sig(isig).fite = e;
                proclog.Q(iQ).rx(irx).sig(isig).fitc = fc;
            case 4
                if proclog.Q(iQ).rx(irx).sig(isig).recorded == 1
                    t   = proclog.Q(iQ).rx(irx).sig(isig).t;
                    v   = proclog.Q(iQ).rx(irx).sig(isig).V;
                    
                    % extract echo parameter
                    
%                     switch proclog.device
%                         case 'MRSModelling'
                             nE = proclog.Q(iQ).rx(irx).sig(isig).nE;
                             echotimes = proclog.Q(iQ).rx(irx).sig(isig).echotimes;
%                         otherwise 
%                             nE = round(max(proclog.Q(1).rx(1).sig(4).t)/proclog.Q(1).timing.tau_e);
%                             echotimes = proclog.Q(1).timing.tau_e/2-proclog.Q(1).timing.tau_p2/2-proclog.Q(1).timing.tau_dead1;
%                             for iE=2:nE
%                                 echotimes=[echotimes echotimes(iE-1) + proclog.Q(1).timing.tau_e];
%                             end
%                     end
                    %   t2s n-times amplitude (one for each echo)
                    lb_echo  = [lb(2)  zeros(1,nE)];
                    ini_echo = [ini(2) ini(1)*ones(1,nE)];
                    ub_echo  = [ub(2) ub(1)*ones(1,nE)];
                    
                    [f,s,e] = mrs_fitEchoTrain(t,v,echotimes,lb_echo,ini_echo,ub_echo);
                    
                    proclog.Q(iQ).rx(irx).sig(isig).fit        = [f];
                    proclog.Q(iQ).rx(irx).sig(isig).echotimes  = echotimes;
                    proclog.Q(iQ).rx(irx).sig(isig).V_fit      = s;
                    proclog.Q(iQ).rx(irx).sig(isig).fite       = e(2:end);
                    proclog.Q(iQ).rx(irx).sig(isig).fitc       = e(2:end);
                end
        end
        proclog.status = 3;
        refreshfitparameters;
        mrs_plotfit(gui,proclog);
    end

%% PUSHBUTTON FIT ALL -----------------------------------------------------
% --- Executes on button press in pushbutton_fit.
% fit current Q & SIG
    function onFitall(a,b)
        mrs_setguistatus(gui,1,'Fitting data...')
        for iQ = 1:length(proclog.Q)
            for irx = 1:length(proclog.rxinfo)  
                    for isig = 2:3
                        if proclog.Q(iQ).rx(irx).sig(isig).recorded == 1
                            
                            % Obtain trim indices 
                            [it1, it2] = mrs_gettrim(proclog,iQ,irx,isig);
                            
                            % Assemble parameters
                            t   = proclog.Q(iQ).rx(irx).sig(isig).t(it1:it2);
                            v   = proclog.Q(iQ).rx(irx).sig(isig).V(it1:it2);
                            lb  = proclog.Q(iQ).rx(irx).sig(isig).lb;
                            ini = proclog.Q(iQ).rx(irx).sig(isig).ini;
                            ub  = proclog.Q(iQ).rx(irx).sig(isig).ub;
                            
                            % Fit
                            [f,e]  = mrs_fitFID(t,v,lb,ini,ub); 
                            fc     = mrs_fitcorrections(f,iQ,isig);

                            % Assemble output
                            proclog.Q(iQ).rx(irx).sig(isig).fit  = f;
                            proclog.Q(iQ).rx(irx).sig(isig).fite = e;
                            proclog.Q(iQ).rx(irx).sig(isig).fitc = fc;                    

                        else
                            % skip if signal not recorded
                        end
                    end
                    for isig = 4
                        if proclog.Q(iQ).rx(irx).sig(isig).recorded == 1
                            t   = proclog.Q(iQ).rx(irx).sig(isig).t;
                            v   = proclog.Q(iQ).rx(irx).sig(isig).V;
                            
%                             switch proclog.device
%                                 case 'MRSModelling'
                                     nE = proclog.Q(iQ).rx(irx).sig(isig).nE;
                                     echotimes = proclog.Q(iQ).rx(irx).sig(isig).echotimes;
%                                 otherwise
%                                     nE = round(max(proclog.Q(1).rx(1).sig(4).t)/proclog.Q(1).timing.tau_e);
%                                     echotimes = proclog.Q(1).timing.tau_e/2-proclog.Q(1).timing.tau_p2/2-proclog.Q(1).timing.tau_dead1;
%                                     for iE=2:nE
%                                         echotimes=[echotimes echotimes(iE-1) + proclog.Q(1).timing.tau_e];
%                                     end
%                             end
                            
                            %   t2s n-times amplitude (one for each echo)
                            lb_echo  = [lb(2)  zeros(1,nE)];
                            ini_echo = [ini(2) ini(1)*ones(1,nE)];
                            ub_echo  = [ub(2) ub(1)*ones(1,nE)];                        
                           
                            [f,s,e] = mrs_fitEchoTrain(t,v,echotimes,lb_echo,ini_echo,ub_echo);
                            
                            proclog.Q(iQ).rx(irx).sig(isig).fit  = [f];
                            proclog.Q(iQ).rx(irx).sig(isig).V_fit  = s;
                            proclog.Q(iQ).rx(irx).sig(isig).fite = e(2:end);
                            proclog.Q(iQ).rx(irx).sig(isig).fitc = e(2:end);
                        end
                    end
            end
        end
        proclog.status = 3;
        mrs_setguistatus(gui,0)
        refreshfitparameters;
        mrs_plotfit(gui,proclog);
    end

%% PUSHBUTTON TRIM --------------------------------------------------------
% --- cut time series at beginning and/or end
    function onDoTrim(a,b)
        
        % Determine current FID
        iQ   = get(gui.panel_controls.popupmenu_Q, 'Value');
        irx  = get(gui.panel_controls.popupmenu_RX, 'Value');
        isig = get(gui.panel_controls.popupmenu_SIG, 'Value');
        
        % Get user input
        mint = str2double(get(gui.panel_controls.edit_minRec,'String'));
        maxt = str2double(get(gui.panel_controls.edit_maxRec,'String'));        
        
        % determine which FID's to trim
        whatisALL = bin2dec([...
                   num2str(get(gui.panel_controls.togglebutton_sig,'Value')), ...
                   num2str(get(gui.panel_controls.togglebutton_rx,'Value')), ...
                   num2str(get(gui.panel_controls.togglebutton_q,'Value'))]);
        switch whatisALL
            case bin2dec('000')  % only currently displayed FID
                theseQ   = iQ;
                theseRX  = irx;
                theseSIG = isig;
            case bin2dec('001')  % all Q
                theseQ   = 1:length(proclog.Q);
                theseRX  = irx;
                theseSIG = isig;
            case bin2dec('101')  % all sig & Q
                theseQ   = 1:length(proclog.Q);
                theseRX  = irx;
                theseSIG = 1:length(proclog.Q(iQ).rx(irx).sig);                
            case bin2dec('111')  % all sig & Q & rx
                theseQ   = 1:length(proclog.Q);
                theseRX  = 1:length(proclog.Q(iQ).rx);
                theseSIG = 1:length(proclog.Q(iQ).rx(irx).sig);
        end

        % execute trim on selected FID's
        for iirx = theseRX
            for iisig = theseSIG
                if proclog.Q(iQ).rx(irx).sig(iisig).recorded == 1
                    for iiQ = theseQ
                        proclog = trim_fid(proclog,iiQ,iirx,iisig,mint,maxt);
                    end
                end
            end     
        end

        % Plot 
        mrs_plotfit(gui,proclog);
    end

%% PUSHBUTTON UNDO TRIM ---------------------------------------------------
% --- reset time series 
    function onUndoTrim(a,b)
        
        % Determine current FID
        iQ   = get(gui.panel_controls.popupmenu_Q, 'Value');
        irx  = get(gui.panel_controls.popupmenu_RX, 'Value');
        isig = get(gui.panel_controls.popupmenu_SIG, 'Value');
        
        % determine which fid's to trim
        whatisALL = bin2dec([...
                   num2str(get(gui.panel_controls.togglebutton_sig,'Value')), ...
                   num2str(get(gui.panel_controls.togglebutton_rx,'Value')), ...
                   num2str(get(gui.panel_controls.togglebutton_q,'Value'))]);
        switch whatisALL
            case bin2dec('000')  % only currently displayed FID
                theseQ   = iQ;
                theseRX  = irx;
                theseSIG = isig;
            case bin2dec('001')  % all Q
                theseQ   = 1:length(proclog.Q);
                theseRX  = irx;
                theseSIG = isig;
            case bin2dec('101')  % all sig & Q
                theseQ   = 1:length(proclog.Q);
                theseRX  = irx;
                theseSIG = 1:length(proclog.Q(iQ).rx(irx).sig);                
            case bin2dec('111')  % all sig & Q
                theseQ   = 1:length(proclog.Q);
                theseRX  = 1:length(proclog.Q(iQ).rx);
                theseSIG = 1:length(proclog.Q(iQ).rx(irx).sig);
        end
        
        % execute undo trim on selected FID's
        for iirx = theseRX
            for iisig = theseSIG
                if proclog.Q(iQ).rx(irx).sig(iisig).recorded == 1
                    for iiQ = theseQ
                        proclog = undo_trim_fid(proclog,iiQ,iirx,iisig);
                    end
                end
            end     
        end        
        
        % Update gui
        set(gui.panel_controls.edit_minRec,'String',num2str(proclog.Q(iQ).rx(irx).sig(isig).t(1)))  % ==0
        set(gui.panel_controls.edit_maxRec,'String',num2str(proclog.Q(iQ).rx(irx).sig(isig).t(end)))
        mrs_plotfit(gui,proclog);
    end

%% TOGGLEBUTTONS TRIM -----------------------------------------------------
% --- Executes on press on togglebuttons in FLOW section.
%     Toggles between current and all time series. Button priority is rec,
%     q, rx, sig (lowest to highest). That means, if sig is toggled to ALL,
%     then all other buttons are also toggled to ALL (and can't be changed
%     unless sig is toggled off again).
    function ontogglebutton_trim(a,b)
        
        % button id
        X(1) = get(gui.panel_controls.popupmenu_Q,   'Value'); % button 1
        X(2) = get(gui.panel_controls.popupmenu_SIG, 'Value'); % button 3
        X(3) = get(gui.panel_controls.popupmenu_RX,  'Value'); % button 2        
        
        % button parameters
        bval  = [1 2 4];
        bname = {'q', 'sig', 'rx'};        
        
        % determine which buttons are on
        status = bin2dec([...
            num2str(get(gui.panel_controls.togglebutton_rx,'Value')), ...
            num2str(get(gui.panel_controls.togglebutton_sig,'Value')), ...
            num2str(get(gui.panel_controls.togglebutton_q,'Value'))]);
        
        % enable current and all lower-order buttons
        for ib = 1:3
            tag = ['togglebutton_',bname{ib}];
            if status >= bval(ib)
                set(gui.panel_controls.(tag), ...
                     'Value',1, ...
                     'String',[bname{ib},'(:)']);
            else
                set(gui.panel_controls.(tag),...
                     'Value',0, ...
                     'String',[bname{ib},'(',num2str(X(ib)),')']);
            end
        end
    end


%% TOGGLEBUTTONS FIT ------------------------------------------------------
% --- Executes on press on togglebutton. 
% If toggle is set to on: set the fitparameter to this value for all Q and 
% this signal (isig). 
% If toggle is set to off: allow individual fitparameter settings.

    function ontogglebutton_fit(a,b)
        tag = ['edit_',get(a,'Tag')];   % get tag of current togglebutton
        if get(a,'Value') == 1 % if togglebutton is pressed
            
            % set parameter the same for all Q at this sig
            iQ   = get(gui.panel_controls.popupmenu_Q, 'Value');
            irx  = get(gui.panel_controls.popupmenu_RX, 'Value');
            isig = get(gui.panel_controls.popupmenu_SIG, 'Value');
            
            whatbound = tag(end-2:end);
            switch whatbound
                case 'min'
                    bds = 'lb';
                case 'ini'
                    bds = 'ini';
                case 'max'
                    bds = 'ub';
            end
            
            whatpara = tag(6:7);
            switch whatpara
                case 'v0'
                    para = 1;
                case 't2'
                    para = 2;
                case 'df'
                    para = 3;
                case 'ph'
                    para = 4;
            end
            
            bvalue = proclog.Q(iQ).rx(irx).sig(isig).(bds)(para);   % value of current bound
            
            for iQ = 1:length(proclog.Q)
                proclog.Q(iQ).rx(irx).sig(isig).(bds)(para) = bvalue;   % set bounds for all Q's to current bound
            end
            set(gui.panel_controls.(tag), ...
                'BackgroundColor', [0.8 0.8 0.8])
        else
            set(gui.panel_controls.(tag), ...
                'BackgroundColor', 'w')
        end
    end

%% FUNCTION RELEASE TOGGLEBUTTONS -----------------------------------------
% --- Release all togglebuttons.
    function releasetogglebuttons
        
        par = {'v0','t2s','df','phi'};  % parameter tag
        kin = {'min','ini','max'};      % kind tag
        
        for ipar = 1:length(par)
            for ikin = 1:length(kin)
                toggletag = ['toggle_' par{ipar} kin{ikin}];
                edittag   = ['edit_' par{ipar} kin{ikin}];
                set(gui.panel_controls.(toggletag), 'Value', 0)
                set(gui.panel_controls.(edittag), 'BackgroundColor', 'w')
            end
        end
        
    end


%% FUNCTION TRIM FID ------------------------------------------------------
    function proclog = trim_fid(proclog,iQ,irx,isig,mint,maxt)
        
        % Delete previous trim event log (there can only be one trim event for each FID)
        proclog.event(...
                proclog.event(:,1) == 101 & ...
                proclog.event(:,2) == iQ & ...
                proclog.event(:,3) == 0 & ...
                proclog.event(:,4) == irx & ...
                proclog.event(:,5) == isig, :) = [];
        
        % Add new trim event log
        proclog.event(end+1,:) = [101 iQ 0 irx isig mint maxt 0];
    end

%% FUNCTION UNDO TRIM FID -------------------------------------------------
    function proclog = undo_trim_fid(proclog,iQ,irx,isig)
        
        % Delete trim event log 
        proclog.event(...
                proclog.event(:,1) == 101 & ...
                proclog.event(:,2) == iQ & ...
                proclog.event(:,3) == 0 & ...
                proclog.event(:,4) == irx & ...
                proclog.event(:,5) == isig, :) = [];
    end

%% FUNCTION PLOT DATA -------------------------------------------------
    function mrs_plotfit(gui,proclog)
        figure(gui.panel_sounding.figureid)
                
        scalefactor_V = 1e9;  % [nV]
        scalefactor_T = 1000; % [ms]

        iQ   = get(gui.panel_controls.popupmenu_Q, 'Value');
        irx  = get(gui.panel_controls.popupmenu_RX, 'Value');
        isig = get(gui.panel_controls.popupmenu_SIG, 'Value');
                
        % update sounding plots
        plt = zeros(4,length(proclog.Q));
        switch isig
            case {2,3}%
                %check plot of corrections
                switch get(gui.panel_sounding.menu_view_rdp, 'Checked');
                    case 'on'
                        RDPcorr = 1;
                    case 'off'
                        RDPcorr = 0;
                end
                switch get(gui.panel_sounding.menu_view_df, 'Checked');
                    case 'on'
                        DFcorr = 1;
                    case 'off'
                        DFcorr = 0;
                end
                
                for n = 1:4
                    cla(gui.panel_sounding.snd(n));
                    hold(gui.panel_sounding.snd(n), 'on')
                    set(gui.panel_sounding.snd(n), ...
                        'Box', 'on', ...
                        'XGrid', 'on', ...
                        'YGrid', 'on', ...
                        'YDir', 'reverse')
                end
                for pQ = 1:length(proclog.Q)
                    plt(1,pQ) = plot(gui.panel_sounding.snd(1), proclog.Q(pQ).rx(irx).sig(isig).fit(1)*scalefactor_V, proclog.Q(pQ).q, 'ro');
                    plt(2,pQ) = plot(gui.panel_sounding.snd(2), proclog.Q(pQ).rx(irx).sig(isig).fit(2)*scalefactor_T, proclog.Q(pQ).q, 'ro');
                    plt(3,pQ) = plot(gui.panel_sounding.snd(3), proclog.Q(pQ).rx(irx).sig(isig).fit(3), proclog.Q(pQ).q, 'ro');
                    plt(4,pQ) = plot(gui.panel_sounding.snd(4), proclog.Q(pQ).rx(irx).sig(isig).fit(4), proclog.Q(pQ).q, 'ro');
                    if RDPcorr && isig == 2
                        delete(plt(1,pQ))
                        plot(gui.panel_sounding.snd(1), proclog.Q(pQ).rx(irx).sig(isig).fit(1)*scalefactor_V, proclog.Q(pQ).q, 'r.')
                        plt(1,pQ) = plot(gui.panel_sounding.snd(1), proclog.Q(pQ).rx(irx).sig(isig).fitc(1)*scalefactor_V, proclog.Q(pQ).q, 'rd');
                    end
                    if DFcorr 
                        delete(plt(4,pQ))
                        plot(gui.panel_sounding.snd(4), proclog.Q(pQ).rx(irx).sig(isig).fit(4), proclog.Q(pQ).q, 'r.')
                        plt(4,pQ) = plot(gui.panel_sounding.snd(4), proclog.Q(pQ).rx(irx).sig(isig).fitc(4), proclog.Q(pQ).q, 'rd');
                    end            
                end
                set(plt(:,iQ), 'MarkerFaceColor', 'red')
            case 4
                clf;
                subplot(141); hold on; axis ij; xlabel('[nV]'); ylabel('pulse moment q [As]');grid on;title('First echo')
                for pQ = 1:length(proclog.Q)
                    plt(1,pQ) = plot(proclog.Q(pQ).rx(irx).sig(isig).fit(2)*scalefactor_V, proclog.Q(pQ).q, 'ro');
                    t     = [1:1:proclog.Q(pQ).rx(irx).sig(isig).nE]; 
                    q(pQ) = pQ;
                    for e=1:proclog.Q(pQ).rx(irx).sig(isig).nE
                        v(e,pQ) = proclog.Q(pQ).rx(irx).sig(isig).fit(e+1);
                    end
                end
                set(plt(1,iQ), 'MarkerFaceColor', 'red')
                subplot(1,4,3:4);
                    imagesc(t,q,v.'); xlabel('tau [index]');title('echo train');ylabel('pulse moment q [index]')
        end
        
        % QD in stacking UND on save in noisereduction
        
        % assign color
        col = [ 0.6  0.6 0.6;
                0.0  0.7 1.0;
              [ 0.0  200 30]/256;
                1.0  0.0 1.0];
        
        % Obtain trim indices
        [it1, it2] = mrs_gettrim(proclog,iQ,irx,isig);
        
        % Xlim
        xl = [0 proclog.Q(iQ).rx(irx).sig(isig).t(end)];
            
        % assemble data
        t  = proclog.Q(iQ).rx(irx).sig(isig).t(it1:it2); % [s]
        v  = proclog.Q(iQ).rx(irx).sig(isig).V(it1:it2); % [V]
        if proclog.status == 3  % data have been fitted
          % f = x1 * exp(-t/x2) * exp[-i(2*pi*x3*t + x4)] -> see also mrs_fitFID
          % MMP: QD uses exp(-i..) but that something different
          % f = x1 * exp(-t/x2) * exp[i(2*pi*x3*t + x4)]
          % I also changed mrs_fitFID
          switch isig
              case {2,3}
            f = proclog.Q(iQ).rx(irx).sig(isig).fit(1) * ...
                exp(-t/proclog.Q(iQ).rx(irx).sig(isig).fit(2) + ...
                    1i*(2*pi*proclog.Q(iQ).rx(irx).sig(isig).fit(3)*t + ...
                         proclog.Q(iQ).rx(irx).sig(isig).fit(4)));  
              case 4
                  f=proclog.Q(iQ).rx(irx).sig(isig).V_fit;
          end
        else
            f = zeros(size(v));
        end
        
        figure(gui.panel_fid.figureid)
        
        % Plot real
        switch isig
            case {2,3,4}
                subplot(gui.panel_fid.stk(1));
                plot(t,scalefactor_V*real(v), 'Color', col(isig,:))
                hold on
                plot(t,scalefactor_V*real(f), 'Color', 'r')
                plot(t,zeros(size(t)), ':', 'Color', 3*[0.1 0.1 0.1])
                hold off
                xlim(xl)
        %         ylim([-40 40])
                set(gca,'Color',[0 0 0])

                % Plot imag
                subplot(gui.panel_fid.stk(2));
                plot(t,scalefactor_V*imag(v), 'Color', col(isig,:))
                hold on
                plot(t,scalefactor_V*imag(f), 'Color', 'r')
                plot(t,zeros(size(t)), ':', 'Color', 3*[0.1 0.1 0.1])
                hold off
                xlim(xl)
        %         ylim([-40 40])
                set(gca,'Color',[0 0 0])
        end
        refreshtrim;
        refreshqvalue;
        refreshrxchannel;
    end


%% FUNCTION REFRESH Q VALUE -----------------------------------------------
% update q value in gui
    function refreshqvalue
        iQ       = get(gui.panel_controls.popupmenu_Q, 'Value');
        isig     = get(gui.panel_controls.popupmenu_SIG, 'Value');
        switch isig
            case 2
                q = proclog.Q(iQ).q;
            case 3
                q = proclog.Q(iQ).q2;
            case 4
                q = proclog.Q(iQ).q;
        end
        currentq = [num2str(q,'%4.2f'),' A.s'];
        set(gui.panel_controls.edit_Qvalue, 'String', currentq);
    end

%% FUNCTION REFRESH CH VALUE ----------------------------------------------
% update ch value in gui
    function refreshrxchannel
        irx = get(gui.panel_controls.popupmenu_RX, 'Value');
        ch = proclog.rxinfo(irx).channel;
        currentch = [' CH ', num2str(ch,'%1.0f')];
        set(gui.panel_controls.edit_RXchannel, 'String', currentch);
    end

    %% FUNCTION REFRESH TRIM ----------------------------------------------
    % update trim value in gui
    function refreshtrim
        iQ    = get(gui.panel_controls.popupmenu_Q, 'Value');
        irx   = get(gui.panel_controls.popupmenu_RX, 'Value');
        isig  = get(gui.panel_controls.popupmenu_SIG, 'Value');
        
        t = proclog.Q(iQ).rx(irx).sig(isig).t;
        [minRecInd, maxRecInd] = mrs_gettrim(proclog,iQ,irx,isig);
        set(gui.panel_controls.edit_minRec, 'String', num2str(t(minRecInd)));
        set(gui.panel_controls.edit_maxRec, 'String', num2str(t(maxRecInd)));
    end


%% FUNCTION INITIALIZE FITPARAMETERS --------------------------------------
% only called once to initialize lb & ub.
    function proclog = initializefitparameters(proclog)
        
        % default bounds
        lb   = [1e-9   10e-3  -2 -2*pi];
        ub   = [800e-9 400e-3  2  2*pi]; 
        ini  = [100e-9 200e-3  0  0];
        
        switch proclog.device
            
            case 'GMR'
                % no estimates for ini from Vista Clara --> set to defaults
                for iQ = 1:length(proclog.Q)
                    for irx = 1:length(proclog.rxinfo)
                        for isig = 1:4 %
                            if proclog.Q(iQ).rx(irx).sig(isig).recorded
                                proclog.Q(iQ).rx(irx).sig(isig).lb  = lb;
                                proclog.Q(iQ).rx(irx).sig(isig).ub  = ub;
                                proclog.Q(iQ).rx(irx).sig(isig).ini = ini;
                            end
                        end
                    end
                end
            
            case 'Jilin'
                % set to defaults
                for iQ = 1:length(proclog.Q)
                    for irx = 1:length(proclog.rxinfo)
                        for isig = 1:4 %
                            if proclog.Q(iQ).rx(irx).sig(isig).recorded
                                proclog.Q(iQ).rx(irx).sig(isig).lb  = lb;
                                proclog.Q(iQ).rx(irx).sig(isig).ub  = ub;
                                proclog.Q(iQ).rx(irx).sig(isig).ini = ini;
                            end
                        end
                    end
                end    
                
            case 'MIDI'     % get ini's from latest stacked ("+") file
                if isdir([proclog.path 'fids'])              % after rename
                    fol_str = ['stacked' filesep];
                    stk_str = [fol_str '*_stk_*.dat'];
                elseif ~isempty(dir([proclog.path 'FID_*'])) % Software rev.
                    stk_str = 'FID+*.dat';
                    fol_str = '';
                else
                    error('Unknown filename format. Probably old unsupported MIDI version')
                end                                
                
                % determine largest/latest file -> contains all q info
                resultfiles = dir([proclog.path stk_str]);
                latestfile = resultfiles([resultfiles(:).bytes]==max([resultfiles(:).bytes])).name;
                midifitini = mrs_readmidi([proclog.path fol_str latestfile],1);

                for iQ = 1:length(proclog.Q)
                    currentQ = abs(midifitini.fit.q-proclog.Q(iQ).q) == min(abs(midifitini.fit.q-proclog.Q(iQ).q));
                    for irx = 1:length(proclog.rxinfo)   % rx4 is not connected for midi
                            for isig = 1:4 % fuer 1 & 4 sinnlos...
                                if proclog.Q(iQ).rx(irx).sig(isig).recorded

                                    ini = [midifitini.fit.V0(currentQ, irx) ...
                                           midifitini.fit.T2s(currentQ, irx) ...
                                           0 0];

                                    ini(isnan(ini)) = mean([lb(isnan(ini)); ub(isnan(ini))],1);
                                    ini(lb>=ini) = lb(lb>=ini);
                                    ini(ub<=ini) = ub(ub<=ini);

                                    proclog.Q(iQ).rx(irx).sig(isig).lb  = lb;
                                    proclog.Q(iQ).rx(irx).sig(isig).ub  = ub;
                                    proclog.Q(iQ).rx(irx).sig(isig).ini = ini;
                                end
                            end
                    end
                end                  

            case {'NUMISpoly','NUMISplus'}    % get ini's from .inp & .in2 files
        
                % read .inp file: get q and fit startvalues
                fidinp = fopen([proclog.path, 'NumisData.inp'],'r');
                lines  = 0;                  % count # lines in file
                while fgets(fidinp)~= -1
                    lines=lines+1;
                end
                fseek(fidinp,0,'bof');       % return to bof
                inp_data   = textscan(fidinp, ...
                    '%f %f %f %f %f %f %f %f %*[^\n]', lines-5, 'Headerlines', 5);
                fclose(fidinp);

                iq = find(inp_data{2} ~= 0 & inp_data{3} ~= 0); % delete skipped q's

                v0_start  = inp_data{3}(iq)/1e9;      % [V]
                t2s_start = inp_data{4}(iq)/1000;     % [s]
                df_start  = inp_data{7}(iq);          % [Hz]  ex Freq_start
                phi_start = inp_data{8}(iq)/180*pi;   % [rad]
                phi_start(phi_start > pi) = phi_start(phi_start > pi) - 2*pi; % phase 180 -> -180

                % read .in2 file (if existent): get q2 and fit2 startvalues 
                fidin2 = fopen([proclog.path, 'NumisData.in2'],'r');
                if (fidin2 ~= -1)
                    lines = 0;                  % count # lines in file
                    while fgets(fidin2)~= -1
                        lines=lines+1;
                    end
                    fseek(fidin2,0,'bof');

                    in2_data   = textscan(fidin2, '%f %f %f %f %f %f %f %f %*[^\n]', lines-5, 'Headerlines', 5);
                    fclose(fidin2);

                    iq2 = find(in2_data{2} ~= 0 | in2_data{3} ~= 0);     % delete skipped pulsemoments; skipped pulsemoments are identified by the fact that neither q nor the amplitude "e2" are zero

                    if size(inp_data{1}(iq)) ~= size(in2_data{1}(iq));  % check: # of qi in inp & in2 should be the same!
                        error('Error! Different missing-q-indices in .inp & .in2 file!')
                    end

                    v0_start  = [v0_start in2_data{3}(iq2)/1e9];      % [V]
                    t2s_start = [t2s_start in2_data{4}(iq2)/1000];     % [s]
                    df_start  = [df_start in2_data{7}(iq2)];          % [Hz]
                    phi2      = in2_data{8}(iq2)/180*pi;   % [rad]
                    phi2(phi2 > pi) = phi2(phi2 > pi) - 2*pi; % phase 180 -> -180
                    phi_start = [phi_start phi2];
                end

                for iQ = 1:length(proclog.Q)
                    for irx = 1:length(proclog.rxinfo)
                            for isig = 2:4 % don't fit noise (1) or echo (4)
                                if proclog.Q(iQ).rx(irx).sig(isig).recorded

                                    ini = [...
                                        v0_start(iQ, isig-1) ...
                                        t2s_start(iQ, isig-1) ...
                                        df_start(iQ, isig-1) - proclog.Q(iQ).fT ...
                                        phi_start(iQ, isig-1)];

                                    ini(lb>=ini) = lb(lb>=ini);
                                    ini(ub<=ini) = ub(ub<=ini);

                                    proclog.Q(iQ).rx(irx).sig(isig).lb  = lb;
                                    proclog.Q(iQ).rx(irx).sig(isig).ub  = ub;
                                    proclog.Q(iQ).rx(irx).sig(isig).ini = ini;
                                end
                            end
                    end
                end
            case 'TERRANOVA'
                % no fit estimates for Terranova --> set to defaults
                for iQ = 1:length(proclog.Q)
                    for irx = 1:length(proclog.rxinfo)
                        for isig = 1:4 % fuer 1 & 4 sinnlos
                            if proclog.Q(iQ).rx(irx).sig(isig).recorded
                                proclog.Q(iQ).rx(irx).sig(isig).lb  = lb;
                                proclog.Q(iQ).rx(irx).sig(isig).ub  = ub;
                                proclog.Q(iQ).rx(irx).sig(isig).ini = ini;
                            end
                        end
                    end
                end
                
        end
    end

%% FUNCTION REFRESH FITPARAMETERS -------------------------------------
% update gui
    function refreshfitparameters
        iQ   = get(gui.panel_controls.popupmenu_Q, 'Value');
        irx  = get(gui.panel_controls.popupmenu_RX, 'Value');
        isig = get(gui.panel_controls.popupmenu_SIG, 'Value');
        
        lb   = proclog.Q(iQ).rx(irx).sig(isig).lb;
        ub   = proclog.Q(iQ).rx(irx).sig(isig).ub;
        ini  = proclog.Q(iQ).rx(irx).sig(isig).ini;
        fitp = proclog.Q(iQ).rx(irx).sig(isig).fit;
        
        %         % phase is mapped in interval [-pi pi]; adapt boundaries to account
        %         % for this.
        %         if lb(4) > -pi
        %             ub(4) = min([ub(4) lb(4)+2*pi]);
        %         end
        %         if ub(4) < pi
        %             lb(4) = max([lb(4) -pi]);
        %         end
        %
        %         ini(lb>=ini)    = lb(lb>=ini);
        %         ini(ub<=ini)    = ub(ub<=ini);
            
        switch isig
            case {2,3}
                set(gui.panel_controls.edit_v0min,'string', num2str(round(lb(1)*1e9)));   % [nV]
                set(gui.panel_controls.edit_v0max,'string', num2str(round(ub(1)*1e9)));   % [nV]
                set(gui.panel_controls.edit_t2smin,'string', num2str(round(lb(2)*1e3)));  % [ms]
                set(gui.panel_controls.edit_t2smax,'string', num2str(round(ub(2)*1e3)));  % [ms]
                set(gui.panel_controls.edit_dfmin,'string', num2str(ext_roundn(lb(3),-1)));   % [Hz]
                set(gui.panel_controls.edit_dfmax,'string', num2str(ext_roundn(ub(3),-1)));   % [Hz]
                set(gui.panel_controls.edit_phimin,'string', num2str(ext_roundn(lb(4),-2)));  % [rad]
                set(gui.panel_controls.edit_phimax,'string', num2str(ext_roundn(ub(4),-2)));  % [rad]
                set(gui.panel_controls.edit_v0ini,'string', num2str(round(ini(1)*1e9)));  % [V]
                set(gui.panel_controls.edit_t2sini,'string', num2str(round(ini(2)*1e3))); % [s]
                set(gui.panel_controls.edit_dfini,'string', num2str(ext_roundn(ini(3),-1)));  % [Hz]
                set(gui.panel_controls.edit_phiini,'string', num2str(ext_roundn(ini(4),-2))); % [rad]

                set(gui.panel_controls.edit_v0fit,'string', num2str(round(fitp(1)*1e9)));  % [nV]
                set(gui.panel_controls.edit_t2sfit,'string', num2str(round(fitp(2)*1e3))); % [ms]
                set(gui.panel_controls.edit_dffit,'string', num2str(ext_roundn(fitp(3),-1)));  % [Hz]
                set(gui.panel_controls.edit_phifit,'string', num2str(ext_roundn(fitp(4),-2))); % [rad]
            case {4}
                set(gui.panel_controls.edit_v0fit,'string', num2str(round(fitp(2)*1e9)));  % [nV]
                set(gui.panel_controls.edit_t2sfit,'string', num2str(round(fitp(1)*1e3))); % [ms]
                set(gui.panel_controls.edit_dffit,'string', '-');  % [Hz]
                set(gui.panel_controls.edit_phifit,'string', '-'); % [rad]
        end
        
        if 0 % temporarily deactivated
            % set font red if fitresult is at bounds
            if ext_roundn(lb(1),-9) == ext_roundn(fitp(1),-9)
                set(gui.panel_controls.edit_v0min, 'ForegroundColor', 'r')
                set(gui.panel_controls.edit_v0fit, 'ForegroundColor', 'r')
            elseif ext_roundn(ub(1),-9) == ext_roundn(fitp(1),-9)
                set(gui.panel_controls.edit_v0max, 'ForegroundColor', 'r')
                set(gui.panel_controls.edit_v0fit, 'ForegroundColor', 'r')
            else
                set(gui.panel_controls.edit_v0min, 'ForegroundColor', 'k')
                set(gui.panel_controls.edit_v0max, 'ForegroundColor', 'k')
                set(gui.panel_controls.edit_v0fit, 'ForegroundColor', 'k')
            end

            if ext_roundn(lb(2),-3) == ext_roundn(fitp(2),-3)
                set(gui.panel_controls.edit_t2smin, 'ForegroundColor', 'r')
                set(gui.panel_controls.edit_t2sfit, 'ForegroundColor', 'r')
            elseif ext_roundn(ub(2),-3) == ext_roundn(fitp(2),-3)
                set(gui.panel_controls.edit_t2smax, 'ForegroundColor', 'r')
                set(gui.panel_controls.edit_t2sfit, 'ForegroundColor', 'r')
            else
                set(gui.panel_controls.edit_t2smin, 'ForegroundColor', 'k')
                set(gui.panel_controls.edit_t2smax, 'ForegroundColor', 'k')
                set(gui.panel_controls.edit_t2sfit, 'ForegroundColor', 'k')
            end

            if ext_roundn(lb(3),-1) == ext_roundn(fitp(3),-1)
                set(gui.panel_controls.edit_dfmin, 'ForegroundColor', 'r')
                set(gui.panel_controls.edit_dffit, 'ForegroundColor', 'r')
            elseif ext_roundn(ub(3),-1) == ext_roundn(fitp(3),-1)
                set(gui.panel_controls.edit_dfmax, 'ForegroundColor', 'r')
                set(gui.panel_controls.edit_dffit, 'ForegroundColor', 'r')
            else
                set(gui.panel_controls.edit_dfmin, 'ForegroundColor', 'k')
                set(gui.panel_controls.edit_dfmax, 'ForegroundColor', 'k')
                set(gui.panel_controls.edit_dffit, 'ForegroundColor', 'k')
            end

            if ext_roundn(lb(4),-2) == ext_roundn(fitp(4),-2)
                set(gui.panel_controls.edit_phimin, 'ForegroundColor', 'r')
                set(gui.panel_controls.edit_phifit, 'ForegroundColor', 'r')
            elseif ext_roundn(ub(4),-2) == ext_roundn(fitp(4),-2)
                set(gui.panel_controls.edit_phimax, 'ForegroundColor', 'r')
                set(gui.panel_controls.edit_phifit, 'ForegroundColor', 'r')
            else
                set(gui.panel_controls.edit_phimin, 'ForegroundColor', 'k')
                set(gui.panel_controls.edit_phimax, 'ForegroundColor', 'k')
                set(gui.panel_controls.edit_phifit, 'ForegroundColor', 'k')
            end
        end
        
    end

%% FUNCTION GET USER STARTVALUES ------------------------------------------
% update proclog structure with gui values
    function getuserstartvalues
        iq   = get(gui.panel_controls.popupmenu_Q, 'Value');
        irx  = get(gui.panel_controls.popupmenu_RX, 'Value');
        isig = get(gui.panel_controls.popupmenu_SIG, 'Value');
        
        lb(1)  = str2double(get(gui.panel_controls.edit_v0min,'string'))/1e9;  % [V]
        lb(2)  = str2double(get(gui.panel_controls.edit_t2smin,'string'))/1e3; % [s]
        lb(3)  = str2double(get(gui.panel_controls.edit_dfmin,'string'));      % [Hz]
        lb(4)  = str2double(get(gui.panel_controls.edit_phimin,'string'));     % [rad]
        ub(1)  = str2double(get(gui.panel_controls.edit_v0max,'string'))/1e9;  % [V]
        ub(2)  = str2double(get(gui.panel_controls.edit_t2smax,'string'))/1e3; % [s]
        ub(3)  = str2double(get(gui.panel_controls.edit_dfmax,'string'));      % [Hz]
        ub(4)  = str2double(get(gui.panel_controls.edit_phimax,'string'));     % [rad]
        ini(1) = str2double(get(gui.panel_controls.edit_v0ini,'string'))/1e9;  % [V];
        ini(2) = str2double(get(gui.panel_controls.edit_t2sini,'string'))/1e3; % [s]
        ini(3) = str2double(get(gui.panel_controls.edit_dfini,'string'));      % [Hz]
        ini(4) = str2double(get(gui.panel_controls.edit_phiini,'string'));     % [rad]
        
        %         % phase is mapped to interval [-pi pi]; adapt boundaries to account
        %         % for this.
        %         if lb(4) > -pi
        %             ub(4) = min([ub(4) pi]);
        %         end
        %         if ub(4) < pi
        %             lb(4) = max([lb(4) -pi]);
        %         end
        
        % adapt ini if beyond bounds
        ini(lb>=ini)    = lb(lb>=ini);
        ini(ub<=ini)    = ub(ub<=ini);
        
        % complain if lb>ub
        if any(lb>ub)
            mrs_setguistatus(gui,1,'LB > UB detected. Please fix.')
%             set(gui.panel_controls.edit_phimin, 'BackgroundColor', 'r')
%             set(gui.panel_controls.edit_phifit, 'BackgroundColor', 'r')
            pause(2)
            mrs_setguistatus(gui,0)
            return
        end
        
        % update proclog
        proclog.Q(iq).rx(irx).sig(isig).lb  = lb;
        proclog.Q(iq).rx(irx).sig(isig).ub  = ub;
        proclog.Q(iq).rx(irx).sig(isig).ini = ini;

    end

%% FUNCTION CORRECT THE FIT PARAMETERS ------------------------------------
% requires proclog (here it is global)
    function fc = mrs_fitcorrections(f,iQ,isig)
        fc  = f;    % initialize
        switch isig
            case 2  % RDP & DF correction for fid1
                tp    = proclog.Q(iQ).timing.tau_p1;
                td    = proclog.Q(iQ).timing.tau_dead1;  % trim not required because fit values f are wrt t=0. 
                fc(1) = mrs_RDPcorr(f(1),tp,td,f(2));
                fc(4) = mrs_DFcorr(f(4),f(3),tp+td);
            case 3  % only DF correction for fid2
                dt    = proclog.Q(iQ).timing.tau_p1 + ...
                        proclog.Q(iQ).timing.tau_dead1 + ...
                        proclog.Q(iQ).timing.tau_p2 + ... 
                        proclog.Q(iQ).timing.tau_dead2;   % CHECK THIS! JW
                fc(4) = mrs_DFcorr(f(4),f(3),dt);
        end
    end

%% FUNCTION CORRECTION: RDP (AMPLITUDE) -----------------------------------
    function vc = mrs_RDPcorr(v,tp,td,T2s)
        % FID amplitude is corrected to the center of the pulse due to 
        % RDP effects - see Walbrecker et al. (2009), Geophysics, 74, 27-34.
        vc = v*exp((tp/2+td)/T2s);
    end

%% FUNCTION CORRECTION: DF (PHASE) ----------------------------------------
    function phic = mrs_DFcorr(phi,df,dt)
        % DF correction (phi)
        % phi(fid1): dt = tau_p1 + tau_dead1
        % phi(fid2): dt = tau_p1 + tau_dead1 + delay + tau_p2 + tau_dead2  ????
        phic = phi - 2*pi*df*dt;    % see "FID phase correction.pdf" in MRSmatlab documentation
    end

%% FUNCTION GET TRIM ------------------------------------------------------
% moved outside as solitary function
% % get trim user input & determine indices to keep
%     function [minRecInd, maxRecInd] = mrs_gettrim(proclog,iQ,irx,isig)
%         
%         % Time
%         t = proclog.Q(iQ).rx(irx).sig(isig).t;
%         
%         % Index of trim event
%         minmaxt = proclog.event(...
%                     proclog.event(:,1) == 101 & ...
%                     proclog.event(:,2) == iQ & ...
%                     proclog.event(:,3) == 0 & ...
%                     proclog.event(:,4) == irx & ...
%                     proclog.event(:,5) == isig, 6:7);
%         
%         % Determine indices corresponding to mint & maxt
%         if isempty(minmaxt)  % no trim event
%             minRecInd = 1;
%             maxRecInd = length(t);
%         else            % there is a trim event
%             
%             % Times
%             mint = minmaxt(1);
%             maxt = minmaxt(2);
%             
%             % Minimum time index
%             minRecInd = find(t >= mint,1);
%             
%             % Maximum time index
%             if maxt >= t(end)
%                 maxRecInd = length(t);
%             else
%                 maxRecInd = find(t > maxt,1)-1;
%             end            
%         end
%     end


%% KEYBOARD SHORTCUTS -----------------------------------------------------
    function dokeyboardshortcut(a,event)
        
        % rightarrow: next Q
        if strcmp(event.Key, 'rightarrow')
            q_max = size(get(gui.panel_controls.popupmenu_Q,'String'),1);
            set(gui.panel_controls.popupmenu_Q,'Value', min(q_max,get(gui.panel_controls.popupmenu_Q,'Value')+1));
            onSelectQ
        end
        
        % leftarrow: previous Q
        if strcmp(event.Key, 'leftarrow')
            set(gui.panel_controls.popupmenu_Q,'Value', max(1,get(gui.panel_controls.popupmenu_Q,'Value')-1));
            onSelectQ
        end
        
        % s: toggle signal 2 / 3
        if strcmp(event.Key, 's')
            isig = get(gui.panel_controls.popupmenu_SIG,'Value');
            if isig == 2
                set(gui.panel_controls.popupmenu_SIG,'Value',3)   % toggle only between sig2 & sig3
            else
                set(gui.panel_controls.popupmenu_SIG,'Value',2)   % toggle only between sig2 & sig3
            end
            onSelectSIG
        end
        
        % r: next receiver
        if strcmp(event.Key, 'r')
            irx = get(gui.panel_controls.popupmenu_RX,'Value');
            nrx = length(proclog.rxinfo);
            set(gui.panel_controls.popupmenu_RX,'Value',mod(irx,nrx)+1); % advance by 1 wrap at max receiver
            onSelectRX
        end        
        
    end
if standalone == 0
    uiwait(gui.panel_controls.figureid)
end
end