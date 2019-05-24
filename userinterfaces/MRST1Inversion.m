function MRST1Inversion(projectfile)

% allow only one instance of MRST1Inversion
wfig = findobj('Name', 'MRS T1 Inversion');
if ~isempty(wfig)
    delete(wfig)
end
wfig = findobj('Name', 'MRS T1 Inversion - Data');
if ~isempty(wfig)
    delete(wfig)
end
wfig = findobj('Name', 'MRS T1 Inversion - Model');
if ~isempty(wfig)
    delete(wfig)
end

gui  = createInterface();
idata    = struct();

if nargin > 0   % i.e. command comes from MRSWorkflow
    standalone = 0;
    onLoadMRSProject(0,1)
else
    standalone = 1;
    % initialize mrsproject
    mrsproject.path = [];
    mrsproject.data.status      = 0;
    mrsproject.data.dir         = '';
    mrsproject.kernel.status    = 0;
    mrsproject.kernel.dir       = '';
    mrsproject.inversion.status = 0;
    mrsproject.inversion.dir    = '';
end


    function gui = createInterface()
        gui = struct();
        screensz = get(0,'ScreenSize');
          %% CREATE FIGURES
        gui.fig_data = figure( ...
            'Position', [5+355+405 screensz(4)-745 500 700], ...
            'Name', 'MRS T1 Inversion - Data', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'Toolbar', 'figure', ...
            'HandleVisibility', 'on');
        gui.fig_model = figure( ...
            'Position', [5+355 screensz(4)-745 400 700], ...
            'Name', 'MRS T1 Inversion - Model', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'Toolbar', 'figure', ...
            'HandleVisibility', 'on');
        
        %% GENERATE CONTROLS PANEL ----------------------------------------
        gui.panel_controls.figureid = figure( ...
            'Name', 'MRS T1 Inversion', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'Toolbar', 'none', ...
            'HandleVisibility', 'on'); % enable shortcuts
        
        set(gui.panel_controls.figureid, 'Position', [5 screensz(4)-745 350 705])
        
        % Set default panel settings
        %uiextras.set(gui.panel_controls.figureid, 'DefaultBoxPanelFontSize', 12);
        %uiextras.set(gui.panel_controls.figureid, 'DefaultBoxPanelFontWeight', 'bold')
        %uiextras.set(gui.panel_controls.figureid, 'DefaultBoxPanelPadding', 5)
        %uiextras.set(gui.panel_controls.figureid, 'DefaultHBoxPadding', 2)
        
        %% MAKE MENU
        % + Quit menu
        gui.QuitMenu = uimenu(gui.panel_controls.figureid, 'Label', 'Quit');
%         uimenu(gui.QuitMenu, ...
%             'Label', 'Save and Quit', ...
%             'Callback', @onSaveAndQuit, ...
%             'Enable', 'on');
        uimenu(gui.QuitMenu,...
            'Label', 'Quit without saving',...
            'Callback', @onQuitWithoutSave);
        
        % + File menu
        gui.FileMenu = uimenu(gui.panel_controls.figureid, 'Label', 'File');
        uimenu(gui.FileMenu, 'Label', 'Load project file', 'Callback', @onLoadMRSProject);
        uimenu(gui.FileMenu, 'Label', 'Load kernel', 'Callback', @onLoadKernel);
        uimenu(gui.FileMenu, 'Label', 'Load InvResults', 'Callback', @onLoadInvResults);
        uimenu(gui.FileMenu, 'Label', 'Save InvResults', 'Callback', @onSaveInvResults);
        uimenu(gui.FileMenu, 'Label', 'Save project file', 'Callback', @onSaveMRSProject);
        
        
        % + Help menu
        gui.menu_help = uimenu(gui.panel_controls.figureid, 'Label', 'Help' );
        uimenu(gui.menu_help, ...
            'Label', 'Documentation', ...
            'Callback', @onHelp);
        
        %% CREATE UICONTROLS ----------------------------------------------
        mainbox = uiextras.VBox('Parent', gui.panel_controls.figureid);

        %% File and Status
        boxF    = uiextras.BoxPanel('Parent', mainbox, 'Title', 'File and Status', 'TitleColor', [0 0.75 1]);
        vboxF   = uiextras.VBox('Parent', boxF);
        uicontrol('Style', 'Text', 'HorizontalAlignment', 'left', 'String', 'Status','Parent', vboxF)
        gui.panel_controls.edit_status = uicontrol(...
            'Style', 'Edit', ...
            'Parent', vboxF, ...
            'Enable', 'off', ...
            'BackgroundColor', [0 1 0], ...
            'String', 'Idle...');
        
        hvboxF2 = uiextras.HBox('Parent', vboxF);
            gui.panel_controls.pushbutton_new = uicontrol(...
                'Style', 'Pushbutton', ...
                'Parent', hvboxF2, ...
                'Enable', 'on', ...
                'BackgroundColor', [0 1 0], ...
                'HorizontalAlignment', 'center', ...
                'String', 'NEW', ...
                'Callback',@onNewProject);
            gui.panel_controls.pushbutton_new = uicontrol(...
                'Style', 'Pushbutton', ...
                'Parent', hvboxF2, ...
                'Enable', 'off', ...
                'BackgroundColor', [0 0.5 1], ...
                'HorizontalAlignment', 'center', ...
                'String', 'LOAD', ...
                'Callback',@onLoadMRSProject);
        
        uicontrol('Style', 'Text','HorizontalAlignment', 'left', 'String', 'Project file','Parent', vboxF)
        gui.panel_controls.edit_projectPath = uicontrol(...
            'Style', 'Edit', ...
            'Parent', vboxF, ...
            'Enable', 'on', ...
            'BackgroundColor', [1 1 1], ...
            'String', '(Project path)', ...
            'Callback', @onLoadMRSProject);
        uicontrol('Style', 'Text', 'HorizontalAlignment', 'left','String', 'Kernel file','Parent', vboxF)
        gui.panel_controls.edit_kernelPath = uicontrol(...
            'Style', 'Edit', ...
            'Parent', vboxF, ...
            'Enable', 'on', ...
            'BackgroundColor', [1 1 1], ...
            'String', '(Kernel path)', ...
            'Callback', @onLoadKernel);
        uicontrol('Style', 'Text', 'HorizontalAlignment', 'left','String', 'WC/T2* results file','Parent', vboxF)
        gui.panel_controls.edit_invPath = uicontrol(...
            'Style', 'Edit', ...
            'Parent', vboxF, ...
            'Enable', 'on', ...
            'BackgroundColor', [1 1 1], ...
            'String', '(WC/T2* results path)', ...
            'Callback', @onLoadInvResults);       
        uicontrol('Style', 'Text', 'HorizontalAlignment', 'left', 'String', 'Data files ','Parent', vboxF)
        gui.files.table = uitable('Parent', vboxF);
        set(gui.files.table, ...
            'Enable','on',...
            'ColumnName', {' ', 'File', 'tau'}, ...
            'ColumnWidth', {30 240 60}, ...
            'ColumnFormat', {'logical','char','numeric'},...
            'Data',{false, '', 0},...
            'RowName', [], ...
            'ColumnEditable', [true false false]);
        
        hvboxF   = uiextras.HBox('Parent', vboxF);        
        gui.file.AddSounding = uicontrol('Style', 'pushbutton', ...
            'HorizontalAlignment', 'center', ...
            'Parent', hvboxF, ...
            'String', 'Add Sounding',...
            'Callback',@onAddSounding);
        gui.file.DeleteEntry = uicontrol('Style', 'pushbutton', ...
            'HorizontalAlignment', 'center', ...
            'Parent', hvboxF, ...
            'String', 'Delete Entry',...
            'Callback',@onDeleteEntry);
        set(hvboxF, 'Sizes', [-1 -1])
        set(hvboxF2, 'Sizes', [-1 -1])
        set(vboxF, 'Sizes', [20 20 20 20 20 20 20 20 20 20 120 30])
        
        
        %% Settings
        boxS  = uiextras.BoxPanel('Parent', mainbox, 'Title', 'Settings', 'TitleColor', [0 0.75 1]);
        vboxS = uiextras.VBox('Parent', boxS);
        % Model Space
        ModelSpace  = uiextras.VBox('Parent', vboxS);
        uicontrol('Style', 'Text', ...
                'Parent', ModelSpace, 'Background', [0.69 0.93 0.93],...
                'HorizontalAlignment', 'left',...
                'String', 'Model Space'); 
        h1ModelSpace  = uiextras.HBox('Parent', ModelSpace);
        uicontrol('Style', 'Text', ...
            'Parent', h1ModelSpace, ...
            'HorizontalAlignment', 'left',...
            'String', 'depth - decaytime');
        gui.para.soltype = uicontrol('Style', 'popupmenu', ...
            'Parent', h1ModelSpace, ...
            'String', {'smooth - mono','block - mono'},...
            'Value', 1, ...
            'Enable','off',...
            'Callback', @onSolType);
        set(h1ModelSpace, 'Sizes',[-1 200])
        h2ModelSpace  = uiextras.HBox('Parent', ModelSpace);        
        uicontrol('Style','Text','String','T1 (min/max)',...
                'HorizontalAlignment', 'left',...
                'parent',h2ModelSpace); 
        gui.para.decayMin = uicontrol('Style','Edit','String','0.01','Enable','off',...
                        'parent',h2ModelSpace,'BackgroundColor', [1 1 1]);             
        gui.para.decayMax = uicontrol('Style','Edit','String','1','Enable','off',...
                        'parent',h2ModelSpace,'BackgroundColor', [1 1 1]);
        set(h2ModelSpace, 'Sizes',[-1 50 50])    
        set(ModelSpace, 'Sizes',[20 25 25])

        %empty
        vboxempty = uiextras.VBox('Parent', vboxS);
        
        Regularisation  = uiextras.VBox('Parent', vboxS);
        uicontrol('Style', 'Text', ...
                'Parent', Regularisation, 'Background', [0.69 0.93 0.93],...
                'HorizontalAlignment', 'left',...
                'String', 'Inversion settings'); 
        h1Regularisation  = uiextras.HBox('Parent', Regularisation);
        uicontrol('Style','Text','String','Regularisation ',...
                        'parent',h1Regularisation,'HorizontalAlignment', 'left');
        gui.para.regpara = uicontrol('Style','Edit','String','1000',...
                        'parent',h1Regularisation,'BackgroundColor', [1 1 1],'Enable','off');
        set(h1Regularisation, 'Sizes',[-1 50]) 
        h2Regularisation  = uiextras.HBox('Parent', Regularisation);
        uicontrol('Style','Text','String','Number of iterations ',...
                        'parent',h2Regularisation,'HorizontalAlignment', 'left');
        gui.para.Niter = uicontrol('Style','Edit','String','5',...
                        'parent',h2Regularisation,'BackgroundColor', [1 1 1],'Enable','off');
        set(h2Regularisation, 'Sizes',[-1 50]) 
        h3Regularisation  = uiextras.HBox('Parent', Regularisation);
        uicontrol('Style','Text','String','T1 initial homogenous model  ',...
                        'parent',h3Regularisation,'HorizontalAlignment', 'left');
        gui.para.initialM = uicontrol('Style','Edit','String','.5',...
                        'parent',h3Regularisation,'BackgroundColor', [1 1 1],'Enable','off');
        set(h3Regularisation, 'Sizes',[-1 50]) 
        uicontrol('Style', 'Text','Parent', Regularisation,'String','');
        set(Regularisation, 'Sizes',[20 25 25 25 10])
        set(vboxS, 'Sizes',[70 20 70])
        
        % run
        vboxempty = uiextras.VBox('Parent', mainbox);
        vboxRun = uiextras.VBox('Parent', mainbox);
        gui.vboxRun.Start = uicontrol(...
            'Style', 'pushbutton', ...
            'HorizontalAlignment', 'center', ...
            'Parent', vboxRun, ...
            'String', 'Run',...
            'Enable','off',...
            'Callback',@on_pushbuttonRun);
        
        
        set(mainbox, 'Sizes',[400 -1 5 60])
    end
%% FUNCTION on_pushbuttonRun
    function on_pushbuttonRun(a,b)
        if isfield(idata,'inv1DT1')
            switch idata.para.modelspace
                case 1 %smooth
                    if isfield(idata.inv1DT1,'smooth')
                        idata.inv1DT1 = rmfield(idata.inv1DT1,'smooth');
                    end
                case 2 %block
                    if isfield(idata.inv1DT1,'block')
                        idata.inv1DT1 = rmfield(idata.inv1DT1,'block');
                    end
            end
        end
        idata = mrs_invT1GetGuiPara(gui,idata);
        idata = mrs_invT1preparation(idata);
        idata = mrs_T1Inversion(idata);
        plotMRST1Data(idata,gui)
    end
%% FUNCTION onLoadMRSProject
    function onLoadMRSProject(a,call)
        if ~isnumeric(call)% workaround for matlab 2014b
            call=0;
        end
        if call
            in = load([projectfile], '-mat');
        else
            inifile = mrs_readinifile;
            if strcmp(inifile.MRSWorkflow.file,'none') == 1
                inifile.MRSWorkflow.path = [pwd filesep];
                inifile.MRSWorkflow.file = 'mrs_project';
            end
            
            [filename,filepath] = uigetfile({...
                '*.mrsp','MRSMatlab project'; '*.*','All Files' },...
                'Open MRSMatlab project file',...
                [inifile.MRSWorkflow.path inifile.MRSWorkflow.file]);
            
            if filepath == 0;
                disp('Aborting...')
                return
            end
            in = load([filepath,filename], '-mat');
            in.mrsproject.path = filepath; % update project path (can be different if project was saved last on a different machine)
            in.mrsproject.file = filename; % update project name (can be different if project was saved last on a different machine)
         end   
         
         mrsproject = in.mrsproject; 
         set(gui.panel_controls.edit_projectPath,'String',[mrsproject.path mrsproject.file])
         mrs_updateinifile([mrsproject.path mrsproject.file],0);
              
         % load data 
         idata = [];
         idata = loadMRST1Data(mrsproject);
                 
         % load kernel
         kernelfile = [mrsproject.path mrsproject.kernel(1).dir mrsproject.kernel(1).file];
         onLoadKernel(kernelfile,1)
         
         % load WC/T2*
         invfile = [mrsproject.path mrsproject.inversion(1).dir mrsproject.inversion(1).file];
         onLoadInvResults(invfile,1)
         % check which w/T2* results exist adapt preselection of inversion
         if isfield(idata.inv1Dqt,'blockMono')
             set(gui.para.soltype,'value',2);
         else
             set(gui.para.soltype,'value',1);
         end
         
         idata = mrs_invT1GetGuiPara(gui,idata);
         idata = mrs_invT1preparation(idata);
         plotMRST1Data(idata,gui); 
         
         % update data table for each entry in mrsproject.data
         if isfield(mrsproject.data, 'dir')
             n_data = length(mrsproject.data);
             data   = cell(n_data,3);
             for n  = 1:n_data
                 data{n,1} = true;
                 data{n,2} = char(mrsproject.data(n).file);
                 data{n,3} = idata.tau(n);
             end
             set(gui.files.table, 'Data', data)
         end
         
         
    end

%% FUNCTION onAddSounding
    function onAddSounding(a,b)
        
        % PROJECT FILE
        % create project file (if does not exist)
        if isempty(mrsproject.path)
            
            % get project path and filename from .ini-file
            inifile = mrs_readinifile;
            if strcmp(inifile.MRSWorkflow.file,'none') == 1
                inifile.MRSWorkflow.path = [pwd filesep];
                inifile.MRSWorkflow.file = 'mrs_project';
            end
            
            % prompt user for project file location (for saving)
            [filename,filepath] = uiputfile({...
                '*.mrsp','MRSMatlab project'; '*.*','All Files' },...
                'Save MRSMatlab project file first',...
                [inifile.MRSWorkflow.path inifile.MRSWorkflow.file]);
            
            % abort on cancel button
            if filepath == 0;
                disp('Aborting...')
                return
            end
            
            % generate default project
            mrsproject.path      = filepath;
            mrsproject.file      = filename;
            mrsproject.data      = struct();    % reset
            mrsproject.kernel    = struct();    % reset
            mrsproject.inversion = struct();    % reset
            
            % update gui & .ini-file and save
            set(gui.panel_controls.edit_projectPath,'String',[mrsproject.path mrsproject.file])
            mrs_updateinifile([mrsproject.path mrsproject.file],0);
            save([mrsproject.path mrsproject.file], 'mrsproject');
        end
        
        % SOUNDINGS
        % prompt user for .mrsd-files (soundings)
        soundings = ext_uipickfiles(...                     
            'FilterSpec', [mrsproject.path '*.mrsd'], ...
            'Prompt','Add *.mrsd data files'...
            );
        
        % abort on CANCEL button
        if ~iscell(soundings)   
            return
        end
        
        % collect new soundings in project file
        nS = length(soundings);         % # new soundings
        oS = length(mrsproject.data);   % # old soundings
        mrsproject.data(oS+nS).dir         = 'ini\';     % preallocate struct
        mrsproject.data(oS+nS).file        = 'ini.mrsd'; % preallocate struct
        mrsproject.data(oS+nS).status      = 0;          % preallocate struct
        mrsproject.kernel(oS+nS).dir       = '';         % JW: is this required? or do we want one kernel only?
        mrsproject.kernel(oS+nS).status    = 0;
        mrsproject.inversion(oS+nS).dir    = '';
        mrsproject.inversion(oS+nS).status = 0;
        for iS = 1:nS
            
            % get sounding directories (e.g. 'Sounding0001\')
            [sounding_path,sounding_file] = fileparts(cell2mat(soundings(iS)));
            sounding_dir                  = sounding_path(length(mrsproject.path)+1:end);
            
            % fill data structure with new soundings
            mrsproject.data(oS+iS).dir         = sounding_dir;
            mrsproject.data(oS+iS).file        = [sounding_file '.mrsd'];
            mrsproject.data(oS+iS).status      = 0;
            
        end
        
        % load data and plot
%         idata = [];                         % this deletes the kernel that is required for mrs_invT1preparation!
        idata = loadMRST1Data(mrsproject, idata);
                
        idata = mrs_invT1GetGuiPara(gui,idata);
        idata = mrs_invT1preparation(idata);
        plotMRST1Data(idata,gui); 
        
        % update data table for each entry in mrsproject.data
        if isfield(mrsproject.data, 'dir')
            n_data = length(mrsproject.data);
            data   = cell(n_data,3);
            for n  = 1:n_data
                data{n,1} = true;
                data{n,2} = char(mrsproject.data(n).file);
                data{n,3} = idata.tau(n);
            end
            set(gui.files.table, 'Data', data)
        end
               
    end

%% FUNCTION onStartNewProject
    function onNewProject(a,b)
        
        % reset idata
        idata = struct();
        
        % (1) PROJECT FILE ++++++++++++++++++++++++++++++++++++++++++++++++
            
        % set gui status
        mrs_setguistatus(gui,1,'Starting new project...')
        
        % get last project path and filename from .ini-file
        inifile = mrs_readinifile;
        if strcmp(inifile.MRSWorkflow.file,'none') == 1
            inifile.MRSWorkflow.path = [pwd filesep];
            inifile.MRSWorkflow.file = 'mrs_project';
        end

        % prompt user for project file location (for saving)
        [filename,filepath] = uiputfile({...
            '*.mrsp','MRSMatlab project'; '*.*','All Files' },...
            'Save new MRSMatlab project file',...
            [inifile.MRSWorkflow.path inifile.MRSWorkflow.file]);

        % abort on cancel button
        if filepath == 0;
            disp('Aborting...')
            return
        end

        % generate default project
        mrsproject.path      = filepath;
        mrsproject.file      = filename;
        mrsproject.data      = struct();
        mrsproject.kernel    = struct();
        mrsproject.inversion = struct();

        % update gui & .ini-file and save
        set(gui.panel_controls.edit_projectPath,'String',[mrsproject.path mrsproject.file])
        mrs_updateinifile([mrsproject.path mrsproject.file],0);
        save([mrsproject.path mrsproject.file], 'mrsproject');
        
        % (2) KERNEL ++++++++++++++++++++++++++++++++++++++++++++++++++++++
        onLoadKernel(-1,0);
        
        % (3) SOUNDINGS +++++++++++++++++++++++++++++++++++++++++++++++++++
        
        % set gui status
        mrs_setguistatus(gui,1,'Loading data...')
        
        % prompt user for .mrsd-files (soundings)
        soundings = ext_uipickfiles(...                     
            'FilterSpec', [mrsproject.path '*.mrsd'], ...
            'Prompt','Add *.mrsd data files'...
            );
        
        % abort on CANCEL button
        if ~iscell(soundings)   
            return
        end
        
        % collect new and overwrite previous soundings in project file
        nS                         = length(soundings);
        mrsproject.data(nS).dir    = 'ini\';     % preallocate struct
        mrsproject.data(nS).file   = 'ini.mrsd'; % preallocate struct
        mrsproject.data(nS).status = 0;          % preallocate struct
        mrsproject.data(nS).status = 0;          % preallocate struct
        mrsproject.kernel(nS).dir       = '';    % JW: is this required? or do we want one kernel only?
        mrsproject.kernel(nS).status    = 0;
        mrsproject.inversion(nS).dir    = '';
        mrsproject.inversion(nS).status = 0;
        for iS = 1:nS
            
            % get sounding directories (e.g. 'Sounding0001\')
            [sounding_path,sounding_file] = fileparts(cell2mat(soundings(iS)));
            sounding_dir                  = sounding_path(length(mrsproject.path)+1:end);
            
            % fill data structure
            mrsproject.data(iS).dir         = sounding_dir;
            mrsproject.data(iS).file        = [sounding_file '.mrsd'];
            mrsproject.data(iS).status      = 0;
            
        end
        
        % load data to idata structure
        idata = loadMRST1Data(mrsproject, idata);        
        
        % (4) SINGLE PULSE INVERSION RESULT +++++++++++++++++++++++++++++++
        
        % set gui status
        mrs_setguistatus(gui,1,'Loading inv...')
        
        % prompt user for inversion file location (for wc & T2*)
        [file.invname,file.invpath] = uigetfile(...
                {'*.mrsi','MRS Inversion Results File (*.mrsi)';
                '*.*',  'All Files (*.*)'}, ...
                'Pick a MRS Inversion Results File (single pulse data)',...
                mrsproject.path);

        % abort on cancel button
        if file.invpath == 0;
            disp('Aborting...')
            return
        end
        
        % store file location
        invfile = [file.invpath,file.invname];
        mrsproject.inversion(1).dir  = file.invpath(length(mrsproject.path)+1:end);
        mrsproject.inversion(1).file = file.invname;
        
        % load inversion file & replace previous content in idata 
        in   = load(invfile, '-mat');
        if isfield(idata,'inv1Dqt');
            idata = rmfield(idata,'inv1Dqt');
        end
        idata.inv1Dqt = in.idata.inv1Dqt;
        if isfield(idata,'inv1DT1')
            idata = rmfield(idata,'inv1DT1');
        end
        if isfield(in.idata,'inv1DT1')
            idata.inv1DT1=in.idata.inv1DT1;
        end
        
        % check which w/T2* results exist adapt preselection of inversion
        if isfield(idata.inv1Dqt,'blockMono')
            set(gui.para.soltype,'value',2);
        else
            set(gui.para.soltype,'value',1);
        end
        
        % finish & plot
        idata = mrs_invT1GetGuiPara(gui,idata);
        idata = mrs_invT1preparation(idata);
        plotMRST1Data(idata,gui);  
        
        % update gui
        set(gui.panel_controls.edit_invPath,'String',invfile)
        set(gui.para.regpara,'Enable','on');
        set(gui.para.Niter,'Enable','on');
        set(gui.para.initialM,'Enable','on');
        set(gui.para.decayMin,'Enable','on');
        set(gui.para.decayMax,'Enable','on');
        set(gui.para.soltype,'Enable','on');
        set(gui.vboxRun.Start,'Enable','on');
        mrs_setguistatus(gui,0)
        
        % update data table for each entry in mrsproject.data
        n_data = length(mrsproject.data);
        data   = cell(n_data,3);
        for n  = 1:n_data
            data{n,1} = true;
            data{n,2} = char(mrsproject.data(n).file);
            data{n,3} = idata.tau(n);
        end
        set(gui.files.table, 'Data', data)
               
    end

%% FUNCTION deleteEntry
    function onDeleteEntry(a,b)
        procme                    = SelectedSounding;
        mrsproject.data(procme)   = [];
        mrsproject.kernel(procme) = [];
        mrsproject.inversion(procme) = [];
        
        % load data and plot
        idata = [];
        idata = loadMRST1Data(mrsproject);
        
        idata = mrs_invT1GetGuiPara(gui,idata);
        idata = mrs_invT1preparation(idata);
        plotMRST1Data(idata,gui); 
        
        % update data table for each entry in mrsproject.data
        if isfield(mrsproject.data, 'dir')
            n_data = length(mrsproject.data);
            data   = cell(n_data,3);
            for n  = 1:n_data
                data{n,1} = true;
                data{n,2} = char(mrsproject.data(n).file);
                data{n,3} = idata.tau(n);
            end
            set(gui.files.table, 'Data', data)
        end
    end

%% FUNCTION onLoadInvResults
    function onLoadInvResults(a,call)
        if ~isnumeric(call)% workaround for matlab 2014b
            call=0;
        end
        mrs_setguistatus(gui,1,'Loading inv...')
        if call
            % kernelfile comes from nargin(2)
            invfile = a; 
        else
            inifile = mrs_readinifile;  % read ini file and get last .mrsd file (if exist)
            if strcmp(inifile.MRSData.file,'none') == 1
                inifile.MRSData.path = [pwd filesep];
                inifile.MRSData.file = 'mrs_project';
            end
            [file.invname,file.invpath] = uigetfile(...
                    {'*.mrsi','MRS Inversion Results File (*.mrsi)';
                    '*.*',  'All Files (*.*)'}, ...
                    'Pick a MRS Inversion Results File',...
                    [inifile.MRSData.path]);
            invfile = [file.invpath,file.invname];
            mrsproject.inversion(1).dir  = file.invpath(length(mrsproject.path)+1:end);
            mrsproject.inversion(1).file = file.invname;
        end 
        
        in   = load(invfile, '-mat');
        if isfield(idata,'inv1Dqt');idata = rmfield(idata,'inv1Dqt');end;
        idata.inv1Dqt = in.idata.inv1Dqt;
        
        if isfield(idata,'inv1DT1');idata = rmfield(idata,'inv1DT1');end;
        if isfield(in.idata,'inv1DT1');
            idata.inv1DT1=in.idata.inv1DT1;
        end
        
        idata = mrs_invT1GetGuiPara(gui,idata);
        idata = mrs_invT1preparation(idata);
        plotMRST1Data(idata,gui);  
        
        set(gui.panel_controls.edit_invPath,'String',invfile)
        set(gui.para.regpara,'Enable','on');
        set(gui.para.Niter,'Enable','on');
        set(gui.para.initialM,'Enable','on');
        set(gui.para.decayMin,'Enable','on');
        set(gui.para.decayMax,'Enable','on');
        set(gui.para.soltype,'Enable','on');
        set(gui.vboxRun.Start,'Enable','on');
        mrs_setguistatus(gui,0)
    end
%% FUNCTION onSaveInvResults
    function onSaveInvResults(a,b)
        mrs_setguistatus(gui,1,'Save inv...')
        inifile = mrs_readinifile;  % read ini file and get last .mrsd file (if exist)
        if strcmp(inifile.MRSData.file,'none') == 1
            inifile.MRSData.path = [pwd filesep];
            inifile.MRSData.file = 'mrs_project';
        end
        [file.invname,file.invpath] = uiputfile(...
            {'*.mrsi','MRS Inversion Results File (*.mrsi)';
            '*.*',  'All Files (*.*)'}, ...
            'Put a MRS Inversion Results File',...
            [inifile.MRSData.path]);
        invfile = [file.invpath,file.invname];
        save(invfile,'idata');
        mrs_setguistatus(gui,0)
        fprintf(1,'T1 inversion result saved to %s\n', invfile);
        mrs_updateinifile(invfile,32);
    end
%% FUNCTION onLoadKernel --------------------------------------------------
    function onLoadKernel(a,call)
        if ~isnumeric(call)% workaround for matlab 2014b
            call=0;
        end
        mrs_setguistatus(gui,1,'Loading kernel...')
        if call
            % kernelfile comes from nargin(2)
            kernelfile = a; 
        else
            inifile = mrs_readinifile;  % read ini file and get last .mrsd file (if exist)
            if strcmp(inifile.MRSKernel.file,'none') == 1
                inifile.MRSKernel.path = [pwd filesep];
                inifile.MRSKernel.file = 'mrs_kernel';
            end
            [file.kernelname,file.kernelpath] = uigetfile(...
                    {'*.mrsk','MRSKernel File (*.mrsk)';
                    '*.*',  'All Files (*.*)'}, ...
                    'Pick a MRSKernel file',...
                    [inifile.MRSKernel.path inifile.MRSKernel.file]);
            kernelfile = [file.kernelpath,file.kernelname];
            mrsproject.kernel(1).dir  = file.kernelpath(length(mrsproject.path)+1:end);
            mrsproject.kernel(1).file = file.kernelname;
        end      
        
        in                = load(kernelfile, '-mat');       
         
        if isfield(idata,'kernel');idata = rmfield(idata,'kernel');end;
        idata.kernel.K       = in.kdata.K;
        idata.kernel.z       = in.kdata.model.z;
        idata.kernel.loop    = in.kdata.loop;
        idata.kernel.model   = in.kdata.model;
        idata.kernel.measure = in.kdata.measure;
        idata.kernel.earth   = in.kdata.earth;
        idata.kernel.B1      = in.kdata.B1;

        idata.fn          = [];
        
        set(gui.panel_controls.edit_kernelPath,'String',kernelfile)
        
        mrs_setguistatus(gui,0)
    end
%% FUNCTION onSolType
    function onSolType(a,b)
        idata = mrs_invT1GetGuiPara(gui,idata);
%         idata = mrs_invT1preparation(idata);
        plotMRST1Data(idata,gui);  
    end
%% FUNCTION SELECTED SOUNDING -----------------------------------------
    function procme = SelectedSounding()
        % determine which sounding is ticked
        soundings = get(gui.files.table, 'Data');
        procme = cell2mat(soundings(:,1));        
    end

%% FUNCTION onSaveMRSProject
    function onSaveMRSProject(a,b)
        save([mrsproject.path mrsproject.file], 'mrsproject');
        fprintf(1,'mrsproject saved to %s\n', mrsproject.path);
    end
%% FUNCTION onQuitWithoutSave
    function onQuitWithoutSave(~,~)
        ifig = findobj('Name', 'MRS T1 Inversion');
        if ~isempty(ifig)
            delete(ifig)
        end
        ifig = findobj('Name', 'MRS T1 Inversion - Data');
        if ~isempty(ifig)
            delete(ifig)
        end
        ifig = findobj('Name', 'MRS T1 Inversion - Model');
        if ~isempty(ifig)
            delete(ifig)
        end
    end
%% FUNCTION onSaveAndQuit
    function onSaveAndQuit(a,b)
        ifig = findobj('Name', 'MRS T1 Inversion');
        if ifig
            delete(ifig)
        end
        ifig = findobj('Name', 'MRS T1 Inversion - Data');
        if ifig
            delete(ifig)
        end
        ifig = findobj('Name', 'MRS T1 Inversion - Model');
        if ifig
            delete(ifig)
        end
    end
end