function sounding_file = MRSSignalPro(sounding_path,status)
% function sounding_file = mrsSigPro(sounding_path,status)
%
% Open mrsSigPro gui to
%   + Import surface-NMR data
%   + Process: Despike, noise cancellation and keep/drop time series
%
% Called functions:
%   mrs_load_numisraw,
%
% Input options:
%   sounding_path - optional: Path to sounding ('d:\Data\Sounding0001\')
%   status - optional: mrsproject.data(procme).status
%
% Output:
%   sounding_file - name of saved datafile ('sounding0001.mrsd')
%
% 10nov2010
% mod. 19 aug 2011 JW
%         sep 2011 MMP
%      04 oct 2011 JW
% =========================================================================

% allow only one instance of mrsSigPro
kfig = findobj('Name', 'MRS Signal Processing');
if ~isempty(kfig)
    delete(kfig)
end
kfig = findobj('Name', 'MRS Signal Processing - data viewer');
if ~isempty(kfig)
    delete(kfig)
end

% set global structures
gui      = createInterface();
fdata    = struct();
proclog  = struct();

if nargin > 0   % i.e. command comes from MRSWorkflow
    standalone = 0;
    sounding_file = ['mrs_sounding', sounding_path(end-4:end-1), '.mrsd'];
    set(gui.panel_controls.edit_path,'String',sounding_path,'Enable','off');
    set(gui.panel_controls.menu_file,'Enable','off');
    if status < 1   % check if load or reload
        onLoad(0,1);
    else
        onReload(0,1);
    end
else
    standalone = 1;
end

    function gui = createInterface()
        
        gui = struct();
        screensz = get(0,'ScreenSize');
        
        %% GENERATE CONTROLS PANEL ----------------------------------------
        gui.panel_controls.figureid = figure( ...
            'Name', 'MRS Signal Processing', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'Toolbar', 'none', ...
            'HandleVisibility', 'on',...
            'KeyPressFcn',@dokeyboardshortcut); % enable shortcuts
        
        set(gui.panel_controls.figureid, 'Position', [1160 screensz(4)-840 370 773])        
        
        % Set default panel settings
        %         uiextras.set( gui.panel_controls.figureid, 'DefaultBoxPanelTitleColor', [0.7 0.7 0.7] );
        %uiextras.set(gui.panel_controls.figureid, 'DefaultBoxPanelFontSize', 12);
        %uiextras.set(gui.panel_controls.figureid, 'DefaultBoxPanelFontWeight', 'bold')
        %uiextras.set(gui.panel_controls.figureid, 'DefaultBoxPanelPadding', 5)
        %uiextras.set(gui.panel_controls.figureid, 'DefaultHBoxPadding', 2)
        
        % + Quit menu
        gui.panel_controls.menu_quit = uimenu(gui.panel_controls.figureid, 'Label', 'Quit');
        uimenu(gui.panel_controls.menu_quit, ...
            'Label', 'Save and quit', ...
            'Callback', @onSaveAndQuit);
        uimenu(gui.panel_controls.menu_quit, ...
            'Label', 'Quit without saving', ...
            'Callback', @onQuitWithoutSave);
        
        % + File Menu
        gui.panel_controls.menu_file = uimenu(gui.panel_controls.figureid, 'Label', 'File');
        uimenu(gui.panel_controls.menu_file, ...
            'Label', 'Load Raw Data', ...
            'Callback', @onLoad)
        uimenu(gui.panel_controls.menu_file, ...
            'Label', 'Save as Stacked Data', ...
            'Callback', @onSave);
        uimenu(gui.panel_controls.menu_file, ...
           'Label', 'Reload Past State', ...
           'Callback', @onLoadWorkspace);
        uimenu(gui.panel_controls.menu_file, ...
           'Label', 'Save Current State', ...
           'Callback', @onSaveWorkspace);
        
        
        % + Plot Options Menu
        gui.panel_controls.plotTools = uimenu(gui.panel_controls.figureid, 'Label', 'Plot Tools' );
        uimenu('Parent',gui.panel_controls.plotTools,...
                'Label','Edit',...
                'Callback',@onEditOn);  
        uimenu('Parent',gui.panel_controls.plotTools,...
                'Label','Pan',...
                'Callback',@onPanOn);
        uimenu('Parent',gui.panel_controls.plotTools,...
                'Label','Zoom',...
                'Callback',@onZoomIn); 
        uimenu('Parent',gui.panel_controls.plotTools,...
                'Label','Data Cursor',...
                'Callback',@onDatacursorOn);     
        uimenu('Parent',gui.panel_controls.plotTools,...
                'Label','All off',...
                'Callback',@onAllOff); 
        uimenu('Parent',gui.panel_controls.plotTools,...
                'Label','Display All Data',...
                'Callback',@onAllData); 
        
        % + Help menu
        gui.panel_controls.menu_help = uimenu(gui.panel_controls.figureid, 'Label', 'Help' );
        uimenu(gui.panel_controls.menu_help, ...
            'Label', 'Documentation', ...
            'Callback', @onHelp);
            
        % + Create main parameter-box
        mainbox = uiextras.VBox('Parent', gui.panel_controls.figureid);
        
        % + File & control parameters
        p1 = uiextras.BoxPanel('Parent', mainbox, 'Title', 'Data', 'TitleColor', [0 0.75 1]);
        box_v1   = uiextras.VBox('Parent', p1);
        
        % file edit fields
        gui.panel_controls.edit_path = uicontrol(...
            'Style', 'Edit', ...
            'Parent', box_v1, ...
            'Enable', 'on', ...
            'BackgroundColor', [1 1 1], ...
            'String', '(Data path)', ...
            'Callback', @onEditPath);
        gui.panel_controls.edit_status = uicontrol(...
            'Style', 'Edit', ...
            'Parent', box_v1, ...
            'Enable', 'off', ...
            'BackgroundColor', [0 1 0], ...
            'String', 'Idle...');
        
        % box for popupmenus
        box_v1h1 = uiextras.HBox('Parent', box_v1);  

        % popupmenu REC
        uicontrol('Style', 'Text', ...
            'HorizontalAlignment', 'right', ...
            'Parent', box_v1h1, ...
            'String', 'rec  ');
        gui.panel_controls.popupmenu_REC = uicontrol(...
            'Style', 'popupmenu', ...
            'Parent', box_v1h1, ...
            'String', {'1', '2'},...
            'Callback', @onSelectREC);
            
        % popupmenu Q
        uicontrol('Style', 'Text', ...
            'HorizontalAlignment', 'right', ...
            'Parent', box_v1h1, ...
            'String', 'q  ');
        gui.panel_controls.popupmenu_Q = uicontrol(...
            'Style', 'popupmenu', ...
            'Parent', box_v1h1, ...
            'String', {'1', '2', '3'},...
            'Callback', @onSelectQ);

        % popupmenu RX
        uicontrol('Style', 'Text', ...
            'HorizontalAlignment', 'right', ...
            'Parent', box_v1h1, ...
            'String', 'rx  ');
        gui.panel_controls.popupmenu_RX = uicontrol(...
            'Style', 'popupmenu', ...
            'Parent', box_v1h1, ...
            'String', {'1', '2', '3', '4'},...
            'Callback', @onSelectRX);

        % popupmenu SIG
        uicontrol('Style', 'Text', ...
            'HorizontalAlignment', 'right', ...
            'Parent', box_v1h1, ...
            'String', 'sig  ');
        gui.panel_controls.popupmenu_SIG = uicontrol(...
            'Style', 'popupmenu', ...
            'Parent', box_v1h1, ...
            'String', {'1', '2', '3', '4'},...
            'Callback', @onSelectSIG);
        
        % processing history: pushbutton edit log
        box_v1h2  = uiextras.HBox('Parent', box_v1);
        uicontrol(...
            'HorizontalAlignment', 'right', ...                        
            'Style','Text',...
            'String','View processing history log:  ',...
            'Parent',box_v1h2);
        gui.panel_controls.pushbutton_editLog = uicontrol(...
            'Style','Pushbutton',...
            'String','show log',...
            'Enable', 'off', ...
            'Parent',box_v1h2,...
            'HandleVisibility','on',...
            'Callback',@onPushbuttonEditLog);
        set(box_v1h2, 'Sizes', [-1 70])
            
        % + Setting
        p2  = uiextras.BoxPanel('Parent', mainbox,'Title', 'Setting', 'TitleColor', [0 0.75 1]);
        box_v2_base = uiextras.VBox('Parent', p2);
                  
        % Despike
            box_v22 = uiextras.VBox('Parent', box_v2_base);
            uicontrol('Style', 'Text', ...
                'Parent', box_v22, 'Background', [0.69 0.93 0.93],...
                'HorizontalAlignment', 'left',...
                'String', 'Despike Properties');
            
            % spike handling
            box_v22h2 = uiextras.HBox('Parent', box_v22);
            box_v22h2v1 = uiextras.VBox('Parent', box_v22h2);
                uicontrol('Style', 'Text', 'Parent', box_v22h2v1, 'String', ''); % empty
                gui.panel_controls.radio_despikeAuto = uicontrol(...
                    'Style','Radio',...
                    'String','enable auto',...
                    'Value',0,...
                    'parent',box_v22h2v1,...
                    'HandleVisibility','on',...
                    'Callback',@onRadioDespikeAuto);
                uicontrol('Style', 'Text', 'Parent', box_v22h2v1, 'String', 'based on:'); % empty
                uicontrol('Style', 'Text', 'Parent', box_v22h2v1, 'String', ''); % empty   
                gui.panel_controls.radio_despikeAutoType = uicontrol(...
                    'Style', 'popupmenu', ...
                    'Parent', box_v22h2v1, ...
                    'Enable', 'off', ...
                    'String', {'q stack','single rec'});
                uicontrol('Style', 'Text', 'Parent', box_v22h2v1, 'String', ''); % empty
                set(box_v22h2v1, 'Sizes', [5 30 20 10 30 5])
                box_v22h2v4 = uiextras.VBox('Parent', box_v22h2); % empty
                box_v22h2v2 = uiextras.VBox('Parent', box_v22h2);
                uicontrol('Style', 'Text', 'Parent', box_v22h2v2, 'String', ''); % empty
                gui.panel_controls.radio_despikeManu = uicontrol(...
                    'Style','Radio',...
                    'String','enable manual',...
                    'Value',1,...
                    'parent',box_v22h2v2,...
                    'HandleVisibility','on',...
                    'Callback',@onRadioDespikeManu);
                gui.panel_controls.pushbutton_despikeManu = uicontrol(...
                    'Style','Pushbutton',...
                    'String','despike',...
                    'Enable', 'on', ...
                    'parent',box_v22h2v2,...
                    'HandleVisibility','on',...
                    'Callback',@onPushbuttonDespikeManu);
%                 box_v22h2v2h1 = uiextras.HBox('Parent', box_v22h2v2);
                    gui.panel_controls.pushbutton_despikeUndo = uicontrol(...
                        'Style','Pushbutton',...
                        'String','undo',...
                        'Enable', 'on', ...
                        'parent',box_v22h2v2,...
                        'HandleVisibility','on',...
                        'Callback',@onPushbuttonUndo);
%                     gui.panel_controls.pushbutton_showLog = uicontrol(...
%                         'Style','Pushbutton',...
%                         'String','show log',...
%                         'Enable', 'on', ...
%                         'parent',box_v22h2v2h1,...
%                         'HandleVisibility','on',...
%                         'Callback',@onPushbuttonShowLog);
                uicontrol('Style', 'Text', 'Parent', box_v22h2v2, 'String', ''); % empty
                set(box_v22h2v2, 'Sizes', [5 30 30 30 5])
                box_v22h2v5 = uiextras.VBox('Parent', box_v22h2); % empty
                box_v22h2v3 = uiextras.VBox('Parent', box_v22h2);
                uicontrol('Style', 'Text', 'Parent', box_v22h2v3, 'String', ''); % empty
                uicontrol('Style', 'Text', ...
                    'Parent', box_v22h2v3, ...
                    'String', 'Width (ms)');
                gui.panel_controls.edit_despikeMutewidth = uicontrol(...
                    'Style', 'Edit', ...
                    'Parent', box_v22h2v3, ...
                    'Enable', 'on', ...
                    'BackgroundColor', [1 1 1], ...
                    'String', '10');
                uicontrol('Style', 'Text', 'Parent', box_v22h2v3, 'String', ''); % empty
                uicontrol('Style', 'Text', ...
                    'Parent', box_v22h2v3, ...
                    'String', 'Threshold');
                gui.panel_controls.edit_despikeThreshold = uicontrol(...
                    'Style', 'Edit', ...
                    'Parent', box_v22h2v3, ...
                    'Enable', 'off', ...
                    'BackgroundColor', [1 1 1], ...
                    'String', '5');
                set(box_v22h2v3, 'Sizes', [5 15 25 5 15 25])
                set(box_v22h2, 'Sizes', [-1 10 -1 10 -1])
               
            set(box_v22, 'Sizes', [20 100])   
            %set(box_v22, 'Sizes', [20 -1]) 
        
            % Delete harmonic
            box_vHarmonic = uiextras.VBox('Parent', box_v2_base);
            uicontrol('Style', 'Text', ...
                'Parent', box_vHarmonic, 'Background', [0.69 0.93 0.93],...
                'HorizontalAlignment', 'left',...
                'String', 'Noise Cancelation - Harmonic Modeling','Visible','on');
            % handling
            box_vHarmonicH0 = uiextras.HBox('Parent', box_vHarmonic);
            gui.panel_controls.check_removeCof = uicontrol(...
                'Style','Check',...
                'String','remove CoF',...
                'Value', 0,...
                'Visible', 'on', ...
                'Enable', 'on', ...
                'Parent',box_vHarmonicH0,...
                'HandleVisibility','on',...
                'Callback',@onCheckRemoveCof);
            gui.panel_controls.check_fastHNC = uicontrol(...
                'Style','Check',...
                'String','fast method',...
                'Value', 1,...
                'Visible', 'on', ...
                'Enable', 'on', ...
                'Parent',box_vHarmonicH0,...
                'HandleVisibility','on',...
                'Callback',@onCheckFastHNC);
            uicontrol('Style', 'Text', 'Parent', box_vHarmonicH0, 'String', ''); % empty 
            set(box_vHarmonicH0, 'Sizes', [-1 -1 -1])           
            box_vHarmonicH1 = uiextras.HBox('Parent', box_vHarmonic);
            gui.panel_controls.radio_DelHarmonicOn = uicontrol(...
                'Style','Radio',...
                'String','enable',...
                'Value',0,...
                'Visible','on',...
                'parent',box_vHarmonicH1,...
                'HandleVisibility','on',...
                'Callback',@onRadioDelHarmonicOn);
            uicontrol('Style', 'Text', 'Parent', box_vHarmonicH1, 'String', ''); % empty
            gui.panel_controls.radio_DelHarmonicOff = uicontrol(...
                'Style','Radio',...
                'String','disable',...
                'Value',1,...
                'Visible','on',...
                'parent',box_vHarmonicH1,...
                'HandleVisibility','on',...
                'Callback',@onRadioDelHarmonicOff);
            uicontrol('Style', 'Text', 'Parent', box_vHarmonicH1, 'String', ''); % empty            
            box_vHarmonicV1 = uiextras.VBox('Parent', box_vHarmonicH1);
            uicontrol('Style', 'Text', ...
                'Parent', box_vHarmonicV1, ...
                'Visible','on',...
                'String', 'base frequency');
            gui.panel_controls.edit_DelHarmonic_frequency = uicontrol('Style', 'popupmenu', ...
                'Parent', box_vHarmonicV1, ...
                'String', {'train (16.6 Hz)', 'power line (50 Hz)' , 'power line (60 Hz)'},...
                'BackgroundColor', [1 1 1], ...
                'Enable', 'off', ...
                'Value', 2);
            set(box_vHarmonicH1, 'Sizes', [-1 10 -1 10 -1])
            set(box_vHarmonicV1, 'Sizes', [15 25])
            %set(box_vHarmonic, 'Sizes', [20 50])
            % handling second harmonic
            box_vHarmonicH1_2 = uiextras.HBox('Parent', box_vHarmonic);
            gui.panel_controls.radio_DelHarmonicOn_2 = uicontrol(...
                'Style','Radio',...
                'String','enable',...
                'Value',0,...
                'Visible','on',...
                'Enable', 'on', ...
                'parent',box_vHarmonicH1_2,...
                'HandleVisibility','on',...
                'Callback',@onRadioDelHarmonicOn_2);
            uicontrol('Style', 'Text', 'Parent', box_vHarmonicH1_2, 'String', ''); % empty
            gui.panel_controls.radio_DelHarmonicOff_2 = uicontrol(...
                'Style','Radio',...
                'String','disable',...
                'Value',1,...
                'Visible','on',...
                'Enable', 'on', ...
                'parent',box_vHarmonicH1_2,...
                'HandleVisibility','on',...
                'Callback',@onRadioDelHarmonicOff_2);
            uicontrol('Style', 'Text', 'Parent', box_vHarmonicH1_2, 'String', ''); % empty
            %box_vHarmonicV1_2 = uiextras.VBox('Parent', box_vHarmonicH1_2);
            %uicontrol('Style', 'Text', ...
            %    'Parent', box_vHarmonicV1_2, ...
            %    'Visible','on',...
            %    'String', 'base frequency');
            gui.panel_controls.edit_DelHarmonic_frequency_2 = uicontrol('Style', 'popupmenu', ...
                'Parent', box_vHarmonicH1_2, ...
                'String', {'train (16.6 Hz)', 'power line (50 Hz)' , 'power line (60 Hz)'},...
                'BackgroundColor', [1 1 1], ...
                'Enable', 'off', ...
                'Value', 1);
            set(box_vHarmonicH1_2, 'Sizes', [-1 10 -1 10 -1])
            %set(box_vHarmonicV1_2, 'Sizes', [15 25])
            set(box_vHarmonic, 'Sizes', [20 20 40 25])
            %set(box_vHarmonic, 'Sizes', [20 -1])
            
            % NC
            box_v24 = uiextras.VBox('Parent', box_v2_base);
            uicontrol('Style', 'Text', ...
                'Parent', box_v24, 'Background', [0.69 0.93 0.93],...
                'HorizontalAlignment', 'left',...
                'String', 'Noise Cancellation - Remote Reference');
            
            box_v24h1 = uiextras.HBox('Parent', box_v24);
            box_v24h1v1 = uiextras.VBox('Parent', box_v24h1);
            uicontrol('Style', 'Text', 'Parent', box_v24h1v1, 'String', ''); % empty
            gui.panel_controls.NCOn = uicontrol(...
                'Style','Radio',...
                'String','enable',...
                'Value',0,...
                'parent',box_v24h1v1,...
                'HandleVisibility','on',...
                'Callback',@NCOn);
            gui.panel_controls.NCOff = uicontrol(...
                'Style','Radio',...
                'String','disable',...
                'Value',1,...
                'parent',box_v24h1v1,...
                'HandleVisibility','on',...
                'Callback',@NCOff);
            uicontrol('Style', 'Text', 'Parent', box_v24h1v1, 'String', ''); % empty
            set(box_v24h1v1, 'Sizes', [20 30 30 20])
            box_v24h1v4 = uiextras.VBox('Parent', box_v24h1);
            box_v24h1v2 = uiextras.VBox('Parent', box_v24h1);
            uicontrol('Style', 'Text', 'Parent', box_v24h1v2, 'String', ''); % empty
            gui.panel_controls.NCGlobalOn = uicontrol(...
                'Style','Radio',...
                'String','Global',...
                'Enable', 'off', ...
                'Value',1,...
                'parent',box_v24h1v2,...
                'HandleVisibility','on',...
                'Callback',@NCGlobalOn);
            gui.panel_controls.NCLocalOn = uicontrol(...
                'Style','Radio',...
                'String','Local',...
                'Enable', 'off', ...
                'Value',0,...
                'parent',box_v24h1v2,...
                'HandleVisibility','on',...
                'Callback',@NCLocalOn);
            gui.panel_controls.NCTransferCalc = uicontrol(...
                'Style','Pushbutton',...
                'String','Calc. Transfer Fct.',...
                'Enable', 'off', ...
                'parent',box_v24h1v2,...
                'HandleVisibility','on',...
                'Callback',@onPushbuttonNCTransferCalc);
            uicontrol('Style', 'Text', 'Parent', box_v24h1v2, 'String', ''); % empty
            set(box_v24h1v2, 'Sizes', [5 30 30 30 5])
            box_v24h1v5 = uiextras.VBox('Parent', box_v24h1);
            box_v24h1v3 = uiextras.VBox('Parent', box_v24h1);
            uicontrol('Style', 'Text', 'Parent', box_v24h1v3, 'String', ''); % empty
            uicontrol('Style', 'Text', ...
                'Parent', box_v24h1v3, ...
                'HorizontalAlignment', 'center',...
                'String', 'Ref. Channels');
            gui.panel_controls.edit_NCRefChannel = uicontrol(...
                'Style', 'Edit', ...
                'Parent', box_v24h1v3, ...
                'Enable', 'off', ...
                'BackgroundColor', [1 1 1], ...
                'String', '', ...
                'Callback',@onEditCHTask);
            uicontrol('Style', 'Text', 'Parent', box_v24h1v3, 'String', ''); % empty
            uicontrol('Style', 'Text', ...
                'Parent', box_v24h1v3, ...
                'HorizontalAlignment', 'center',...
                'String', 'Detect. Channels');
            gui.panel_controls.edit_NCDetectChannel = uicontrol(...
                'Style', 'Edit', ...
                'Parent', box_v24h1v3, ...
                'Enable', 'off', ...
                'BackgroundColor', [1 1 1], ...
                'String', '', ...
                'Callback',@onEditCHTask);  
            set(box_v24h1v3, 'Sizes', [5 15 25 5 15 25])
            set(box_v24h1, 'Sizes', [-1 10 -1 10 -1])
            set(box_v24, 'Sizes', [20 100])
            %set(box_v24, 'Sizes', [20 -1])
            
        % Filter           
            box_v21 = uiextras.VBox('Parent', box_v2_base);
            uicontrol('Style', 'Text', ...
                'Parent', box_v21, 'Background', [0.69 0.93 0.93],...
                'HorizontalAlignment', 'left',...
                'String', 'Filter Properties');
            box_v21h1 = uiextras.HBox('Parent', box_v21);
            box_v21h1v1 = uiextras.VBox('Parent', box_v21h1);
            uicontrol('Style', 'Text', ...
                'Parent', box_v21h1v1, ...
                'HorizontalAlignment', 'center',...
                'String', 'Pass freq. -->');
            gui.panel_controls.edit_filterwidth = uicontrol(...
                'Style', 'Edit', ...
                'Parent', box_v21h1v1, ...
                'Enable', 'on', ...
                'BackgroundColor', [1 1 1], ...
                'String', '500',...
                'Callback', @onEditFilterwidth);
            box_v21h1v2 = uiextras.VBox('Parent', box_v21h1);
            uicontrol('Style', 'Text', ...
                'Parent', box_v21h1v2, ...
                'HorizontalAlignment', 'center',...
                'String', 'Stop freq. -->');
            gui.panel_controls.filterstop = uicontrol(...
                'Style', 'Edit', ...
                'Parent', box_v21h1v2, ...
                'Enable', 'off', ...
                'BackgroundColor', [1 1 1], ...
                'String', '1500');
            box_v21h1v3 = uiextras.VBox('Parent', box_v21h1);
            uicontrol('Style', 'Text', ...
                'Parent', box_v21h1v3, ...
                'HorizontalAlignment', 'center',...
                'String', 'Deadtime');
            gui.panel_controls.filterdead = uicontrol(...
                'Style', 'Edit', ...
                'Parent', box_v21h1v3, ...
                'Enable', 'off', ...
                'BackgroundColor', [1 1 1], ...
                'String', '0');
            set(box_v21, 'Sizes', [20 50])
            %set(box_v21, 'Sizes', [20 -1])
            
        
                
        % Truncation
            box_v23 = uiextras.VBox('Parent', box_v2_base);
            
        % checkbox keep
            box_v24 = uiextras.VBox('Parent', box_v2_base);
            uicontrol('Style', 'Text', ...
                'Parent', box_v24, 'Background', [0.69 0.93 0.93],...
                'HorizontalAlignment', 'left',...
                'String', 'Keep');
            box_v24_h1 = uiextras.HBox('Parent', box_v24);
                gui.panel_controls.checkbox_keep = uicontrol(...
                    'Style', 'Checkbox', ...
                    'Parent', box_v24_h1, ...
                    'Enable', 'on', ...
                    'Value', 1, ...
                    'Callback', @onCheckboxKeep);
                uicontrol('Style', 'Text', ...
                    'Parent', box_v24_h1, ...
                    'HorizontalAlignment', 'left',...
                    'String', 'keep this recording');
                uiextras.HBox('Parent', box_v24_h1);   % empty
%                 gui.panel_controls.pushbutton_searchKeep = uicontrol(...
%                     'Style', 'Pushbutton', ...
%                     'Parent', box_v24_h1, ...
%                     'String', 'search',...
%                     'Callback', @onSearchKeep);
                gui.panel_controls.pushbutton_checkKeep = uicontrol(...
                    'Style', 'Pushbutton', ...
                    'Parent', box_v24_h1, ...
                    'String', 'Check Phase Cycle',...
                    'Callback', @onCheckPhaseCycle);
                gui.panel_controls.pushbutton_FixKeep = uicontrol(...
                    'Style', 'Pushbutton', ...
                    'Parent', box_v24_h1, ...
                    'String', 'Fix Phase Cycle',...
                    'Callback', @onFixKeepPhaseCycle);
                
%                 set(box_v24_h1, 'Sizes', [20 100 -1 50 100 100])
                set(box_v24_h1, 'Sizes', [20 100 -1 100 100])
            set(box_v24, 'Sizes', [20 20])
            
        %set(box_v2_base, 'Sizes', [140 80 130 80 60]);
        set(box_v2_base, 'Sizes', [120 120 120 80 1 60]);
%         set(box_v2_base, 'Sizes', [-1 -1 120 80 1 60]);
        
        % + Define flow
        p3  = uiextras.BoxPanel('Parent', mainbox,'Title', 'Define Flow', 'TitleColor', [0 0.75 1]);
        
        box_p3v1   = uiextras.VBox('Parent', p3);
        box_p3v1h0 = uiextras.HBox('Parent', box_p3v1);
            uicontrol(...
                'Style', 'Text', ...
                'Parent', box_p3v1h0, ...
                'HorizontalAlignment', 'left', ...
                'String', 'Toggle buttons to process flow ONE(id) to ALL(:)');
        box_p3v1h1 = uiextras.HBox('Parent', box_p3v1);
        gui.panel_controls.togglebutton_rx = uicontrol(...
                'Style', 'Togglebutton', ...
                'Parent', box_p3v1h1, ...
                'String', 'rx',...
                'Callback', @onTogglebutton);
            gui.panel_controls.togglebutton_rec = uicontrol(...
                'Style', 'Togglebutton', ...
                'Parent', box_p3v1h1, ...
                'String', 'rec',...
                'Callback', @onTogglebutton);
            gui.panel_controls.togglebutton_q = uicontrol(...
                'Style', 'Togglebutton', ...
                'Parent', box_p3v1h1, ...
                'String', 'q',...
                'Callback', @onTogglebutton);
            gui.panel_controls.togglebutton_sig = uicontrol(...
                'Style', 'Togglebutton', ...
                'Parent', box_p3v1h1, ...
                'String', 'sig',...
                'Callback', @onTogglebutton);
        box_p3v1h2 = uiextras.HBox('Parent', box_p3v1);
            gui.panel_controls.pushbutton_flowrun = uicontrol(...
                'Style', 'Pushbutton', ...
                'Parent', box_p3v1h2, ...
                'String', 'Run',...
                'Callback', @onPushbuttonRunFlow);
            gui.panel_controls.pushbutton_flowreset = uicontrol(...
                'Style', 'Pushbutton', ...
                'Parent', box_p3v1h2, ...
                'String', 'Reset',...
                'Callback', @onPushbuttonResetFlow); 
            gui.panel_controls.togglebutton_flowstop = uicontrol(...
                'Style', 'Togglebutton', ...
                'Parent', box_p3v1h2, ...
                'String', 'Stop',...
                'Callback', @onTogglebuttonStopFlow); 
      

%         box_v3_base = uiextras.VBox('Parent', p3);
%             box_v3h1   = uiextras.HBox('Parent', box_v3_base);
%             box_v3h1v1 = uiextras.VBox('Parent', box_v3h1);
%             uicontrol('Style', 'Pushbutton', ...
%                 'Parent', box_v3h1v1, ...
%                 'String', 'run on current',...
%                 'Callback', @onPushbuttonRunOnCurrent);
%             gui.panel_controls.pushbutton_undo = uicontrol(...
%                 'Style', 'Pushbutton', ...
%                 'Parent', box_v3h1v1, ...
%                 'String', 'undo',...
%                 'Callback', @onPushbuttonUndo);
%             box_v3h1v2 = uiextras.VBox('Parent', box_v3h1);
%             uicontrol('Style', 'Pushbutton', ...
%                 'Parent', box_v3h1v2, ...
%                 'String', 'run on +',...
%                 'Callback', @onPushbuttonRunAll);
%             uicontrol('Style', 'Pushbutton', ...
%                 'Parent', box_v3h1v2, ...
%                 'String', 'undo +',...
%                 'Callback', @onPushbuttonUndoAll);
%             box_v3h1v3 = uiextras.VBox('Parent', box_v3h1);
%             uicontrol('Style', 'Text', ...
%                 'Parent', box_v3h1v3, ...
%                 'HorizontalAlignment', 'center',...
%                 'String', 'Define "+":');
%             gui.panel_controls.popupmenu_ALL = uicontrol(...
%                 'Style', 'Popupmenu', ...
%                 'Parent', box_v3h1v3, ...
%                 'String', {'all rec (1Q, 1rx, 1sig)',...
%                 'all rec & Q (1rx, 1sig)',...
%                 'all rec & Q & rx (1sig)',...
%                 'all rec & Q & rx & sig)'}); 
        set(mainbox, 'Sizes', [140 -1  120])

        
        %% GENERATE PLOT PANEL --------------------------------------------
        gui.panel_data.figureid = figure( ...
            'Name', 'MRS Signal Processing - data viewer', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'Toolbar', 'none', ...
            'HandleVisibility', 'on', ...
            'KeyPressFcn',@dokeyboardshortcut); % enable shortcuts
        
%         set(gui.panel_data.figureid, 'OuterPosition', [5 screensz(4)-750 1140 750])
        set(gui.panel_data.figureid, 'Position', [5 screensz(4)-840 1140 800])
        
        % window geometry
        stf = 0.04; % relative space to frame
        t0 = [0 1]; v0 = [-1000 1000];  % dummy values
        bv = 1/5;                       % Breitenverhaeltnis
        wp = 0.5*(1-4*stf)/(1+bv);      % width primary plot
        hp = 0.33-2*stf;                 % height primary plot
        ws = 1 - 4*stf - 2*wp;          % width secondary plots
        hs = (0.5 - 4*stf)/3;           % height secondary plots
        
        % Plot variable by user defined (e.g.FFT)
        gui.panel_data.FFT(1) = subplot(50,50,2500);
        plot(t0,v0,'w-',t0,-v0,'w-')
        set(gca,'Color',[0 0 0],...
            'Position',[stf stf wp hp])
        gui.panel_data.txt_varData(1) = uicontrol( ...
            'Style', 'Text',...
            'String', 'FFT(fid)',...
            'Units','normalized',...
            'Position', [stf+wp-0.081 1*stf+1*hp-0.031 0.08 0.03]);
        gui.panel_data.FFT(2) = subplot(50,50,2500);
        plot(t0,v0,'w-',t0,-v0,'w-')
        set(gca,'Color',[0 0 0],...
            'Position',[2*stf+wp stf wp hp])
        gui.panel_data.txt_varData(2) = uicontrol( ...
            'Style', 'Text',...
            'String', 'FFT(stack)',...
            'Units','normalized',...
            'Position', [2*stf+2*wp-0.081 1*stf+1*hp-0.031 0.08 0.03]);
        % Plot fid
        gui.panel_data.fid(1) = subplot(50,50,2500);
        plot(t0,v0,'w-',t0,-v0,'w-')
        set(gca,'Color',[0 0 0],...
            'Position',[stf 1-stf-hp wp hp])
        gui.panel_data.txt_fid(1) = uicontrol( ...
            'Style', 'Text',...
            'String', 're(fid) rx1',...
            'Units','normalized',...
            'Position', [stf+wp-0.081 1-stf-0.031 0.08 0.03]);
        gui.panel_data.fid(2) = subplot(50,50,2500);
        plot(t0,v0,'w-',t0,-v0,'w-')
        set(gca,'Color',[0 0 0],...
            'Position',[3*stf+2*wp 1-stf-hp ws hp],...
            'XTickLabel',[],...
            'YTickLabel',[])
        gui.panel_data.txt_fid(2) = uicontrol( ...
            'Style', 'Text',...
            'String', 'all Q - gated time domain ',...
            'Units','normalized',...
            'Position', [3*stf+2*wp+ws-0.14 1-stf-0.0 0.15 0.02]);
%         gui.panel_data.fid(3) = subplot(50,50,2500);
%         plot(t0,v0,'w-',t0,-v0,'w-')
%         set(gca,'Color',[0 0 0],...
%             'Position',[3*stf+2*wp 0.5+2*stf+1*hs ws hs],...
%             'XTickLabel',[],...
%             'YTickLabel',[])
%         gui.panel_data.txt_fid(3) = uicontrol( ...
%             'Style', 'Text',...
%             'String', 'rx3',...
%             'Units','normalized',...
%             'Position', [3*stf+2*wp+ws-0.021 0.5+2*stf+2*hs-0.031 0.02 0.03]);
%         gui.panel_data.fid(4) = subplot(50,50,2500);
%         plot(t0,v0,'w-',t0,-v0,'w-')
%         set(gca,'Color',[0 0 0],...
%             'Position',[3*stf+2*wp 0.5+1*stf ws hs],...
%             'XTickLabel',[],...
%             'YTickLabel',[])
%         gui.panel_data.txt_fid(4) = uicontrol( ...
%             'Style', 'Text',...
%             'String', 'rx4',...
%             'Units','normalized',...
%             'Position', [3*stf+2*wp+ws-0.021 0.5+1*stf+1*hs-0.031 0.02 0.03]);
        gui.panel_data.fid(5) = subplot(50,50,2500);
        plot(t0,v0,'w-',t0,-v0,'w-')
        set(gca,'Color',[0 0 0],...
            'Position',[stf 1-3*stf-2*hp wp hp])
        gui.panel_data.txt_fid(5) = uicontrol( ...
            'Style', 'Text',...
            'String', 'im(fid) rx1',...
            'Units','normalized',...
            'Position', [stf+wp-0.081 1-3*stf-0.035-1*hp 0.08 0.03]);
        
        % plot stack
        gui.panel_data.stk(1) = subplot(50,50,2500);
        plot(t0,v0,'w-',t0,-v0,'w-')
        set(gca,'Color',[0 0 0],...
            'Position',[2*stf+wp 1-stf-hp wp hp])
        gui.panel_data.txt_stk(1) = uicontrol( ...
            'Style', 'Text',...
            'String', 're(stk) rx1',...
            'Units','normalized',...
            'Position',[2*stf+2*wp-0.081 1-stf-0.031 0.08 0.03]);
        gui.panel_data.stk(5) = subplot(50,50,2500);
        plot(t0,v0,'w-',t0,-v0,'w-')
        set(gca,'Color',[0 0 0],...
            'Position',[2*stf+wp 1-3*stf-2*hp wp hp])
        gui.panel_data.txt_stk(5) = uicontrol( ...
            'Style', 'Text',...
            'String', 'im(stk) rx1',...
            'Units','normalized',...
            'Position',[2*stf+2*wp-0.081 1-3*stf-0.035-1*hp 0.08 0.03]);
%         gui.panel_data.stk(3) = subplot(50,50,2500);
%         plot(t0,v0,'w-',t0,-v0,'w-')
%         set(gca,'Color',[0 0 0],...
%             'Position',[3*stf+2*wp 2*stf+1*hs ws hs],...
%             'XTickLabel',[],...
%             'YTickLabel',[])
%         gui.panel_data.txt_stk(3) = uicontrol( ...
%             'Style', 'Text',...
%             'String', 'rx3',...
%             'Units','normalized',...
%             'Position',[3*stf+2*wp+ws-0.021 2*stf+2*hs-0.031 0.02 0.03]);
        gui.panel_data.stk(2) = subplot(50,50,2500);
        plot(t0,v0,'w-',t0,-v0,'w-')
        set(gca,'Color',[0 0 0],...
            'Position',[3*stf+2*wp 1-3*stf-2*hp ws hp],...
            'XTickLabel',[],...
            'YTickLabel',[])
        gui.panel_data.txt_stk(2) = uicontrol( ...
            'Style', 'Text',...
            'String', 'all Q - frequency domain',...
            'Units','normalized',...
            'Position',[3*stf+2*wp+ws-0.14 1-3*stf-0.0-1*hp 0.15 0.02]);
        gui.panel_data.stk(4) = subplot(50,50,2500);
        plot(t0,v0,'w-',t0,-v0,'w-')
        set(gca,'Color',[0 0 0],...
            'Position',[3*stf+2*wp 1*stf ws hp],...
            'XTickLabel',[],...
            'YTickLabel',[])
        gui.panel_data.txt_stk(4) = uicontrol( ...
            'Style', 'Text',...
            'String', 'all stacks -  frequency domain',...
            'Units','normalized',...
            'Position',[3*stf+2*wp+ws-0.14 1*stf+1*hp+0.03 0.15 0.02]);
        gui.panel_data.txt2_stk(4) = uicontrol( ...
            'Style', 'Text',...
            'String', '',...
            'Units','normalized',...
            'Position',[3*stf+2*wp+ws-0.14 1*stf+1*hp+0.0 0.15 0.02]);
        
        figure(gui.panel_controls.figureid); % set control figure to front
    end

%% MENU LOAD DATA ---------------------------------------------------------
% --- Executes on selection in menu_file or directly when called
%     from MRSWorkflow.
    function onLoad(a,call)
        
        % reset structures
        fdata   = struct();
        proclog = struct();
        
        % update gui status
        mrs_setguistatus(gui,1,'Loading data...')
        
        % determine path to load data from
        if ~isnumeric(call)% workaround for matlab 2014b
            call=0;
        end
            if call  % command called from edit path or MRSworkflow
                fdata.info.path = get(gui.panel_controls.edit_path,'String');
            else     % standalone - get fdata.info.path to load sounding
                inifile = mrs_readinifile;
                if strcmp(inifile.MRSData.file,'none') == 1
                    inifile.MRSData.path = [pwd filesep];
                end
                fdata.info.path = uigetdir(...
                    inifile.MRSData.path, ...
                    'Pick a MRS sounding folder that contains the raw data folder');
                if fdata.info.path == 0  % if load is aborted (CANCEL in uigetdir)
                    disp('Aborting...');
                    mrs_setguistatus(gui,0)
                    drawnow
                    return
                end
                fdata.info.path = [fdata.info.path filesep];
            end

        
        % load data
        instrument = mrs_checkinstrument(fdata.info.path);
%           instrument = 'Jilin';
        switch instrument
            case 'numis'
                fdata = mrs_load_numisraw(fdata.info.path);
            case 'midi'
                fdata = mrs_load_midiraw(fdata.info.path);
            case 'mini'
                fdata = mrs_load_miniraw(fdata.info.path);
            case 'terranova'
                fdata = mrs_load_terranova(fdata.info.path);
            case 'gmr' 
%                 % Request data type
%                 if strcmp(fdata.info.path(end-9:end-1),'GMR2NUMIS')
%                     gmrdatatype = 'Converted';
%                 else
%                     gmrdatatype = questdlg(...
%                         'Select the type of GMR data', ...
%                         'GMR data type', ...
%                         'Preprocessed','Converted','Raw','Preprocessed');
%                 end
%                 % load
%                 switch gmrdatatype
%                     case 'Preprocessed'
%                         fdata = mrs_load_gmrpreproc(fdata.info.path);
%                     case 'Converted'
%                         fdata = mrs_load_gmrconverted(fdata.info.path);
%                     case 'Raw' 
% %                         fdata = mrs_load_gmrraw(fdata.info.path);
                         fdata = mrsSigPro_ImportGMR(fdata.info.path,gui);
%                 end
            case 'LIAGNoiseMeter'
                fdata = mrs_load_LIAGNoiseMeter(fdata.info.path);
            case 'Jilin'
                fdata = mrs_load_Jilin(fdata.info.path);
        end
        
        if ~isstruct(fdata)  % prevent error for next if (==0 doens't work for struct)
            if fdata == 0    % if load is aborted (CANCEL in uigetdir)
                disp('Aborting...');
                mrs_setguistatus(gui,0)
                drawnow
                return
            end
        end
        
        % update gui status
        mrs_setguistatus(gui,0)

        % set edit path
        set(gui.panel_controls.edit_path,'String',fdata.info.path)
        
        % initialize proclog structure
        proclog = initialize_proclog(fdata);
        
        % deactivate NC for NumisPlus
        if strcmp(proclog.device,'NUMISplus')
           set(gui.panel_controls.NCOn,'Enable','off') 
        end
        
        % set default signal
        set(gui.panel_controls.popupmenu_SIG,'Value',2)
        
        % find out q's in path and pipe to q dropdown menu
%         set(gui.panel_controls.popupmenu_Q,'String',mrs_getX('Q',fdata.info))
        set(gui.panel_controls.popupmenu_Q,'String',num2str((1:length(fdata.Q))'))
        set(gui.panel_controls.popupmenu_Q,'Value',1)
        
        % find out available recordings for current q and pipe to REC dropdown menu
%         set(gui.panel_controls.popupmenu_REC,'String',mrs_getX('REC',fdata.info,1))
        set(gui.panel_controls.popupmenu_REC,'String',num2str((1:length(fdata.Q(1).rec))'))
        set(gui.panel_controls.popupmenu_REC,'Value',1)
        
        % find out available receivers and pipe to RX dropdown menu
%         set(gui.panel_controls.popupmenu_RX,'String',num2str([fdata.info.rxinfo(:).channel]'))
        set(gui.panel_controls.popupmenu_RX,'String',num2str((1:length(fdata.info.rxinfo))'))
        set(gui.panel_controls.popupmenu_RX,'Value',1)
        
        % enable pushbutton edit log
        set(gui.panel_controls.pushbutton_editLog, 'Enable', 'on')
        
        % update deadtime
        set(gui.panel_controls.filterdead,'String',num2str(fdata.Q(1).rec(1).info.timing.tau_dead1));
        
        % update togglebutton text
        onTogglebutton;        
        
        % find references and detection
        ref = ([fdata.info.rxinfo(:).task] == 2);   % JW: according to Converter this should be 3?
        sig = ([fdata.info.rxinfo(:).task] == 1);
        set(gui.panel_controls.edit_NCRefChannel, 'String', num2str([fdata.info.rxinfo(ref).channel]))
        set(gui.panel_controls.edit_NCDetectChannel, 'String', num2str([fdata.info.rxinfo(sig).channel]))
        
        % find trim time
%        set(gui.panel_controls.trimMint,'String',num2str(min(fdata.Q(1).rec(1).rx(1).sig(2).t0)))
%        set(gui.panel_controls.trimMaxt,'String',num2str(max(fdata.Q(1).rec(1).rx(1).sig(2).t0)))
        
        mrsSigPro_plotdata(gui,fdata,proclog);
    end

%% MENU RELOAD DATA (PROCLOG FILE) ----------------------------------------
% --- Executes on selection in menu_reload_proclog OR if called by
%     MRSWorkflow and status > 0. Reloads proclog file from ui,
%     loads numis data in folder of proclog file.
%     function onReload(a,call)
%         
%         % get saved *.mrsd-file
%         if call  % command comes from workflow
%             % filename is saved in mrsproject.mrsp file. It is not
%             % available here...
%             filename = uigetfile( ...
%                 {'*.mrsd','MRSData File (*.mrsd)';
%                 '*.*',  'All Files (*.*)'}, ...
%                 'Pick a MRSData file',...
%                 sounding_path);
%             filepath = sounding_path;
%         else     % standalone
%             inifile = mrs_readinifile;
%             if strcmp(inifile.MRSData.file,'none') == 1
%                 inifile.MRSData.path = [pwd filesep];
%                 inifile.MRSData.file = 'mrs_project';
%             end
%             [filename,filepath] = uigetfile(...
%                 {'*.mrsd','MRSData File (*.mrsd)';
%                 '*.*',  'All Files (*.*)'}, ...
%                 'Pick a MRSData file',...
%                 [inifile.MRSData.path inifile.MRSData.file]);
%         end
%         if filename == 0    % if reload is aborted (CANCEL in uigetfile)
%             disp('Aborting...');
%             mrs_setguistatus(gui,0)
%             return
%         end
%         
%         % load proclog
%         proclog = mrs_load_proclog(filepath, filename);
%         
%         % check version
%         savedversion    = proclog.MRSversion;
% %         softwareversion = mrs_version;
%         if ~isequal(savedversion,mrs_version)
%             msgbox('The selected .mrsd-file is outdated. Running MRSUpdate is recommended.','Outdated .mrsd file')
%         end
%         
%         % load data (switch for instruments)
%         mrs_setguistatus(gui,1,'Loading data...')   % update gui status
%         switch proclog.device
%             case {'NUMISpoly'}
%                 fdata = mrs_load_numisraw(filepath); % preserves path: data.info.path == filepath
%             case {'NUMISplus'}
%                 fdata = mrs_load_numisraw(filepath); % preserves path: data.info.path == filepath
%                 set(gui.panel_controls.NCOn,'Enable','off')
%             case 'MIDI'
%                 fdata = mrs_load_midiraw(filepath); % preserves path: data.info.path == filepath
%             case 'MINI'
%                 error('MINI IS NOT YET IMPLEMENTED')
%                 fdata = mrs_load_miniraw(filepath); % preserves path: data.info.path == filepath        
%             case 'GMR'
%                 % Request data type
%                 if strcmp(proclog.path(end-9:end-1),'GMR2NUMIS')
%                     gmrdatatype = 'Converted';
%                 else
%                     gmrdatatype = questdlg(...
%                         'Select the type of GMR data', ...
%                         'GMR data type', ...
%                         'Preprocessed','Converted','Raw','Preprocessed');
%                 end
%                 switch gmrdatatype
%                     case 'Preprocessed'
%                         fdata = mrs_load_gmrpreproc(filepath);
%                     case 'Converted'
%                         fdata = mrs_load_gmrconverted(filepath);
%                     case 'Raw'
%                         fdata = mrs_load_gmrraw(filepath);
%                 end
%         end        
%         
%         % reprocess data
%         mrs_setguistatus(gui,1,'Reprocessing data...')
%         id    = find(proclog.event(:,1) < 100);   % reprocess all events of type <100 (>100 is done in MRSFit)
%         fdata = mrs_reprocess_proclog(fdata, proclog, id);
%         
%         % update gui status
%         mrs_setguistatus(gui,0)
%         
%         % set edit path
%         set(gui.panel_controls.edit_path,'String',fdata.info.path)
%         
%         % set default signal
%         set(gui.panel_controls.popupmenu_SIG,'Value',2)
%         
%         % set keep
%         set(gui.panel_controls.checkbox_keep,'Value',mrs_getkeep(proclog,1,1,1,2))
%         
%         % find out q's in path and pipe to q dropdown menu
% %         set(gui.panel_controls.popupmenu_Q,'String',mrs_getX('Q',fdata.info))
%         set(gui.panel_controls.popupmenu_Q,'String',num2str((1:length(fdata.Q))'))
%         set(gui.panel_controls.popupmenu_Q,'Value',1)
%         
%         % find out available recordings for current q and pipe to REC dropdown menu
% %         set(gui.panel_controls.popupmenu_REC,'String',mrs_getX('REC',fdata.info,1))
%         set(gui.panel_controls.popupmenu_REC,'String',num2str((1:length(fdata.Q(1).rec))'))
%         set(gui.panel_controls.popupmenu_REC,'Value',1)
%         
%         % find out available receivers and pipe to RX dropdown menu
% %         set(gui.panel_controls.popupmenu_RX,'String',num2str([fdata.info.rxinfo(:).channel]'))     
%         set(gui.panel_controls.popupmenu_RX,'String',num2str((1:length(fdata.info.rxinfo))'))        
%         set(gui.panel_controls.popupmenu_RX,'Value',1)
%         
%         % enable pushbutton edit log
%         set(gui.panel_controls.pushbutton_editLog, 'Enable', 'on') 
%         
%         % find references and detection
%         ref = ([fdata.info.rxinfo(:).task] == 2);   % JW: according to Converter this should be 3?
%         sig = ([fdata.info.rxinfo(:).task] == 1);
%         set(gui.panel_controls.edit_NCRefChannel, 'String', num2str([fdata.info.rxinfo(ref).channel]))
%         set(gui.panel_controls.edit_NCDetectChannel, 'String', num2str([fdata.info.rxinfo(sig).channel]))        
%         
%         mrsSigPro_plotdata(gui,fdata,proclog);
%     end


%% MENU SAVE --------------------------------------------------------------
% --- Executes on menu selection save. Saves datafile. Only active when
%     mrsSigPro is called standalone (i.e., not from workflow).
    function onSave(a,b)
        [filename,filepath] = uiputfile({...
            '*.mrsd','MRSMatlab data'; '*.*','All Files' },...
            'Save MRSMatlab data file',...
            [fdata.info.path,'mrs_sounding',fdata.info.path(end-4:end-1)]); % NUMIS specific...
        if filepath == 0;
            disp('Aborting...'); return;
        end
        outfile = [filepath filename];   
        
        % check for phase cycling
        proceed = mrsSigPro_check_keep_phasecycle(fdata,proclog);      
        if proceed == 0
            % proclog = mrsSigPro_adjust_keep_phasecycle(fdata,proclog);
            % disp('adjusted keep to correct the phase cycle - check and start save again');
            return
        end
        
        proclog = mrsSigPro_stack(gui,fdata,proclog);
        proclog.status = 2;
        save(outfile,'proclog');
        fprintf(1,'proclog saved to %s\n', outfile);
        mrs_updateinifile(outfile,1);
    end


%% MENU SAVE CURRENT STATE
    function onSaveWorkspace(a,b)
        [filename,filepath] = uiputfile({...
            '*.mrsr','MRSSigPro raw data file'; '*.*','All Files' },...
            'Save MRSSigPro raw data file',...
            [fdata.info.path,'mrs_sounding',fdata.info.path(end-4:end-1)]); % NUMIS specific...
        if filepath == 0;
            disp('Aborting...'); return;
        end
        outfile = [filepath filename]; 
        save(outfile,'proclog','fdata');
        fprintf(1,'processing state saved to %s\n', outfile);
        mrs_updateinifile(outfile,1);
    end
%% MENU LOAD PROCESSING STATE
    function onLoadWorkspace(a,b)
        inifile = mrs_readinifile;
        if strcmp(inifile.MRSData.file,'none') == 1
            inifile.MRSData.path = [pwd filesep];
        end
        [filename,filepath] = uigetfile({'*.*; *.*','Pick MRSSigPro raw data file'},...
                'MultiSelect','off',...
                'MRSSigPro raw data file',...
                [inifile.MRSData.path]);
        if filepath == 0  % if load is aborted (CANCEL in uigetdir)
            disp('Aborting...');
            mrs_setguistatus(gui,0)
            drawnow
            return
        end
        tmp = load([filepath filename],'-mat');
        
        % proclog
        proclog=tmp.proclog;
        
        % check version
        savedversion    = proclog.MRSversion;
%         softwareversion = mrs_version;
        if ~isequal(savedversion,mrs_version)
            msgbox('The selected .mrsd-file is outdated. Running MRSUpdate is recommended.','Outdated .mrsd file')
        end
        
        % data
        fdata=tmp.fdata;
        
        % set edit path
        set(gui.panel_controls.edit_path,'String',fdata.info.path)
        
        % set default signal
        set(gui.panel_controls.popupmenu_SIG,'Value',2)
        
        % set keep
        set(gui.panel_controls.checkbox_keep,'Value',mrs_getkeep(proclog,1,1,1,2))
        
        % find out q's in path and pipe to q dropdown menu
%         set(gui.panel_controls.popupmenu_Q,'String',mrs_getX('Q',fdata.info))
        set(gui.panel_controls.popupmenu_Q,'String',num2str((1:length(fdata.Q))'))
        set(gui.panel_controls.popupmenu_Q,'Value',1)
        
        % find out available recordings for current q and pipe to REC dropdown menu
%         set(gui.panel_controls.popupmenu_REC,'String',mrs_getX('REC',fdata.info,1))
        set(gui.panel_controls.popupmenu_REC,'String',num2str((1:length(fdata.Q(1).rec))'))
        set(gui.panel_controls.popupmenu_REC,'Value',1)
        
        % find out available receivers and pipe to RX dropdown menu
%         set(gui.panel_controls.popupmenu_RX,'String',num2str([fdata.info.rxinfo(:).channel]'))     
        set(gui.panel_controls.popupmenu_RX,'String',num2str((1:length(fdata.info.rxinfo))'))        
        set(gui.panel_controls.popupmenu_RX,'Value',1)
        
        % enable pushbutton edit log
        set(gui.panel_controls.pushbutton_editLog, 'Enable', 'on') 
        
        % find references and detection
        ref = ([fdata.info.rxinfo(:).task] == 2);   % JW: according to Converter this should be 3?
        sig = ([fdata.info.rxinfo(:).task] == 1);
        set(gui.panel_controls.edit_NCRefChannel, 'String', num2str([fdata.info.rxinfo(ref).channel]))
        set(gui.panel_controls.edit_NCDetectChannel, 'String', num2str([fdata.info.rxinfo(sig).channel]))        
        
        % find trim time
%        set(gui.panel_controls.trimMint,'String',num2str(min(fdata.Q(1).rec(1).rx(1).sig(2).t0)))
%        set(gui.panel_controls.trimMaxt,'String',num2str(max(fdata.Q(1).rec(1).rx(1).sig(2).t0)))
        
        mrsSigPro_plotdata(gui,fdata,proclog);
        
    end
%% MENU SAVE & QUIT -------------------------------------------------------
% --- Executes on menu selection save&quit. Saves datafile and returns
%     proclog to mrsSigPro.
    function onSaveAndQuit(a,b)
        switch standalone
            case 0
                outfile = [sounding_path sounding_file];
            case 1
                [filename,filepath] = uiputfile({...
                    '*.mrsd','MRSMatlab data'; '*.*','All Files' },...
                    'Save MRSMatlab data file',...
                    [fdata.info.path,'mrs_sounding',fdata.info.path(end-4:end-1)]); % NUMIS specific...
                if filepath == 0;
                    disp('Aborting...'); return;
                end
                outfile = [filepath filename];
        end
        proclog = mrsSigPro_stack(gui,fdata,proclog);
        proclog.status = 2;
        save(outfile,'proclog');
        fprintf(1,'proclog saved to %s\n', outfile);
        mrs_updateinifile(outfile,1);
        uiresume;
        delete(gui.panel_controls.figureid)
        delete(gui.panel_data.figureid)
    end

%% MENU QUIT --------------------------------------------------------------
% --- Executes on menu selection Quit.
    function onQuitWithoutSave(a,b)
        sounding_file = -1;
        uiresume
        delete(gui.panel_controls.figureid)
        delete(gui.panel_data.figureid)
    end

%% MENU HELP --------------------------------------------------------------
% --- Executes on menu selection Help.
    function onHelp(a,b)
        warndlg({'Whatever your question is:'; ''; 'Its not a bug - Its a feature!'; '';'All the rest is incorrect user action'}, 'modal')
    end

%% EDIT PATH (DATA) -------------------------------------------------------
% --- Executes on selection in menu_file or directly when called
%     from MRSWorkflow.
    function onEditPath(a,b)
        onLoad(gui.panel_controls.menu_file,1);
    end

%% EDIT CHANNEL TASK (NOISE REDUCTION) ------------------------------------
% --- Executes on edit task in noise reduction. Updates fdata.

    function onEditCHTask(a,b)
        
        % determine the channel tasks
        ch  = [fdata.info.rxinfo(:).channel];   
        ref = intersect(ch, str2num(get(gui.panel_controls.edit_NCRefChannel, 'String')));     %#ok<ST2NM>
        sig = intersect(ch, str2num(get(gui.panel_controls.edit_NCDetectChannel, 'String')));  %#ok<ST2NM>
        off = setdiff(ch, [ref sig]);   % setdiff & intersect ignore any non-existing channel id in the edit fields

        % reset fields if channels are ambiguous
        if length([sig ref off]) > length(unique([sig ref off]))
            msgbox('Set channel tasks uniquely!')
            set(gui.panel_controls.edit_NCRefChannel, 'String', num2str([fdata.info.rxinfo([fdata.info.rxinfo(:).task]==2).channel]))
            set(gui.panel_controls.edit_NCDetectChannel, 'String', num2str([fdata.info.rxinfo([fdata.info.rxinfo(:).task]==1).channel]))            
            return
        end
        
        % update fdata
        for iref = 1:length(ref)
            fdata.info.rxinfo(ch==ref(iref)).task = 2;
        end
        for isig = 1:length(sig)
            fdata.info.rxinfo(ch==sig(isig)).task = 1;
        end
        for ioff = 1:length(off)
            fdata.info.rxinfo(ch==off(ioff)).task = 0;
        end
        
        % update fields - only necessary if a non-existing channel id was entered before
        set(gui.panel_controls.edit_NCRefChannel, 'String', num2str([fdata.info.rxinfo([fdata.info.rxinfo(:).task]==2).channel]))
        set(gui.panel_controls.edit_NCDetectChannel, 'String', num2str([fdata.info.rxinfo([fdata.info.rxinfo(:).task]==1).channel]))

    end

%% SELECT Q ---------------------------------------------------------------
% --- Executes on selection change in popupmenu_Q.
    function onSelectQ(a,b)
        
        % find out available recordings for current q and pipe to REC dropdown menu
        iQ   = get(gui.panel_controls.popupmenu_Q,   'Value');
        irec = get(gui.panel_controls.popupmenu_REC, 'Value');
        irx  = get(gui.panel_controls.popupmenu_RX,  'Value');
        isig = get(gui.panel_controls.popupmenu_SIG, 'Value');
        
        % update recordings
        REC = (1:length(fdata.Q(iQ).rec))';
        set(gui.panel_controls.popupmenu_REC,'String',REC)
        
        % update deadtime
        switch isig
            case 2
                set(gui.panel_controls.filterdead,'String',num2str(fdata.Q(iQ).rec(1).info.timing.tau_dead1));
            case 3
                set(gui.panel_controls.filterdead,'String',num2str(fdata.Q(iQ).rec(1).info.timing.tau_dead2));    
        end
        
        % prevent crash if irec > # rec for this q
        irec = min([irec length(REC)]);
        set(gui.panel_controls.popupmenu_REC, 'Value', irec)
        
        % update togglebutton text
        onTogglebutton;
        
        % update keep
        set(gui.panel_controls.checkbox_keep,'Value', mrs_getkeep(proclog,iQ,irec,irx,isig)); 
        
        % turn off selection highlight (to enable keyboard shortcuts)
        remove_selectionhighlight(gui.panel_controls.popupmenu_Q);
        
        mrsSigPro_plotdata(gui,fdata,proclog);
    end

%% SELECT REC -------------------------------------------------------------
% --- Executes on selection change in popupmenu_REC.
    function onSelectREC(a,b)
        iQ   = get(gui.panel_controls.popupmenu_Q, 'Value');
        irec = get(gui.panel_controls.popupmenu_REC, 'Value');
        irx  = get(gui.panel_controls.popupmenu_RX, 'Value');
        isig = get(gui.panel_controls.popupmenu_SIG, 'Value');
        
        % update togglebutton text
        onTogglebutton;
        
        % update keep
        set(gui.panel_controls.checkbox_keep,'Value', mrs_getkeep(proclog,iQ,irec,irx,isig));
               
        mrsSigPro_plotdata(gui,fdata,proclog);
    end

%% SELECT RX --------------------------------------------------------------
% --- Executes on selection change in popupmenu_REC.
    function onSelectRX(a,b)
        iQ   = get(gui.panel_controls.popupmenu_Q, 'Value');
        irec = get(gui.panel_controls.popupmenu_REC, 'Value');
        irx  = get(gui.panel_controls.popupmenu_RX, 'Value');
        isig = get(gui.panel_controls.popupmenu_SIG, 'Value');
        
        % update togglebutton text
        onTogglebutton;

        % update keep
        set(gui.panel_controls.checkbox_keep,'Value', mrs_getkeep(proclog,iQ,irec,irx,isig));
              
        mrsSigPro_plotdata(gui,fdata,proclog);
    end

%% SELECT SIG -------------------------------------------------------------
% --- Executes on selection change in popupmenu_SIG.
    function onSelectSIG(a,b)
        iQ   = get(gui.panel_controls.popupmenu_Q, 'Value');
        irec = get(gui.panel_controls.popupmenu_REC, 'Value');
        irx  = get(gui.panel_controls.popupmenu_RX, 'Value');
        isig = get(gui.panel_controls.popupmenu_SIG, 'Value');
        
        % block signal switch if not recorded
        if fdata.Q(iQ).rec(irec).rx(irx).sig(isig).recorded == 0
            isig = 2;
            set(gui.panel_controls.popupmenu_SIG, 'Value',isig);
        end
        
        % update deadtime
        switch isig
            case 2
                set(gui.panel_controls.filterdead,'String',num2str(fdata.Q(iQ).rec(1).info.timing.tau_dead1));
            case 3
                set(gui.panel_controls.filterdead,'String',num2str(fdata.Q(iQ).rec(1).info.timing.tau_dead2));    
        end
        
        % update togglebutton text
        onTogglebutton;
        
        % update keep
        set(gui.panel_controls.checkbox_keep,'Value', mrs_getkeep(proclog,iQ,irec,irx,isig));
        
        mrsSigPro_plotdata(gui,fdata,proclog);
    end


%% CHECKBOX KEEP ----------------------------------------------------------
% --- Executes on ticking checkbox_keep.
    function onCheckboxKeep(a,b)
        iQ   = get(gui.panel_controls.popupmenu_Q, 'Value');
        irec = get(gui.panel_controls.popupmenu_REC, 'Value');
        irx  = get(gui.panel_controls.popupmenu_RX, 'Value');
        isig = get(gui.panel_controls.popupmenu_SIG, 'Value');
        
        % Return if there is only one record
        % This case happens e.g. when processing GMR-preproc data (stacked).
        % MAYBE CHECK ALSO IF THERE IS AT LEAST 1 KEEP FOR ALL REC's
        if length(fdata.Q(iQ).rec) < 2
            mrs_setguistatus(gui,1,'There is only 1 recording - cannot delete this')
            pause(1)
            set(gui.panel_controls.checkbox_keep,'Value',1);
            mrs_setguistatus(gui,0)
            return
        end                
        
        % update proclog
        keep = get(gui.panel_controls.checkbox_keep,'Value');
        proclog.event(end+1,:) = [1 iQ irec irx isig keep 0 0];
        
        % write new proclog entries for every tick/untick -> this keeps
        % track of the situation that an fid is dropped for averaging, and
        % then taken back in.

        mrsSigPro_plotdata(gui,fdata,proclog);
    end
    function onSearchKeep(a,b) % scan q
        iQ   = get(gui.panel_controls.popupmenu_Q, 'Value');
        irec = get(gui.panel_controls.popupmenu_REC, 'Value');
        irx  = get(gui.panel_controls.popupmenu_RX, 'Value');
        isig = get(gui.panel_controls.popupmenu_SIG, 'Value');
        proclog = mrsSigPro_search_keep(fdata,proclog,iQ,irec,irx,isig);
        % update keep
        set(gui.panel_controls.checkbox_keep,'Value', mrs_getkeep(proclog,iQ,irec,irx,isig));
        mrsSigPro_plotdata(gui,fdata,proclog);
    end
    function onCheckPhaseCycle(a,b)
        proceed = mrsSigPro_check_keep_phasecycle(fdata,proclog); 
        if proceed == 1
            msgbox('odd and even number of records is equal. ')
        elseif proceed==2
            msgbox('only GMR used phasecycling - no need to check ')
        end
    end
    function onFixKeepPhaseCycle(a,b)
        iQ   = get(gui.panel_controls.popupmenu_Q, 'Value');
        irec = get(gui.panel_controls.popupmenu_REC, 'Value');
        irx  = get(gui.panel_controls.popupmenu_RX, 'Value');
        isig = get(gui.panel_controls.popupmenu_SIG, 'Value');
        
        proclog = mrsSigPro_adjust_keep_phasecycle(fdata,proclog);
         
        % update keep
        set(gui.panel_controls.checkbox_keep,'Value', mrs_getkeep(proclog,iQ,irec,irx,isig));
        mrsSigPro_plotdata(gui,fdata,proclog);
        
        proceed = mrsSigPro_check_keep_phasecycle(fdata,proclog);
        if proceed == 1
            msgbox('odd and even number of records is equal. ')
        elseif proceed==2
            msgbox('only GMR used phasecycling - no need to fix ')    
        else
            msgbox('Run Fix again')
        end
    end
%% Filter properties
    function filterOn(a,b)
        set(gui.panel_controls.filterOn, 'Value', 1)
        set(gui.panel_controls.filterOff, 'Value', 0)
        set(gui.panel_controls.edit_filterwidth, 'Enable', 'on')
    end
    function filterOff(a,b)
        set(gui.panel_controls.filterOn, 'Value', 0)
        set(gui.panel_controls.filterOff, 'Value', 1)
        set(gui.panel_controls.edit_filterwidth, 'Enable', 'off')
    end
    function onEditFilterwidth(a,b)
        % only allow for multiple of 50 and stop freq. beeing 3 times pass
        % freq.
        fW = str2double(get(gui.panel_controls.edit_filterwidth, 'String'));
        fW = 50*floor(fW/50);
        set(gui.panel_controls.edit_filterwidth, 'String',num2str(fW));    
        if fW < 50
            set(gui.panel_controls.edit_filterwidth, 'String','50')
        elseif fW > 1000
            set(gui.panel_controls.edit_filterwidth, 'String','1000')
        end
        proclog.LPfilter.fW = str2double(get(gui.panel_controls.edit_filterwidth, 'String'));
        
        set(gui.panel_controls.filterstop, 'String',num2str(3*proclog.LPfilter.fW))
        
        mrsSigPro_plotdata(gui,fdata,proclog);
    end

%% RADIOBUTTON TRIM
    function trimOn(a,b)
        set(gui.panel_controls.trimOn, 'Value', 1)
        set(gui.panel_controls.trimOff, 'Value', 0)
        set(gui.panel_controls.trimMint, 'Enable', 'on')
        set(gui.panel_controls.trimMaxt, 'Enable', 'on')
    end

    function trimOff(a,b)
        set(gui.panel_controls.trimOn, 'Value', 0)
        set(gui.panel_controls.trimOff, 'Value', 1)
        set(gui.panel_controls.trimMint, 'Enable', 'off')
        set(gui.panel_controls.trimMaxt, 'Enable', 'off')
    end

    function trim(a,b)
        minT = str2num(get(gui.panel_controls.trimMint,'String'));
        maxT = str2num(get(gui.panel_controls.trimMaxt,'String'));
    end

%% RADIOBUTTON HARMONIC
    function onRadioDelHarmonicOn(a,b)
        set(gui.panel_controls.radio_DelHarmonicOn, 'Value', 1)
        set(gui.panel_controls.radio_DelHarmonicOff, 'Value', 0)
        set(gui.panel_controls.edit_DelHarmonic_frequency, 'Enable', 'on')        
    end
    function onRadioDelHarmonicOff(a,b)        
        set(gui.panel_controls.radio_DelHarmonicOn, 'Value', 0)
        set(gui.panel_controls.radio_DelHarmonicOff, 'Value', 1)
        set(gui.panel_controls.edit_DelHarmonic_frequency, 'Enable', 'off')
        set(gui.panel_controls.radio_DelHarmonicOn_2, 'Value', 0)
        set(gui.panel_controls.radio_DelHarmonicOff_2, 'Value', 1)
        set(gui.panel_controls.edit_DelHarmonic_frequency_2, 'Enable', 'off')
    end
    function onRadioDelHarmonicOn_2(a,b)
        set(gui.panel_controls.radio_DelHarmonicOn_2, 'Value', 1)
        set(gui.panel_controls.radio_DelHarmonicOff_2, 'Value', 0)
        set(gui.panel_controls.edit_DelHarmonic_frequency_2, 'Enable', 'on')        
    end
    function onRadioDelHarmonicOff_2(a,b)        
        set(gui.panel_controls.radio_DelHarmonicOn_2, 'Value', 0)
        set(gui.panel_controls.radio_DelHarmonicOff_2, 'Value', 1)
        set(gui.panel_controls.edit_DelHarmonic_frequency_2, 'Enable', 'off')
    end
%% CheckBUTTON CoFreqHarmonic
    function onCheckRemoveCof(a,b)

    end
    function onCheckFastHNC(a,b)

    end

%% RADIOBUTTON DESPIKE ----------------------------------------------------
% --- Executes on press on radiobuttons in DESPIKE PROPERTIES.
%     Manually despike a single recording. The despiking event is logged in
%     proclog.    
    function onRadioDespikeAuto(a,b)
        set(gui.panel_controls.radio_despikeAuto, 'Value', 1)
        set(gui.panel_controls.radio_despikeManu, 'Value', 0)
        set(gui.panel_controls.pushbutton_despikeManu, 'Enable', 'off')
        set(gui.panel_controls.pushbutton_despikeUndo, 'Enable', 'off')
        set(gui.panel_controls.radio_despikeAutoType, 'Enable', 'on')
        set(gui.panel_controls.edit_despikeThreshold, 'Enable', 'on')        
    end

    function onRadioDespikeManu(a,b)
        set(gui.panel_controls.radio_despikeAuto, 'Value', 0)
        set(gui.panel_controls.radio_despikeManu, 'Value', 1)
        set(gui.panel_controls.pushbutton_despikeManu, 'Enable', 'on')
        set(gui.panel_controls.pushbutton_despikeUndo, 'Enable', 'on')
        set(gui.panel_controls.radio_despikeAutoType, 'Enable', 'off')
        set(gui.panel_controls.edit_despikeThreshold, 'Enable', 'off')
    end

%% PUSHBUTTON MANUAL (DESPIKE) --------------------------------------------
% --- Executes on press on pushbutton MANUAL (despike properties).
%     Manually despike a single recording. The despiking event is logged in
%     proclog.
    function onPushbuttonDespikeManu(a,b)
        iQ   = get(gui.panel_controls.popupmenu_Q, 'Value');
        irec = get(gui.panel_controls.popupmenu_REC, 'Value');
        irx  = get(gui.panel_controls.popupmenu_RX, 'Value');
        isig = get(gui.panel_controls.popupmenu_SIG, 'Value');
        
        % Return if there is only one record - averaging is impossible
        % This case happens e.g. when processing GMR-preproc data (stacked).
        % HANDLE Q-STACK VS REC-STACK!
        if length(fdata.Q(iQ).rec) < 2
            mrs_setguistatus(gui,1,'There is only 1 recording - cannot replace spike by average (over recordings)')
            pause(1)
            mrs_setguistatus(gui,0)
            return
        end
        
        % calculate window
        mint  = 0; % No trim manipulation in MRSSigPro str2double(get(gui.panel_controls.trimMint,'String'));
        width = str2double(get(gui.panel_controls.edit_despikeMutewidth,'String'))/1000;
        
        % get spike via mouse interaction
        figure(gui.panel_data.figureid)
        cut       = ginput(1);          % [s]
        cutcenter = cut(1,1) - mint;    % [s]
        
        % replace detected window by average
        [fdata,proclog] = mrsSigPro_replaceSpike(fdata,proclog,iQ,irec,irx,isig,-1,cutcenter,width,1);
               
        % plot
        mrsSigPro_plotdata(gui,fdata,proclog);
        
    end

%% PUSHBUTTON UNDO (DESPIKE) ----------------------------------------------
% --- Executes on press on pushbutton UNDO (despike properties AND define flow).
%     Restores the rawdata v0 and deletes all despike and noise cancellation events for this
%     record
    function onPushbuttonUndo(a,b)
        if nargin < 2
            b = [];
        end
        
        % determine current fid
        iQ   = get(gui.panel_controls.popupmenu_Q, 'Value');
        irec = get(gui.panel_controls.popupmenu_REC, 'Value');
        irx  = get(gui.panel_controls.popupmenu_RX, 'Value');
        isig = get(gui.panel_controls.popupmenu_SIG, 'Value');
        
        % determine last despike event
        lde = find(...
                proclog.event(:,1) == 3 & ... 
                proclog.event(:,2) == iQ & ...
                proclog.event(:,3) == irec & ...
                proclog.event(:,4) == irx & ...
                proclog.event(:,5) == isig);
            
        % return if there is no despike event
        if isempty(lde)
            mrs_setguistatus(gui,1,'No despike events for this record')
            pause(1)
            mrs_setguistatus(gui,0)
            return
        else
            lde = lde(end); % get last event
        end
        
        % delete last despike event for this rec
        proclog.event(lde, :) = [];
        
        % determine all remaining events for this fid
        id = find(...
                proclog.event(:,2) == iQ & ...
                proclog.event(:,3) == irec & ...
                proclog.event(:,4) == irx & ...
                proclog.event(:,5) == isig);
        
        % restore fdata
        fdata.Q(iQ).rec(irec).rx(irx).sig(isig).v1 = ...
            fdata.Q(iQ).rec(irec).rx(irx).sig(isig).v0;
        
        % reprocess fdata
        fdata = mrs_reprocess_proclog(fdata, proclog, id);
        
        % refresh plot
        mrsSigPro_plotdata(gui,fdata,proclog);
        
%         % reset proclog: delete all despike events for this rec
%         proclog.event(proclog.event(:,1) == 3 & ...
%             proclog.event(:,2) == iQ & ...
%             proclog.event(:,3) == irec & ...
%             proclog.event(:,4) == irx & ...
%             proclog.event(:,5) == isig, :) = [];
%         
%         % reset proclog: NC events for this rec
%         proclog.event(proclog.event(:,1) == 4 & ...
%             proclog.event(:,2) == iQ & ...
%             proclog.event(:,3) == irec & ...
%             proclog.event(:,4) == irx & ...
%             proclog.event(:,5) == isig, :) = [];
%         
%         if isempty(b)
%             mrsSigPro_plotdata(gui,fdata,proclog);
%         end
    end

%% PUSHBUTTON EDIT LOG ----------------------------------------------------
% --- Executes on press on pushbutton SHOW (despike properties).
%     Restores the rawdata v0 and deletes all despike events for this
%     record
    function onPushbuttonEditLog(a,b)
        
        if nargin < 2
            b = [];
        end
        
        % set(gui.panel_controls.pushbutton_showLog, 'Enable', 'off')
        
        iQ   = get(gui.panel_controls.popupmenu_Q, 'Value');
        irec = get(gui.panel_controls.popupmenu_REC, 'Value');
        irx  = get(gui.panel_controls.popupmenu_RX, 'Value');
        isig = get(gui.panel_controls.popupmenu_SIG, 'Value');
        
        % edit processing log
        % processing has become to complex and thus slow for edition -->
        % only show the steps
        % [fdata,proclog] = mrs_edit_proclog(gui,fdata,proclog,iQ,irec,irx,isig);
        % show processing log
        [fdata,proclog] = mrs_show_proclog(gui,fdata,proclog,iQ,irec,irx,isig);
        
        % update gui status
        mrs_setguistatus(gui,0)
        
        if isempty(b)
            mrsSigPro_plotdata(gui,fdata,proclog);
        end
    end


%% PUSHBUTTON RUN (FLOW) --------------------------------------------------
% --- Executes on press on pushbutton RUN.
%     Executes the signal processing flow.
	function onPushbuttonRunFlow(a,b)
     
        whatisALL = bin2dec([...
                   num2str(get(gui.panel_controls.togglebutton_sig,'Value')), ...
                   num2str(get(gui.panel_controls.togglebutton_q,'Value')), ...
                   num2str(get(gui.panel_controls.togglebutton_rec,'Value')), ...
                   num2str(get(gui.panel_controls.togglebutton_rx,'Value'))]);
        whatisTODO = bin2dec([...
                    num2str(get(gui.panel_controls.NCOn, 'Value')),...
                    num2str(get(gui.panel_controls.radio_DelHarmonicOn_2,'Value')),...
                    num2str(get(gui.panel_controls.radio_DelHarmonicOn,'Value')),...
                    num2str(get(gui.panel_controls.radio_despikeAuto,'Value'))]);
                
        % before RNC, HNC and despiking is do be done first for all
        % rx,rec,q
        switch whatisTODO
            case bin2dec('0001') % only despike
                runSubFlow(whatisALL)
            case bin2dec('0010') % only HNC
                runSubFlow(whatisALL)
            case bin2dec('0110') % only HNC + HNC
                set(gui.panel_controls.radio_DelHarmonicOn_2,'Value',0)
                runSubFlow(whatisALL)
                set(gui.panel_controls.radio_DelHarmonicOn,'Value',0)
                set(gui.panel_controls.radio_DelHarmonicOn_2,'Value',1)
                runSubFlow(whatisALL)
                set(gui.panel_controls.radio_DelHarmonicOn,'Value',1)
            case bin2dec('1000') % only RNC
                runSubFlow(whatisALL)
            case bin2dec('0011') % despike + HNC
                runSubFlow(whatisALL)
            case bin2dec('0111') % despike + HNC + HNC
                set(gui.panel_controls.radio_DelHarmonicOn_2,'Value',0)
                runSubFlow(whatisALL)
                set(gui.panel_controls.radio_despikeAuto,'Value',0)
                set(gui.panel_controls.radio_DelHarmonicOn,'Value',0)
                set(gui.panel_controls.radio_DelHarmonicOn_2,'Value',1)
                runSubFlow(whatisALL)
                set(gui.panel_controls.radio_despikeAuto,'Value',1)
                set(gui.panel_controls.radio_DelHarmonicOn,'Value',1)
            case bin2dec('1001') % despike + RNC
                set(gui.panel_controls.NCOn, 'Value',0)
                runSubFlow(whatisALL)
                set(gui.panel_controls.radio_despikeAuto,'Value',0)
                set(gui.panel_controls.NCOn, 'Value',1)
                runSubFlow(whatisALL)
                set(gui.panel_controls.radio_despikeAuto,'Value',1)
            case bin2dec('1100') % HNC + RNC
                set(gui.panel_controls.NCOn, 'Value',0)
                runSubFlow(whatisALL)
                set(gui.panel_controls.radio_DelHarmonicOn,'Value',0)
                set(gui.panel_controls.NCOn, 'Value',1)
                runSubFlow(whatisALL)
                set(gui.panel_controls.radio_DelHarmonicOn,'Value',1) 
            case bin2dec('1110') % HNC + HNC + RNC
                set(gui.panel_controls.NCOn, 'Value',0)
                set(gui.panel_controls.radio_DelHarmonicOn_2,'Value',0)
                runSubFlow(whatisALL)
                set(gui.panel_controls.radio_DelHarmonicOn,'Value',0)
                set(gui.panel_controls.radio_DelHarmonicOn_2,'Value',1)
                runSubFlow(whatisALL)
                set(gui.panel_controls.radio_DelHarmonicOn_2,'Value',0)
                set(gui.panel_controls.NCOn, 'Value',1)
                runSubFlow(whatisALL)
                set(gui.panel_controls.radio_DelHarmonicOn,'Value',1) 
                set(gui.panel_controls.radio_DelHarmonicOn_2,'Value',1)
            case bin2dec('1101') % despike + HNC + RNC
                set(gui.panel_controls.NCOn, 'Value',0)
                runSubFlow(whatisALL)
                set(gui.panel_controls.radio_despikeAuto,'Value',0)
                set(gui.panel_controls.radio_DelHarmonicOn,'Value',0)
                set(gui.panel_controls.NCOn, 'Value',1)
                runSubFlow(whatisALL)
                set(gui.panel_controls.radio_despikeAuto,'Value',1)
                set(gui.panel_controls.radio_DelHarmonicOn,'Value',1)
            case bin2dec('1111') % despike + HNC + HNC + RNC
                set(gui.panel_controls.NCOn, 'Value',0)
                set(gui.panel_controls.radio_DelHarmonicOn_2,'Value',0)
                runSubFlow(whatisALL)
                set(gui.panel_controls.radio_despikeAuto,'Value',0)
                set(gui.panel_controls.radio_DelHarmonicOn,'Value',0)
                set(gui.panel_controls.radio_DelHarmonicOn_2,'Value',1)
                set(gui.panel_controls.NCOn, 'Value',0)
                runSubFlow(whatisALL)
                set(gui.panel_controls.radio_despikeAuto,'Value',0)
                set(gui.panel_controls.radio_DelHarmonicOn,'Value',0)
                set(gui.panel_controls.radio_DelHarmonicOn_2,'Value',0)
                set(gui.panel_controls.NCOn, 'Value',1)
                runSubFlow(whatisALL)
                set(gui.panel_controls.radio_despikeAuto,'Value',1)
                set(gui.panel_controls.radio_DelHarmonicOn,'Value',1)
                set(gui.panel_controls.radio_DelHarmonicOn_2,'Value',1)
            otherwise
                msgbox('Flow not implemented. Change settings')
        end
        
        iQ   = get(gui.panel_controls.popupmenu_Q, 'Value');
        irec = get(gui.panel_controls.popupmenu_REC, 'Value');
        irx  = get(gui.panel_controls.popupmenu_RX, 'Value');
        isig = get(gui.panel_controls.popupmenu_SIG, 'Value');
         % update keep
        set(gui.panel_controls.checkbox_keep,'Value', mrs_getkeep(proclog,iQ,irec,irx,isig));
        
        mrsSigPro_plotdata(gui,fdata,proclog);
    end
    
    %% subsubfunction for running the flow
    function runSubFlow(whatisALL)
        iQ   = get(gui.panel_controls.popupmenu_Q, 'Value');
        irec = get(gui.panel_controls.popupmenu_REC, 'Value');
        irx  = get(gui.panel_controls.popupmenu_RX, 'Value');
        isig = get(gui.panel_controls.popupmenu_SIG, 'Value');
        
        switch whatisALL
            case bin2dec('0000')  % only currently displayed fid
                onPushbuttonRunOnCurrent(0,0)
            case bin2dec('0001')  % all rx
                for iirx = 1:length(fdata.Q(iQ).rec(irec).rx) % rx
                    if check_stop
                        mrsSigPro_plotdata(gui,fdata,proclog);
                        return
                    else
                        set(gui.panel_controls.popupmenu_RX, 'Value',iirx);
                        if iirx == 1
                            onPushbuttonRunOnCurrent(0,0)
                        else
                            if get(gui.panel_controls.radio_DelHarmonicOn,'Value')
                                hSource = get(gui.panel_controls.edit_DelHarmonic_frequency, 'Value');
                            else
                                hSource = get(gui.panel_controls.edit_DelHarmonic_frequency_2, 'Value');
                            end
                            id = find(...
                                proclog.event(:,1) == 2 & ... % HNC
                                proclog.event(:,2) == iQ & ...
                                proclog.event(:,3) == irec & ...
                                proclog.event(:,4) == 1 & ...
                                proclog.event(:,5) == isig & ...
                                proclog.event(:,6) == hSource); % find ids for this record
                            if  ~isempty(id)
                                onPushbuttonRunOnCurrent(proclog.event(id(end),7),0)
                            else
                                onPushbuttonRunOnCurrent(0,0)
                            end
                        end
                        
                    end
                end
            case bin2dec('0010')  % all rec
                for iirec = 1:length(fdata.Q(iQ).rec) % rec
                    check_stop;
                    if check_stop
                        mrsSigPro_plotdata(gui,fdata,proclog);
                        return
                    else
                        set(gui.panel_controls.popupmenu_REC, 'Value',iirec);
                        onPushbuttonRunOnCurrent(0,0)
                    end
                end
            case bin2dec('0011')  % all rx & rec
                for iirec = 1:length(fdata.Q(iQ).rec) % rec
                    for iirx = 1:length(fdata.Q(iQ).rec(iirec).rx) % rx
                        check_stop;
                        if check_stop 
                            mrsSigPro_plotdata(gui,fdata,proclog);
                            return
                        else
                            set(gui.panel_controls.popupmenu_RX, 'Value',iirx);
                            set(gui.panel_controls.popupmenu_REC, 'Value',iirec);
                            if iirx == 1
                                onPushbuttonRunOnCurrent(0,0)
                            else
                                if get(gui.panel_controls.radio_DelHarmonicOn,'Value')
                                    hSource = get(gui.panel_controls.edit_DelHarmonic_frequency, 'Value');
                                else
                                    hSource = get(gui.panel_controls.edit_DelHarmonic_frequency_2, 'Value');
                                end
                                id = find(...
                                    proclog.event(:,1) == 2 & ... % HNC
                                    proclog.event(:,2) == iQ & ...
                                    proclog.event(:,3) == iirec & ...
                                    proclog.event(:,4) == 1 & ...
                                    proclog.event(:,5) == isig & ...
                                    proclog.event(:,6) == hSource); % find ids for this record
                                if  ~isempty(id)
                                    onPushbuttonRunOnCurrent(proclog.event(id(end),7),0)
                                else
                                    onPushbuttonRunOnCurrent(0,0)
                                end
                            end
                        end
                    end
                end
            case bin2dec('0110')  % rec & q
                for iiQ = 1:length(fdata.Q)
                    for iirec = 1:length(fdata.Q(iiQ).rec)
                        if check_stop
                            mrsSigPro_plotdata(gui,fdata,proclog);
                            return
                        else
                            set(gui.panel_controls.popupmenu_Q, 'Value',iiQ);
                            set(gui.panel_controls.popupmenu_REC, 'Value',iirec);
                            onPushbuttonRunOnCurrent(0,0)
                        end
                    end
                end
            case bin2dec('0111')  % all rx & rec & q
                iii=1;
                 for iiQ = 1:length(fdata.Q)
                     for iirec = 1:length(fdata.Q(iiQ).rec)
                         for iirx = 1:length(fdata.Q(iiQ).rec(iirec).rx) 
                            if check_stop 
                                mrsSigPro_plotdata(gui,fdata,proclog);
                                return
                            else
                                set(gui.panel_controls.popupmenu_RX, 'Value',iirx);
                                set(gui.panel_controls.popupmenu_Q, 'Value',iiQ);
                                set(gui.panel_controls.popupmenu_REC, 'Value',iirec);
                                if iirx == 1
                                    onPushbuttonRunOnCurrent(0,0)
                                else
                                    if get(gui.panel_controls.radio_DelHarmonicOn,'Value')
                                        hSource = get(gui.panel_controls.edit_DelHarmonic_frequency, 'Value');
                                    else
                                        hSource = get(gui.panel_controls.edit_DelHarmonic_frequency_2, 'Value');
                                    end
                                    id = find(...
                                        proclog.event(:,1) == 2 & ... % HNC
                                        proclog.event(:,2) == iiQ & ...
                                        proclog.event(:,3) == iirec & ...
                                        proclog.event(:,4) == 1 & ...
                                        proclog.event(:,5) == isig & ...
                                        proclog.event(:,6) == hSource); % find ids for this record
                                    if  ~isempty(id)
                                        onPushbuttonRunOnCurrent(proclog.event(id(end),7),0)
                                    else
                                        onPushbuttonRunOnCurrent(0,0)
                                    end
                                end
                            end
                        end
                    end
                end
            case bin2dec('1111')  % everything
                for iisig = 1:length(fdata.Q(1).rec(1).rx(1).sig)
                    if fdata.Q(1).rec(1).rx(1).sig(iisig).recorded == 1
                        for iiQ = 1:length(fdata.Q)  
                            for iirec = 1:length(fdata.Q(iiQ).rec)
                                for iirx = 1:length(fdata.Q(iiQ).rec(iirec).rx)
                                    if check_stop 
                                        mrsSigPro_plotdata(gui,fdata,proclog);
                                        return
                                    else
                                        set(gui.panel_controls.popupmenu_RX, 'Value',iirx);
                                        set(gui.panel_controls.popupmenu_SIG, 'Value',iisig);
                                        set(gui.panel_controls.popupmenu_Q, 'Value',iiQ);
                                        set(gui.panel_controls.popupmenu_REC, 'Value',iirec);
                                        onPushbuttonRunOnCurrent(0,0)
                                    end
                                end
                            end
                        end
                    end
                end
            otherwise
                msgbox('defined flow not implemented')
        
        end
        
        set(gui.panel_controls.popupmenu_Q, 'Value',iQ);
        set(gui.panel_controls.popupmenu_REC, 'Value',irec);
        set(gui.panel_controls.popupmenu_RX, 'Value',irx);
        set(gui.panel_controls.popupmenu_SIG, 'Value',isig);
    end

%% PUSHBUTTON RESET ALL ---------------------------------------------------
% --- Executes on press on pushbutton RESET.
%     Resets the selected time series to original.
    function onPushbuttonResetFlow(a,b)
        iQ   = get(gui.panel_controls.popupmenu_Q, 'Value');
        irec = get(gui.panel_controls.popupmenu_REC, 'Value');
        irx  = get(gui.panel_controls.popupmenu_RX, 'Value');
        isig = get(gui.panel_controls.popupmenu_SIG, 'Value');
        
        whatisALL = bin2dec([...
            num2str(get(gui.panel_controls.togglebutton_sig,'Value')), ...
            num2str(get(gui.panel_controls.togglebutton_q,'Value')), ...
            num2str(get(gui.panel_controls.togglebutton_rec,'Value')), ...
            num2str(get(gui.panel_controls.togglebutton_rx,'Value'))]);
        switch whatisALL
            case bin2dec('0000')  % only currently displayed fid
                reset_fid;
            case bin2dec('0001')  % all rx
                for iirx = 1:length(fdata.Q(iQ).rec(irec).rx) %rx
                    if check_stop
                        mrsSigPro_plotdata(gui,fdata,proclog);
                        return
                    else
                        set(gui.panel_controls.popupmenu_RX, 'Value',iirx);
                        reset_fid;
                    end
                end
            case bin2dec('0010')  % all rec
                for iirec = 1:length(fdata.Q(iQ).rec) % rec
                    check_stop;
                    if check_stop
                        mrsSigPro_plotdata(gui,fdata,proclog);
                        return
                    else
                        set(gui.panel_controls.popupmenu_REC, 'Value',iirec);
                        reset_fid;
                    end
                end
            case bin2dec('0011')  % all rx & rec
                for iirec = 1:length(fdata.Q(iQ).rec) % rec
                    for iirx = 1:length(fdata.Q(iQ).rec(iirec).rx) %rx
                        check_stop;
                        if check_stop 
                            mrsSigPro_plotdata(gui,fdata,proclog);
                            return
                        else
                            set(gui.panel_controls.popupmenu_RX, 'Value',iirx);
                            set(gui.panel_controls.popupmenu_REC, 'Value',iirec);
                            reset_fid;
                        end
                    end
                end
            case bin2dec('0110')  % all rec & q
                 for iiQ = 1:length(fdata.Q)
                     for iirec = 1:length(fdata.Q(iiQ).rec)
                         if check_stop
                             mrsSigPro_plotdata(gui,fdata,proclog);
                             return
                         else
                             set(gui.panel_controls.popupmenu_Q, 'Value',iiQ);
                             set(gui.panel_controls.popupmenu_REC, 'Value',iirec);
                             reset_fid;
                         end
                    end
                end
            case bin2dec('0111')  % all rx & rec & q
                 for iiQ = 1:length(fdata.Q)
                     for iirec = 1:length(fdata.Q(iiQ).rec)
                         for iirx = 1:length(fdata.Q(iiQ).rec(iirec).rx) 
                            if check_stop 
                                mrsSigPro_plotdata(gui,fdata,proclog);
                                return
                            else
                                set(gui.panel_controls.popupmenu_RX, 'Value',iirx);
                                set(gui.panel_controls.popupmenu_Q, 'Value',iiQ);
                                set(gui.panel_controls.popupmenu_REC, 'Value',iirec);
                                reset_fid;
                            end
                        end
                    end
                end
            case bin2dec('1111')  % everything
                for iisig = 1:length(fdata.Q(1).rec(1).rx(1).sig)
                    if fdata.Q(1).rec(1).rx(1).sig(iisig).recorded == 1
                        for iiQ = 1:length(fdata.Q)  
                            for iirec = 1:length(fdata.Q(iiQ).rec)
                                for iirx = 1:length(fdata.Q(iiQ).rec(iirec).rx)
                                    if check_stop 
                                        mrsSigPro_plotdata(gui,fdata,proclog);
                                        return
                                    else
                                        set(gui.panel_controls.popupmenu_RX, 'Value',iirx);
                                        set(gui.panel_controls.popupmenu_SIG, 'Value',iisig);
                                        set(gui.panel_controls.popupmenu_Q, 'Value',iiQ);
                                        set(gui.panel_controls.popupmenu_REC, 'Value',iirec);
                                        reset_fid;
                                    end
                                end
                            end
                        end
                    end
                end
            otherwise
                msgbox('defined flow not implemented')
        end
        
%         switch whatisALL
%             case bin2dec('0000')  % current display
% %                 onPushbuttonUndo(gui.panel_controls.pushbutton_despikeUndo,0)
%                 if check_stop 
%                     mrsSigPro_plotdata(gui,fdata,proclog);
%                     return
%                 else
%                     reset_fid;
%                 end
%             case bin2dec('0001')  % all rec
%                 for iirec = 1:length(fdata.Q(iQ).rec) % auto despike
%                     if check_stop 
%                         mrsSigPro_plotdata(gui,fdata,proclog);
%                         return
%                     else
%                         set(gui.panel_controls.popupmenu_REC, 'Value',iirec);
%                         reset_fid;
%                     end
%                 end
%             case bin2dec('0011')  % all rec & Q
%                 for iiQ = 1:length(fdata.Q)
%                     set(gui.panel_controls.popupmenu_Q, 'Value',iiQ);
%                     for iirec = 1:length(fdata.Q(iiQ).rec)
%                         if check_stop 
%                             mrsSigPro_plotdata(gui,fdata,proclog);
%                             return
%                         else
%                             set(gui.panel_controls.popupmenu_REC, 'Value',iirec);
%                             reset_fid;
%                         end                        
%                     end
%                 end
%             case bin2dec('0111')  % all rec & Q & rx
%                 for iirx = 1:length(fdata.Q(1).rec(1).rx)
%                     set(gui.panel_controls.popupmenu_RX, 'Value',iirx);
%                     for iiQ = 1:length(fdata.Q)
%                         set(gui.panel_controls.popupmenu_Q, 'Value',iiQ);
%                         for iirec = 1:length(fdata.Q(iiQ).rec)
%                             if check_stop 
%                                 mrsSigPro_plotdata(gui,fdata,proclog);
%                                 return
%                             else
%                                 set(gui.panel_controls.popupmenu_REC, 'Value',iirec);
%                                 reset_fid;
%                             end                            
%                         end
%                     end
%                 end
%             case bin2dec('1111')  % everything
%                 for iirx = 1:length(fdata.Q(1).rec(1).rx)
%                     set(gui.panel_controls.popupmenu_RX, 'Value',iirx);
%                     for iisig = 1:length(fdata.Q(1).rec(1).rx(iirx).sig)
%                         if fdata.Q(1).rec(1).rx(iirx).sig(iisig).recorded == 1
%                             set(gui.panel_controls.popupmenu_SIG, 'Value',iisig);
%                             for iiQ = 1:length(fdata.Q)
%                                 set(gui.panel_controls.popupmenu_Q, 'Value',iiQ);
%                                 for iirec = 1:length(fdata.Q(iiQ).rec)
%                                     if check_stop 
%                                         mrsSigPro_plotdata(gui,fdata,proclog);
%                                         return
%                                     else
%                                         set(gui.panel_controls.popupmenu_REC, 'Value',iirec);
%                                         reset_fid;
%                                     end  
%                                 end
%                             end
%                         end
%                     end
%                 end 
%                 
%         end
        
        % update keep
        set(gui.panel_controls.checkbox_keep,'Value', mrs_getkeep(proclog,iQ,irec,irx,isig));        
        
        % go back to fid before flow execution & plot
        set(gui.panel_controls.popupmenu_Q,   'Value',iQ);
        set(gui.panel_controls.popupmenu_REC, 'Value',irec);
        set(gui.panel_controls.popupmenu_RX,  'Value',irx);
        set(gui.panel_controls.popupmenu_SIG, 'Value',isig);
        mrsSigPro_plotdata(gui,fdata,proclog);
    end


%% RADIOBUTTON NC (NOISE CANCELLATION) ------------------------------------
% Activate/deactivate NC when executing processing flow.
    function NCOn(a,b)
        
        % Return if no reference channels are available
        if ~any([fdata.info.rxinfo(:).task]==2)
            mrs_setguistatus(gui,1,'No reference channel available')
            pause(1)
            set(gui.panel_controls.NCOn, 'Value', 0)
            mrs_setguistatus(gui,0)
            return
        end
        
        set(gui.panel_controls.NCOn, 'Value', 1)
        set(gui.panel_controls.NCOff, 'Value', 0)
        set(gui.panel_controls.edit_NCRefChannel, 'Enable', 'on')
        set(gui.panel_controls.edit_NCDetectChannel, 'Enable', 'on')
        set(gui.panel_controls.NCGlobalOn, 'Enable', 'on')
        set(gui.panel_controls.NCLocalOn, 'Enable', 'on')
        switch get(gui.panel_controls.NCGlobalOn, 'Value')
            case 1
                %'Global';
                set(gui.panel_controls.NCTransferCalc, 'Enable', 'on')
            case 0
                %'Local';
                set(gui.panel_controls.NCTransferCalc, 'Enable', 'off')
        end
        
    end

    function NCOff(a,b)
        set(gui.panel_controls.NCOn, 'Value', 0)
        set(gui.panel_controls.NCOff, 'Value', 1)
        set(gui.panel_controls.edit_NCRefChannel, 'Enable', 'off')
        set(gui.panel_controls.edit_NCDetectChannel, 'Enable', 'off')
        set(gui.panel_controls.NCGlobalOn, 'Enable', 'off')
        set(gui.panel_controls.NCLocalOn, 'Enable', 'off')
        set(gui.panel_controls.NCTransferCalc, 'Enable', 'off')
    end

    function NCGlobalOn(a,b)
        set(gui.panel_controls.NCGlobalOn, 'Value', 1)
        set(gui.panel_controls.NCLocalOn, 'Value', 0)
        set(gui.panel_controls.NCTransferCalc, 'Enable', 'on')
    end

    function NCLocalOn(a,b)
        set(gui.panel_controls.NCGlobalOn, 'Value', 0)
        set(gui.panel_controls.NCLocalOn, 'Value', 1)
        set(gui.panel_controls.NCTransferCalc, 'Enable', 'off')
    end

    function onPushbuttonNCTransferCalc(a,b)
    % precalculation of transferfct. saved in fdata
        mrs_setguistatus(gui,1,'Calc. transfer functions')
        
        % reset proclog: delete old transfer fct.
        proclog.event(proclog.event(:,1)==6,:)=[];       
        
        % get current fid
        iQ         = get(gui.panel_controls.popupmenu_Q, 'Value');
        irec       = get(gui.panel_controls.popupmenu_REC, 'Value');
        irx        = get(gui.panel_controls.popupmenu_RX, 'Value');
        isig       = get(gui.panel_controls.popupmenu_SIG, 'Value');        
        
        % get fid & reference from fdata (updated on change in edit fld)
        fid = ([fdata.info.rxinfo(:).task] == 1);   % signal receiver (index vector: fid = [1 0 1 0])
        ref = ([fdata.info.rxinfo(:).task] == 2);   % reference receiver 
        rx  = 1:length(fdata.info.rxinfo);          % receiver index        
        
        % calculate transferfct.
        [fdata,proclog] = mrsSigPro_NCGetTransfer(fdata,proclog,rx(ref==1),rx(fid==1));
        
%         [ref,dect,rxnumber] = channels2indices;
%         switch get(gui.panel_controls.NCGlobalOn, 'Value')
%             case 1
%                 C=1; %'Global';
%             case 0
%                 C=2; %'Local';
%         end
        
%         % calculate transferfct.
%         [fdata] = mrsSigPro_NCGetTransfer(fdata,proclog,rx(ref==1),rx(fid==1));
        
%         % UPDATE PROCLOG
%         % determine detection receivers
%         AD  = length(fdata.info.rxinfo);  % # channels (required for decoding dec2bin(B,A))
%         BD  = bin2dec(num2str(dect));      % detection channels
%         % determine reference receivers
%         AR  = length(fdata.info.rxinfo);  % # channels (required for decoding dec2bin(B,A))
%         BR  = bin2dec(num2str(ref));      % reference channels
%         % type of transfer Calculation
%         C = C;  % 1 Global, 2 Local
%         % log entry
%         proclog.event(end+1,:) = [5 0 0 AD BD AR BR C];

        % update proclog
        A = length(fdata.info.rxinfo);    % # channels (required for decoding dec2bin(B,A))
        B = bin2dec(num2str(ref));        % reference channels encoded as bin2dec([0 1 0 0 1 0 0 0])
        C = bin2dec(num2str(fid));        % signal channels encoded as bin2dec([1 0 1 0 0 0 0 0])

        % create log entry
        proclog.event(end+1,:) = [6 iQ irec irx isig A B C];

        mrs_setguistatus(gui,0)
    end

%     function [ref,dect,rxnumber] = channels2indices
%         % translate channel numbers to internal indices for User input NC
%         % usage to get indices: rxnumber(ref)
%         ch              = [fdata.info.rxinfo(:).channel];
%         refChannel      = str2num(get(gui.panel_controls.edit_NCRefChannel,'String'));
%         detectChannel   = str2num(get(gui.panel_controls.edit_NCDetectChannel,'String'));
%         
%         ref  = zeros(size(fdata.info.rxtask)); 
%         dect = zeros(size(fdata.info.rxtask));
%         rxnumber = [1:1:length(fdata.info.rxtask)];
%         for iNC=1:length(refChannel)
%              ref = ref + [ch==refChannel(iNC)];
%         end
%         for iSig=1:length(detectChannel)
%              dect = dect + [ch==detectChannel(iSig)];
%         end
%     end

%% Flow defintion
    function onPushbuttonRunOnCurrent(a,b)
    % processing flow of whatever is enabled and set in GUI
    % 1. NC: NC uses v1
    % 2. Despike: uses v1 
    % 3. Delete Single Harmonic uses v1
    % 3. QD + filter: Since QD needs filter (in fact via hilbert not
    %           necessarily but mostly) the selected filter is applied there
    
%         % if executed by "run flow" set b to empty
%         if nargin < 2
%             b = [];
%         end
        
        % get current fid
        iQ         = get(gui.panel_controls.popupmenu_Q, 'Value');
        irec       = get(gui.panel_controls.popupmenu_REC, 'Value');
        irx        = get(gui.panel_controls.popupmenu_RX, 'Value');
        isig       = get(gui.panel_controls.popupmenu_SIG, 'Value');        
        
        % get fid & reference from fdata (updated on change in edit fld)
        fid = ([fdata.info.rxinfo(:).task] == 1);   % signal receiver (index vector: fid = [1 0 1 0])
        ref = ([fdata.info.rxinfo(:).task] == 2);   % reference receiver 
        rx  = 1:length(fid);                        % receiver index
    
        % despike
        mrs_setguistatus(gui,1,'working on despike')
        if get(gui.panel_controls.radio_despikeAuto,'Value') == 1
            threshold = str2double(get(gui.panel_controls.edit_despikeThreshold, 'String'));
            width     = str2double(get(gui.panel_controls.edit_despikeMutewidth,'String'))/1000;
            type      = get(gui.panel_controls.radio_despikeAutoType, 'Value');
            if get(gui.panel_controls.radio_despikeAuto, 'Value') % auto
                % keep old events and do automatic detection
%                 proclog.event(proclog.event(:,1) == 3 & proclog.event(:,2) == iQ & proclog.event(:,3) == irec & proclog.event(:,4) == irx & proclog.event(:,5) == isig, :) = [];
%                 [fdata,proclog] = mrsSigPro_replaceSpike(fdata,proclog,iQ,irec,irx,isig,'auto',threshold,width);
                [fdata,proclog] = mrsSigPro_replaceSpike(fdata,proclog,iQ,irec,irx,isig,threshold,'auto',width,type);
            else % manual 
                % JW: do nothing. This is already stored in proclog.
            end
        end
        
        % delete single harmonic
        mrs_setguistatus(gui,1,'working on HNC')
        if get(gui.panel_controls.radio_DelHarmonicOn,'Value') == 1
            hSource = get(gui.panel_controls.edit_DelHarmonic_frequency, 'Value');
            removeCof = get(gui.panel_controls.check_removeCof, 'Value');
            fastHNC   = get(gui.panel_controls.check_fastHNC, 'Value');
            [fdata, proclog] = mrsSigPro_DelHarmonic(fdata,proclog,hSource,removeCof,fastHNC, iQ,irec,irx,isig,a); 
            %removeCof=0;
            %fdata = mrsSigPro_DelHarmonic_Qi(fdata,proclog,hSource,removeCof,iQ,irec,irx,isig);
        end
        if get(gui.panel_controls.radio_DelHarmonicOn_2,'Value') == 1
            hSource = get(gui.panel_controls.edit_DelHarmonic_frequency_2, 'Value');
            removeCof = get(gui.panel_controls.check_removeCof, 'Value');
            fastHNC   = get(gui.panel_controls.check_fastHNC, 'Value');
            [fdata, proclog] = mrsSigPro_DelHarmonic(fdata,proclog,hSource,removeCof,fastHNC, iQ,irec,irx,isig,a);
        end
        
        % noise cancellation
        mrs_setguistatus(gui,1,'working on RNC')
        if fid(irx) == 0 
            % skip NC if current irx is not a signal receiver
        else
            if get(gui.panel_controls.NCOn, 'Value') == 1
                switch get(gui.panel_controls.NCGlobalOn, 'Value')
                    case 1 % Global

                        % check for correct transferfct.
                        id = find(proclog.event(:,1) == 6);
                        if length(id) > 1
                            error('proclog file corrupted. There can be only 1 type-6 event')
                        elseif length(id) < 1
                            msgbox('no proper transfer function found --> run calculation first')
                            return
                        end
                        
                        % Check if the same reference & signal receivers
                        % are selected as for the calculated TF
                        if proclog.event(id,7) == bin2dec(num2str(ref)) && proclog.event(id,8) == bin2dec(num2str(fid))
                            fdata    = mrsSigPro_NCDo(fdata,proclog,iQ,irec,irx,isig,1,rx(ref==1));
                        else
                            msgbox('no proper transfer function found --> run calculation first')
                            return
                        end
                        
%                         lastNCGetTransfer = find([proclog.event(:,1)==5]==1,1,'last');
%                         lastNCGetTransferLog = proclog.event(lastNCGetTransfer,:);
%                         if lastNCGetTransferLog(8) == C & lastNCGetTransferLog(7) == bin2dec(num2str(ref))
% %                             fdata    = mrsSigPro_NCDo(fdata,iQ,irec,irx,isig,C,rx(ref==1),rx(fid==1));
%                             fdata    = mrsSigPro_NCDo(fdata,iQ,irec,irx,isig,C,rx(ref==1));
%                         else
%                             msgbox('no proper transfer function found --> run calculation first')
%                         end

                        % update proclog
                        A = length(fdata.info.rxinfo);    % # channels (required for decoding dec2bin(B,A))
                        B = bin2dec(num2str(ref));        % reference channels encoded as bin2dec([0 1 0 0 1 0 0 0])
                        C = bin2dec(num2str(fid));        % signal channels encoded as bin2dec([1 0 1 0 0 0 0 0])

                        % create log entry
                        proclog.event(end+1,:) = [5 iQ irec irx isig A B C];
                        
                    case 0  % Local noise cancellation
                        
                        fdata    = mrsSigPro_NCDo(fdata,proclog,iQ,irec,irx,isig,2,rx(ref==1));
                        
                        % update proclog
                        A = length(fdata.info.rxinfo);    % # channels (required for decoding dec2bin(B,A))
                        B = bin2dec(num2str(ref));        % reference channels encoded as bin2dec([0 1 0 0 1 0 0 0])
                        C = 0;                            % n/a meaningless here

                        % create log entry
                        proclog.event(end+1,:) = [4 iQ irec irx isig A B C];
                        
                end
            end
        end
        
       
        mrs_setguistatus(gui,0)
        % filter here
            
        % plot + QD + filter (JW: QD+filter only for plotting; not stored)
        if isempty(b)
            mrsSigPro_plotdata(gui,fdata,proclog);
        end
        
    end


%% TOGGLEBUTTONS FLOW -----------------------------------------------------
% --- Executes on press on togglebuttons in FLOW section.
%     Toggles between current and all time series. Button priority is rec,
%     q, rx, sig (lowest to highest). That means, if sig is toggled to ALL,
%     then all other buttons are also toggled to ALL (and can't be changed
%     unless sig is toggled off again).
    function onTogglebutton(a,b)
        
         % button id
         X(1) = get(gui.panel_controls.popupmenu_RX,  'Value'); % button 3
         X(2) = get(gui.panel_controls.popupmenu_REC, 'Value'); % button 1
         X(3) = get(gui.panel_controls.popupmenu_Q,   'Value'); % button 2
         X(4) = get(gui.panel_controls.popupmenu_SIG, 'Value'); % button 4
         
         % button parameters
         bval  = [1 2 4 8];
         bname = {'rx', 'rec', 'q', 'sig'}; 
         
         if get(gui.panel_controls.togglebutton_rec,'Value')
            set(gui.panel_controls.togglebutton_rec,'String','rec(:)')
         else
            set(gui.panel_controls.togglebutton_rec,'String',[bname{2},'(',num2str(X(2)),')']) 
         end
         if get(gui.panel_controls.togglebutton_q,'Value')
            set(gui.panel_controls.togglebutton_q,'String','q(:)')
         else
            set(gui.panel_controls.togglebutton_q,'String',[bname{3},'(',num2str(X(3)),')']) 
         end
         if get(gui.panel_controls.togglebutton_rx,'Value')
            set(gui.panel_controls.togglebutton_rx,'String','rx(:)')
         else
            set(gui.panel_controls.togglebutton_rx,'String',[bname{1},'(',num2str(X(1)),')']) 
         end
         if get(gui.panel_controls.togglebutton_sig,'Value')
            set(gui.panel_controls.togglebutton_sig,'String','sig(:)')
         else
            set(gui.panel_controls.togglebutton_sig,'String',[bname{4},'(',num2str(X(4)),')']) 
         end
%         
%         % determine which buttons are on
%         status = bin2dec([...
%                    num2str(get(gui.panel_controls.togglebutton_sig,'Value')), ...
%                    num2str(get(gui.panel_controls.togglebutton_q,'Value')), ...
%                    num2str(get(gui.panel_controls.togglebutton_rec,'Value')), ...
%                    num2str(get(gui.panel_controls.togglebutton_rx,'Value'))]);
%         
%         % enable current and all lower-order buttons
%         for ib = 1:4
%             tag = ['togglebutton_',bname{ib}];
%             if status >= bval(ib)
%                 set(gui.panel_controls.(tag), ...
%                      'Value',1, ...
%                      'String',[bname{ib},'(:)']);
%             else
%                 set(gui.panel_controls.(tag),...
%                      'Value',0, ...
%                      'String',[bname{ib},'(',num2str(X(ib)),')']);
%             end
%         end
    end

%% TOGGLEBUTTON STOP FLOW -------------------------------------------------
    function onTogglebuttonStopFlow(a,b)
        % nothing to do. Interrupt handled in Pushbuttons: execute flow
        % (Run & Reset)
    end


%% FUNCTION INITIALIZE PROCLOG --------------------------------------------
% initialize proclog structure
    function proclog = initialize_proclog(fdata)
        inifile              = mrs_readinifile;        
        proclog.MRSversion   = inifile.MRSmatlab.version;
        proclog.path         = fdata.info.path;
        proclog.device       = fdata.info.device;
        proclog.rxinfo       = fdata.info.rxinfo;
        proclog.txinfo       = fdata.info.txinfo;
        proclog.status       = 0;
        proclog.event(1,1:8) = 0;
        
        % build filter
%         proclog.LPfilter = load('coefficient.mat');
        if strcmp(proclog.device, 'NUMISplus')
            proclog.LPfilter.coeff = -1;
        else
            proclog.LPfilter = ...
                mrs_makefilter(inifile.MRSData.filter_passFreq, ...
                               inifile.MRSData.filter_stopFreq, ...
                               inifile.MRSData.filter_sampleFreq); 
        end
        proclog.LPfilter.fW = 500;  % default
        
        for iQ = 1:length(fdata.Q)
            proclog.Q(iQ).q   = fdata.Q(iQ).q ; % Pulse moment [A.s]
            if(isfield(fdata.Q, 'q2'))
                proclog.Q(iQ).q2    = fdata.Q(iQ).q2;
                proclog.Q(iQ).phi12 = ...   % Phase difference between 1st and 2nd pulse
                    (fdata.Q(iQ).rec(1).info.phases.phi_timing(3)-2*pi*fdata.Q(iQ).rec(1).info.fT*(fdata.Q(iQ).rec(1).info.timing.tau_p2 + fdata.Q(1).rec(1).info.timing.tau_dead2)) - ...
                    (fdata.Q(iQ).rec(1).info.phases.phi_timing(2)-2*pi*fdata.Q(iQ).rec(1).info.fT*(fdata.Q(iQ).rec(1).info.timing.tau_p1 + fdata.Q(1).rec(1).info.timing.tau_dead1));
                %                 proclog.Q(iQ).taud  = fdata.Q(iQ).rec(1).info.timing.tau_d - fdata.Q(iQ).rec(1).info.timing.tau_p1;
            end
            proclog.Q(iQ).timing = fdata.Q(iQ).rec(1).info.timing;
            proclog.Q(iQ).fT  = fdata.Q(iQ).rec(1).info.fT ; % transmitter frequency
            proclog.Q(iQ).fS  = fdata.Q(iQ).rec(1).info.fS ; % sampling frequency
        end
    end

%% FUNCTION STOP FLOW (TOGGLEBUTTON STOP) ---------------------------------
%   Restores the rawdata v0 and deletes all proclog events for this record

    function stop = check_stop
        switch get(gui.panel_controls.togglebutton_flowstop,'Value')
            case 0
                stop = 0; % proceed
            case 1
                stop = 1;
                mrs_setguistatus(gui,1,'Flow interrupted')
                pause(1)
                mrs_setguistatus(gui,0)
        end
    end

%% FUNCTION RESET FID (PUSHBUTTON RESET) ----------------------------------
%   Restores the rawdata v0 and deletes all proclog events for this record

    function reset_fid

        % determine current fid
        iQ   = get(gui.panel_controls.popupmenu_Q, 'Value');
        irec = get(gui.panel_controls.popupmenu_REC, 'Value');
        irx  = get(gui.panel_controls.popupmenu_RX, 'Value');
        isig = get(gui.panel_controls.popupmenu_SIG, 'Value');
               
        % restore fdata
        fdata.Q(iQ).rec(irec).rx(irx).sig(isig).v1 = ...
            fdata.Q(iQ).rec(irec).rx(irx).sig(isig).v0;

        % reset proclog: delete all events (id 1-5) for this rec
        % leave in proclog: 1st line (id 0), calc TF (id 6), trim (id 101)
        proclog.event(...
            proclog.event(:,1) > 0 & ...            % keep first line of 0
            proclog.event(:,1) < 6 & ...            % delete all events
            proclog.event(:,2) == iQ & ...
            proclog.event(:,3) == irec & ...
            proclog.event(:,4) == irx & ...
            proclog.event(:,5) == isig, :) = [];
        
    end

%% FUNCTION REMOVE SELECTION HIGHLIGHT ------------------------------------
% Removes the selection highlight after clicking a gui element. This
% enables the keyboard shortcuts after clicking elements.
function remove_selectionhighlight(active_element)
    
%     set(gui.panel_controls.edit_status, 'o')
    
    set(active_element, 'Enable', 'off');
    pause(0.1)
    set(active_element, 'Enable', 'on');
%     set(active_element, 'Visible', 'off');
%     set(active_element, 'Visible', 'on');    
    
%     set(gui.panel_controls.popupmenu_Q, 'Visible', 'on');
    
%         set(gui.panel_controls.popupmenu_Q, 'Visible', 'off');
%         set(gui.panel_controls.popupmenu_Q, 'Visible', 'on');
end



%% PLOT EDIT TOOLS --------------------------------------------------------
    function onPanOn(a,b)
        figure(gui.panel_data.figureid)
        plotedit('off') 
        zoom('off')
        pan('on') 
        datacursormode('off')
    end
    function onZoomIn(a,b)
        figure(gui.panel_data.figureid)
        plotedit('off') 
        zoom('on')
        pan('off')
        datacursormode('off')
    end
    function onEditOn(a,b)
        figure(gui.panel_data.figureid)
        plotedit('on') 
        zoom('off')
        pan('off')
        datacursormode('off')
    end
    function onDatacursorOn(a,b)
        figure(gui.panel_data.figureid)
        plotedit('off') 
        zoom('off')
        pan('off') 
        datacursormode('on')
    end
    function onAllOff(a,b)
        figure(gui.panel_data.figureid)
        plotedit('off') 
        zoom('off')
        pan('off')
        datacursormode('off')
    end
    function onAllData(a,b)
        tic
        mrsSigPro_stackForQuickDisplay(gui,fdata,proclog);
        toc
    end

%% KEYBOARD SHORTCUTS -----------------------------------------------------
    function dokeyboardshortcut(a,event)
        
        % del: despike
        if strcmp(event.Key, 'delete')
            onPushbuttonDespikeManu
        end
        
        % backspace: undo despike
        if strcmp(event.Key, 'backspace')
            onPushbuttonUndo
        end
        
        % insert: keep
        if strcmp(event.Key, 'insert')
            if get(gui.panel_controls.checkbox_keep, 'Value') == 1
                set(gui.panel_controls.checkbox_keep, 'Value', 0)
            else
                set(gui.panel_controls.checkbox_keep, 'Value', 1)
            end
            onCheckboxKeep
        end
        
        % downarrow: next recording
        if strcmp(event.Key, 'downarrow')
            r_max = size(get(gui.panel_controls.popupmenu_REC,'String'),1);
            set(gui.panel_controls.popupmenu_REC,'Value', min(r_max,get(gui.panel_controls.popupmenu_REC,'Value')+1));
            onSelectREC
        end
        
        % uparrow: previous recording
        if strcmp(event.Key, 'uparrow')
            set(gui.panel_controls.popupmenu_REC,'Value', max(1,get(gui.panel_controls.popupmenu_REC,'Value')-1));
            onSelectREC
        end
        
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
            iQ   = get(gui.panel_controls.popupmenu_Q,'Value');
            irec = get(gui.panel_controls.popupmenu_REC,'Value');
            irx  = get(gui.panel_controls.popupmenu_RX,'Value');
            set(gui.panel_controls.popupmenu_RX,'Value',mod(irx,length(fdata.Q(iQ).rec(irec).rx))+1) % advance by 1 wrap at max receiver
            onSelectRX
        end
        
        % *: double window length
        if strcmp(event.Key, 'multiply')
            width = str2double(get(gui.panel_controls.edit_mutewidth,'String'));
            set(gui.panel_controls.edit_mutewidth,'String',num2str(width*2))
        end
        
        % /: halve window length
        if strcmp(event.Key, 'divide')
            width = str2double(get(gui.panel_controls.edit_mutewidth,'String'));
            set(gui.panel_controls.edit_mutewidth,'String',num2str(width/2))
        end
        
    end
    
if standalone == 0
    uiwait(gui.panel_controls.figureid)
end
end

