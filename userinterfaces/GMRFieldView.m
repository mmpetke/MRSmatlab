function GMRFieldView

% only one instance of the GUI running
kfig = findobj('Name', 'GMR Field View');
if ~isempty(kfig)
    delete(kfig)
end
    
        
% set global structures
gui      = createInterface();
fdata    = struct();
% defaults


    function gui = createInterface()
        
        gui = struct();
        screensz = get(0,'ScreenSize');
        
        %% GENERATE CONTROLS PANEL ----------------------------------------
        gui.panel_controls.figureid = figure( ...
            'Name', 'GMR Field View', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'Toolbar', 'none', ...
            'HandleVisibility', 'on',...
            'KeyPressFcn',@dokeyboardshortcut); % enable shortcuts
        
        set(gui.panel_controls.figureid, 'Position', [5 screensz(4)-600 640 440])
        
%         % Set default panel settings
%         uiextras.set(gui.panel_controls.figureid, 'DefaultBoxPanelFontSize', 12);
%         uiextras.set(gui.panel_controls.figureid, 'DefaultBoxPanelFontWeight', 'bold')
%         uiextras.set(gui.panel_controls.figureid, 'DefaultBoxPanelPadding', 5)
%         uiextras.set(gui.panel_controls.figureid, 'DefaultHBoxPadding', 2)
        
        %% MAKE MENU
        % + Quit menu
        gui.panel_controls.menu_quit = uimenu(gui.panel_controls.figureid, 'Label', 'Quit');
        uimenu(gui.panel_controls.menu_quit, ...
            'Label', 'Quit', ...
            'Callback', @onQuit);
        
        % + File Menu
        gui.panel_controls.menu_file = uimenu(gui.panel_controls.figureid, 'Label', 'File');
        uimenu(gui.panel_controls.menu_file, ...
            'Label', 'Load GMR Data Header', ...
            'Callback', @onLoadGMRHeader);
        
        % + Help menu
        gui.panel_controls.menu_help = uimenu(gui.panel_controls.figureid, 'Label', 'Help' );
        uimenu(gui.panel_controls.menu_help, ...
            'Label', 'Documentation', ...
            'Callback', @onHelp);
        
        
        %% CREATE UICONTROLS ----------------------------------------------
        mainbox = uiextras.VBox('Parent', gui.panel_controls.figureid);
        
        boxV  = uiextras.BoxPanel(...
            'Parent', mainbox, ...
            'Title', 'File and Status');
        box_Control  = uiextras.VBox('Parent', boxV);
        uicontrol(...
            'Style', 'Text',  'HorizontalAlignment', 'left', ...
            'Parent', box_Control, ...
            'String', 'Status');
        gui.panel_controls.edit_status = uicontrol(...
            'Style', 'Edit', ...
            'Parent', box_Control, ...
            'Enable', 'off', ...
            'BackgroundColor', [0 1 0], ...
            'String', 'Idle...');         
        uicontrol(...
            'Style', 'Text',  'HorizontalAlignment', 'left', ...
            'Parent', box_Control, ...
            'String', 'GMR Header');
        gui.GMRfilepath = uicontrol(...
            'Style', 'Edit', ...
            'Parent', box_Control, ...
            'Enable', 'on', ...
            'BackgroundColor', [0 1 0], ...
            'String', 'GMR filepath',...
            'Callback', @onEditPath); 
        set(box_Control, 'Sizes', [20 30 20 30])
        
        boxH = uiextras.HBox('Parent', mainbox);
        box1 = uiextras.VBox('Parent', boxH);
        box_UserSet  = uiextras.BoxPanel(...
            'Parent', box1, ...
            'Title', 'User Information');
        box_UserSetv1 = uiextras.VBox('Parent', box_UserSet);
        gui.UserInfoTable = uitable('Parent', box_UserSetv1);
        set(gui.UserInfoTable, ...
            'ColumnName', {'Ch1', 'Ch2', 'Ch3', 'Ch4', 'Ch5', 'Ch6', 'Ch7', 'Ch8'}, ...
            'ColumnWidth', {50 50 50 50 50 50 50 50}, ...
            'RowName', {'Loop Task'}, ...
            'ColumnEditable', false, ...
            'CellEditCallback', @onModTabUser);%
        uicontrol(...
            'Style', 'Text', ...
            'Parent', box_UserSetv1, ...
            'String', '');
        uicontrol(...
            'Style', 'Text', ...
            'Parent', box_UserSetv1, ...
            'String', 'Loop Task - 0: unconnected, 1: Tx/Rx, 2: Rx, 3: NC');
        set(box_UserSetv1, 'Sizes', [80 5 20])
        
        box_GMRSet  = uiextras.BoxPanel(...
            'Parent', box1, ...
            'Title', 'GMR Information');
        gui.GMRInfoTable = uitable('Parent', box_GMRSet);
        set(gui.GMRInfoTable, ...
            'ColumnName', [], ...
            'ColumnWidth', {100}, ...
            'RowName', {'Pulse sequence ID','Frequency [Hz]','Pulse length [ms]','Pulse delay [ms]','# Stacks','# Pulsemoments','Dead time [ms]','DAQ version','Tx version'}, ...
            'ColumnEditable', false);
        set(box1, 'Sizes', [120 -1])
        
        box2  = uiextras.BoxPanel(...
            'Parent', boxH, ...
            'Title', 'View');
        box_Run_Preview = uiextras.VBox('Parent', box2);
        gui.PreviewTable = uitable('Parent', box_Run_Preview);
        set(gui.PreviewTable, ...
            'CellEditCallback', @onEditPreviewTable, ...
            'ColumnName', {'select', '#'}, ...
            'ColumnWidth', {55 30}, ...
            'ColumnEditable', [true false], ...
            'ColumnFormat', {'logical','numeric'},...
            'RowName', []);
        uicontrol(...
            'Style', 'Text', ...
            'Parent', box_Run_Preview, ...
            'String', '');
        gui.process.pushbutton_preview = uicontrol(...
            'Style', 'Pushbutton', ...
            'Enable', 'on',...
            'Parent', box_Run_Preview, ...
            'String', 'Actualize',...
            'Callback', @onPreview);
        
        set(box_Run_Preview, 'Sizes', [-1 10 50])
        
%         set(boxH, 'Sizes', [510 120])
        set(boxH, 'Sizes', [510 -1])
        set(mainbox, 'Sizes',[130 -1])
    end
    function onEditPath(a,b)
        onLoadGMRHeader(gui.panel_controls.menu_file,1)
    end

    function onLoadGMRHeader(a,b)
%         if b % get file from edit path
%             file               = get(gui.GMRfilepath,'String');
%             [fdata.header.path,fdata.header.filename] = fileparts(file);
%             fdata.header.path  = [fdata.header.path filesep];
%         else % get file from dialog       
%             [fdata.header.filename,fdata.header.path] = uigetfile({'*.*; *.*','pick header for GMR'},...
%                 'MultiSelect','off',...
%                 'Open GMR Header File');
%         end
        
        % get header
%         fdata.header.info  = importdata(fullfile(fdata.header.path,fdata.header.filename));

        [fdata.headerfilename,fdata.headerpath] = uigetfile({'*.*; *.*','pick header for GMR'},...
                        'MultiSelect','off',...
                        'Open GMR Header File');

        fdata.header          = openGMRheader(fullfile(fdata.headerpath,fdata.headerfilename)); 
        fdata.header.filename = fdata.headerfilename;
        fdata.header.path     = fdata.headerpath;
        fdata.info.sequence   = fdata.header.sequenceID;
        
        
        % estimate number of files... instead of number of stacks!!!!!
        fid                 = 0;
        n                   = 1;
        fdata.filenumber    = [];
        while fid > -1
            if fdata.header.DAQversion<2.1
                fid = fopen([fdata.header.path fdata.header.filename '_' num2str(n)]);
            else
                fid   = fopen([fdata.header.path fdata.header.filename '_' num2str(n) '.lvm'],'r','ieee-be');
            end
            if fid > -1
                feof = fseek(fid,0,'eof'); fs(n) = ftell(fid);
                if n > 1
                    %if (fs(n) >= fs(n-1)*0.98)
                        fdata.filenumber = [fdata.filenumber n];
                    %end
                else
                    fdata.filenumber = [fdata.filenumber n];
                end
                fclose(fid);
                n=n+1;
            end
        end
              
        % check number of connected channels (extension box connected)
%         if fdata.header.DAQversion<2.1
%             fid = fopen([fdata.header.path fdata.header.filename '_1']);
%             l   = fgetl(fid);
%             col = sscanf(l,'%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f');
%             fdata.header.connectedchannels = length(col)-5; % either 4 or 8
%             
%         else
%             fid   = fopen([fdata.header.path fdata.header.filename '_1.lvm'],'r','ieee-be');
%             temp1  = fread(fid,4);
%             temp2  = fread(fid,4);
%             siz    = [2^32 2^16 2^8 1]'; % calculate dimensions based on 4 bits
%             dim1   = sum(siz.*temp1);
%             dim2   = sum(siz.*temp2);
%             N_chan = dim1;
%             N_samp = dim2;
%             fdata.header.connectedchannels = N_chan-4;
%             fclose(fid);
%         end
        
        
%         switch fdata.header.info(1) % 1: FID; 2: 90-90; 3:  ; 4: 4phase T1
%             case 1
%                 fdata.header.pulsesequence  = 1; 
%             case 2
%                 fdata.header.pulsesequence  = 2;                 
%             case 4
%                 fdata.header.pulsesequence  = 4;  
%         end
%         fdata.header.frequency      = fdata.header.info(2);         % Lamor frequency /Hz
%         fdata.header.taup           = fdata.header.info(4)/1e3;     % pulse length /s
%         fdata.header.tau            = fdata.header.info(5)/1e3;     % pulse delay /s between two pulses (T1/T2)
%         fdata.header.nQnRec         = fdata.header.info(7);         % number of pulse moments or stacks
%         fdata.header.capacitance    = fdata.header.info(8)/1e6;     % Tuning capacitance /F
%         fdata.header.TXversion      = fdata.header.info(9);         % Version transmitter; 1:8ms deadtime, 400 Imax; 2:5ms deadtime, 600 Imax
%         fdata.header.DAQversion     = fdata.header.info(10);        % Version DAQ
        
%         if fdata.header.DAQversion  == 1                            % DAQ version 1.x
%             fdata.header.deadtime   = 8e-3;                        % deadtime between pulse and time series record /s
%             fdata.header.Qsampling  = 0;                            % Q sampling methode; 0: standard GMR; 1: user defined
%             fdata.header.preampgain = 500;                          % gain preamplifier
%             fdata.header.sampleFreq = 50e3;                         % sample frequency /Hz
%             fdata.header.nQnRec     = NaN;                          % different in this version
%             % put some defaults for user input
%             for irx=1:4
%             	fdata.UserData(irx).looptask  = NaN;
%             end
%             InfoTable = [fdata.UserData(1).looptask]';
%             for irx=2:4
%                 InfoTable = [InfoTable [fdata.UserData(irx).looptask]'];
%             end
            
%         elseif fdata.header.DAQversion  >= 2                        % DAQ version 2.x
%             fdata.header.deadtime   = fdata.header.info(12)/1e3;    % deadtime between pulse and time series record /s
%             fdata.header.Qsampling  = fdata.header.info(13);        % Q sampling methode; 0: standard GMR; 1: user specified
%             fdata.header.preampgain = fdata.header.info(14);        % gain preamplifier
%             fdata.header.sampleFreq = fdata.header.info(15);        % sample frequency \Hz
%             % get values from header
            
            for irx=1:fdata.header.nrx
                fdata.UserData(irx).looptask = NaN;
            end
            InfoTable = [fdata.UserData(1).looptask]';
            for irx=2:fdata.header.nrx
                InfoTable = [InfoTable [fdata.UserData(irx).looptask]'];
            end
%         end

        
%         if fdata.header.Qsampling       ==   0 ;                    % Q sampling methode; standard GMR
%             fdata.header.stacks         = length(fdata.filenumber); % number of stacks    
%             fdata.header.Qnumber        = NaN;                      % number of Qs
%             
%         elseif fdata.header.Qsampling   ==   1 ;                    % Q sampling methode; user specified
%             fdata.header.stacks         = NaN;                      % number of stacks    
%             fdata.header.Qnumber        = length(fdata.filenumber); % number of Qs
%         end

        set(gui.GMRInfoTable,'Data',[fdata.header.sequenceID; fdata.header.fT; ...
                                     fdata.header.tau_p*1e3; fdata.header.tau_d*1e3; fdata.header.nrec; ...
                                     fdata.header.nQ;fdata.header.tau_dead*1e3;...
                                     fdata.header.DAQversion;fdata.header.TXversion]);
        set(gui.GMRfilepath,'String',fullfile(fdata.header.path,fdata.header.filename));

        
        set(gui.UserInfoTable, 'ColumnEditable', true, ...
            'Data',InfoTable);%
        
        tabledata      = cell(length(fdata.filenumber),1);
        tabledata(:,1) = {false};
        tabledata(1,1) = {true};
        for nF=1:length(fdata.filenumber)
            tabledata(nF,2) = {fdata.filenumber(nF)};
        end
        set(gui.PreviewTable,'Data', tabledata);
        fdata.previewFileID=1;
        
    end


    function onModTabUser(hTable, EdtData)
        tabData=get(hTable,'Data');
        for irx=1:fdata.header.nrx
            fdata.UserData(irx).looptask  = tabData(1,irx);
        end
    end
    function onEditPreviewTable(hTable, EdtData)
        tabData = get(hTable,'Data');
        tabData(fdata.previewFileID,1) = {false};
        
        fdata.previewFileID = EdtData.Indices(1);
        set(hTable,'Data',tabData);
    end

    function onPreview(a,b)
        FieldViewGMR(gui,fdata,fdata.previewFileID);
    end


    function onQuit(a,b)
        kfig = findobj('Name', 'GMR Field View');
        if ~isempty(kfig)
            delete(kfig)
        end
    end
end