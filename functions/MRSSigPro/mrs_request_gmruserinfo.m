function mrs_request_gmruserinfo(sounding_path, hfile)

% check if header file name is passed
if nargin < 2
    requesthfile = 1;
else
    requesthfile = 0;
end

% only for bugfixing - remove later
if nargin < 1   
    sounding_path = 'c:\Users\Jan\Documents\su\matlab\nmr\data\gmr_test_raw\';
end

% allow only one instance of the GUI
mfig = findobj('Name', 'Requesting GMR survey information');
if mfig
    delete(mfig)
end

% set requested parameters to default
uiparameter = { 'Header file',      'x','','','','','','','',       ' Name of header file';...
                'RX task',          1,  0,  0,  0,  0,  0,  0,  0,  ' 0=off, 1=RX, 2=REF';...     
                'TX task',          1,  0,  0,  0,  0,  0,  0,  0,  ' 0=off, 1=TX (only one allowed)';...     
                'loop type',        1,  0,  0,  0,  0,  0,  0,  0,  ' 0=off, 1=circular, 2=square, 3=circ-8, 4=sq-8';...
                'loop size',        50, 0,  0,  0,  0,  0,  0,  0,  ' [m] (diameter / edge length)';...
                'loop turns',       1,  0,  0,  0,  0,  0,  0,  0,  ' ';...
                'Sample frequency', 1,  '','','','','','','',       ' [Hz] (obtained from header file)';...
                'Prepulse delay',   50, '','','','','','','',       ' [ms] time before pulse';...
                'Dead time',        8,  '','','','','','','',       ' [ms] time between pulse shutdown and FID recording';...
                'Current gain',     -1, '','','','','','','',       ' (obtained from header file)';...
                'Voltage gain',     -1, '','','','','','','',       ' (obtained from header file)'};   


% COLOR INDIVIDUAL CELL ENTRIES
% x = strcat(...
%     '<html><span style="color: #FF0000; font-weight: bold;">', ...
%     cellstr(num2str(cell2mat(uiparameter(2,2)))));
% uiparameter(2,2) = x;            
            
% set global structures
gui   = createInterface;
onLoad(0,0);                % call load on startup

    function gui = createInterface
        
    gui = struct();
    screensz = get(0,'ScreenSize');
    

    %% MAKE GUI WINDOW ----------------------------------------------------
    gui.figureid = figure( ...
        'Name', 'Requesting GMR survey information', ...
        'NumberTitle', 'off', ...
        'MenuBar', 'none', ...
        'Toolbar', 'none', ...
        'HandleVisibility', 'on');
    
    set(gui.figureid, 'Position', [15 screensz(4)-375 900 340])

    % Set default panel settings
    uiextras.set(gui.figureid, 'DefaultBoxPanelFontSize', 12);
    uiextras.set(gui.figureid, 'DefaultBoxPanelFontWeight', 'bold')
    uiextras.set(gui.figureid, 'DefaultBoxPanelPadding', 5)
    uiextras.set(gui.figureid, 'DefaultHBoxPadding', 2)

    %% MAKE MENU ----------------------------------------------------------
%     % + Quit menu
%     gui.menu_quit = uimenu(gui.figureid, 'Label', 'Quit');
%     uimenu(gui.menu_quit, ...
%         'Label', 'Quit', ...
%         'Callback', @onQuit);
% 
%     % + File Menu
%     gui.menu_file = uimenu(gui.figureid, 'Label', 'File');
%     uimenu(gui.menu_file, ...
%         'Label', 'Load GMR header file', ...
%         'Callback', @onLoad);
%     uimenu(gui.menu_file, ...
%         'Label', 'Save userinput', ...
%         'Callback', @onSave);
% 
%     % + Help menu
%     gui.menu_help = uimenu(gui.figureid, 'Label', 'Help' );
%     uimenu(gui.menu_help, ...
%         'Label', 'Documentation', ...
%         'Callback', @onHelp);

    %% MAKE UICONTROLS ----------------------------------------------------
    mainbox = uiextras.VBox('Parent', gui.figureid);
    
    % File header selection
    box_h1  = uiextras.HBox('Parent', mainbox);
        gui.pushbutton_file = uicontrol(...
            'Style', 'Pushbutton', ...
            'Parent', box_h1, ...
            'String', 'LOAD', ...
            'Callback', @onLoad);
        gui.edit_file = uicontrol(...
            'Style', 'Edit', ...
            'Parent', box_h1, ...
            'Enable', 'off', ...
            'BackgroundColor', [0 1 0], ...
            'HorizontalAlignment', 'left', ...
            'String', ' Load GMR header ( > LOAD)...'); 
    set(box_h1, 'Sizes', [50 -1])

    % boxes & panel for tables
    box_h2 = uiextras.HBox('Parent', mainbox);
        panel1 = uiextras.BoxPanel(...
                            'Parent', box_h2, ...
                            'Title', 'User input');
            box_h2v1 = uiextras.VBox('Parent', panel1);
            
                % table with general survey info
                gui.table_info = uitable('Parent', box_h2v1);
                set(gui.table_info, ...
                    'CellEditCallback', @onEditTable, ...
                    'ColumnName', {'Value', 'Info'}, ...
                    'ColumnWidth', {50 605}, ...
                    'RowName', uiparameter(7:end,1), ...
                    'Enable', 'off', ...
                    'Data',uiparameter(7:end,[2 10]),...
                    'ColumnFormat', {'numeric','char'},...
                    'ColumnEditable', [true false]);

                % table with channel-specific info
                gui.table_channels = uitable('Parent', box_h2v1);
                set(gui.table_channels, ...
                    'CellEditCallback', @onEditTable, ...
                    'ColumnName', {'Ch1', 'Ch2', 'Ch3', 'Ch4', 'Ch5', 'Ch6', 'Ch7', 'Ch8', 'Info'}, ...
                    'ColumnWidth', {50 50 50 50 50 50 50 50 288}, ...
                    'RowName', uiparameter(2:6,1), ...
                    'Enable', 'off', ...
                    'ColumnEditable', [true true true true true true true true false],...
                    'Data', uiparameter(2:6,2:10));
                
    box_h3 = uiextras.HBox('Parent', mainbox);
        gui.edit_status = uicontrol(...
            'Style', 'Edit', ...
            'Parent', box_h3, ...
            'Enable', 'on', ...
            'ForegroundColor', [1 0 0], ...
            'HorizontalAlignment', 'right', ...
            'String', 'Waiting for header file.  ');         
        gui.pushbutton_save = uicontrol(...
            'Enable', 'off', ...
            'Style', 'Pushbutton', ...
            'Parent', box_h3, ...
            'String', 'SAVE', ...
            'Callback', @onSave);
        gui.pushbutton_quit = uicontrol(...
            'Enable', 'on', ...
            'Style', 'Pushbutton', ...
            'Parent', box_h3, ...
            'String', 'QUIT', ...
            'Callback', @onQuit);
    set(box_h3, 'Sizes', [-1 50 50])        
    
    set(mainbox, 'Sizes',[30 -1 30])
    end


    %% LOAD HEADERFILE ----------------------------------------------------
    function onLoad(a,b) %#ok<*INUSD>
     
        % locate header file
        if requesthfile
            hfile = uigetfile([sounding_path '*'],'Select the GMR header file');
        end
        
        % read header file
        header = mrs_read_gmrheader([sounding_path hfile]);
        
        % update parameters
        uiparameter(1,2) = {hfile};
        for iCh = 1:length(header.rxt)
            % convert from GMR rxt to MRSmatlab rxt
            % GMR: 0 detect, 1 reference, 2 off
            % MRS: 0 off, 1 RX, 2 reference
            uiparameter(2,iCh+1) = {mod(header.rxt(iCh)+1,3)};
        end
        uiparameter(3,1)  = {1};                % set ch1 to TX per default
        uiparameter(7,2)  = {header.fS};
        uiparameter(10,2) = {header.gain_I};
        uiparameter(11,2) = {header.gain_V};
        
        % update default prepulse delay
        switch header.sequenceID
            case {1,2}
                uiparameter(8,2)  = {50};   % prepulse delay is 50ms for sequences 1 & 2
            case 4
                uiparameter(8,2)  = {10};   % prepulse delay is 10ms for sequence 4
        end
        
        % if version > 1: get dead time from header file
        if header.GMRversion > 1
            uiparameter(9,2)  = {header.tau_dead*1000};
        end
        
        % update gui
        set(gui.table_channels, ...
                'Enable', 'on', ...
                'Data',uiparameter(2:6,2:10));
        set(gui.table_info, ...
                'Enable', 'on', ...
                'Data',uiparameter(7:end,[2 10]));
        set(gui.edit_file, 'String', [sounding_path hfile]);
        set(gui.edit_status, 'String', 'Waiting for user input.  ')
    end

    %% MENU ITEMS ---------------------------------------------------------
    function onQuit(a,b) %#ok<INUSD>
        delete(gui.figureid)
    end

%     function onHelp(a,b) %#ok<INUSD>
%         warndlg({'There is no help.'; ''; 'Really not.'}, 'modal')
%     end

    function onSave(a,b) %#ok<INUSD>
        
        % collect info from ui table
        data_table_info      = get(gui.table_info, 'Data');
        data_table_channels  = get(gui.table_channels, 'Data');
        uiparameter(7:11,2)  = data_table_info(:,1);
        uiparameter(2:6,2:9) = data_table_channels(:,1:8);
        
        % write output
        saved = write_gmruserinfo(sounding_path,uiparameter);
        if saved 
            set(gui.pushbutton_save,'Enable', 'off')
            set(gui.edit_status, ...
                'String', ['User input saved to:  ' sounding_path 'GMRuserinfo.mrs  '], ...
                'ForegroundColor', [0 0 0])
%             set(gui.edit_status, 'String', ['User input saved to:  ' sounding_path hfile 'UI.mrs  '])            
        end
    end
    
    %% ON EDIT TABLE ------------------------------------------------------
    function onEditTable(a,b)
        
        % get table data
        xtable = get(a,'Data');
        
        % if RXtask & TXtask are both zero, set all other values to zero
        for iCh = 1:size(xtable,2)-1
            if xtable{1,iCh}==0 && xtable{2,iCh}==0
                xtable{3,iCh} = 0;
                xtable{4,iCh} = 0;
                xtable{5,iCh} = 0;
            end
        end
        
        % allow only one TX
        if b.Indices(1)==2 && b.NewData == 1    % if one TX was set to 1
            for iCh = 1:size(xtable,2)-1
                xtable{2,iCh} = 0;              % set all TX to zero
            end
            xtable{2,b.Indices(2)} = 1;         % reset cahnged TX to one
        end
        
        % update table
        set(a, 'Data', xtable)
        
        set(gui.pushbutton_save,'Enable', 'on')
        set(gui.edit_status, 'String', 'Waiting to save changes.  ')
    end


    %% FUNCTION WRITE_GMRUSERINFO -----------------------------------------
    function saved = write_gmruserinfo(sounding_path,uiparameter)
    % function write_gmruserinfo(sounding_path,uival)
    %
    % Write gmr userinfo to file GMRuserinfo.mrs in sounding path.
    %
    % 10jun2011
    % ed. 18aug2011 JW
    % =========================================================================
    
    iTX = find(cell2mat(uiparameter(3,2:9))==1)+1;  % +1 to accomodate 2:9
    if length(iTX) > 1
        set(gui.edit_status, ...
            'String', 'Error. Only 1 TX allowed. Check TX task.', ...
            'ForegroundColor', [1 0 0])
        disp('Error. Only 1 TX allowed. Check TX task.')
        saved = 0;
        return
    end
    
    fid = fopen([sounding_path 'GMRuserinfo.mrs'],'w');
    content = { 'GMR ADDITIONAL HEADER INFORMATION';...
               ['file generated by MRSmatlab (modified ' date ')'];...
                '=================================';...
               ['headerfile=',       cell2mat(uiparameter(1,2))];...
               ['sample_frequency=', num2str(cell2mat(uiparameter(7,2)))];...
               ['prepulse_delay=',   num2str(cell2mat(uiparameter(8,2)))];...
               ['dead_time=',        num2str(cell2mat(uiparameter(9,2)))];...
               ['currentgain=',      num2str(cell2mat(uiparameter(10,2)))];...
               ['voltagegain=',      num2str(cell2mat(uiparameter(11,2)))];...
               ['looptype=',         num2str(cell2mat(uiparameter(4,2:9)))];...
               ['loopsize=',         num2str(cell2mat(uiparameter(5,2:9)))];...
               ['loopturns=',        num2str(cell2mat(uiparameter(6,2:9)))];...
               ['receivertask=',     num2str(cell2mat(uiparameter(2,2:9)))];...
               ['transmitterch=',    num2str(cell2mat(uiparameter(3,2:9)))]};

    for ln = 1:length(content)
        fprintf(fid,'%s\n',content{ln});
    end
    fclose(fid);
    saved = 1;
    end
uiwait(gui.figureid)
end