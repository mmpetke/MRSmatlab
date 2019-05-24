function invfilename = MRSQTInversion(datafile,kernelfile,invfile)
ifig = findobj('Name', 'MRS QT Inversion');
if ~isempty(ifig)
    delete(ifig)
end
ifig = findobj('Name', 'MRS QT Inversion - Data');
if ~isempty(ifig)
    delete(ifig)
end
ifig = findobj('Name', 'MRS QT Inversion - Model');
if ~isempty(ifig)
    delete(ifig)
end

% set global structures
gui      = createInterface();
idata    = struct();


if nargin > 0   % i.e. command comes from MRSWorkflow
    standalone = 0;
    onLoadData(0,1);
    onLoadKernel(0,1);
    if ~isempty(invfile)
        onLoadInv(0,1)
        [path,name,ext] = fileparts(invfile);
        invfilename = [name ext];       
    else
        [path,name] = fileparts(datafile);
        ext         = '.mrsi';
        invfilename = [name ext];
    end
else
    standalone = 1;
end

    function gui = createInterface()       
        gui = struct();
        screensz = get(0,'ScreenSize');
          %% CREATE FIGURES
        gui.fig_data = figure( ...
            'Position', [5+355+405 screensz(4)-765 500 720], ...
            'Name', 'MRS QT Inversion - Data', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'Toolbar', 'figure', ...
            'HandleVisibility', 'on');
        gui.fig_model = figure( ...
            'Position', [5+355 screensz(4)-765 400 720], ...
            'Name', 'MRS QT Inversion - Model', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'Toolbar', 'figure', ...
            'HandleVisibility', 'on');
        
        %% GENERATE CONTROLS PANEL ----------------------------------------
        gui.panel_controls.figureid = figure( ...
            'Name', 'MRS QT Inversion', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'Toolbar', 'none', ...
            'HandleVisibility', 'on'); % enable shortcuts
        
        set(gui.panel_controls.figureid, 'Position', [5 screensz(4)-775 350 735])
        
        % Set default panel settings
        %uiextras.set(gui.panel_controls.figureid, 'DefaultBoxPanelFontSize', 12);
        %uiextras.set(gui.panel_controls.figureid, 'DefaultBoxPanelFontWeight', 'bold')
        %uiextras.set(gui.panel_controls.figureid, 'DefaultBoxPanelPadding', 5)
        %uiextras.set(gui.panel_controls.figureid, 'DefaultHBoxPadding', 2)
        
        %% MAKE MENU
        % + Quit menu
        gui.QuitMenu = uimenu(gui.panel_controls.figureid, 'Label', 'Quit');
        uimenu(gui.QuitMenu, ...
            'Label', 'Save and Quit', ...
            'Callback', @onSaveAndQuit, ...
            'Enable', 'on');
        uimenu(gui.QuitMenu,...
            'Label', 'Quit without saving',...
            'Callback', @onQuitWithoutSave);
        
        % + File menu
        gui.FileMenu = uimenu(gui.panel_controls.figureid, 'Label', 'File');
        uimenu(gui.FileMenu, 'Label', 'Load Data',   'Callback', @onLoadData);
        uimenu(gui.FileMenu, 'Label', 'Load Kernel', 'Callback', @onLoadKernel);
        uimenu(gui.FileMenu, 'Label', 'Load Inversion',   'Callback', @onLoadInv);
        uimenu(gui.FileMenu, 'Label', 'Save Data', 'Callback', @onSaveData);
        
        
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
        vboxFH1   = uiextras.HBox('Parent', vboxF); 
        uicontrol('Style', 'Text','HorizontalAlignment', 'left', 'String', 'Data file','Parent', vboxFH1)
        gui.panel_controls.edit_dataPath = uicontrol(...
            'Style', 'Edit', ...
            'Parent', vboxFH1, ...
            'Enable', 'on', ...
            'BackgroundColor', [1 1 1], ...
            'String', '(Data path)', ...
            'Callback', @onEditDataPath);
        set(vboxFH1, 'Sizes',[80 -1])
        vboxFH2   = uiextras.HBox('Parent', vboxF);
        uicontrol('Style', 'Text', 'HorizontalAlignment', 'left','String', 'Kernel file','Parent', vboxFH2)
        gui.panel_controls.edit_kernelPath = uicontrol(...
            'Style', 'Edit', ...
            'Parent', vboxFH2, ...
            'Enable', 'on', ...
            'BackgroundColor', [1 1 1], ...
            'String', '(Kernel path)', ...
            'Callback', @onEditKernelPath);
        set(vboxFH2, 'Sizes',[80 -1])
        vboxFH3   = uiextras.HBox('Parent', vboxF);
        uicontrol('Style', 'Text', 'HorizontalAlignment', 'left', 'String', 'Inversion File','Parent', vboxFH3)
        gui.panel_controls.edit_invPath = uicontrol(...
            'Style', 'Edit', ...
            'Parent', vboxFH3, ...
            'Enable', 'on', ...
            'BackgroundColor', [1 1 1], ...
            'String', '(Inversion path)', ...
            'Callback', @onEditInvPath);
        set(vboxFH3, 'Sizes',[80 -1])
        vboxFH4   = uiextras.HBox('Parent', vboxF);
        uicontrol('Style', 'Text', 'HorizontalAlignment', 'left', 'String', 'Status','Parent', vboxFH4)
        gui.panel_controls.edit_status = uicontrol(...
            'Style', 'Edit', ...
            'Parent', vboxFH4, ...
            'Enable', 'off', ...
            'BackgroundColor', [0 1 0], ...
            'String', 'Idle...');
        set(vboxFH4, 'Sizes',[80 -1])
        uicontrol('Style', 'Text', 'HorizontalAlignment', 'left', 'String', ' ','Parent', vboxF)
        set(vboxF, 'Sizes',[30 30 30 30 10])
        
        
        %% Settings box
        boxS  = uiextras.BoxPanel('Parent', mainbox, 'Title', 'Settings', 'TitleColor', [0 0.75 1]);
        vboxS = uiextras.VBox('Parent', boxS);
        
        % Data Space
        DataSpace  = uiextras.VBox('Parent', vboxS);
        uicontrol('Style', 'Text', ...
                'Parent', DataSpace, 'Background', [0.69 0.93 0.93],...
                'HorizontalAlignment', 'left',...
                'String', 'Data Space');
        h0DataSpace  = uiextras.HBox('Parent', DataSpace);
        uicontrol('Style', 'Text', ...
            'Parent', h0DataSpace, ...
            'HorizontalAlignment', 'left',...
            'String', 'Channel');
        gui.para.datachannel = uicontrol('Style', 'popupmenu', ...
            'Parent', h0DataSpace, ...
            'String', {'1'},...
            'Value', 1, ...
            'Callback', @onDataChannel);
        set(h0DataSpace, 'Sizes',[-1 50]) 
        h01DataSpace  = uiextras.HBox('Parent', DataSpace);
        uicontrol('Style', 'Text', ...
            'Parent', h01DataSpace, ...
            'HorizontalAlignment', 'left',...
            'String', 'Signal');
        gui.para.datasignal = uicontrol('Style', 'popupmenu', ...
            'Parent', h01DataSpace, ...
            'String', {'fid','cpmg'},...
            'Value', 1, ...
            'Callback', @onDataSignal);
        set(h01DataSpace, 'Sizes',[-1 100]) 
        h1DataSpace  = uiextras.HBox('Parent', DataSpace);
        uicontrol('Style', 'Text', ...
            'Parent', h1DataSpace, ...
            'HorizontalAlignment', 'left',...
            'String', 'Dataspace');
        gui.para.datatype = uicontrol('Style', 'popupmenu', ...
            'Parent', h1DataSpace, ...
            'String', {'amplitude', 'rotated complex','complex'},...
            'Value', 1, ...
            'Callback', @onDataType);
        set(h1DataSpace, 'Sizes',[-1 200]) 
        h2DataSpace  = uiextras.HBox('Parent', DataSpace);
        gui.para.gateIntegration = uicontrol('Style', 'checkbox', ...
            'Parent', h2DataSpace, ...
            'String','Gate Integration --> N logspaced gates',...
            'Value', 1, ...
            'Callback', @onGateIntegration);
        gui.para.nGates = uicontrol('Style','Edit','Enable','on',...
             'String','50',...
             'parent',h2DataSpace,...
             'Callback', @onGateIntegrationChangeNumber);
        set(h2DataSpace, 'Sizes',[-1 50])
        h3DataSpace  = uiextras.HBox('Parent', DataSpace);
%         gui.para.buttonGetInstrumentPhase = uicontrol('Style', 'pushbutton', ...
%             'HorizontalAlignment', 'center', ...
%             'Parent', h3DataSpace, ...
%             'String', 'Get instrument phase',...
%             'Callback',@onPushbuttonGetInstrumentPhase);
        uicontrol('Style','Text',...
             'String','Instrument Phase', 'HorizontalAlignment', 'left',...
             'parent',h3DataSpace);
        gui.para.instPhase = uicontrol('Style','Edit',...
             'String','0',...
             'parent',h3DataSpace,...
            'Callback',@onGetInstrumentPhaseChange);
        set(h3DataSpace, 'Sizes',[-1  50])
        h4DataSpace  = uiextras.HBox('Parent', DataSpace);
        gui.para.buttonCheckQ = uicontrol('Style', 'pushbutton', ...
            'HorizontalAlignment', 'center', ...
            'Parent', h4DataSpace, ...
            'String', 'Active/ Inactive qs',...
            'Callback',@onPushbuttonCheckQ);
        uicontrol('Style','Text','String','','parent',h4DataSpace);
        set(h4DataSpace, 'Sizes',[200 -1])            
        set(DataSpace, 'Sizes',[20 25 25 25 25 25 25]) 
        
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
            'String', {'smooth - distribution','smooth - mono','block - mono'},...
            'Value', 2, ...
            'Callback', @onSolType);
        set(h1ModelSpace, 'Sizes',[-1 200])
        h2ModelSpace  = uiextras.HBox('Parent', ModelSpace);        
        uicontrol('Style','Text','String','T2* (min/max/number)',...
                'HorizontalAlignment', 'left',...
                'parent',h2ModelSpace); 
        gui.para.decaySpecMin = uicontrol('Style','Edit','String','0.005',...
                        'parent',h2ModelSpace,'BackgroundColor', [1 1 1]);             
        gui.para.decaySpecMax = uicontrol('Style','Edit','String','0.5',...
                        'parent',h2ModelSpace,'BackgroundColor', [1 1 1]);
        gui.para.decaySpecN = uicontrol('Style','Edit','String','30',...
                        'parent',h2ModelSpace,'BackgroundColor', [1 1 1],'Enable','off');
        set(h2ModelSpace, 'Sizes',[-1 50 50 50])    
        h3ModelSpace  = uiextras.HBox('Parent', ModelSpace); 
        uicontrol('Style','Text','String','water content (min/max)',...
                'HorizontalAlignment', 'left',...
                'parent',h3ModelSpace);
        gui.para.lowerboundWater = uicontrol('Style','Edit','String','0.0',...
                        'parent',h3ModelSpace,'BackgroundColor', [1 1 1],'Enable','on');
        gui.para.upperboundWater = uicontrol('Style','Edit','String','0.5',...
                        'parent',h3ModelSpace,'BackgroundColor', [1 1 1]);
        uicontrol('Style','Text','String','','parent',h3ModelSpace); %empty           
        set(h3ModelSpace, 'Sizes',[-1 50 50 50]) 
        h4ModelSpace  = uiextras.HBox('Parent', ModelSpace); 
        gui.para.modelDiscretisationText = uicontrol('Style','Text','String','min. layer thickness/m',...
                'HorizontalAlignment', 'left',...
                'parent',h4ModelSpace);
        gui.para.GAthkMin = uicontrol('Style','Edit','String','2', 'Visible','off',...
                'parent',h4ModelSpace,'BackgroundColor', [1 1 1]);
        gui.para.GAthkMax = uicontrol('Style','Edit','String','20','Visible','off',...
                'parent',h4ModelSpace,'BackgroundColor', [1 1 1]);
        gui.para.modelDiscretisation = uicontrol('Style','Edit','String','0.5',...
                'parent',h4ModelSpace,'BackgroundColor', [1 1 1]);            
        set(h4ModelSpace, 'Sizes',[-1 50 50 50]) 
        h5ModelSpace  = uiextras.HBox('Parent', ModelSpace); 
        gui.para.modelMaxDepthText = uicontrol('Style','Text','String','max. depth/m',...
                'HorizontalAlignment', 'left',...
                'parent',h5ModelSpace);
        gui.para.GALayerPresets = uicontrol('Style', 'pushbutton', 'Visible','off',...
            'HorizontalAlignment', 'center', 'Parent', h5ModelSpace, ...
            'String', 'layer presets','Callback',@onPushbuttonGALayerGUI);
        uicontrol('Style','Text','String',' ','parent',h5ModelSpace);
        gui.para.GAnLay = uicontrol('Style','Edit','String','5','Visible','off',...
                'parent',h5ModelSpace,'BackgroundColor', [1 1 1]);      
        gui.para.modelMaxDepth = uicontrol('Style','Edit','String','-',...
                'parent',h5ModelSpace,'BackgroundColor', [1 1 1]);            
        set(h5ModelSpace, 'Sizes',[-1 100 50 50 50]) 
        set(ModelSpace, 'Sizes',[20 25 25 25 25 25]) 
        
        % Regularisation
        Regularisation  = uiextras.VBox('Parent', vboxS);
        uicontrol('Style', 'Text', ...
                'Parent', Regularisation, 'Background', [0.69 0.93 0.93],...
                'HorizontalAlignment', 'left',...
                'String', 'Regularisation'); 
        h1Regularisation  = uiextras.HBox('Parent', Regularisation);
        uicontrol('Style','Text','String','Partial Water Content (PWC)',...
                        'parent',h1Regularisation,'HorizontalAlignment', 'left');
        gui.para.regtypeFixV = uicontrol('Style','Edit','String','1',...
                        'parent',h1Regularisation,'BackgroundColor', [1 1 1],'Enable','off');
        h2Regularisation  = uiextras.HBox('Parent', Regularisation);
        uicontrol('Style','Text','String','WaterContent / T2*',...
                        'parent',h2Regularisation,'HorizontalAlignment', 'left');
        gui.para.regtypeMonoWC = uicontrol('Style','Edit','String','1000',...
                        'parent',h2Regularisation,'BackgroundColor', [1 1 1],'Enable','on'); 
        gui.para.regtypeMonoT2 = uicontrol('Style','Edit','String','1000',...
                        'parent',h2Regularisation,'BackgroundColor', [1 1 1],'Enable','on'); 
        set(h1Regularisation, 'Sizes',[-1 50])  
        set(h2Regularisation, 'Sizes',[-1 50 50])
        gui.para.struCoupling = uicontrol('Style', 'checkbox', ...
            'Parent', Regularisation, ...
            'String','Structural coupling of WaterContent and T2*',...
            'Value', 1, 'Enable','on');
        uicontrol('Style', 'Text','Parent', Regularisation,'String','');
        set(Regularisation, 'Sizes',[20 25 25 25 10])
        
        % Termination criteria
        Termination  = uiextras.VBox('Parent', vboxS);
        uicontrol('Style', 'Text', ...
                'Parent', Termination, 'Background', [0.69 0.93 0.93],...
                'HorizontalAlignment', 'left',...
                'String', 'Termination criteria/ Statistics');       
        h1Termination  = uiextras.HBox('Parent', Termination); 
        uicontrol('Style','Text','String','max. iterations',...
                'HorizontalAlignment', 'left',...
                'parent',h1Termination);
        gui.para.maxIteration = uicontrol('Style','Edit','String','10',...
                        'parent',h1Termination,'BackgroundColor', [1 1 1]);
        set(h1Termination, 'Sizes',[-1 50]) 
        h21Termination  = uiextras.HBox('Parent', Termination); 
        gui.para.minModelUpdateText = uicontrol('Style','Text','String','min. model update',...
                'HorizontalAlignment', 'left','Visible','off',...
                'parent',h21Termination);
        gui.para.minModelUpdate = uicontrol('Style','Edit','String','1e-4',...
                        'parent',h21Termination,'BackgroundColor', [1 1 1],'Enable','off','Visible','off','Callback',@selectChi_min); 
        set(h21Termination, 'Sizes',[-1 50])
        h22Termination  = uiextras.HBox('Parent', Termination);
        gui.para.PopulationText = uicontrol('Style','Text','String','members per and number of populations',...
                'HorizontalAlignment', 'left','Visible','off',...
                'parent',h22Termination);
        gui.para.membersOfPop = uicontrol('Style','Edit','String','5000',...
                        'parent',h22Termination,'BackgroundColor', [1 1 1],'Enable','off','Visible','off');     
        gui.para.numbersOfPop = uicontrol('Style','Edit','String','1',...
                        'parent',h22Termination,'BackgroundColor', [1 1 1],'Enable','off','Visible','off'); 
        set(h22Termination, 'Sizes',[-1 50 50])
        h3Termination  = uiextras.HBox('Parent', Termination); 
        gui.para.statisticRunsText = uicontrol('Style','Text','String','number of statistic runs (bootstraps)',...
                'HorizontalAlignment', 'left',...
                'parent',h3Termination);
        gui.para.GAstatistic = uicontrol('Style','Edit','String','1',...
                        'parent',h3Termination,'BackgroundColor', [1 1 1],'visible','off'); 
        gui.para.statisticRuns = uicontrol('Style','Edit','String','0',...
                        'parent',h3Termination,'BackgroundColor', [1 1 1],'Enable','on'); 
        set(h3Termination, 'Sizes',[-1 50 50])
        set(Termination, 'Sizes',[20 25 25 25 25])
              
        set(vboxS, 'Sizes',[175 -1 90 120])
        
        %empty
        vboxempty = uiextras.VBox('Parent', mainbox);
        
        % run
        Run     = uiextras.VBox('Parent', mainbox);
        h1Run = uiextras.HBox('Parent', Run); 
        gui.vboxRun.Start = uicontrol(...
            'Style', 'pushbutton', ...
            'HorizontalAlignment', 'center', ...
            'Background', [0.00 0.90 0.50],...
            'Parent', h1Run, ...
            'String', 'Run',...
            'Callback',@on_pushbuttonRun);
        gui.vboxRun.StartLCurve = uicontrol(...
            'Style', 'pushbutton', ...
            'HorizontalAlignment', 'center', ...
            'Background', [0.00 0.90 0.50],...
            'Parent', h1Run, ...
            'String', 'Run L-Curve',...
            'Callback',@on_pushbuttonRun_Lcurve);
        set(h1Run, 'Sizes',[-1 -1])
        set(mainbox, 'Sizes',[150 550 -1 40])
         
      
    end

%% FUNCTION onLoadData ----------------------------------------------------    
    function onLoadData(a,call)
        if ~isnumeric(call)% workaround for matlab 2014b
            call=0;
        end
        mrs_setguistatus(gui,1,'Loading data...')
        if call 
            % datafile comes from nargin(1)
        else
            inifile = mrs_readinifile;  % read ini file and get last .mrsd file (if exist)
            if strcmp(inifile.MRSData.file,'none') == 1
                inifile.MRSData.path = [pwd filesep];
                inifile.MRSData.file = 'mrs_project';
            end
            [file.soundingname, file.soundingpath] = uigetfile(...
                    {'*.mrsd','MRSData File (*.mrsd)';
                    '*.*',  'All Files (*.*)'}, ...
                    'Pick a MRSData file',...
                    [inifile.MRSData.path]); 
            datafile = [file.soundingpath,file.soundingname];  
            mrs_updateinifile(datafile,1);
        end
        set(gui.panel_controls.edit_dataPath,'String',datafile)

        in = load(datafile, '-mat');
        proclog = in.proclog;
        
        % check version
        savedversion    = proclog.MRSversion;
%         softwareversion = mrs_version;
        if ~isequal(savedversion,mrs_version)
            msgbox('The selected .mrsd-file is outdated. Running MRSUpdate is recommended.','Outdated .mrsd file')
            mrs_setguistatus(gui,0)
        end
        
        clear in;
        iChannel = get(gui.para.datachannel,'Value');
        iSig     = get(gui.para.datasignal,'Value')*2;
        % block signal switch if sig not recorded
        if proclog.Q(1).rx(iChannel).sig(iSig).recorded == 0
            set(gui.para.datasignal, 'Value',1);
            iSig=2;
        end
        
        factor   = 1; % circular!
        %iChannel=4; factor=5.5; % factor for squids!
        if isfield(idata,'data');idata = rmfield(idata,'data');end;
        idata.data.q         = zeros(length(proclog.Q),1);
        idata.data.efit      = zeros(length(proclog.Q),1);
        idata.data.estack    = zeros(length(proclog.Q),1);
        idata.data.V0fit     = zeros(length(proclog.Q),1);
        idata.data.T2sfit    = zeros(length(proclog.Q),1);
        idata.data.df        = zeros(length(proclog.Q),1);
        idata.data.phi       = zeros(length(proclog.Q),1);
        
        switch iSig
            case 2% FID
                % check if there has been trim during fit and get indices
                [minRecInd, maxRecInd] = mrs_gettrim(proclog,1,1,iSig);
                idata.data.dcubeRaw    = zeros(length(proclog.Q),length(proclog.Q(1).rx(iChannel).sig(iSig).t(minRecInd:maxRecInd)));
                % tRaw shold start with zero
                idata.data.tRaw      = proclog.Q(1).rx(iChannel).sig(iSig).t(minRecInd:maxRecInd) - proclog.Q(1).rx(1).sig(iSig).t(minRecInd);
                % effective dead time should include all (hardware deadtime + RDP + trim)
                idata.data.effDead   = proclog.Q(1).timing.tau_dead1  + ...
                                       0.5*proclog.Q(1).timing.tau_p1 + ...
                                       proclog.Q(1).rx(iChannel).sig(iSig).t(minRecInd);

                for m = 1:length(proclog.Q)
                    idata.data.q(m)       = proclog.Q(m).q;
                    % error estimation using the mono-fit (mrs_fitFID.m)
                    %idata.data.efit(m)    = proclog.Q(m).rx(iChannel).sig(2).fite.E;
                    % error estimation using stacking (mrsSigPro_stack.m)
%                     idata.data.estack(m)  = proclog.Q(m).rx(1).sig(2).fite.E;
                    idata.data.estack(m)  = real(mean(proclog.Q(m).rx(iChannel).sig(iSig).E));
                    idata.data.V0fit(m)   = proclog.Q(m).rx(iChannel).sig(iSig).fitc(1);
                    idata.data.T2sfit(m)  = proclog.Q(m).rx(iChannel).sig(iSig).fitc(2);
                    idata.data.df(m)      = proclog.Q(m).rx(iChannel).sig(iSig).fitc(3);
                    idata.data.phi(m)     = proclog.Q(m).rx(iChannel).sig(iSig).fit(4);
                    idata.data.dcubeRaw(m,:) = proclog.Q(m).rx(iChannel).sig(iSig).V(minRecInd:maxRecInd).*factor;
                end
            case 4 %T2
                idata.data.dcubeRaw    = zeros(length(proclog.Q),proclog.Q(1).rx(iChannel).sig(iSig).nE);
                % tRaw shold start with zero
                idata.data.tRaw      = proclog.Q(1).rx(iChannel).sig(iSig).echotimes - proclog.Q(1).rx(1).sig(iSig).echotimes(1);
                % effective dead time should include all (hardware deadtime + RDP + trim)
                idata.data.effDead   = proclog.Q(1).rx(1).sig(iSig).echotimes(1);
                for m = 1:length(proclog.Q)
                    idata.data.q(m)       = proclog.Q(m).q;
                    idata.data.estack(m)  = (mean(proclog.Q(m).rx(iChannel).sig(iSig).fite));
                    idata.data.V0fit(m)   = 1;
                    idata.data.T2sfit(m)  = 1;
                    idata.data.df(m)      = 0;
                    idata.data.phi(m)     = 0;
                    idata.data.dcubeRaw(m,:) = proclog.Q(m).rx(iChannel).sig(iSig).fit(2:end).*factor;
                end
        end
        
        if ~standalone        
        end
        
        % find out number of channels and pipe to rx menu
        set(gui.para.datachannel,'String',num2str((1:length(proclog.rxinfo))'))
        set(gui.para.datachannel,'Value',iChannel);
        
        idata = mrs_invQTGetGuiPara(gui,idata);
        idata = mrs_invQTpreparation(idata);   
        
        mrsInvQT_plotData(gui,idata);
        mrs_setguistatus(gui,0)
    end

%% FUNCTION onLoadKernel --------------------------------------------------
    function onLoadKernel(a,call)
        if ~isnumeric(call)% workaround for matlab 2014b
            call=0;
        end
        mrs_setguistatus(gui,1,'Loading kernel...')
        if call
            % kernelfile comes from nargin(2)
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
            kernelfile = [file.kernelpath,file.kernelname];
        end
        
        
        
        in                = load(kernelfile, '-mat');
        if isfield(idata,'kernel');idata = rmfield(idata,'kernel');end;
        idata.kernel.K    = in.kdata.K;
        idata.kernel.z    = in.kdata.model.z;
        idata.fn          = [];
        
        set(gui.panel_controls.edit_kernelPath,'String',kernelfile)
        set(gui.para.modelDiscretisation,'String',num2str(min(idata.kernel.z)))
        set(gui.para.modelMaxDepth,'String',num2str(max(idata.kernel.z)))
        
        mrs_setguistatus(gui,0)
    end
%% FUNCTION onLoadInv
    function onLoadInv(a,call)
        if ~isnumeric(call)% workaround for matlab 2014b
            call=0;
        end
        mrs_setguistatus(gui,1,'Loading Inversion Results...')
        if call
            % invfile comes from nargin(3)
        else
            inifile = mrs_readinifile;  % read ini file and get last .mrsd file (if exist)
            if strcmp(inifile.MRSData.file,'none') == 1
                inifile.MRSData.path = [pwd filesep];
                inifile.MRSData.file = 'mrs_project';
            end
            [invfilename,path] = uigetfile(...
                    {'*.mrsi','MRSInversion File (*.mrsi)';
                    '*.*',  'All Files (*.*)'}, ...
                    'Pick a MRSInversion file',...
                    [inifile.MRSData.path]);
            invfile = [path,invfilename];
        end
        
        in   = load(invfile, '-mat');
        if isfield(idata,'inv1Dqt');idata = rmfield(idata,'inv1Dqt');end;
        if isfield(idata,'para');idata = rmfield(idata,'para');end;
        idata.inv1Dqt = in.idata.inv1Dqt;
        idata.para    = in.idata.inv1Dqt.para;
        if isfield(in.idata,'inv1DT1');idata.inv1DT1=in.idata.inv1DT1;end;
        
        set(gui.panel_controls.edit_invPath,'String',invfile)
        % restore parameter
        set(gui.para.gateIntegration,'Value',idata.para.gates);
        set(gui.para.nGates,'String',num2str(idata.para.Ngates));
        set(gui.para.datatype,'Value',idata.para.dataType);
        set(gui.para.instPhase,'String',num2str(idata.para.instPhase));
        
        set(gui.para.regtypeFixV,'String',num2str(idata.para.regVec));
        set(gui.para.maxIteration,'String',num2str(idata.para.maxIteration));
        set(gui.para.minModelUpdate,'String',num2str(idata.para.minModelUpdate));
        set(gui.para.regtypeMonoWC,'String',num2str(idata.para.regMonoWC));
        set(gui.para.regtypeMonoT2,'String',num2str(idata.para.regMonoT2));
        set(gui.para.struCoupling,'value',idata.para.struCoupling);
        set(gui.para.statisticRuns,'String',num2str(idata.para.statisticRuns));
        
        set(gui.para.decaySpecMin,'String',num2str(idata.para.decaySpecMin));
        set(gui.para.decaySpecMax,'String',num2str(idata.para.decaySpecMax));
        set(gui.para.decaySpecN,'String',num2str(idata.para.decaySpecN));
        set(gui.para.upperboundWater,'String',num2str(idata.para.upperboundWater));
        set(gui.para.lowerboundWater,'String',num2str(idata.para.lowerboundWater));
        
        set(gui.para.modelDiscretisation,'String',num2str(idata.para.minThickness));
        set(gui.para.modelMaxDepth,'String',num2str(idata.para.maxDepth));
    
        set(gui.para.soltype, 'Value',idata.para.modelspace)
        onSolType();
        
        idata = mrs_invQTGetGuiPara(gui,idata);
        idata = mrs_invQTpreparation(idata);
        
        mrsInvQT_plotData(gui,idata);
        mrs_setguistatus(gui,0)
        
    end

%% RUN QTinversion Mono Smooth for L-Curve
    function on_pushbuttonRun_Lcurve(a,b)
       % clear last solution(s)
       if isfield(idata,'inv1Dqt')
           switch idata.para.modelspace
               case 2 %smooth-mono
                   if isfield(idata.inv1Dqt,'smoothMono')
                       idata.inv1Dqt = rmfield(idata.inv1Dqt,'smoothMono');
                   end
           end
       end
       idata = mrs_invQTGetGuiPara(gui,idata);
       idata = mrs_invQTpreparation(idata);
       
       lcurve = logspace(log10(100),log10(1000000),10);
       for nlc=1:length(lcurve)
           idata.para.regMonoWC = lcurve(nlc);
           idata.para.regMonoT2 = lcurve(nlc);
           
           idata = mrs_invQT1DMono(idata,1);
           
           dnorm(nlc) = idata.inv1Dqt.smoothMono.solution(1).dnorm;
           mnorm(nlc) = idata.inv1Dqt.smoothMono.solution(1).mnorm;
       end
       
       figure(111); hold on; xlabel('mnorm');ylabel('dnorm');grid on; title([{'l-curve', '(highest curvature --> optimal regularisation )'}])
       for nlc=1:length(lcurve)
        plot(mnorm(nlc),dnorm(nlc),'o')
        text(mnorm(nlc),dnorm(nlc),num2str(lcurve(nlc)));
       end
    end

%% RUN QTinversion
    function on_pushbuttonRun(a,b)
       % clear last solution(s)
       if isfield(idata,'inv1Dqt')
           switch idata.para.modelspace
               case 1 %smooth-multi
                   if isfield(idata.inv1Dqt,'smoothMulti')
                       idata.inv1Dqt = rmfield(idata.inv1Dqt,'smoothMulti');
                   end
               case 2 %smooth-mono
                   if isfield(idata.inv1Dqt,'smoothMono')
                       idata.inv1Dqt = rmfield(idata.inv1Dqt,'smoothMono');
                   end
               case 3 %block-mono
                   if isfield(idata.inv1Dqt,'blockMono')
                       idata.inv1Dqt = rmfield(idata.inv1Dqt,'blockMono');
                   end
           end
       end
       idata = mrs_invQTGetGuiPara(gui,idata);
       idata = mrs_invQTpreparation(idata);
       switch idata.para.modelspace
           case 1 %smooth-multi
              idata = mrs_invQT1D(idata); 
              mrsInvQT_plotData(gui,idata);
           case 2 %smooth-mono
               idata = mrs_invQT1DMono(idata,1+idata.para.statisticRuns);
               set(gui.para.instPhase,'String',num2str(round(100*idata.para.instPhase)/100));
               mrsInvQT_plotData(gui,idata);
           case 3 %block-mono
%               idata = mrs_invQT1DMonoBlockGA(idata,1);
              idata = mrs_invQT1DMonoBlockGA_multicore(idata);
              set(gui.para.instPhase,'String',num2str(round(100*idata.para.instPhase)/100));
              mrsInvQT_plotData(gui,idata);
       end 
       % bring figures back to focus
       figure(gui.fig_data)
       figure(gui.fig_model)
    end

%% GA Layer settings
    function onPushbuttonGALayerGUI(a,b)
        idata.para.layer = GALayerSettings(gui,idata);
    end
       

%% some other function
    function onPushbuttonGetInstrumentPhase(a,b)  
        switch idata.para.modelspace
            case 1 %smooth-multi
                if isfield(idata.inv1Dqt,'smoothMulti')
                    idata.inv1Dqt.solution = idata.inv1Dqt.smoothMulti.solution ;
                    idata.inv1Dqt.decaySpecVec = idata.inv1Dqt.smoothMulti.decaySpecVec;
                    idata.inv1Dqt.z = idata.inv1Dqt.smoothMulti.z;
                    idata.inv1Dqt.t = idata.inv1Dqt.smoothMulti.t;
                else
                    return
                end
            case 2 %smooth-mono
                if isfield(idata.inv1Dqt,'smoothMono')
                    idata.inv1Dqt.solution = idata.inv1Dqt.smoothMono.solution ;
                    idata.inv1Dqt.z = idata.inv1Dqt.smoothMono.z;
                    idata.inv1Dqt.t = idata.inv1Dqt.smoothMono.t;
                else
                    return
                end
            case 3 %block-mono
                if isfield(idata.inv1Dqt,'blockMono')
                    idata.inv1Dqt.solution = idata.inv1Dqt.blockMono.solution ;
                    idata.inv1Dqt.z = idata.inv1Dqt.blockMono.z;
                    idata.inv1Dqt.t = idata.inv1Dqt.blockMono.t;
                else
                    return
                end
        end
        if isfield(idata,'inv1Dqt')
            dcube = reshape(idata.inv1Dqt.solution(1).d ,length(idata.data.q),length(idata.inv1Dqt.t));
            % clear data from frequency offsets, use dataType = 1;
            idata.para.dataType = 1; idata = mrs_invQTpreparation(idata);
            instPhase = [-pi:0.01:pi];
            for n=1:length(instPhase)
                zwergdcube = abs(dcube).*exp(1i*(angle(dcube) + instPhase(n)));
                zwergR = (real(idata.data.dcube)-real(zwergdcube))./idata.data.ecube;
                zwergI = (imag(idata.data.dcube)-imag(zwergdcube))./idata.data.ecube;
                ErrorWR(n) = sqrt(sum(sum(zwergR.^2)))/sqrt(numel(zwergR));
                ErrorWI(n) = sqrt(sum(sum(zwergI.^2)))/sqrt(numel(zwergI));
            end
            [dummy,index] = min(ErrorWR + ErrorWI);
            idata.para.instPhase = instPhase(index);
            set(gui.para.instPhase,'String',num2str(idata.para.instPhase));
            
            % plot results to check
            idata.para.dataType = 3; 
            idata = mrs_invQTGetGuiPara(gui,idata);
            idata = mrs_invQTpreparation(idata);
            mrsInvQT_plotData(gui,idata);
        else
            msgbox('to determine instrument phase invert amplitude or rotated amplitude datat first')
        end
        % reset user choise
        idata.para.dataType = get(gui.para.datatype,'Value');
    end
    function onGetInstrumentPhaseChange(a,b)
        idata.para.dataType = 3;
        idata = mrs_invQTGetGuiPara(gui,idata);
        idata = mrs_invQTpreparation(idata);
        mrsInvQT_plotData(gui,idata);
        idata.para.dataType = get(gui.para.datatype,'Value');
    end
    function onPushbuttonCheckQ(a,b)
        % restore
        if isfield(idata,'bck')
            idata.data.dcubeRaw = idata.bck.dcubeRaw;
            idata.data.efit     = idata.bck.efit;
            idata.data.estack   = idata.bck.estack;
            idata.data.q        = idata.bck.q;
            idata.kernel.K      = idata.bck.K;
        else
            idata.para.iQuse    = [1:1:length(idata.data.q)];
        end
        idata.para.iQuse = getActiveQ(idata);
        if isempty(idata.para.iQuse)
           idata.para.iQuse    = [1:1:length(idata.data.q)]; 
        end
        % backup before deleting pulse
        idata.bck.dcubeRaw = idata.data.dcubeRaw;
        idata.bck.efit     = idata.data.efit;
        idata.bck.estack   = idata.data.estack;
        idata.bck.q        = idata.data.q;
        idata.bck.K        = idata.kernel.K;
        % now delete
        idata.data.dcubeRaw = idata.data.dcubeRaw(idata.para.iQuse,:);
        idata.data.efit     = idata.data.efit(idata.para.iQuse);
        idata.data.estack   = idata.data.estack(idata.para.iQuse);
        idata.data.q        = idata.data.q(idata.para.iQuse);
        idata.kernel.K      = idata.kernel.K(idata.para.iQuse,:);
        % plot
        idata = mrs_invQTGetGuiPara(gui,idata);
        idata = mrs_invQTpreparation(idata);
        mrsInvQT_plotData(gui,idata);
        
    end
    function onEditDataPath(a,b)
        datafile = get(gui.panel_controls.edit_dataPath,'String');
        onLoadData(0,1)
    end
    function onEditKernelPath(a,b)
        kernelfile = get(gui.panel_controls.edit_kernelPath,'String');
        onLoadKernel(0,1)
    end
    function onEditInvPath(a,b)
        invfile = get(gui.panel_controls.edit_invPath,'String');
        onLoadInv(0,1)
    end
    function onRegTypeFix(a,b)
        set(gui.para.regtypeFix,'value',1)
        set(gui.para.regtypeInt,'value',0)
    end
    function onRegTypeInt(a,b)
        set(gui.para.regtypeFix,'value',0)
        set(gui.para.regtypeInt,'value',1)
    end
    function onGateIntegration(a,b)
        if get(gui.para.gateIntegration,'Value')
            set(gui.para.nGates,'Enable','on')
        else
            set(gui.para.nGates,'Enable','off')
        end
        idata = mrs_invQTGetGuiPara(gui,idata);
        idata = mrs_invQTpreparation(idata);   
        mrsInvQT_plotData(gui,idata);
    end
    function onGateIntegrationChangeNumber(a,b)
        idata = mrs_invQTGetGuiPara(gui,idata);
        idata = mrs_invQTpreparation(idata);
        mrsInvQT_plotData(gui,idata);
    end
    function onDataChannel(a,b)
        datafile = get(gui.panel_controls.edit_dataPath,'String');
        onLoadData(0,1)
    end
    function onDataSignal(a,b)
        datafile = get(gui.panel_controls.edit_dataPath,'String');
        onLoadData(0,1)
    end
    function onDataType(a,b)
        idata = mrs_invQTGetGuiPara(gui,idata);
        idata = mrs_invQTpreparation(idata);   
        mrsInvQT_plotData(gui,idata);
    end
    function onSolType(a,b)
        idata.para.QTinv.soltype = get(gui.para.soltype, 'Value');
        switch idata.para.QTinv.soltype
            case 1
                set(gui.para.lowerboundWater,'Enable','off');
                set(gui.para.decaySpecN,'Enable','on');
                set(gui.para.regtypeFixV,'Enable','on');
                set(gui.para.regtypeMonoWC,'Enable','off');
                set(gui.para.regtypeMonoT2,'Enable','off');
                set(gui.para.struCoupling,'Enable','off');
                set(gui.para.statisticRuns,'Enable','off','visible','off');
                set(gui.para.GAstatistic,'visible','off');
                set(gui.para.statisticRunsText,'visible','off');
                set(gui.para.modelDiscretisation,'Visible','on');
                set(gui.para.modelDiscretisationText,'visible','on','String','min. layer thickness/m');
                set(gui.para.modelMaxDepth,'Visible','on');
                set(gui.para.modelMaxDepthText,'String','max. depth/m');
                set(gui.para.GAthkMin,'Visible','off');
                set(gui.para.GAthkMax,'Visible','off');
                set(gui.para.GAnLay,'Visible','off');
                set(gui.para.GALayerPresets,'Visible','off');
                set(gui.para.membersOfPop,'Visible','off','Enable','off');
                set(gui.para.numbersOfPop,'Visible','off','Enable','off');
                set(gui.para.PopulationText,'Visible','off');
                set(gui.para.minModelUpdate,'Visible','on','Enable','on');
                set(gui.para.minModelUpdateText,'Visible','on','String','min. model update');
                set(gui.vboxRun.StartLCurve,'Enable','off');
                if isfield(idata,'backupGUIpara')
                if isfield(idata.backupGUIpara,'minModUp')
                    set(gui.para.minModelUpdate,'String',num2str(idata.backupGUIpara.minModUp));
                else
                    set(gui.para.minModelUpdate,'String','1e-4');
                end
                else
                    set(gui.para.minModelUpdate,'String','1e-4');
                end
            case 2
                set(gui.para.lowerboundWater,'Enable','on');
                set(gui.para.decaySpecN,'Enable','off');
                set(gui.para.regtypeFixV,'Enable','off');
                set(gui.para.regtypeMonoWC,'Enable','on');
                set(gui.para.regtypeMonoT2,'Enable','on');
                set(gui.para.struCoupling,'Enable','on');
                set(gui.para.statisticRuns,'Enable','on','visible','on');
                set(gui.para.GAstatistic,'visible','off');
                set(gui.para.statisticRunsText,'visible','on','String','number of statistic runs (bootstraps)');
                set(gui.para.modelDiscretisation,'Visible','on');
                set(gui.para.modelDiscretisationText,'visible','on','String','min. layer thickness/m');
                set(gui.para.modelMaxDepth,'Visible','on');
                set(gui.para.modelMaxDepthText,'String','max. depth/m');
                set(gui.para.GAthkMin,'Visible','off');
                set(gui.para.GAthkMax,'Visible','off');
                set(gui.para.GAnLay,'Visible','off');
                set(gui.para.GALayerPresets,'Visible','off');
                set(gui.para.membersOfPop,'Visible','off','Enable','off');
                set(gui.para.numbersOfPop,'Visible','off','Enable','off');
                set(gui.para.PopulationText,'Visible','off');
                set(gui.para.minModelUpdate,'Visible','off','Enable','off');
                set(gui.para.minModelUpdateText,'Visible','off');
                set(gui.vboxRun.StartLCurve,'Enable','on');
            case 3
                set(gui.para.lowerboundWater,'Enable','on');
                set(gui.para.decaySpecN,'Enable','off');
                set(gui.para.regtypeFixV,'Enable','off');
                set(gui.para.regtypeMonoWC,'Enable','off');
                set(gui.para.regtypeMonoT2,'Enable','off');
                set(gui.para.struCoupling,'Enable','off');
                set(gui.para.statisticRuns,'visible','off');
                set(gui.para.statisticRunsText,'visible','off','String','get models below chi^2 of');
                set(gui.para.GAstatistic,'visible','off');
                set(gui.para.modelDiscretisation,'Visible','off');
                set(gui.para.modelDiscretisationText,'visible','on','String','layer thickness (min/max)');
                set(gui.para.modelMaxDepth,'Visible','off');
                set(gui.para.modelMaxDepthText,'String','nLayer');
                set(gui.para.GAthkMin,'Visible','on');
                set(gui.para.GAthkMax,'Visible','on');
                set(gui.para.GAnLay,'Visible','on');
                set(gui.para.GALayerPresets,'Visible','on');
                set(gui.para.membersOfPop,'Visible','on','Enable','on');
                set(gui.para.numbersOfPop,'Visible','on','Enable','on');
                set(gui.para.PopulationText,'Visible','on');
                set(gui.para.minModelUpdate,'Visible','on','Enable','on','String','10');
                set(gui.para.minModelUpdateText,'Visible','on','String','max. chi^2');
                set(gui.vboxRun.StartLCurve,'Enable','off');
                if isfield(idata,'backupGUIpara')
                if isfield(idata.backupGUIpara,'maxGAchi')
                    set(gui.para.minModelUpdate,'String',num2str(idata.backupGUIpara.maxGAchi));
                else
                    set(gui.para.minModelUpdate,'String','10');
                end
                else
                    set(gui.para.minModelUpdate,'String','10');
                end
                
        end
        if isfield(idata,'inv1Dqt')
            idata = mrs_invQTGetGuiPara(gui,idata);
            idata = mrs_invQTpreparation(idata);
            mrsInvQT_plotData(gui,idata);
        end
    end

%% FUNCTION selectChi_min
    function selectChi_min(a,b)
     idata.para.QTinv.soltype = get(gui.para.soltype, 'Value');
        switch idata.para.QTinv.soltype
            case 1
                idata.backupGUIpara.minModUp = str2num(get(gui.para.minModelUpdate,'String'));
            case 3
                idata.backupGUIpara.maxGAchi = str2num(get(gui.para.minModelUpdate,'String'));
        end
        if isfield(idata,'inv1Dqt')
            idata = mrs_invQTGetGuiPara(gui,idata);
            idata = mrs_invQTpreparation(idata);
            mrsInvQT_plotData(gui,idata);
        end
    end
%% FUNCTION onQuitWithoutSave
    function onQuitWithoutSave(dummy,dummy1)
        ifig = findobj('Name', 'MRS QT Inversion');
        if ~isempty(ifig)
            delete(ifig)
        end
        ifig = findobj('Name', 'MRS QT Inversion - Data');
        if ~isempty(ifig)
            delete(ifig)
        end
        ifig = findobj('Name', 'MRS QT Inversion - Model');
        if ~isempty(ifig)
            delete(ifig)
        end
        invfilename=[];
    end
    function onSaveAndQuit(a,b)
        ifig = findobj('Name', 'MRS QT Inversion');
        if ~isempty(ifig)
            delete(ifig)
        end
        ifig = findobj('Name', 'MRS QT Inversion - Data');
        if ~isempty(ifig)
            delete(ifig)
        end
        ifig = findobj('Name', 'MRS QT Inversion - Model');
        if ~isempty(ifig)
            delete(ifig)
        end
        save([path filesep invfilename],'idata')
        mrs_updateinifile([path filesep invfilename],1);
    end
    function onSaveData(a,call)
        if ~isnumeric(call)% workaround for matlab 2014b
            call=0;
        end
        mrs_setguistatus(gui,1,'save data')       
        if call
            %file from nargin            
        else
            inifile = mrs_readinifile;  % read ini file and get last .mrsd file (if exist)
            if strcmp(inifile.MRSData.file,'none') == 1
                inifile.MRSData.path = [pwd filesep];
                inifile.MRSData.file = 'mrs_project';
            end
            [invfilename, path] = uiputfile(...
                {'*.mrsi','MRSInversion File (*.mrsi)';
                '*.*',  'All Files (*.*)'}, ...
                'Put a MRSInversion file',...
                [inifile.MRSData.path]);
        end
        % some parameter mapping
        idata.inv1Dqt.para = idata.para;
        save([path filesep invfilename],'idata')
        set(gui.panel_controls.edit_invPath,'String',[path filesep invfilename]);
        mrs_updateinifile([path filesep invfilename],1);
        mrs_setguistatus(gui,0)   
    end

if standalone == 0;
    uiwait(gui.panel_controls.figureid)
end
end