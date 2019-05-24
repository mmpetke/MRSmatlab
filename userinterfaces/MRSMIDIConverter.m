function MRSMIDIConverter

% only one instance of the GUI running
mfig = findobj('Name', 'MRS-MIDI Converter');
        if mfig
            delete(mfig)
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
            'Name', 'MRS-MIDI Converter', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'Toolbar', 'none', ...
            'HandleVisibility', 'on',...
            'KeyPressFcn',@dokeyboardshortcut); % enable shortcuts
        
        set(gui.panel_controls.figureid, 'Position', [5 screensz(4)-600 800 550])
        
        % Set default panel settings
        uiextras.set(gui.panel_controls.figureid, 'DefaultBoxPanelFontSize', 12);
        uiextras.set(gui.panel_controls.figureid, 'DefaultBoxPanelFontWeight', 'bold')
        uiextras.set(gui.panel_controls.figureid, 'DefaultBoxPanelPadding', 5)
        uiextras.set(gui.panel_controls.figureid, 'DefaultHBoxPadding', 2)
        
        %% MAKE MENU
        % + Quit menu
        gui.panel_controls.menu_quit = uimenu(gui.panel_controls.figureid, 'Label', 'Quit');
        uimenu(gui.panel_controls.menu_quit, ...
            'Label', 'Quit', ...
            'Callback', @onQuit);
        
        % + File Menu
        gui.panel_controls.menu_file = uimenu(gui.panel_controls.figureid, 'Label', 'File');
        uimenu(gui.panel_controls.menu_file, ...
            'Label', 'Open folder with MRS-MIDI Raw data', ...
            'Callback', @onOpenMIDIFolder);
        uimenu(gui.panel_controls.menu_file, ...
            'Label', 'Select File Destination', ...
            'Callback', @onSelectFileDestination);
        
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
            'String', 'MRS-MIDI Folder');
        gui.MIDIfilepath = uicontrol(...
            'Style', 'Edit', ...
            'Parent', box_Control, ...
            'Enable', 'on', ...
            'BackgroundColor', [0 1 0], ...
            'String', 'MRS-MIDI filepath',...
            'Callback', @onEditPath); 
        uicontrol(...
            'Style', 'Text', 'HorizontalAlignment', 'left', ...
            'Parent', box_Control, ...
            'String', 'Destination of Converted Files');
        gui.Convertedfilepath = uicontrol(...
            'Style', 'Edit', ...
            'Parent', box_Control, ...
            'Enable', 'off', ...
            'BackgroundColor', [0 1 0], ...
            'String', 'filepath for converted'); 
        set(box_Control, 'Sizes', [20 30 20 30 20 30])
        
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
            'RowName', {'Loop Task', 'Loop Type', 'Loop Size', 'Number of Turns'}, ...
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
        uicontrol(...
            'Style', 'Text', ...
            'Parent', box_UserSetv1, ...
            'String', 'Loop Type - 1: circular, 2: square, 3: circular 8, 4: square 8');
        uicontrol(...
            'Style', 'Text', ...
            'Parent', box_UserSetv1, ...
            'String', 'Loop Size - diameter for circular , side length for square');
        set(box_UserSetv1, 'Sizes', [-1 5 18 18 18])
        
        box_MIDISet  = uiextras.BoxPanel(...%box_GMRSet
            'Parent', box1, ...
            'Title', 'MRS-MIDI Information');
        gui.MIDIInfoTable = uitable('Parent', box_MIDISet);
        set(gui.MIDIInfoTable, ...
            'ColumnName', [], ...
            'ColumnWidth', {100}, ...
            'RowName', {'Pulse sequence ID','Frequency [Hz]','Pulse length [ms]','Pulse delay [ms]','# Stacks','# Pulsemoments','Dead time [ms]','Rec. mode','MIDI version'}, ...
            'ColumnEditable', false);
        
        
        box2  = uiextras.BoxPanel(...
            'Parent', boxH, ...
            'Title', 'Preview / Conversion');
        box_Run_Preview = uiextras.VBox('Parent', box2);
        gui.PreviewTable = uitable('Parent', box_Run_Preview);
        set(gui.PreviewTable, ...
            'CellEditCallback', @onEditPreviewTable, ...
            'ColumnName', {'select', '#'}, ...
            'ColumnWidth', {50 50}, ...
            'ColumnEditable', [true false], ...
            'ColumnFormat', {'logical','numeric'},...
            'RowName', []);
        gui.process.pushbutton_preview = uicontrol(...
            'Style', 'Pushbutton', ...
            'Enable', 'on',...
            'Parent', box_Run_Preview, ...
            'String', 'Data preview',...
            'Callback', @onPreview);
        gui.process.pushbutton_run = uicontrol(...
            'Style', 'Pushbutton', ...
            'Enable', 'on',...
            'Parent', box_Run_Preview, ...
            'String', 'Run conversion',...
            'Callback', @onRun);
        set(box1, 'Sizes', [200 210])
        set(box_Run_Preview, 'Sizes', [300 30 30])
        
        set(boxH, 'Sizes', [600 200])
        
        set(mainbox, 'Sizes',[160 -1])
    end
    function onEditPath(a,b)
        onOpenMIDIFolder(gui.panel_controls.menu_file,1)
    end
    function onOpenMIDIFolder(a,b)
        if b % get file from edit path
            file               = get(gui.MIDIfilepath,'String');
            [fdata.header.path] = fileparts(file);%,fdata.header.filename
            fdata.header.path  = [fdata.header.path filesep];
            fdata.convpath     = [fdata.header.path 'MIDI2NUMIS' filesep];
        else % get folder from dialog       
            fdata.header.path = uigetdir('','pick a folder with MRS-MIDI rawdata'); %fdata.header.filename
            fdata.header.path  = [fdata.header.path filesep];
            fdata.convpath     = [fdata.header.path 'MIDI2NUMIS' filesep];
        end
% estimate number of files... instead of number of stacks!!!!!
filenames = dir(fdata.header.path);
for nof = 3:1:length(filenames)
    if strcmp(filenames(nof).name(1:4),'FID_')==1
        %search filename for number of pulsemoment
        name = filenames(nof).name;
        dummy = strfind(name,'Q');
        pulsmoment = 1+str2double(name(dummy+1:dummy+strfind(name(dummy:dummy+4),'_')-2));
        
        %search filename for number of stack 
        dummy = strfind(name,'R');
        stack = str2double(name(dummy+1:dummy+strfind(name(dummy:dummy+4),'.')-2));

        pm(pulsmoment).rec(stack)=stack;
%         %remember filenames for FID and corresponding NOISE data, if exist:
        fdata.pulsemoments(pulsmoment).fid{stack} = name;
        fdata.pulsemoments(pulsmoment).noise{stack} = ['NOISE',name(4:end)];
    end
end

%caution! vector fdata.filenumber consists of number of stacks for each
%pulse moment, significant difference compared to GMR conversion code!!!
%field-name could be changed in the future to stacknumber, take care of following
%scripts, too lazy to do this now 
for noq = 1:length(pm)
    %change sorting of pulse moments to ascending order
    fdata.filenumber(length(pm)-noq+1) = max(pm(noq).rec);      
end

% % % % % % % %         fid                 = 0;
% % % % % % % %         n                   = 1;
% % % % % % % %         fdata.filenumber    = [];
% % % % % % % %         while fid > -1
% % % % % % % %             fid = fopen([fdata.header.path fdata.header.filename '_' num2str(n)]);
% % % % % % % %             if fid > -1
% % % % % % % %                 feof = fseek(fid,0,'eof'); fs(n) = ftell(fid);
% % % % % % % %                 if n > 1
% % % % % % % %                     %if (fs(n) >= fs(n-1)*0.98)
% % % % % % % %                         fdata.filenumber = [fdata.filenumber n];
% % % % % % % %                     %end
% % % % % % % %                 else
% % % % % % % %                     fdata.filenumber = [fdata.filenumber n];
% % % % % % % %                 end
% % % % % % % %                 fclose(fid);
% % % % % % % %                 n=n+1;
% % % % % % % %             end
% % % % % % % %         end
% % % % % % % %  

%         % check number of connected channels (extension box connected)
%         fid = fopen([fdata.header.path fdata.header.filename '_1']);
%         l   = fgetl(fid);
%         col = sscanf(l,'%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f');
%         fdata.header.connectedchannels = length(col)-5; % either 4 or 8
%         fclose(fid);

        fdata.header.MIDIversion    = 1;                    %Version of MRS-MIDI System

        %MRS-MIDI I with 3 receiver channels, later: MRS-MIDI II with 7 Channels
        if fdata.header.MIDIversion    == 1;                    
            fdata.header.connectedchannels = 3;
        else
            disp('So far, import of MRS-MIDI 2 data is not possible');
        end
        % get info 1: FID; 2: 90-90; 3:  ; 4: 4phase T1
        [data,info]=import_MIDIdata(fullfile(fdata.header.path,'FID_Q0_D0_R1.dat'),1);
        if info.delay < 0
            fdata.header.pulsesequence  = 1;
            fdata.header.info(1)        = 1;
        else %for the case T1 measurements with MIDI are realized in the future
            fdata.header.pulsesequence  = 2;
            fdata.header.info(1)        = 2;
        end

        fdata.header.frequency      = info.f_larmor;        % Lamor frequency /Hz
        fdata.header.taup           = info.pulse_length;    % pulse length /s
        fdata.header.tau            = info.delay;           % pulse delay /s between two pulses (T1/T2)
        fdata.header.capacitance    = 1;                    % Tuning capacitance /F, not available in MRS-MIDI files
%        fdata.header.TXversion      = 0;                    % Version transmitter
%        fdata.header.DAQversion     = 0;                    % Version DAQ
        fdata.header.deadtime       = info.dead_time;       % deadtime between pulse and time series record /s
 %       fdata.header.Qsampling      = 0;                    % Q sampling methode; 0: standard GMR; 1: user defined
        fdata.header.sampleFreq     = info.sample_freq;     % sample frequency /Hz        
        fdata.header.preampgain     = 1;                    % gain preamplifier, already considered in import_MIDIdata
        fdata.header.Rxmode         = info.mode;            % Receiver mode, 1: 3 FID or 0: FID+REF
        
        %to be modified later, when implementing MRS-MIDI II import...
        
        if fdata.header.Rxmode == 0
        %info about 1. Channel: handled as Tx! with 1 turn, Rx with 12 turn
        %currently not considered - be aware when inverting!
        fdata.UserData(1).looptask  = 1;%Really??? check how Tx is handled with 1 turn????
        fdata.UserData(1).looptype  = 2;
        fdata.UserData(1).loopsize  = sqrt(info.loop_area(1));
        fdata.UserData(1).nturns    = 1;%info.turns(1);    
            
        %info about 2. Channel
        fdata.UserData(2).looptask  = 3;
        fdata.UserData(2).looptype  = 2;
        fdata.UserData(2).loopsize  = sqrt(info.loop_area(2));
        fdata.UserData(2).nturns    = info.turns(2);    
        
        %info about 3. Channel
        fdata.UserData(3).looptask  = 3;
        fdata.UserData(3).looptype  = 2;
        fdata.UserData(3).loopsize  = sqrt(info.loop_area(3));
        fdata.UserData(3).nturns    = info.turns(3); 
        
        %info about 4. Channel, possibly used for Tx channel in future,
        %when 1. Channel is handled as receiver only
        fdata.UserData(4).looptask  = 0;
        fdata.UserData(4).looptype  = 0;
        fdata.UserData(4).loopsize  = 0;
        fdata.UserData(4).nturns    = 0;   
        
        
        InfoTable = [fdata.UserData(1).looptask fdata.UserData(1).looptype fdata.UserData(1).loopsize fdata.UserData(1).nturns]';
            for irx=2:3
                InfoTable = [InfoTable [fdata.UserData(irx).looptask fdata.UserData(irx).looptype fdata.UserData(irx).loopsize fdata.UserData(irx).nturns]'];
            end
            
        else
            disp('So far, the software allows only data import for measurement mode <FID+REF>');
        end

        fdata.header.stacks         = max(fdata.filenumber); % number of stacks
        fdata.header.Qnumber        = length(pm);             %number of pulse moments

        
        set(gui.MIDIInfoTable,'Data',[fdata.header.pulsesequence; fdata.header.frequency; ...
                                     fdata.header.taup; fdata.header.tau; fdata.header.stacks; ...
                                     fdata.header.Qnumber;fdata.header.deadtime;...
                                     fdata.header.Rxmode;fdata.header.MIDIversion]);
        set(gui.MIDIfilepath,'String',fdata.header.path);
        set(gui.Convertedfilepath,'String',fdata.convpath);
        
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

    function onSelectFileDestination(a,b)
        path = uigetdir;
        fdata.convpath = [path filesep];
        set(gui.Convertedfilepath,'String',fdata.convpath);
    end

    function onModTabUser(hTable, EdtData)
        tabData=get(hTable,'Data');
        for irx=1:fdata.header.connectedchannels
            fdata.UserData(irx).looptask  = tabData(1,irx);
            fdata.UserData(irx).looptype  = tabData(2,irx);
            fdata.UserData(irx).loopsize  = tabData(3,irx);
            fdata.UserData(irx).nturns    = tabData(4,irx);
        end
    end
    function onEditPreviewTable(hTable, EdtData)
        tabData = get(hTable,'Data');
        tabData(fdata.previewFileID,1) = {false};
        
        fdata.previewFileID = EdtData.Indices(1);
        set(hTable,'Data',tabData);
    end
    function onRun(a,b)      
        convMIDI2NumisPoly(gui,fdata);
    end

    function onPreview(a,b)
        previewMIDIData(gui,fdata,fdata.previewFileID);
    end


    function onQuit(a,b)
        mfig = findobj('Name', 'MRS-MIDI Converter');
        if mfig
            delete(mfig)
        end
    end
end