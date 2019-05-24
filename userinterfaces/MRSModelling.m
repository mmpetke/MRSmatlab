function welldone = MRSModelling(kernel_pathdirfile)

% allow only one instance of the GUI running
mfig = findobj('Name', 'MRS Modelling - Model Parameter Table');
if ~isempty(mfig)
    delete(mfig)
end
mfig = findobj('Name', 'MRS Modelling - Model Parameter Graphs');
if ~isempty(mfig)
    delete(mfig)
end
mfig = findobj('Name', 'MRS Modelling - Data Sounding');
if ~isempty(mfig)
    delete(mfig)
end
mfig = findobj('Name', 'MRS Modelling - Data QT-cube');
if ~isempty(mfig)
    delete(mfig)
end

% set global structures
mdata    = struct();
mdata.mod.nTau = 2;
mdata.mod.tau  = [0.1 0.3];
for nTau=1:mdata.mod.nTau
    identTau(nTau) = {num2str(nTau)};
    widthTau{nTau} = 40;
end
kdata    = struct();
mdataTau = struct();

%initialeize gui
gui      = createInterface();

switch nargin
    case 0 %call from command line
        standalone = 1;
    case 1   % i.e. command comes from MRSWorkflow only with kernel
        standalone = 0;
        onLoadKernel(0,1);
end

    function gui = createInterface()
        
        gui = struct();
        screensz = get(0,'ScreenSize');
        
        %% GENERATE CONTROLS PANEL ----------------------------------------
        gui.panel_controls.figureid = figure( ...
            'Name', 'MRS Modelling - Model Parameter Table', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'Toolbar', 'none', ...
            'HandleVisibility', 'on');
        
        set(gui.panel_controls.figureid, 'Position', [5 screensz(4)-418 562 373])
        
        % Set default panel settings
        %uiextras.set(gui.panel_controls.figureid, 'DefaultBoxPanelFontSize', 12);
        %uiextras.set(gui.panel_controls.figureid, 'DefaultBoxPanelFontWeight', 'bold')
        %uiextras.set(gui.panel_controls.figureid, 'DefaultBoxPanelPadding', 5)
        %uiextras.set(gui.panel_controls.figureid, 'DefaultHBoxPadding', 2)
        
        %% MAKE MENU
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
            'Label', 'Load Kernel', ...
            'Callback', @onLoadKernel);
        uimenu(gui.panel_controls.menu_file, ...
            'Label', 'Save Data', ...
            'Callback', @onSave);
        
        % + Help menu
        gui.panel_controls.menu_help = uimenu(gui.panel_controls.figureid, 'Label', 'Help' );
        uimenu(gui.panel_controls.menu_help, ...
            'Label', 'Documentation', ...
            'Callback', @onHelp);
        
        
        %% CREATE UICONTROLS ----------------------------------------------
        mainbox = uiextras.VBox('Parent', gui.panel_controls.figureid);
        
        box_settings  = uiextras.BoxPanel(...
            'Parent', mainbox, ...
            'Title', 'File and Status');
        box_sv1  = uiextras.VBox('Parent', box_settings);
        
        uicontrol(...
            'Style', 'Text','HorizontalAlignment', 'left', ...
            'Parent', box_sv1, ...
            'String', 'Kernel')
        gui.edit_kernelfile = uicontrol(...
            'Style', 'Edit', ...
            'Parent', box_sv1, ...
            'String', 'kernelpath');      
        uicontrol(...
            'Style', 'Text','HorizontalAlignment', 'left', ...
            'Parent', box_sv1, ...
            'String', 'Status')
        gui.panel_controls.edit_status = uicontrol(...
            'Style', 'Edit', ...
            'Parent', box_sv1, ...
            'Enable', 'off', ...
            'BackgroundColor', [0 1 0], ...
            'String', 'Idle...');
        uicontrol(...
            'Style', 'Text','HorizontalAlignment', 'left', ...
            'Parent', box_sv1, ...
            'String', '')
%         box_sh1  = uiextras.HBox('Parent', box_sv1);
%         gui.sequenceType = uicontrol('Style', 'popupmenu', ...
%             'Parent', box_sh1, ...
%             'String', {'FID','FID + T1','Echo'},...
%             'Value', 1);
        gui.Run = uicontrol('Style', 'pushbutton', ...
            'HorizontalAlignment', 'center', ...
            'Parent', box_sv1, ...
            'Enable', 'off', ...
            'String', 'Run modelling',...
            'Callback',@onPushbuttonRun);
        %set(box_sh1, 'Sizes', [-1 -1])  
        
        set(box_sv1, 'Sizes', [20 20 20 20 20 -1])       
        
        
        box_ph  = uiextras.HBox('Parent', mainbox);
        
        box_ModelParameter = uiextras.BoxPanel(...
            'Parent', box_ph, ...
            'Title', 'Model Parameter');
        box_pv1  = uiextras.VBox('Parent', box_ModelParameter);
        gui.modeltable = uitable('Parent', box_pv1);
        set(gui.modeltable, ...
            'ColumnName', {'#', 'depth', 'wc', 'T2s', 'T1/T2'}, ...
            'ColumnWidth', {20 60 60 60 60}, ...
            'RowName', [], ...
            'ColumnEditable', true, ...
            'CellEditCallback', @onModTabCellEdt);
        box_ph1 = uiextras.HBox('Parent', box_pv1);
        gui.modelAddLayer = uicontrol(...
            'Style', 'PushButton', ...
            'Parent', box_ph1, ...
            'String', '+', ...
            'Callback', @onAddLayer);
        gui.modelRemLayer = uicontrol(...
            'Style', 'PushButton', ...
            'Parent', box_ph1, ...
            'String', '-', ...
            'Callback', @onRemoveLayer);
        set(box_ph1, 'Sizes', [-1 -1])      
        set(box_pv1, 'Sizes', [-1 28])
        
        box_MeasParameter = uiextras.BoxPanel(...
            'Parent', box_ph, ...
            'Title', 'Measurement Parameter');
        box_pv2  = uiextras.VBox('Parent', box_MeasParameter);
            box_pv2h1 = uiextras.HBox('Parent', box_pv2);
            uicontrol('Style', 'text', ...
                'Parent', box_pv2h1, ...
                'String','Pulse Sequence');
            uicontrol('Style', 'text', ...
                'Parent', box_pv2h1, ...
                'String','');
            gui.sequenceType = uicontrol('Style', 'popupmenu', ...
                'Parent', box_pv2h1, ...
                'Enable','off',...
                'String', {'FID','FID + T1','Echo'},...
                'Value', 1,...
                'Callback',@onPulseSequence);
            set(box_pv2h1, 'Sizes', [120 -1 100])
        uicontrol('Style', 'text','Parent', box_pv2, 'String',''); % blank
            box_pv2h4 = uiextras.HBox('Parent', box_pv2);
            uicontrol('Style', 'text', ...
                    'Parent', box_pv2h4, ...
                    'String','FID para');
            gui.MeasureParaTable = uitable('Parent', box_pv2h4);
            set(gui.MeasureParaTable, ...
                'ColumnName',[], ...
                'ColumnWidth', {60 120}, ...
                'RowName',  {'dead time/s', 'sampleFreq/Hz', 'record time/s', 'noise/nV'}, ...
                'ColumnEditable', true, ...
                'CellEditCallback', @onMeasTabCellEdt);
            set(box_pv2h4, 'Sizes', [60 -1])
        uicontrol('Style', 'text','Parent', box_pv2, 'String',''); % blank
            box_pv2h2 = uiextras.HBox('Parent', box_pv2);
            gui.IncludeT1 = uicontrol('Style', 'text', ...
                'Parent', box_pv2h2, ...
                'String','T1/T2 para');
            gui.TauParaTable = uitable('Parent', box_pv2h2);
            set(gui.TauParaTable, ...
                'ColumnName',identTau, ...
                'ColumnWidth', widthTau, ...
                'RowName',  {'tau/s'}, ...
                'ColumnEditable', true, ...
                'Data',[0.1 0.3],...
                'Visible','on',...
                'Enable','off',...
                'CellEditCallback', @onTauTabCellEdt);
            set(box_pv2h2, 'Sizes', [60 -1])   
            box_pv2h3 = uiextras.HBox('Parent', box_pv2);
         uicontrol('Style', 'text','Parent', box_pv2h3, 'String',''); % blank
            gui.modelAddTau = uicontrol(...
                'Style', 'PushButton', ...
                'Parent', box_pv2h3, ...
                'String', '+', ...
                'Enable','off',...
                'Callback', @onAddTau);
            gui.modelRemTau = uicontrol(...
                'Style', 'PushButton', ...
                'Parent', box_pv2h3, ...
                'String', '-', ...
                'Enable','off',...
                'Callback', @onRemoveTau);
           set(box_pv2h3, 'Sizes', [60 -1 -1])  
%         uicontrol('Style', 'text','Parent', box_pv2, 'String',''); % blank   
%         gui.Run = uicontrol('Style', 'pushbutton', ...
%             'HorizontalAlignment', 'center', ...
%             'Parent', box_pv2, ...
%             'Enable', 'off', ...
%             'String', 'Run modelling',...
%             'Callback',@onPushbuttonRun);
        set(box_ph1, 'Sizes', [-1 -1])
        set(box_pv2, 'Sizes', [20 -1 90 -1 40 20])
        set(box_ph, 'Sizes', [-1 -1])
        set(mainbox, 'Sizes', [150 -1])
        
        
        %% CREATE FIGURES
        gui.fig_graphs = figure( ...
            'OuterPosition', [0 screensz(4)-420-350 570 350], ...
            'Name', 'MRS Modelling - Model Parameter Graphs', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'Toolbar', 'none', ...
            'HandleVisibility', 'on');
        gui.fig_soundings = figure( ...
            'OuterPosition', [570 screensz(4)-420-350 570 350], ...
            'Name', 'MRS Modelling - Data Sounding', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'Toolbar', 'none', ...
            'HandleVisibility', 'on');
        gui.fig_qtcube = figure( ...
            'OuterPosition', [570 screensz(4)-420 570 420], ...
            'Name', 'MRS Modelling - Data QT-cube', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'Toolbar', 'none', ...
            'HandleVisibility', 'on');

    end

%% LOAD KERNEL ------------------------------------------------------------
    function onLoadKernel(a,call)
        if ~isnumeric(call)% workaround for matlab 2014b
            call=0;
        end
        if call
            % kernel_pathdirfile is determined from command nargin(1)
        else
            inifile = mrs_readinifile;  % read ini file and get last .mrsd file (if exist)
            if strcmp(inifile.MRSData.file,'none') == 1
                inifile.MRSData.path = [pwd filesep];
                inifile.MRSData.file = 'mrs_project';
            end
            [file.kernelname,file.kernelpath] = uigetfile(...
                    {'*.mrsk','MRSKernel File (*.mrsk)';
                    '*.*',  'All Files (*.*)'}, ...
                    'Pick a MRSKernel file',...
                    [inifile.MRSData.path]);
            kernel_pathdirfile = [file.kernelpath,file.kernelname];
        end
        set(gui.edit_kernelfile, 'String', kernel_pathdirfile, 'FontSize', 8)
        dat   = load(kernel_pathdirfile,'-mat');
        kdata = dat.kdata;
        
        mdata.mod.Nlayer = 3;
        mdata.mod.zlayer = kdata.model.zmax*[0 (1:mdata.mod.Nlayer)/mdata.mod.Nlayer];
        mdata.mod.f      = [0.05 0.25 0.10];
        mdata.mod.T2s    = [0.1 0.2 0.05];
        mdata.mod.T2     = zeros(1, length(mdata.mod.zlayer)-1);
        mdata.mod.T1     = zeros(1, length(mdata.mod.zlayer)-1);
        
        mdata.mod.tfid1  = 5e-3:0.001:0.5;
        mdata.mod.tfid2  = 5e-3:0.001:0.5;
        %mdata.mod.techo  = 5e-3:0.001:0.5;
        mdata.mod.noise  = 10e-9;
        mdata.mod.tau    = get(gui.TauParaTable,'Data');
        
        tdata = [(1:mdata.mod.Nlayer).' mdata.mod.zlayer(2:end).' 100*mdata.mod.f.' 1000*mdata.mod.T2s.' 1000*mdata.mod.T1.'];
        set(gui.modeltable, 'Data', tdata)
        
        tdata = [5e-3; 1000; 0.5; 10];
        set(gui.MeasureParaTable, 'Data', tdata)  
        if isfield(kdata.measure,'pulsesequence')
            set(gui.sequenceType,'enable','on');
            switch kdata.measure.pulsesequence
                case 'FID'
                   set(gui.sequenceType,'Value', 1);
                   set(gui.TauParaTable,'enable','off');
                    set(gui.modelAddTau,'enable','off');
                    set(gui.modelRemTau,'enable','off');
                case 'T1'
                    set(gui.sequenceType,'Value', 2);
                    set(gui.TauParaTable,'enable','on');
                    set(gui.modelAddTau,'enable','on');
                    set(gui.modelRemTau,'enable','on');
                case 'T2'
                    set(gui.sequenceType,'Value', 3);
                    set(gui.TauParaTable,'enable','on');
                    set(gui.modelAddTau,'enable','on');
                    set(gui.modelRemTau,'enable','on');
            end
        else
            msgbox('old kernel please re-calculate!');
        end
        set(gui.Run, 'Enable', 'on')    

    end


%% Pushbutton RUN ---------------------------------------------------------
    function onPushbuttonRun(a,b)
        switch get(gui.sequenceType,'value')
            case 1 % FID
                mrs_setguistatus(gui,1,'Modelling')
                kdata.measure.pulsesequence = 1; %'FID';
                kdata.KT1 = [];
                mdata     = mrs_ForwardModelling(mdata,kdata);
                mrs_Modelling_plotdata(gui, mdata, kdata)
                mrs_setguistatus(gui,0)
            case 2 % T1
                % check kernel
                if ~isempty(kdata.B1)
                    mrs_setguistatus(gui,1,'Preparing kernel for T1')
                    kdata.measure.pulsesequence = 2;% 'T1';
                    kdata.earth.T1  = mdata.mod.T1(1)*ones(size(kdata.model.z));
                    for lay=2:length(mdata.mod.T1)
                        kdata.earth.T1(kdata.model.z > mdata.mod.zlayer(lay)) = mdata.mod.T1(lay);
                    end
                    kdata.earth.type = 2;
                    %                 mdata.mod.tau    = logspace(log10(0.01),log10(10),20);
                    kdata.measure.taud = mdata.mod.tau;
                    % calculate the kernel for T1
                    [kdata.KT1TauAll]  = MakeKernel(kdata.loop, ...
                        kdata.model, ...
                        kdata.measure, ...
                        kdata.earth,...
                        kdata.B1);
                    
                    for nTau=1:length(mdata.mod.tau)
                        mrs_setguistatus(gui,1,['Modelling tau = ' num2str(mdata.mod.tau(nTau))])
                        kdata.KT1      = kdata.KT1TauAll    (1+(nTau-1)*length(kdata.measure.pm_vec):nTau*length(kdata.measure.pm_vec),:);
                        mdata.mod.ctau = mdata.mod.tau(nTau);
                        zwerg          = mrs_ForwardModelling(mdata,kdata);
                        mdataTau(nTau).dat = zwerg.dat;
                        mdataTau(nTau).mod = zwerg.mod;
                    end
                    mrs_ModellingT1_plotdata(gui, mdataTau, kdata)
                    mrs_setguistatus(gui,0)
                else
                    msgbox([{'Kernel does not allow for T1 modeling'};...
                        {'Include double pulse into kernel calculation (checkbox in MRSKernel)'}])
                end
            case 3 % T2
                mrs_setguistatus(gui,1,'Modelling')
                kdata.measure.pulsesequence = 3;% 'T2';
                kdata.KT1 = [];
                mdata     = mrs_ForwardModelling(mdata,kdata);
                mrs_Modelling_plotdata(gui, mdata, kdata)
                mrs_setguistatus(gui,0)
        end
    end

%% onPulseSequence
    function onPulseSequence(a,b)
        switch get(gui.sequenceType,'value')
            case 1
                set(gui.sequenceType,'Value', 1);
                set(gui.TauParaTable,'enable','off');
                set(gui.modelAddTau,'enable','off');
                set(gui.modelRemTau,'enable','off');
            case 2
                set(gui.sequenceType,'Value', 2);
                set(gui.TauParaTable,'enable','on');
                set(gui.modelAddTau,'enable','on');
                set(gui.modelRemTau,'enable','on');
            case 3
                set(gui.sequenceType,'Value', 3);
                set(gui.TauParaTable,'enable','on');
                set(gui.modelAddTau,'enable','on');
                set(gui.modelRemTau,'enable','on');
        end
    end

%% onModTabCellEdt ---------------------------------------------------------
    function onModTabCellEdt(hTable, EdtData)
        switch EdtData.Indices(2)
            case 2
                mdata.mod.zlayer(EdtData.Indices(1)+1) = EdtData.NewData;
            case 3
                mdata.mod.f(EdtData.Indices(1)) = EdtData.NewData/100;
            case 4
                mdata.mod.T2s(EdtData.Indices(1)) = EdtData.NewData/1000;
            case 5
                mdata.mod.T1(EdtData.Indices(1)) = EdtData.NewData/1000;
        end
        
    end
%% onMeasTabCellEdt -------------------------------------------------------
    function onMeasTabCellEdt(hTable, EdtData)
        zwerg = get(hTable,'Data');
         
        mdata.mod.tfid1  = zwerg(1):1/zwerg(2):zwerg(3);
        mdata.mod.tfid2  = zwerg(1):1/zwerg(2):zwerg(3);
        mdata.mod.noise  = zwerg(4)*1e-9;

    end

%% ADD- / REMOVE LAYERS ---------------------------------------------------
    function onAddLayer(a,b)
        mdata.mod.Nlayer = mdata.mod.Nlayer+1;
        if mdata.mod.Nlayer>1
            set(gui.modelRemLayer, 'Enable', 'on');
        else
            set(gui.modelRemLayer, 'Enable', 'off');
        end
        mdata.mod.zlayer = [mdata.mod.zlayer kdata.model.zmax];
        mdata.mod.f      = [mdata.mod.f mdata.mod.f(end)];
        mdata.mod.T2s    = [mdata.mod.T2s mdata.mod.T2s(end)];
        mdata.mod.T1     = [mdata.mod.T1 mdata.mod.T1(end)];
        tdata = [(1:mdata.mod.Nlayer).' mdata.mod.zlayer(2:end).' 100*mdata.mod.f.' 1000*mdata.mod.T2s.' 1000*mdata.mod.T1.'];
        set(gui.modeltable, 'Data', tdata)
    end

    function onRemoveLayer(a,b)
        mdata.mod.Nlayer = mdata.mod.Nlayer-1;
        if mdata.mod.Nlayer>1
            set(gui.modelRemLayer, 'Enable', 'on');
        else
            set(gui.modelRemLayer, 'Enable', 'off');
        end
        mdata.mod.zlayer(end-1) = [];
        mdata.mod.f(end)        = [];
        mdata.mod.T2s (end)     = [];
        mdata.mod.T1(end)       = [];
        tdata = [(1:mdata.mod.Nlayer).' mdata.mod.zlayer(2:end).' 100*mdata.mod.f.' 1000*mdata.mod.T2s.' 1000*mdata.mod.T1.'];
        set(gui.modeltable, 'Data', tdata)
    end

%% ADD- / REMOVE Tau ---------------------------------------------------
    function onTauTabCellEdt(hTable, EdtData)
        mdata.mod.tau=get(gui.TauParaTable,'Data');
    end
    function onIncludeT1(a,b)
        if get(gui.IncludeT1,'Value')
            set(gui.TauParaTable,'Visible','on','Enable','on')
            set(gui.modelAddTau,'Visible','on','Enable','on')
            set(gui.modelRemTau,'Visible','on','Enable','on')
        else
            set(gui.TauParaTable,'Visible','on','Enable','off')
            set(gui.modelAddTau,'Visible','on','Enable','off')
            set(gui.modelRemTau,'Visible','on','Enable','off')
        end
    end
    function onAddTau(a,b)
        mdata.mod.nTau = mdata.mod.nTau+1;
        if mdata.mod.nTau>1
            set(gui.modelRemTau, 'Enable', 'on');
        else
            set(gui.modelRemTau, 'Enable', 'off');
        end
        mdata.mod.tau = [mdata.mod.tau 10];
        identTau(mdata.mod.nTau) = {num2str(mdata.mod.nTau)};
        widthTau{mdata.mod.nTau} = 40;
        set(gui.TauParaTable, ...
            'ColumnName',identTau, ...
            'ColumnWidth', widthTau, ...
            'Data',[mdata.mod.tau]);
    end
    function onRemoveTau(a,b)
        mdata.mod.nTau = mdata.mod.nTau-1;
        if mdata.mod.nTau>1
            set(gui.modelRemTau, 'Enable', 'on');
        else
            set(gui.modelRemTau, 'Enable', 'off');
        end
        mdata.mod.tau(end) = [];
        identTau={};widthTau={};
        for nTau=1:mdata.mod.nTau
            identTau(nTau) = {num2str(nTau)};
            widthTau{nTau} = 40;
        end
        set(gui.TauParaTable, ...
            'ColumnName',identTau, ...
            'ColumnWidth', widthTau, ...
            'Data',[mdata.mod.tau]);
    end

%% SAVE ---------------------------------------------------
    function onSave(a,call)
        if ~isnumeric(call)% workaround for matlab 2014b
            call=0;
        end
        mrs_setguistatus(gui,1,'save data')
        if call
            % file from nargin
            [filepath,filename]    = fileparts(kernel_pathdirfile);
            in=load([kernel_pathdirfile(1:end-5) '.mrsp'],'-mat');
            mrsproject = in.mrsproject;
        else
            % create mrsproject files
            % [kpath,kfilename]    = fileparts(kernel_pathdirfile);
%            filepath             = uigetdir(kpath,'select folder to save data');
            [filename,filepath] = uiputfile({...
                 '*.mrsp','MRSProject file'; '*.*','All Files' },...
                 'Save MRSProject file',...
                 [kernel_pathdirfile(1:end-5) '.mrsp']);
            if filepath == 0;
                disp('Aborting...'); return;
            end
            mrsproject.path      = filepath;
            mrsproject.file      = filename;
            mrsproject.data      = struct();    % reset
            mrsproject.kernel    = struct();    % reset
            mrsproject.inversion = struct();    % reset
        end
        
        % set folder name
        basename = filename(1:end-5);
        
        % save as *.mrsd for compatibility with all other modules 
        % check for T1
        switch get(gui.sequenceType,'value')
            case 1 %FID
        %if ~get(gui.IncludeT1,'Value') % only one file has to be saved
            mrsproject.data(1).status   = 15;
            mrsproject.data(1).file     = [basename '.mrsd'];
            mrsproject.data(1).dir      = [basename];
            mrsproject.kernel(1).status = 1;
            mrsproject.kernel(1).file   = [basename '.mrsk'];
            mrsproject.kernel(1).dir    = [basename];
            mrsproject.inversion(1).status = 0;
            mkdir(mrsproject.path,mrsproject.data(1).dir)
            % save data
            proclog = mdata2proclog(mdata,kdata);
            outfile = [filepath filesep mrsproject.data(1).dir filesep mrsproject.data(1).file];
            proclog.status = 3;
            save(outfile,'proclog');
            fprintf(1,'proclog saved to %s\n', outfile);
            % save kernel
            outfile = [filepath filesep mrsproject.kernel(1).dir filesep mrsproject.kernel(1).file];
            save(outfile,'kdata');
            % save projectfile
            save([mrsproject.path mrsproject.file], 'mrsproject');
            mrs_updateinifile(outfile,1); 
         
            case 2 %T1    
        %else % a number of file has to be saved
            for iTau=1:length(mdata.mod.tau)
                mrsproject.data(iTau).status   = 15;
                mrsproject.data(iTau).file     = [basename 'Tau' num2str(mdata.mod.tau(iTau)) 's.mrsd'];
                mrsproject.data(iTau).dir      = [basename '_' num2str(iTau)];
                mrsproject.kernel(iTau).status = 1;
                mrsproject.kernel(iTau).file   = [basename '.mrsk'];
                mrsproject.kernel(iTau).dir    = [basename '_'  num2str(iTau)];
                mrsproject.inversion(iTau).status = 0;
                mkdir(mrsproject.path,mrsproject.data(iTau).dir)
                % save data
                proclog = mdata2proclog(mdataTau(iTau),kdata);
                outfile = [filepath filesep mrsproject.data(iTau).dir filesep mrsproject.data(iTau).file];
                proclog.status = 3;
                save(outfile,'proclog');
                fprintf(1,'proclog saved to %s\n', outfile);
                % save kernel
                outfile = [filepath filesep mrsproject.kernel(iTau).dir filesep mrsproject.kernel(iTau).file];
                save(outfile,'kdata');
                % save projectfile
                save([mrsproject.path mrsproject.file], 'mrsproject');
                mrs_updateinifile(outfile,1);
            end
            case 3 %T2
                mrsproject.data(1).status   = 15;
                mrsproject.data(1).file     = [basename '.mrsd'];
                mrsproject.data(1).dir      = [basename];
                mrsproject.kernel(1).status = 1;
                mrsproject.kernel(1).file   = [basename '.mrsk'];
                mrsproject.kernel(1).dir    = [basename];
                mrsproject.inversion(1).status = 0;
                mkdir(mrsproject.path,mrsproject.data(1).dir)
                % save data
                proclog = mdata2proclog(mdata,kdata);
                outfile = [filepath filesep mrsproject.data(1).dir filesep mrsproject.data(1).file];
                proclog.status = 3;
                save(outfile,'proclog');
                fprintf(1,'proclog saved to %s\n', outfile);
                % save kernel
                outfile = [filepath filesep mrsproject.kernel(1).dir filesep mrsproject.kernel(1).file];
                save(outfile,'kdata');
                % save projectfile
                save([mrsproject.path mrsproject.file], 'mrsproject');
                mrs_updateinifile(outfile,1);
        end
        % save as *.mrsm for later review of modelling as ascii
        outfile = [filepath basename '.mrsm'];
        fid = fopen(outfile, 'w');
            a = ['Depth    ' 'WC   ' 'T2s   ' 'T1'];
            fprintf(fid, '%s \n', a);
            for nL=1:length(mdata.mod.f)
               fprintf(fid, '%.3f %3f %.3f %.3f\n', [mdata.mod.zlayer(nL+1) mdata.mod.f(nL) mdata.mod.T2s(nL) mdata.mod.T1(nL)]); 
            end
        fclose(fid);
        
        mrs_setguistatus(gui,0)
    end

    function onSaveAndQuit(a,b)
        onSave(a,kernel_pathdirfile)
        
        mfig = findobj('Name', 'MRS Modelling - Model Parameter Table');
        if ~isempty(mfig)
            delete(mfig)
        end
        mfig = findobj('Name', 'MRS Modelling - Model Parameter Graphs');
        if ~isempty(mfig)
            delete(mfig)
        end
        mfig = findobj('Name', 'MRS Modelling - Data Sounding');
        if ~isempty(mfig)
            delete(mfig)
        end
        mfig = findobj('Name', 'MRS Modelling - Data QT-cube');
        if ~isempty(mfig)
            delete(mfig)
        end
        welldone = 1;
    end
    function onQuitWithoutSave(a,b)
        mfig = findobj('Name', 'MRS Modelling - Model Parameter Table');
        if ~isempty(mfig)
            delete(mfig)
        end
        mfig = findobj('Name', 'MRS Modelling - Model Parameter Graphs');
        if ~isempty(mfig)
            delete(mfig)
        end
        mfig = findobj('Name', 'MRS Modelling - Data Sounding');
        if ~isempty(mfig)
            delete(mfig)
        end
        mfig = findobj('Name', 'MRS Modelling - Data QT-cube');
        if ~isempty(mfig)
            delete(mfig)
        end
        welldone = 0;
    end

if standalone == 0
    uiwait(gui.panel_controls.figureid)
end

end