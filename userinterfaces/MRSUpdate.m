function MRSUpdateProclog(proclog_pathdirfile)
% function MRSUpdateProclog(proclog_pathdirfile)
%
% Open UPDATE gui to update & save proclog data structure to current 
% MRSmatlab version. User is prompted for output file (old proclog is not
% overwritten).
%
% Input options:
%   sounding_pathdirfile - optional: Path to proclog file (.mrsd file)
%
% 11apr2012 Jan Walbrecker
% mod. 17may2012 JW
% =========================================================================

% Allow only one instance of the GUI
mfig = findobj('Name', 'Updating data file');
if mfig
    delete(mfig)
end

% Set globals
gui       = createInterface();
proclog   = struct();

% Check standalone
if nargin > 0   % i.e. command comes from MRSWorkflow
    standalone = 0;
else
    standalone = 1;
end

    function gui = createInterface
        
    gui = struct();
    screensz = get(0,'ScreenSize');
    
    %% MAKE GUI WINDOW ----------------------------------------------------
    gui.figureid = figure( ...
        'Name', 'Updating data file', ...
        'NumberTitle', 'off', ...
        'MenuBar', 'none', ...
        'Toolbar', 'none', ...
        'HandleVisibility', 'on');
    
    set(gui.figureid, 'Position', [15 screensz(4)-125 500 90])

    % Set default panel settings
    uiextras.set(gui.figureid, 'DefaultBoxPanelFontSize', 12);
    uiextras.set(gui.figureid, 'DefaultBoxPanelFontWeight', 'bold')
    uiextras.set(gui.figureid, 'DefaultBoxPanelPadding', 5)
    uiextras.set(gui.figureid, 'DefaultHBoxPadding', 2)

    %% MAKE UICONTROLS ----------------------------------------------------
    mainbox = uiextras.VBox('Parent', gui.figureid);
    
    % Select proclog file
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
            'String', ' Load data file (proclog) that needs to be updated ( > LOAD)...'); 
    set(box_h1, 'Sizes', [50 -1])

    % Version boxes
    box_h2 = uiextras.HBox('Parent', mainbox);
        uicontrol(...
            'Style', 'Text', ...
            'Parent', box_h2, ...
            'HorizontalAlignment', 'left', ...
            'String', ' Old (current) file version: '); 
        gui.edit_old = uicontrol(...
            'Style', 'Edit', ...
            'Parent', box_h2, ...
            'Enable', 'off', ...
            'BackgroundColor', [0 1 0], ...
            'HorizontalAlignment', 'left', ...
            'String', ' 0'); 
        uicontrol(...               % empty
            'Style', 'Text', ...
            'Parent', box_h2, ...
            'String', ' '); 
        uicontrol(...
            'Style', 'Text', ...
            'Parent', box_h2, ...
            'HorizontalAlignment', 'right', ...
            'String', ' New file version:   '); 
        gui.edit_new = uicontrol(...
            'Style', 'Edit', ...
            'Parent', box_h2, ...
            'Enable', 'off', ...
            'BackgroundColor', [0 1 0], ...
            'HorizontalAlignment', 'left', ...
            'String', ' 1'); 
    set(box_h2, 'Sizes', [150 50 -1 150 50])
    
    % Pushbuttons
    box_h4 = uiextras.HBox('Parent', mainbox);
        gui.edit_status = uicontrol(...
            'Style', 'Edit', ...
            'Parent', box_h4, ...
            'Enable', 'on', ...
            'ForegroundColor', [1 0 0], ...
            'HorizontalAlignment', 'right', ...
            'String', 'Waiting for data file.  ');         
        gui.pushbutton_info = uicontrol(...
            'Enable', 'off', ...
            'Style', 'Pushbutton', ...
            'Parent', box_h4, ...
            'String', 'INFO', ...
            'Callback', @onInfo);
        gui.pushbutton_update = uicontrol(...
            'Enable', 'off', ...
            'Style', 'Pushbutton', ...
            'Parent', box_h4, ...
            'String', 'UPDATE', ...
            'Callback', @onUpdate);
        gui.pushbutton_save = uicontrol(...
            'Enable', 'off', ...
            'Style', 'Pushbutton', ...
            'Parent', box_h4, ...
            'String', 'SAVE', ...
            'Callback', @onSave);
        gui.pushbutton_quit = uicontrol(...
            'Enable', 'on', ...
            'Style', 'Pushbutton', ...
            'Parent', box_h4, ...
            'String', 'QUIT', ...
            'Callback', @onQuit);
        set(box_h4, 'Sizes', [-1 50 50 50 50])     
    
    set(mainbox, 'Sizes',[30 30 30])
    end


    %% LOAD OLD DATA FILE (PROCLOG) ---------------------------------------
    function onLoad(a,b) %#ok<*INUSD>

        % Read .ini-file (get new version)
        inifile = mrs_readinifile;
            
        % Locate proclog data file
        if standalone   % get from user input
            
            % Get last project path from .ini-file
            if strcmp(inifile.MRSData.file,'none') == 1
                inifile.MRSData.path = [pwd filesep];
            end
            
            % Pick file
            [filename,filepath] = uigetfile(...
                [inifile.MRSData.path, '*.mrsd'], ...
                'Select the data file that needs to be updated:');
            if filename == 0  % if load is aborted (CANCEL in uigetdir)
                disp('Aborting...');
                drawnow
                return
            end
            proclog_pathdirfile = [filepath filename];
        end
        [filepath, filename, ext] = fileparts(proclog_pathdirfile) ;
        filepath = [filepath filesep];
        filename = [filename ext];        
        
        % switch filetype
        switch ext
            
            case '.mrsd'    % data file (proclog)
        
                % Read proclog file
                proclog = mrs_load_proclog(filepath, filename);

                % Determine version
                if ~isfield(proclog, 'MRSversion')
                    if ~isfield(proclog, 'rxinfoRaw')
                        proclog.MRSversion = 0;
                    else
                        proclog.MRSversion = 2.00;
                    end
                end
                if ischar(proclog.MRSversion)   % previously, version was erroneously saved as string; avoid crash here
                    proclog.MRSversion = str2double(proclog.MRSversion);
                end
                oldversion = proclog.MRSversion;
                newversion = mrs_version;
            
            case '.mrsk'    % kernel file
                
                % MAYBE RENAME PROCLOG OR INTRODUCE ANOTHER VARIABLE KDATA
                error('NOT YET IMPLEMENTED')
                % +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                
                % load .mrsk file
                dat   = load([file.kernelpath,file.kernelname],'-mat');
                kdata = dat.kdata;
                if ~isfield(kdata.measure,'pm_vec_2ndpulse')% workaround old kernel without 2nd pulse
                    kdata.measure.pm_vec_2ndpulse = kdata.measure.pm_vec;
                end
                
        end
        
        % Update gui
        set(gui.edit_old, 'String', num2str(oldversion, '%4.2f'));
        set(gui.edit_new, 'String', num2str(newversion, '%4.2f'));
        if newversion > oldversion
            set(gui.pushbutton_info, 'Enable', 'on');
            set(gui.pushbutton_update, 'Enable', 'on');
            set(gui.edit_status, 'String', 'Waiting for user input.  ')
        else
            set(gui.edit_status, 'String', 'File is up to date. Nothing to do.  ')
        end
    end


    %% PUSHBUTTON SAVE ----------------------------------------------------
    function onSave(a,b) %#ok<INUSD>
        
        % Get location to put file
        [filename,filepath] = uiputfile({...
            '*.mrsd','MRSMatlab data'; '*.*','All Files' },...
            'Save MRSMatlab data file',...
            proclog_pathdirfile);
        if filepath == 0;
            disp('Aborting...'); return;
        end
        
        % Save file
        outfile = [filepath filename];          
        save(outfile,'proclog');
        fprintf(1,'proclog saved to %s\n', outfile);
        set(gui.edit_status, ...
            'String', ['Data file saved to:  ' outfile '  '], ...
            'ForegroundColor', [0 0 0])        
    end

    %% PUSHBUTTON INFO ----------------------------------------------------
    function onInfo(a,b) %#ok<INUSD>
        
        % Get versions
        oldversion = get(gui.edit_old, 'String');
        newversion = get(gui.edit_new, 'String');
        
        % Display update description
        update  = [oldversion '->' newversion];
        mrs_updateproclogversion(proclog, update, 0);

    end


    %% PUSHBUTTON UPDATE --------------------------------------------------
    function onUpdate(a,b) %#ok<INUSD>
        
        % Get versions
        oldversion = get(gui.edit_old, 'String');
        newversion = get(gui.edit_new, 'String');
        
        % Update 
        update  = [oldversion '->' newversion];
        proclog = mrs_updateproclogversion(proclog, update, 1);
        
        % Update gui
        set(gui.pushbutton_save, 'Enable', 'on');
        set(gui.edit_status, ...
            'String', ['Data file (proclog) updated to version ', newversion, '  '], ...
            'ForegroundColor', [1 0 0]);
    end

    %% PUSHBUTTON QUIT ----------------------------------------------------
    function onQuit(a,b) %#ok<INUSD>
        delete(gui.figureid)
    end

    %% FUNCTION UPDATE ----------------------------------------------------
    
    function new = mrs_updateproclogversion(old, update, dowhat)
    % old:    old structure proclog 
    % new:    proclog after updating
    % dowhat: 0 - show update info (don't do the update); no output
    %         1 - do update
    
    if strcmp(update(1:4),'0.00')
        new = mrs_updateproclogversion_v000(old,dowhat);
    end
    
    switch update
        case '2.00->2.04'
            tmp  = mrs_updateproclogversion_v200_v201(old,dowhat);
            tmp2 = mrs_updateproclogversion_v201_v202(tmp,dowhat);
            tmp3 = mrs_updateproclogversion_v202_v203(tmp2,dowhat);
            new  = mrs_updateproclogversion_v203_v204(tmp3,dowhat);
        case '2.01->2.04'
            tmp  = mrs_updateproclogversion_v201_v202(old,dowhat);
            tmp2 = mrs_updateproclogversion_v202_v203(tmp,dowhat);
            new  = mrs_updateproclogversion_v203_v204(tmp2,dowhat);
        case '2.02->2.04'
            tmp = mrs_updateproclogversion_v202_v203(old,dowhat);
            new = mrs_updateproclogversion_v203_v204(tmp,dowhat);
        case '2.03->2.04'
            new = mrs_updateproclogversion_v203_v204(old,dowhat);
    end
    
    end    
    
    %% FUNCTION UPDATE 0.00 > 2.01 ----------------------------------------
    function new = mrs_updateproclogversion_v000(old,dowhat)
    
    switch dowhat
        case 0  % display info
            version_string = 'Cannot upgrade from unversioned file. Aborting.';
            msgbox(version_string, 'Info on update from 0.00', 'help');
            new = [];
        case 1  % do update
            new = old;  % cannot update from unversioned MRSMatlab
    end
    
    end

    %% FUNCTION UPDATE 2.00 > 2.01 ----------------------------------------
    function new = mrs_updateproclogversion_v200_v201(old,dowhat)
    % old - old structure proclog 
    % new - proclog after updating

    switch dowhat
        
        case 0  % display info
            version_string = {...
                    'Replacing fields ';
                    '  proclog.rxinfoRaw';
                    '  proclog.rxinfoStack';
                    'with field';
                    '  proclog.rxinfo';
                    ' ';
                    'Adding fields:';
                    '  proclog.rxinfo.loopype';
                    '  proclog.rxinfo.loopsize';
                    '  proclog.rxinfo.loopturns';
                    ' ';
                    'Adding field: proclog.Q(:).rx(:).channel';
                };
            msgbox(version_string, 'Info on update 2.00 -> 2.01', 'help');
            new = [];
            
        case 1  % do update
            % replace proclog.rxinfoRaw & proclog.rxinfoStack by proclog.rxinfo
            new = old;
            new.rxinfo = new.rxinfoRaw; 
            new = rmfield(new, {'rxinfoRaw'; 'rxinfoStacked'});

            % add rxinfo.loopype .loopsize .loopturns
            for irx = 1:length(new.rxinfo)
                new.rxinfo(irx).looptype  = 0; 
                new.rxinfo(irx).loopsize  = 0; 
                new.rxinfo(irx).loopturns = 0; 
            end
            itxrx = find(new.txinfo.channel == [new.rxinfo(:).channel]);
            new.rxinfo(itxrx).looptype  = new.txinfo.looptype; 
            new.rxinfo(itxrx).loopsize  = new.txinfo.loopsize; 
            new.rxinfo(itxrx).loopturns = new.txinfo.loopturns; 

            % add proclog.Q(:).rx(:).channel
            for iQ = 1:length(new.Q)
                for irx = 1:length(new.Q(iQ).rx)
                    new.Q(iQ).rx(irx).channel = new.rxinfo(irx).channel;
                end
            end

            % Update version
            new.MRSversion = 2.01;
    end
        
    end

    %% FUNCTION UPDATE 2.01 > 2.02 ----------------------------------------
    function new = mrs_updateproclogversion_v201_v202(old,dowhat)
    % old - old structure proclog 
    % new - proclog after updating
    
        % JW: UNTESTED
        
    switch dowhat
        
        case 0  % display info
            version_string = {...
                    'Change the coding for proclog type5-events ';
                    'proclog.event(:,1)==5 (execute global NC)';
                    ' ';
                    'From: ';
                    '  (5,2)iQ   -> 0';
                    '  (5,3)irec -> 0';
                    '  (5,4)irx  -> # fid channels';
                    '  (5,5)isig -> fid channels (bin2dec)';
                    '  (5,6)A    -> # ref channels';
                    '  (5,7)B    -> ref channels (bin2dec)';
                    '  (5,8)C    -> local/global switch';       % not required; encoded in type5 (vs type4 for local)
                    ' ';
                    'To: ';
                    '  (5,2)iQ   -> 1';
                    '  (5,3)irec -> 1';
                    '  (5,4)irx  -> 1';
                    '  (5,5)isig -> 1';
                    '  (5,6)A    -> # channels';
                    '  (5,7)B    -> ref channels (bin2dec)';
                    '  (5,8)C    -> fid channels (bin2dec)';
                };
            msgbox(version_string, 'Info on update 2.01 -> 2.02', 'help');
            new = [];
        
        case 1  % do update

            % rewrite proclog.event type 5 (global tranfer function)
            new = old;
            ID  = find(new.event(:,1) == 5);

            for id = 1:length(ID)

                % decode old version
                BD = dec2bin(old.event(ID(id),5),old.event(ID(id),4));   % # reference channels
                BR = dec2bin(old.event(ID(id),7),old.event(ID(id),6));    % reference channels
    %                     BD   = dec2bin(relog(ilog,5),relog(ilog,4));    % detection channels
    %                     dect = str2num(BD(:));
    %                     BR  = dec2bin(relog(ilog,7),relog(ilog,6));    % reference channels
    %                     ref = str2num(BR(:));   
    %                    rxnumber=[1:1:length(ref)];
    %                    data = mrsSigPro_NCGetTransfer(data,rxnumber(ref==1),rxnumber(dect==1),C);

                % encode new version
                A = length(old.rxinfo);  % set A to # channels  
                B = bin2dec(BR);         % set B to reference channels (bin2dec)
                C = bin2dec(BD);         % set C to signal channels (bin2dec)

                new.event(ID(id),2) = 1;    % set iQ to 1
                new.event(ID(id),3) = 1;    % set irec to 1
                new.event(ID(id),4) = 1;    % set irx to 1
                new.event(ID(id),5) = 1;    % set isig to 1
                new.event(ID(id),6) = A;    % # channels
                new.event(ID(id),7) = B;    % reference channels
                new.event(ID(id),8) = C;    % signal channels
            end

            % Update version
            new.MRSversion = 2.02;
    end

    end
    %% FUNCTION UPDATE 2.02 > 2.03 ----------------------------------------
    function new = mrs_updateproclogversion_v202_v203(old,dowhat)
    % old - old structure proclog 
    % new - proclog after updating
    
        % MMP: UNTESTED
        
    switch dowhat
        
        case 0  % display info
            version_string = {...
                    'Renamed error obtained from fitting';
                    '  proclog.Q().rx().sig().e -> efit';
                    'Included data error obtained from stacking';
                    '  proclog.Q().rx().sig().E';
               };
            msgbox(version_string, 'Info on update 2.02 -> 2.03', 'help');
            new = [];
        
        case 1  % do update

            new = old;
            nq  = length(new.Q);           % number of pulse moments
            nrx = length(new.Q(1).rx); % number of ALL receivers
            for iQ=1:nq % all pulse moments
                for irx=1:nrx % all receivers
                    for isig=1:4 % all signals
                        if new.Q(iQ).rx(irx).sig(isig).recorded
                            new.Q(iQ).rx(irx).sig(isig).fite = old.Q(iQ).rx(irx).sig(isig).e;
                            new.Q(iQ).rx(irx).sig(isig).E    = old.Q(iQ).rx(irx).sig(isig).e.E;
                        end
                    end
                end
            end
            % Update version
            new.MRSversion = 2.03;
    end

    end

    %% FUNCTION UPDATE 2.03 > 2.04 ----------------------------------------
    function new = mrs_updateproclogversion_v203_v204(old,dowhat)
    % old - old structure proclog 
    % new - proclog after updating
        
    switch dowhat
        
        case 0  % display info
            version_string = {...
                    'proclog.MRSversion was saved as string';
                    '  instead of double during updating.';
                    'This update replaces the string by ';
                    '  a number (if necessary).';
               };
            msgbox(version_string, 'Info on update 2.03 -> 2.04', 'help');
            new = [];
        
        case 1  % do update

            new = old;
            if ischar(new.MRSversion)
                new.MRSversion = str2double(MRSversion);
            else
                % nothing to fix
            end
            
            % Update version
            new.MRSversion = 2.04;
    end

    end
end

