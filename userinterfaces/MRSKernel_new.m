function kfile = MRSKernel_new(sounding_pathdirfile)

kfig = findobj('Name', 'MRS Kernel');
if ~isempty(kfig)
    delete(kfig)
end

if nargin > 0  % i.e. command comes from MRSWorkflow
    standalone = 0;
else
    standalone = 1;
end

proclog   = struct();
if nargin > 0  % i.e. command comes from MRSWorkflow
    % set path; execute initialize
    kfile = '';
    kpath = '';
    Initialize();
    kdata = createData();
    gui   = createInterface();
    % activate Quit and save
    child=get(gui.QuitMenu,'Children');
    set(child(2),'Enable','on')
else
    kfile = -1;
    kdata = createData();
    gui   = createInterface();
end

    function kdata = createData()
        kdata       = get_defaults();     
        if isfield(proclog, 'Q')
            kdata.loop.shape  = proclog.txinfo.looptype;
            kdata.loop.size   = proclog.txinfo.loopsize; % be careful circular loop size is diameter
            kdata.loop.turns = proclog.txinfo.loopturns.*[1 1];
            kdata.measure.pm_vec = [];
            kdata.measure.pm_vec_2ndpulse = [];
            for m = 1:length(proclog.Q)
                kdata.measure.pm_vec(m) = proclog.Q(m).q;
            end
            kdata.earth.f         = proclog.Q(1).fT;
        end
        kdata.model.zmax      =  1.5*kdata.loop.size;
        kdata.model.z_space   =  1;
        kdata.model.nz        =  4*length(kdata.measure.pm_vec);
        kdata.model.sinh_zmin =  kdata.loop.size/500;
        kdata.model.LL_dzmin  =  kdata.loop.size/500; 
        kdata.model.LL_dzmax  =  kdata.loop.size/50;
        kdata.model.LL_dlog   =  kdata.loop.size/5;
        kdata.model           =  MakeZvec(kdata.model);
        kdata.earth.w_rf      =  kdata.earth.f*2*pi;
        kdata.earth.erdt      =  kdata.earth.w_rf/kdata.gammaH;
    end

    function gui = createInterface()
        % Create the user interface for the application and return a
        % structure of handles for global use.
        gui = struct();
        % Open a window and add some menus
        gui.Window = figure( ...
            'Name', 'MRS Kernel', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'Toolbar', 'none', ...
            'HandleVisibility', 'on' );
        
        pos    = get(gui.Window,'Position');
        posout = get(gui.Window,'OuterPosition');
        frame = posout - pos;
        scrsize = get(0,'ScreenSize');
        set(gui.Window,'Position',[5 scrsize(4)-560 1050 500])
        
        % + File menu
        gui.QuitMenu = uimenu(gui.Window,'Label','Quit');
        uimenu(gui.QuitMenu, ...
            'Label', 'Save and Quit','Enable','off',...
            'Callback', @onSaveAndQuit);
        uimenu(gui.QuitMenu,...
            'Label','Quit without saving',...
            'Callback',@onQuitWithoutSave);
        
        % + File menu
        gui.FileMenu = uimenu(gui.Window,'Label','File');
        gui.ImportMenu = uimenu(gui.Window,'Parent',gui.FileMenu,'Label','Import Parameter');
        uimenu(gui.ImportMenu,'Label','from field data','Callback', @loadData);
        uimenu(gui.ImportMenu,'Label','from existing kernel','Callback', @loadKernel);
        uimenu(gui.Window,'Parent',gui.FileMenu,'Label','Save Kernel as','Callback',@onSaveK,'Enable','off');
                
        % + Kernel menu
        gui.KernelMenu = uimenu(gui.Window,'Label','Kernel');
        uimenu(gui.KernelMenu,'Label','Make','Callback', @makeK);
        uimenu(gui.KernelMenu,'Label','Show kernel','Callback',@viewK,'Enable','off');

        % + Help menu
        gui.helpMenu = uimenu(gui.Window,'Label','Help');
        uimenu(gui.helpMenu,'Label','Documentation','Callback',@onHelp);
        
        set(gui.Window,'CloseRequestFcn',@onQuit)
               
        % create boxes for the parameters
        b = uiextras.HBox('Parent',gui.Window);
        
        % + Loop parameters
        %loopw = [85 65];
        loopw = [85 -1];
        %uiloopp  = uiextras.BoxPanel('Parent', b, 'Title', 'Loop');
        %uiloopv  = uiextras.VBox('Parent', uiloopp);
        
        uiloop1 = uiextras.VBox('Parent', b);
        uiloopp = uiextras.BoxPanel('Parent',uiloop1,'Title','Tx / Rx Loop');
        uiloopv = uiextras.VBox('Parent', uiloopp,'Padding',3,'Spacing',3);
        
        uilooph1 = uiextras.HBox('Parent',uiloopv);
        uicontrol('Style','Text','Parent',uilooph1,'String','Loop shape');
        gui.LoopShape = uicontrol('Style', 'popupmenu', ...
            'Parent', uilooph1, ...
            'String', {'circular', 'square', 'c-eight', 's-eight', 'InLoop',...
            'SepLoop', 'circular & dB/dt', 'circular & B'},...
            'Value', kdata.loop.shape, ...
            'Callback', @onLoopShape);
        set(uilooph1, 'Sizes', [150 -1])
        
        uilooph2 = uiextras.HBox( 'Parent', uiloopv);
        gui.LoopSizeString = uicontrol('Style', 'Text', ...
            'Parent', uilooph2, ...
            'String', 'Diameter [m]');
        gui.LoopSize = uicontrol('Style', 'Edit', ...
            'Parent', uilooph2, ...
            'Enable', 'on', ...
            'String', num2str(kdata.loop.size), ...
            'Callback', @onLoopSize);
        gui.LoopSizeInLoopReceiver = uicontrol('Style', 'Edit', ...
            'Parent', uilooph2, ...
            'Enable', 'off', ...
            'String', num2str(kdata.loop.size), ...
            'Callback', @onLoopSize);
        set(uilooph2, 'Sizes', [150 -1 -1])
        
        uilooph3 =  uiextras.HBox( 'Parent', uiloopv);
        uicontrol('Style', 'Text', ...
            'Parent', uilooph3, ...
            'String', '# Turns (Tx / Rx)' );
        gui.LoopTurnsTx = uicontrol('Style', 'Edit', ...
            'Parent', uilooph3, ...
            'String', num2str(kdata.loop.turns(1)), ...
            'Callback', @onLoopTurns);
        gui.LoopTurnsRx = uicontrol('Style', 'Edit', ...
            'Parent', uilooph3, ...
            'String', num2str(kdata.loop.turns(2)), ...
            'Callback', @onLoopTurns);
        set(uilooph3, 'Sizes', [150 -1 -1])
        
        uilooph4 =  uiextras.HBox( 'Parent', uiloopv);
        uicontrol('Style', 'Text', 'Parent', uilooph4, 'String', 'Direction (0 = N, 90 = E)');
        gui.Loop8dir = uicontrol('Style', 'Edit', ...
            'Parent', uilooph4, ...
            'Enable', 'off', ...
            'String', '','Callback', @onLoop8dir);
        set(uilooph4, 'Sizes', [150 -1])
        
        uilooph5 =  uiextras.HBox( 'Parent', uiloopv);
        uicontrol('Style', 'Text', 'Parent', uilooph5, 'String', 'Separation [m]');
        gui.LoopSep = uicontrol('Style', 'Edit', ...
            'Parent', uilooph5, ...
            'Enable', 'off', ...
            'String', '','Callback', @onLoopSep);
        set(uilooph5, 'Sizes', [150 -1])
        
        % empty space and push button to show loop layout
        uiempty1 = uiextras.Empty('Parent',uiloopv);
        uilooph6 = uiextras.HBox('Parent',uiloopv);
        uicontrol('Style', 'pushbutton', 'Parent', uilooph6, 'String', 'show layout', 'Callback', @onLoopShow);
        % set all hbox heights
        set(uiloopv, 'Sizes', [24 26 26 26 26 -1 26]);
        
        % Prepolarisation loop parameters:
        uilooppre  = uiextras.BoxPanel('Parent', uiloop1, 'Title', 'Prepolarisation Loop');
        uiloopprev  = uiextras.VBox('Parent', uilooppre,'Padding',3,'Spacing',3);
        
        uilooph11 =  uiextras.HBox( 'Parent', uiloopprev,'Spacing',3);
        uicontrol('Style', 'Text', 'Parent', uilooph11, 'String', 'Px pulse on / off');
        gui.PXcheck = uicontrol('Style', 'popupmenu', ...
            'Parent', uilooph11, ...
            'Enable', 'on', ...
            'String', {'off', 'on',},...
            'Value', kdata.measure.PX+1, ...
            'Callback', @onPXcheck);
        set(uilooph11, 'Sizes', [150 -1]);
        
        uilooph12 =  uiextras.HBox( 'Parent', uiloopprev,'Spacing',3);
        uicontrol('Style', 'Text', 'Parent', uilooph12, 'String', 'Px shape');
        gui.PXshape = uicontrol('Style', 'popupmenu', ...
            'Parent', uilooph12, ...
            'Enable', 'off', ...
            'String', {'circular','c-eight'},...
            'Callback', @onPXshape);
        set(uilooph12, 'Sizes', [150 -1])
        
        uilooph13 =  uiextras.HBox( 'Parent', uiloopprev,'Spacing',3);
        uicontrol('Style', 'Text', 'Parent', uilooph13, 'String', 'Px diameter [m]');
        gui.PXsize = uicontrol('Style', 'Edit', ...
            'Parent', uilooph13, ...
            'Enable', 'off', ...
            'String', '2',...
            'Callback', @onPXsize);
        set(uilooph13, 'Sizes', [150 -1])
        
        uilooph14 =  uiextras.HBox( 'Parent', uiloopprev,'Spacing',3);
        uicontrol('Style', 'Text', 'Parent', uilooph14, 'String', 'Px current [A] / # turns');
        gui.PXcurrent = uicontrol('Style', 'Edit', ...
            'Parent', uilooph14, ...
            'Enable', 'off', ...
            'String', '20',...
            'Callback', @onPXcurrent);
        gui.PXturns = uicontrol('Style', 'Edit', ...
            'Parent', uilooph14, ...
            'Enable', 'off', ...
            'String', '50',...
            'Callback', @onPXcurrent);
        set(uilooph14, 'Sizes', [150 -1 -1])

        uilooph15 =  uiextras.HBox( 'Parent', uiloopprev,'Spacing',3);
        uicontrol('Style', 'Text', 'Parent', uilooph15, 'String', 'Px eight-dir [°] (0 = N)');
        gui.PX8dir = uicontrol('Style', 'Edit', ...
            'Parent', uilooph15, ...
            'Enable', 'off', ...
            'String', '',...
            'Callback', @onPX8dir);
        set(uilooph15, 'Sizes', [150 -1])
        
        uilooph16 =  uiextras.HBox( 'Parent', uiloopprev,'Spacing',3);
        uicontrol('Style', 'Text', 'Parent', uilooph16, 'String', 'Px switch-off ramp / ramp time');
        gui.PXramp = uicontrol('Style', 'popupmenu', ...
            'Parent', uilooph16, ...
            'Enable', 'off', ...
            'String', {'off', 'MIDI','LIN','LIN&EXP','EXP'},...
            'Value', 1, ...
            'Callback', @onPXramp);
        gui.PXramptime = uicontrol('Style', 'popupmenu', ...
            'Parent', uilooph16, ...
            'Enable', 'off', ...
            'String', {'1 ms', '2 ms','3 ms','4 ms'},...
            'Value', 1, ...
            'Callback', @onPXramptime);
        set(uilooph16, 'Sizes', [150 -1 -1]);
        
        uilooph17 = uiextras.HBox( 'Parent', uiloopprev); %#ok<*NASGU>
        set(uiloopprev, 'Sizes', [24 24 26 26 26 24 -1]);
        set(uiloop1,'Sizes',[-1 -1]);
        
        % + model discretization
        modelw = [75 -1];
        
        uimodelp = uiextras.BoxPanel('Parent', b, 'Title', 'Model');        
        uimodelv = uiextras.VBox('Parent', uimodelp,'Padding',3,'Spacing',3);        
        uimodelw2 = uiextras.HBox('Parent', uimodelv);
        uicontrol('Style', 'text', 'Parent', uimodelw2, 'String', 'z-discretization');
        
        uimodelw3 = uiextras.HBox('Parent', uimodelv);
        gui.ModelZvec = uitable('Parent', uimodelw3);
        set(gui.ModelZvec, ...
            'Data', [(1:length(kdata.model.z))' kdata.model.z' kdata.model.Dz'], ...
            'ColumnName', {'#', 'z [m]', 'dz [m]'}, ... 
            'ColumnWidth', {40 80 80}, ...
            'RowName', [], ...
            'ColumnEditable', false);

        uimodelw4 = uiextras.HBox( 'Parent', uimodelv);
        uicontrol('Style', 'pushbutton', 'Parent', uimodelw4, 'String', 'set', 'Callback', @onModSetZ);
        
        set(uimodelv, 'Sizes', [28 -1 26]);
        
        % + measurement parameter
        uimeasp1 = uiextras.VBox('Parent', b);
        uimeasp = uiextras.BoxPanel('Parent', uimeasp1, 'Title', 'Tx Meas. Parameter');       
        uimeasv = uiextras.VBox('Parent', uimeasp,'Padding',3,'Spacing',3);
        
        uimeasv01_1 = uiextras.HBox( 'Parent', uimeasv);
        uicontrol('Style', 'Text', 'Parent', uimeasv01_1, ...
            'String', 'Pulse sequence' );
        gui.pulsesequence = uicontrol('Style', 'popupmenu', ...
                'Parent', uimeasv01_1, ...
                'String', {'FID', 'T1', 'T2'},...
                'Value', kdata.measure.pulsesequence, ...
                'Callback', @onEditPulseSequence);
        set(uimeasv01_1, 'Sizes', [150 -1]) 
        
        uimeasv01_2 =  uiextras.HBox( 'Parent', uimeasv);
        uicontrol('Style', 'Text', 'Parent', uimeasv01_2, ...
            'String', 'Pulse type' );
        gui.pulsetype = uicontrol('Style', 'popupmenu', ...
                'Parent', uimeasv01_2, ...
                'String', {'standard','adiabatic','Px switch-off'},...
                'Value', kdata.measure.pulsetype, ...
                'Callback', @onEditPulseType);
        set(uimeasv01_2, 'Sizes', [150 -1])                

        uimeasv02_1 =  uiextras.HBox( 'Parent', uimeasv);
        uicontrol('Style', 'Text', 'Parent', uimeasv02_1, ...
            'String', 'Pulse duration [s]' );
        gui.edit_taup1 = uicontrol(...
            'Style', 'Edit', ...
            'Parent', uimeasv02_1, ...
            'Enable', 'on', ...
            'String', num2str(kdata.measure.taup1), ...
            'Callback', @ontaup1CellEdit);
        set(uimeasv02_1, 'Sizes', [150 -1])
        
        uimeasv02_2 =  uiextras.HBox( 'Parent', uimeasv);
        uicontrol('Style', 'Text', 'Parent', uimeasv02_2, ...
            'String', 'Off-resonance freq. [Hz]' );
        gui.edit_df = uicontrol(...
            'Style', 'Edit', ...
            'Parent', uimeasv02_2, ...
            'Enable', 'on', ...
            'String', num2str(kdata.measure.df), ...
            'Callback', @oneditdf);    
        set(uimeasv02_2, 'Sizes', [150 -1])
    
        uimeasv03_1 =  uiextras.HBox( 'Parent', uimeasv);
        gui.advancedAP = uicontrol(...
            'Style', 'pushbutton',...
            'Parent', uimeasv03_1,...
            'String', 'Advanced adiabatic pulse settings',...
            'Enable', 'off', ...
            'Callback', @drawpulseshape);
%         set(uimeasv03_1, 'Sizes', [-1])  
        
        uimeasw04 = uiextras.HBox( 'Parent', uimeasv);
        gui.MeasQvec = uitable('Parent', uimeasw04);
        set(gui.MeasQvec, ...
            'Data', [(1:length(kdata.measure.pm_vec))' kdata.measure.pm_vec' (kdata.measure.Imax_vec)'], ...  % initial value
            'ColumnName', {'#', 'q [As]', 'max(I) [A]'}, ...
            'ColumnWidth', {40 80 80}, ...
            'RowName', [], ...
            'ColumnEditable', true);
        
        uimeasw05 = uiextras.HBox( 'Parent', uimeasv);
        uicontrol('Style', 'pushbutton', 'Parent', uimeasw05, 'String', 'set', 'Callback', @onMeasSetQ);

        set(uimeasv, 'Sizes', [24 24 26 26 26 -1 26])

        % + earth parameter
        earthw = [150 -1];
        
        uiearthp = uiextras.BoxPanel('Parent', b, 'Title', 'Earth');        
        eV1  = uiextras.VBox('Parent', uiearthp,'Padding',3,'Spacing',3);
        
        eV1Hmag = uiextras.HBox('Parent', eV1);
        uicontrol('Style', 'text', 'Parent', eV1Hmag, 'String', 'B_0 magnitude [nT]')
        gui.EarthB0 = uicontrol('Style', 'edit', ...
            'Parent', eV1Hmag, ...
            'String', num2str(round(kdata.earth.erdt*1e9)), ...
            'Callback', @onEarthB0);
        set(eV1Hmag, 'Sizes', earthw)
        
        eV1Hfreq = uiextras.HBox('Parent', eV1);
        uicontrol('Style', 'text', 'Parent', eV1Hfreq, 'String', 'Larmor frequency [Hz]')
        gui.EarthF = uicontrol('Style', 'edit', 'Parent', eV1Hfreq, 'String', num2str(round(kdata.earth.f*100)/100), 'Callback', @onEarthW0);
        set(eV1Hfreq, 'Sizes', earthw)
        
        eV1Hincl = uiextras.HBox('Parent', eV1);
        uicontrol('Style', 'text', 'Parent', eV1Hincl, 'String', 'B_0 inclination [°]')
        gui.EarthInkl = uicontrol('Style', 'edit', 'Parent', eV1Hincl, 'String', num2str(kdata.earth.inkl), 'Callback', @onEarthInkl);
        set(eV1Hincl, 'Sizes', earthw)
        
        eV1Hdecl = uiextras.HBox('Parent', eV1);
        uicontrol('Style', 'text', 'Parent', eV1Hdecl, 'String', 'B_0 declination [°] (0 = N)')
        gui.EarthDecl= uicontrol('Style', 'edit', 'Parent', eV1Hdecl, 'String', num2str(kdata.earth.decl), 'Callback', @onEarthDecl);
        set(eV1Hdecl, 'Sizes', earthw)
        
        eV1AqT = uiextras.HBox('Parent', eV1);
        uicontrol('Style', 'text', 'Parent', eV1AqT, 'String', 'Aquifer temperature')
        gui.AquaTemp= uicontrol('Style', 'edit', 'Parent', eV1AqT, 'String', num2str(kdata.earth.temp), 'Callback', @onEarthAqT);
        set(eV1AqT, 'Sizes', earthw)
        
        eV1Hres = uiextras.HBox('Parent', eV1);
        gui.EarthRes  = uicontrol('Style', 'Togglebutton', 'Parent', eV1Hres, 'String', 'Resistive Earth', 'Callback', @onEarthRes);
        
        eV1Hltab = uiextras.HBox( 'Parent', eV1);
        gui.EarthResMod = uitable('Parent', eV1Hltab);
        set(gui.EarthResMod, ...
            'Data', [(1:length(kdata.earth.sm))' [kdata.earth.zm inf]' 1./kdata.earth.sm'], ...
            'ColumnName', {'#', 'depth [m]',['resistivity [',char(hex2dec('03A9')),']']}, ...
            'ColumnWidth', {40 80 80}, ...
            'RowName', [], ...
            'ColumnEditable', true, ...
            'CellEditCallback', @onEarthResCellEdit);
        %set(eV1Hltab, 'Sizes', 230)
        set(eV1Hltab, 'Sizes', -1)
        
        eV1Hladd = uiextras.HBox('Parent', eV1,'Spacing',3);
        gui.EarthLayerAdd = uicontrol('Style', 'pushbutton', 'Parent', eV1Hladd, 'String', '+', 'Callback', @onEarthLayerAdd);
        gui.EarthLayerRem = uicontrol('Style', 'pushbutton', 'Parent', eV1Hladd, 'String', '-', 'Callback', @onEarthLayerRem);
        %set(eV1Hladd, 'Sizes', [115 115])
        set(eV1Hladd, 'Sizes', [-1 -1])
        
        eV1Hlres = uiextras.HBox( 'Parent', eV1);
        gui.EarthLoadRes = uicontrol('Style', 'pushbutton', 'Parent', eV1Hlres, 'String', 'load', 'Callback', @onEarthLoadRes);
        %set(eV1Hlres, 'Sizes', 230)
        set(eV1Hlres, 'Sizes', -1)
        
        set(eV1, 'Sizes', [26 26 26 26 26 26 -1 26 26]);
        
        %set(b, 'Sizes', [150 180 200 210])
        set(b, 'Sizes', [-1 -1 -1 -1])
        
    end

%% Menu Callbacks
    function loadData(a,b) %#ok<*INUSD>
        % load data
        inifile = mrs_readinifile;  % read ini file and get last .mrsd file (if exist)
        if strcmp(inifile.MRSData.file,'none') == 1
            inifile.MRSData.path = [pwd filesep];
            inifile.MRSData.file = 'mrs_project';
        end    
        
        [file.soundingname, file.soundingpath] = uigetfile(...
            {'*.mrsd','MRSData File (*.mrsd)';
            '*.*',  'All Files (*.*)'}, ...
            'Pick a MRSData file',...
            [inifile.MRSData.path inifile.MRSData.file]);
        datafile = [file.soundingpath,file.soundingname];
        
        [pathstr, name, ext] = fileparts(datafile);
        filepath = [pathstr filesep];
        filename = [name ext];
        proclog  = mrs_load_proclog(filepath, filename);
        
        %kdata            = get_defaults();
        kdata.loop.shape = proclog.txinfo.looptype;
        kdata.loop.size  = proclog.txinfo.loopsize;
        kdata.loop.turns = proclog.txinfo.loopturns.*[1 1];     % JW: why *[1 1]?
        
        if isfield(proclog.Q(1),'tx') % check if adiabatic pulse sequence
            kdata.measure.flag_loadAHP  = 1; % set flag to AHP
        else
            kdata.measure.flag_loadAHP  = 0; % set flag to AHP 
        end
        
        % clear q vector before loading
        kdata.measure.pm_vec          = [];
        kdata.measure.pm_vec_2ndpulse = [];
        kdata.measure.Imax_vec        = [];
        
        if kdata.measure.flag_loadAHP % modRD: check if AHP: save I, STDI and df for each Q   
            kdata.measure.Imod.I=[];
            kdata.measure.Imod.InormImax=[];            
            kdata.measure.Imod.STD_I=[];
            kdata.measure.fmod.df=[];   
        end
        for m = 1:length(proclog.Q)
%             kdata.measure.pm_vec(m) = proclog.Q(m).q;
            if kdata.measure.flag_loadAHP % modRD: check if AHP: save I, STD_I and df for each Q   
                kdata.measure.Imax_vec(m)   = proclog.Q(m).q; % current is saved as Q!!!!
                kdata.measure.pm_vec(m)     = proclog.Q(m).q .* proclog.Q(m).timing.tau_p1; % only true for on-res excitation
                kdata.measure.Imod.I(m,:)   = proclog.Q(m).tx.I;
                kdata.measure.Imod.InormImax(m,:) = proclog.Q(m).tx.I./kdata.measure.Imax_vec(m);                
                kdata.measure.Imod.STD_I(m,:)     = proclog.Q(m).tx.STD_I;    
                kdata.measure.Imod.t_pulse(m,:)   = proclog.Q(m).tx.t_pulse;                
                kdata.measure.fmod.df(m,:)   = proclog.Q(m).tx.df;

            else
                kdata.measure.pm_vec(m)   = proclog.Q(m).q;
                kdata.measure.Imax_vec(m) = proclog.Q(m).q/proclog.Q(m).timing.tau_p1;
            end
            
            if proclog.Q(m).rx(1).sig(3).recorded
%             if ~isempty(proclog.Q(m).q2)
                kdata.measure.pm_vec_2ndpulse(m) = proclog.Q(m).q2;
                set(gui.pulsesequence , 'Value',2);
            end
            if proclog.Q(m).rx(1).sig(4).recorded
%             if ~isempty(proclog.Q(m).q2)
                kdata.measure.pm_vec_2ndpulse(m) = proclog.Q(m).q2;
                set(gui.pulsesequence , 'Value',3);
            end
            set(gui.pulsesequence ,'Enable','off');
        end
        
        switch kdata.loop.shape
            case {1,3} % circular loop, single or eight            
                kdata.model.zmax   = 1.5 * kdata.loop.size;
            case 2 % square loop, single or eight
                kdata.model.zmax   = 1.5 * kdata.loop.size;
        end
        kdata.earth.f    = proclog.Q(1).fT;
        kdata.measure.taup1 = proclog.Q(1).timing.tau_p1;     % JW: added for df kernel
        if get(gui.pulsesequence , 'Value') ~= 1
            kdata.measure.taup2 = proclog.Q(1).timing.tau_p2; % NOT EX FOR 1PULSE!
        else
            kdata.measure.taup2 = -1; % NOT EX FOR 1PULSE!
        end
        kdata.model.z_space   =  1;
        kdata.model.nz        =  4*length(kdata.measure.pm_vec);
        kdata.model.sinh_zmin =  kdata.loop.size/500;
        kdata.model.LL_dzmin  =  kdata.loop.size/500; 
        kdata.model.LL_dzmax  =  kdata.loop.size/50;
        kdata.model.LL_dlog   =  kdata.loop.size/5;
        kdata.earth.w_rf      =  kdata.earth.f*2*pi;
        kdata.earth.erdt      =  kdata.earth.w_rf/kdata.gammaH;
        
        set(gui.LoopSize, 'String', num2str(kdata.loop.size));
        set(gui.LoopShape, 'Value', kdata.loop.shape);
        set(gui.LoopTurnsTx, 'String', num2str(kdata.loop.turns(1)));
        set(gui.LoopTurnsRx, 'String', num2str(kdata.loop.turns(2)));
        set(gui.EarthF,'String', num2str(kdata.earth.f));       
        set(gui.EarthB0, 'String', num2str(round(kdata.earth.erdt)))
        set(gui.MeasQvec, ...
            'Data', [(1:length(kdata.measure.pm_vec))' kdata.measure.pm_vec' (kdata.measure.Imax_vec)']) % load data
        kdata.model = MakeZvec(kdata.model);
        set(gui.ModelZvec, ...
            'Data', [(1:length(kdata.model.z))' kdata.model.z' kdata.model.Dz'])  
        onLoopShape(0,0);    % update gui - enable handles for loaded loop shape
        if kdata.measure.flag_loadAHP % show real AHP pulse shapes
            
            kdata.measure.pulsetype = 2;
            set(gui.pulsetype, 'Value', kdata.measure.pulsetype, 'Enable','off');
            
            kdata.measure.fmod.shape    = proclog.txinfo.Fmod.shape;
            kdata.measure.fmod.startdf  = proclog.txinfo.Fmod.startdf;
            kdata.measure.fmod.enddf    = proclog.txinfo.Fmod.enddf;
            kdata.measure.fmod.A        = proclog.txinfo.Fmod.A;
            kdata.measure.fmod.B        = proclog.txinfo.Fmod.B;

            set(gui.edit_taup1, 'Enable', 'off', 'String', num2str(kdata.measure.taup1));
            set(gui.edit_df, 'Enable', 'Off')
            
        else
            kdata.measure.pulsetype = 1;
            set(gui.pulsetype, 'Value', kdata.measure.pulsetype,'Enable','off');
            set(gui.edit_taup1, 'Enable', 'off', 'String', num2str(kdata.measure.taup1));
            set(gui.edit_df, 'Enable', 'On')
        end
    end

    function loadKernel(a,b)
        inifile = mrs_readinifile;  % read .ini file and get last .mrsk file (if exist)
        if strcmp(inifile.MRSKernel.file,'none') == 1
            inifile.MRSKernel.path = [pwd filesep];
            inifile.MRSKernel.file = 'mrs_kernel';
        end
        [file.kernelname,file.kernelpath] =  uigetfile(...
            {'*.mrsk','MRS kernel File (*.mrsk)';
            '*.*',  'All Files (*.*)'}, ...
            'Pick a MRS kernel file',...
            [inifile.MRSKernel.path inifile.MRSKernel.file]);
        
        % load .mrsk file
        dat  = load([file.kernelpath,file.kernelname],'-mat');
        kdata = dat.kdata;
        if ~isfield(kdata.measure,'pm_vec_2ndpulse')% workaround old kernel without 2nd pulse
            kdata.measure.pm_vec_2ndpulse = kdata.measure.pm_vec;
        end
        proclog.path = inifile.MRSData.path;

        % enable view
        child=get(gui.KernelMenu,'Children');
        set(child(1),'Enable','on');
        
        set(gui.LoopShape,'Value',  kdata.loop.shape);
        set(gui.LoopSize,'String',  num2str(kdata.loop.size));
        set(gui.LoopTurnsTx,'String', num2str(kdata.loop.turns(1)));
        if length(kdata.loop.turns) > 1% workaround for old kernels not including tx and rx turns separatly
            set(gui.LoopTurnsRx,'String', num2str(kdata.loop.turns(2)));
        else
            set(gui.LoopTurnsRx,'String', num2str(kdata.loop.turns(1)));
        end
        
        if (kdata.loop.shape == 3 || kdata.loop.shape == 4)
            set(gui.Loop8dir, 'Enable', 'on', 'String', num2str(kdata.loop.eightoritn))
        else
            set(gui.Loop8dir, 'Enable', 'off','String', '')
        end
        
        % set tickboxes 2pulse & df in measure
        % LATER: change if's to switch statement once kernel.earth.type is
        % sorted out
        % MMP: started replacing by kdata.measure.pulseseuqence --> debugging
        if isfield(kdata.measure,'pulsesequence')
            switch kdata.measure.pulsesequence
                case 'FID'
                   set(gui.pulsesequence,'Value', 1);
                   %set(gui.pulsetype, 'Enable', 'On')
                   % set(gui.pulsetype, 'Value', 1);
                case 'T1'
                    set(gui.pulsesequence,'Value', 2);
                    %set(gui.pulsetype, 'Enable', 'Off')
                    %set(gui.pulsetype, 'Value', 1);
                case 'T2'
                    set(gui.pulsesequence,'Value', 3);
                    %set(gui.pulsetype, 'Enable', 'Off')
                    %set(gui.pulsetype, 'Value', 1);
                case 1
                    set(gui.pulsesequence,'Value', 1);
                    %set(gui.pulsetype, 'Enable', 'On')
                    %set(gui.pulsetype, 'Value', 1);
                case 2
                    set(gui.pulsesequence,'Value', 2);
                    %set(gui.pulsetype, 'Enable', 'Off')
                    %set(gui.pulsetype, 'Value', 1);
                case 3
                    set(gui.pulsesequence,'Value', 3);
                    %set(gui.pulsetype, 'Enable', 'Off')
                    %set(gui.pulsetype, 'Value', 1);
            end
        else
            set(gui.pulsesequence,'Value', 1);
        end
        onEditPulseSequence
%         if isempty(kdata.B1)
%             flag_2pulse = 0;
%         else
%             flag_2pulse = 1;
%         end

%         set(gui.checkbox_doublepulse,'Value', flag_2pulse);

        if isfield(kdata.measure,'pulsetype')
        switch kdata.measure.pulsetype
            case 1 % standard
                %set(gui.pulsesequence, 'Enable', 'On')
                set(gui.pulsetype, 'Value', 1);
            case 2 % adiabatic
                %set(gui.pulsesequence, 'Enable', 'Off')
                set(gui.pulsetype, 'Value', 2); 
        end
        end
        onEditPulseType
        
        % set df in gui
        set(gui.edit_df, 'String', num2str(kdata.measure.df));

        % transfer parameter to getZgui must be done
        set(gui.ModelZvec, ...
            'Data', [(1:length(kdata.model.z))' kdata.model.z' kdata.model.Dz'])
        
        set(gui.MeasQvec, ...
            'Data', [(1:length(kdata.measure.pm_vec))' kdata.measure.pm_vec' (kdata.measure.Imax_vec)']) % load kernel
        
        set(gui.EarthB0,'String',   num2str(kdata.earth.erdt*1e9));
        set(gui.EarthF,'String',    num2str(kdata.earth.f));
        set(gui.EarthInkl,'String', num2str(kdata.earth.inkl));
        set(gui.EarthResMod, ...
            'Data', [(1:length(kdata.earth.sm))' [kdata.earth.zm inf]' 1./kdata.earth.sm'])
    end

    function onSaveK(a,b)
        
        % read .ini file and get last .mrsk file name & path (if exist)
        inifile = mrs_readinifile;  
        if strcmp(inifile.MRSKernel.file,'none') == 1
            inifile.MRSKernel.path = [pwd filesep];
            inifile.MRSKernel.file = 'mrs_kernel';
        end
        
        % prompt for file location and save kernel
        [filename,filepath] = uiputfile({...
            '*.mrsk','MRSmatlab kernel file'; '*.*','All Files' },...
            'Save MRSmatlab kernel file',...
            [inifile.MRSKernel.path inifile.MRSKernel.file]);
        save([filepath, filename], 'kdata');
        fprintf(1,'kernel file saved to %s\n', [filepath, filename]);
        mrs_updateinifile([filepath, filename],2);        
        kfile = filename;        
    end

    function makeK(a,b)
        % calculate the kernel
        if max(kdata.earth.zm) > kdata.model.zmax
            kdata.model.zmax = max(kdata.earth.zm);
        end
      
        tic;      
        [kdata.K, dummy, kdata.B1] = MakeKernel(kdata.loop, ...
            kdata.model, ...
            kdata.measure, ...
            kdata.earth);
        
        dummy =[];
        timeforkernel = toc;
        
        % change back sequence
        if get(gui.pulsesequence,'Value') == 2
           kdata.measure.pulsesequence = 2; 
        end
        
        % enable view and save
        child=get(gui.KernelMenu,'Children');
        set(child(1),'Enable','on');
        child=get(gui.FileMenu,'Children');
        set(child(1),'Enable','on');
    end

    function viewK(a,b)
        kfig = figure('Name','kernel','Position',[0 0 700 400], 'Toolbar', 'none');
        set(kfig, 'PaperUnits', 'points', ....
            'PaperSize', [700 400], ...
            'PaperPosition', [0 0 700 400])
        tbh = uitoolbar(kfig);
        png = load('png.mat'); eps = load('eps.mat'); logq = load('logq.mat'); logz = load('logz.mat');
        absk = load('abs.mat'); rek = load('re.mat'); imk = load('im.mat');
        uipushtool(tbh, 'CData', png.cdata, 'ClickedCallback', @onExportPNG);
        uipushtool(tbh, 'CData', eps.cdata,'ClickedCallback', @onExportEPS);
        uitogz = uitoggletool(tbh, 'CData', logz.cdata, 'Separator', 'on','ClickedCallback', @ontogLogZ);
        uitogq = uitoggletool(tbh, 'CData', logq.cdata,'ClickedCallback', @ontogLogQ);
        uiabsk = uitoggletool(tbh, 'State', 'on', 'CData', absk.cdata, 'Separator', 'on','ClickedCallback', @t_absk);
        uirek  = uitoggletool(tbh, 'CData', rek.cdata,'ClickedCallback', @t_rek);
        uiimk  = uitoggletool(tbh, 'CData', imk.cdata,'ClickedCallback', @t_imk);
        set(kfig, 'DefaultAxesFontSize', 10)
        set(kfig, 'DefaultTextFontSize', 10)
       
        [kplt,k1,k2] = plotK(1);
        
        function [kplt,k1,k2] = plotK(in)
            fs=10;
            subplot(1,4,1:2);
            
            % scaling factor for fT or nV
            switch kdata.loop.shape
                case {8}
                    scale_fac = 1e15; % fT
                otherwise
                    scale_fac = 1e9; % nV
            end
            
            % sensitivity weighting [nV/m] or [fT/m]
            weight = repmat(kdata.model.Dz,size(kdata.K,1),1)/scale_fac; 
            
            % we discriminate between loops and point-sensors:            
            switch kdata.loop.shape
                case {7,8} % point sensors                    
                    KKx = kdata.K(:,:,1); % x-dipole
                    KKy = kdata.K(:,:,2); % y-dipole
                    KKz = kdata.K(:,:,3); % z-dipole
                    
                    switch in
                        case 1 % abs
                            tmpKx = (abs(KKx)./weight)';
                            tmpKy = (abs(KKy)./weight)';
                            tmpK = (abs(KKz)./weight)';
                            clims = [0 mean(tmpK(:))+std(tmpK(:))];
                        case 2 % re
                            tmpKx = (real(KKx)./weight)';
                            tmpKy = (real(KKy)./weight)';
                            tmpK = (real(KKz)./weight)';
                            clims = [mean(tmpK(:))-std(tmpK(:)) mean(tmpK(:))+std(tmpK(:))];
                        case 3 % im
                            tmpKx = (imag(KKx)./weight)';
                            tmpKy = (imag(KKy)./weight)';
                            tmpK = (imag(KKz)./weight)';
                            clims = [mean(tmpK(:))-std(tmpK(:)) mean(tmpK(:))+std(tmpK(:))];
                    end
                    
                    % check if it is a single pulse moment kernel
                    if size(tmpK,2) == 1
                        kplt = plot(tmpKx, kdata.model.z,'r'); hold on;
                        kplt = plot(tmpKy, kdata.model.z,'g');
                        kplt = plot(tmpK, kdata.model.z,'b');
                        hold off;
                    else % we only show the z-component in the pcolor plot
                        kplt = pcolor(kdata.measure.pm_vec, kdata.model.z, tmpK);
                        set(gca,'CLim',clims);
                    end
                    
                otherwise % loops
                    KK = kdata.K;
                    
                    switch in
                        case 1 % abs
                            tmpK = (abs(KK)./weight)';
                            clims = [0 mean(tmpK(:))+std(tmpK(:))];
                        case 2 % re
                            tmpK = (real(KK)./weight)';
                            clims = [mean(tmpK(:))-std(tmpK(:)) mean(tmpK(:))+std(tmpK(:))];
                        case 3 % im
                            tmpK = (imag(KK)./weight)';
                            clims = [mean(tmpK(:))-std(tmpK(:)) mean(tmpK(:))+std(tmpK(:))];
                    end
                    
                    % check if it is a single pulse moment kernel
                    if size(tmpK,2) == 1
                        kplt = plot(tmpK, kdata.model.z);
                    else
                        kplt = pcolor(kdata.measure.pm_vec, kdata.model.z, tmpK);
                        set(gca,'CLim',clims);
                    end
            end

            % axis title
            switch in
                case 1
                    switch kdata.loop.shape
                        case {1,2,3,4,5,6}
                            title('sensitivity kernel (abs value)', 'FontSize', fs);
                        case {7,8}
                            title('sensitivity kernel z-comp. (abs value)', 'FontSize', fs);
                    end
                case 2
                    switch kdata.loop.shape
                        case {1,2,3,4,5,6}
                            title('sensitivity kernel (real value)', 'FontSize', fs);
                        case {7,8}
                            title('sensitivity kernel z-comp. (real value)', 'FontSize', fs);
                    end
                case 3
                    switch kdata.loop.shape
                        case {1,2,3,4,5,6}
                            title('sensitivity kernel (imag value)', 'FontSize', fs);
                        case {7,8}
                            title('sensitivity kernel z-comp. (imag value)', 'FontSize', fs);
                    end   
            end
            
            % axis settings
            if size(tmpK,2) > 1
                axis ij
                shading flat
                xlabel('pulse moment q [As]', 'Fontsize', fs);
                clb = colorbar('Location', 'EastOutside');
                switch kdata.loop.shape
                    case {1,2,3,4,5,6,7}
                        set(get(clb,'Title'),'String','nV/m');
                    case 8
                        set(get(clb,'Title'),'String','fT/m');
                end
            else
                axis ij
                switch kdata.loop.shape
                    case {1,2,3,4,5,6,7}
                        xlabel('amplitude [nV/m]', 'Fontsize', fs);
                    case 8
                        xlabel('amplitude [fT/m]', 'Fontsize', fs);
                end
            end
            box on
            grid on
            set(gca, 'layer', 'top')
            ylabel('depth [m]', 'Fontsize', fs)
            kplt = gca;

            % resistivity model
            k1 = subplot(1,4,3);
            stairs([1./kdata.earth.sm(1) 1./kdata.earth.sm],[kdata.model.z(1) kdata.earth.zm max(kdata.model.z)])
            title('resistivity model', 'FontSize', fs)
            axis ij
            box on
            set(gca,'xscale','log')
            grid on
            set(gca, 'layer', 'top')
            xlim([floor(min(1./kdata.earth.sm))/2 ceil(max(1./kdata.earth.sm))*2])
            xlabel('resistivity [Ohm m]', 'Fontsize', fs)
            ylabel('depth [m]', 'Fontsize', fs)
            
            % kernel sum
            k2 = subplot(1,4,4);
            switch kdata.loop.shape
                case {1,2,3,4,5,6}
                    plot(abs(sum(KK,2)).*scale_fac, kdata.measure.pm_vec, 'ro');
                    xlabel('amplitude [nV]', 'Fontsize', fs)
                case {7}
                    switch in
                        case 1 % abs
                            tmp_x = abs(sum(KKx,2)).*scale_fac;
                            tmp_y = abs(sum(KKy,2)).*scale_fac;
                            tmp_z = abs(sum(KKz,2)).*scale_fac;
                        case 2 % re
                            tmp_x = real(sum(KKx,2)).*scale_fac;
                            tmp_y = real(sum(KKy,2)).*scale_fac;
                            tmp_z = real(sum(KKz,2)).*scale_fac;
                        case 3 % im
                            tmp_x = imag(sum(KKx,2)).*scale_fac;
                            tmp_y = imag(sum(KKy,2)).*scale_fac;
                            tmp_z = imag(sum(KKz,2)).*scale_fac;
                    end
                    tmp_abs = sqrt(tmp_x.^2+tmp_y.^2+tmp_z.^2);
                    plot(tmp_x,kdata.measure.pm_vec, 'ro'); hold on
                    plot(tmp_y,kdata.measure.pm_vec, 'go');
                    plot(tmp_z,kdata.measure.pm_vec, 'bo');
                    plot(tmp_abs,kdata.measure.pm_vec, 'ko');
                    xlabel('amplitude [nV]', 'Fontsize', fs)
                case {8}
                    if isreal(KKx) % T1 magnetics
                        switch in
                            case 1 % abs
                                tmp_x = abs(sum(KKx,2)).*scale_fac;
                                tmp_y = abs(sum(KKy,2)).*scale_fac;
                                tmp_z = abs(sum(KKz,2)).*scale_fac;
                            case 2 % re
                                tmp_x = sum(KKx,2).*scale_fac;
                                tmp_y = sum(KKy,2).*scale_fac;
                                tmp_z = sum(KKz,2).*scale_fac;
                            case 3 % im
                                tmp_x = 0;
                                tmp_y = 0;
                                tmp_z = 0;
                        end
                    else
                        switch in
                            case 1 % abs
                                tmp_x = abs(sum(KKx,2)).*scale_fac;
                                tmp_y = abs(sum(KKy,2)).*scale_fac;
                                tmp_z = abs(sum(KKz,2)).*scale_fac;
                            case 2 % re
                                tmp_x = real(sum(KKx,2)).*scale_fac;
                                tmp_y = real(sum(KKy,2)).*scale_fac;
                                tmp_z = real(sum(KKz,2)).*scale_fac;
                            case 3 % im
                                tmp_x = imag(sum(KKx,2)).*scale_fac;
                                tmp_y = imag(sum(KKy,2)).*scale_fac;
                                tmp_z = imag(sum(KKz,2)).*scale_fac;
                        end
                    end
                    tmp_abs = sqrt(tmp_x.^2+tmp_y.^2+tmp_z.^2);
                    plot(tmp_x,kdata.measure.pm_vec, 'ro'); hold on
                    plot(tmp_y,kdata.measure.pm_vec, 'go');
                    plot(tmp_z,kdata.measure.pm_vec, 'bo');
                    plot(tmp_abs,kdata.measure.pm_vec, 'ko');
                    xlabel('amplitude [fT]', 'Fontsize', fs)
            end
            title('kernel row sums', 'FontSize', fs)
            axis ij
            box on
            grid on
            set(gca, 'layer', 'top');
            ylabel('pulse moment [As]', 'Fontsize', fs)
            hold off;
            
            switch get(uitogz, 'State')
                case 'off'
                    set(kplt, 'yscale','lin');
                    set(k1, 'yscale','lin');
                case 'on'
                    set(kplt, 'yscale','log');
                    set(k1, 'yscale','log');
            end
            switch get(uitogq, 'State')
                case 'off'
                    set(kplt, 'xscale','lin');
                    set(k2, 'yscale','lin');
                case 'on'
                    set(kplt, 'xscale','log');
                    set(k2, 'yscale','log');
            end
        end
        
        % export buttons
        function onExportPNG(a,b)
            [pname, ppath] = uiputfile({'*.png'},'export as png');
            [outpath, outname, outxt] = fileparts([ppath, pname]);
            print(kfig, '-dpng', '-r600', fullfile([outpath, filesep, outname, '.png']));
        end
        function onExportEPS(a,b)
            [pname, ppath] = uiputfile({'*.eps'},'export as eps');
            [outpath, outname, outxt] = fileparts([ppath, pname]);
            print(kfig, '-depsc2', '-painters', fullfile([outpath, filesep, outname, '.eps']));
        end
        
        % axis toggle
        function ontogLogZ(a,b)
            switch get(uitogz, 'State')
                case 'off'
                    set(kplt, 'yscale','lin');
                    set(k1, 'yscale','lin');
                case 'on'
                    set(kplt, 'yscale','log');
                    set(k1, 'yscale','log');
            end
        end
        function ontogLogQ(a,b)
            switch get(uitogq, 'State')
                case 'off'
                    set(kplt, 'xscale','lin');
                    set(k2, 'yscale','lin');
                case 'on'
                    set(kplt, 'xscale','log');
                    set(k2, 'yscale','log');
            end
        end
        
        % abs, re, im toggle buttons
        function t_absk(a,b)
            set(uirek, 'State', 'off')
            set(uiimk, 'State', 'off')
            kplt = plotK(1);
        end
        function t_rek(a,b)
            set(uiabsk, 'State', 'off')
            set(uiimk, 'State', 'off')
            kplt = plotK(2);
        end
        function t_imk(a,b)
            set(uiabsk, 'State', 'off')
            set(uirek, 'State', 'off')
            kplt = plotK(3);
        end
    end

    function onExport(a,b)
        [file.kernelname, file.kernelpath] = uiputfile({'*.mms'},'save kernel');
        if isfield(kdata, 'K')
            kdata = rmfield(kdata, 'K');
        end
        save([file.kernelpath, file.kernelname], 'kdata');
    end

    function onQuit(a,b)
        uiresume
        delete(gui.Window)
    end

    function onHelp(a,b)
        warndlg({'Whatever your question is:'; ''; 'Its not a bug - Its a feature!'; '';'All the rest is incorrect user action'}, 'modal')
    end

%% Loop Callbcks
    function onLoopShape(a,b)
        kdata.loop.size(2) = 0; % initially set here, to avoid error
        kdata.loop.shape = get(gui.LoopShape,'Value');
        
        switch kdata.loop.shape
            case 1 % circular
                set(gui.LoopSizeString,'String','Diameter [m]');
                set(gui.Loop8dir,'Enable','off','String', '');
                set(gui.LoopSizeInLoopReceiver,'Enable','off');
                kdata.loop.size(2) = 0;
                set(gui.LoopSep,'enable','off','String','');
                set(gui.LoopTurnsRx,'Enable','on');
            case 2 % square
                set(gui.LoopSizeString,'String','Size [m]');
                set(gui.Loop8dir, 'Enable','off','String','');
                set(gui.LoopSizeInLoopReceiver,'Enable','off');
                kdata.loop.size(2) = 0;
                set(gui.LoopSep,'enable','off','String','');
                set(gui.LoopTurnsRx,'Enable','on');
            case 3 % circular eight
                set(gui.LoopSizeString,'String','Diameter [m]');
                set(gui.Loop8dir, 'Enable','on','String',num2str(kdata.loop.eightoritn));
                set(gui.LoopSizeInLoopReceiver,'Enable','off');
                kdata.loop.size(2) = 0;
                set(gui.LoopSep,'enable','off','String','');
                set(gui.LoopTurnsRx,'Enable','on');
            case 4 % square eight
                set(gui.LoopSizeString,'String','Size [m]');
                set(gui.Loop8dir, 'Enable','on','String',num2str(kdata.loop.eightoritn));
                set(gui.LoopSizeInLoopReceiver,'Enable','off');
                kdata.loop.size(2) = 0;
                set(gui.LoopSep,'enable','off','String','');
                set(gui.LoopTurnsRx,'Enable','on');
            case 5 % circular Inloop
                set(gui.LoopSizeString,'String','Diameter [m] (Tx / Rx)');
                set(gui.Loop8dir, 'Enable','off','String', '');
                set(gui.LoopSizeInLoopReceiver,'Enable','on');
                kdata.loop.size(2) = str2double(get(gui.LoopSizeInLoopReceiver,'String'));
                set(gui.LoopSep,'enable','off','String','');
                set(gui.LoopTurnsRx,'Enable','on');
            case 6 % circular Seploop
                set(gui.LoopSizeString,'String','Diameter [m] (Tx / Rx)');
                set(gui.Loop8dir,'Enable','on','String', num2str(kdata.loop.eightoritn));
                set(gui.LoopSizeInLoopReceiver,'Enable','on');
                kdata.loop.size(2) = str2double(get(gui.LoopSizeInLoopReceiver,'String'));
                set(gui.LoopSep,'Enable','on','String',num2str(kdata.loop.eightsep));
                set(gui.LoopTurnsRx,'Enable','on');
            case 7 % circular Tx & dB/dt Rx
                set(gui.LoopSizeString,'String','Diameter [m]');
                set(gui.Loop8dir,'Enable','off','String','');
                set(gui.LoopSizeInLoopReceiver,'Enable','off');
                kdata.loop.size(2) = 0;
                set(gui.LoopSep,'enable','off','String','');
                set(gui.LoopTurnsRx,'Enable','off');
                kdata.loop.turns(2) = 1; 
            case 8 % circular Tx & B Rx
                set(gui.LoopSizeString,'String','Diameter [m]');
                set(gui.Loop8dir,'Enable','off','String','');
                set(gui.LoopSizeInLoopReceiver,'Enable','off');
                kdata.loop.size(2) = 0;
                set(gui.LoopSep,'enable','off','String','');
                set(gui.LoopTurnsRx,'Enable','off');
                kdata.loop.turns(2) = 1; 
        end        
    end

    function onLoop8dir(a,b)
        kdata.loop.eightoritn = str2double(get(gui.Loop8dir,'String'));
    end

    function onLoopSep(a,b)
        kdata.loop.eightsep = str2double(get(gui.LoopSep,'String'));
    end

    function onLoopSize(a,b)
        kdata.loop.size = str2double(get(gui.LoopSize, 'String'));
        switch kdata.loop.shape
            case {1,3,7,8} % circular loop, single or eight            
                kdata.model.zmax = 1.5 * kdata.loop.size;
                kdata.model.sinh_zmin = kdata.loop.size/500;
            case 2 % square loop, single or eight
                kdata.model.zmax = 1.5 * kdata.loop.size;
                kdata.model.sinh_zmin = kdata.loop.size/500;
            case 5 % InLoop
                kdata.model.zmax = 1.5 * max(kdata.loop.size);
                kdata.loop.size(2) = str2double(get(gui.LoopSizeInLoopReceiver, 'String'));
                kdata.model.sinh_zmin = kdata.loop.size(2)/500;
            case 6 % SEPLoop
                kdata.model.zmax = 1.5 * max(kdata.loop.size);
                kdata.loop.size(2)= str2double(get(gui.LoopSizeInLoopReceiver, 'String'));
                kdata.model.sinh_zmin = kdata.loop.size(2)/500;
        end
        
        kdata.model = MakeZvec(kdata.model);
        set(gui.ModelZvec, ...
            'Data', [(1:length(kdata.model.z))' kdata.model.z' kdata.model.Dz'])  
    end

    function onLoopTurns(a,b)
        kdata.loop.turns(1) = str2double(get(gui.LoopTurnsTx, 'String'));
        kdata.loop.turns(2) = str2double(get(gui.LoopTurnsRx, 'String'));
    end

    function onPXcheck(a,b)
        if get(gui.PXcheck,'Value') == 2
            set(gui.PXshape,'Enable','On');
            if get(gui.PXshape,'Value') == 2
                set(gui.PX8dir,'Enable','On');
            else
                set(gui.PX8dir,'Enable','Off');
            end
            set(gui.PXsize,'Enable','On');
            set(gui.PXcurrent,'Enable','On');
            set(gui.PXturns,'Enable','On');
            set(gui.PXramp,'Enable','On');
            if get(gui.PXramp,'Value') == 1
                set(gui.PXramptime,'Enable','Off');
            else
                set(gui.PXramptime,'Enable','On');
            end            
            kdata.measure.PX = 1;
            kdata.loop.PXshape = get(gui.PXshape,'Value');
            kdata.loop.PXsize = str2double(get(gui.PXsize,'String'));
            kdata.loop.PXcurrent = str2double(get(gui.PXcurrent,'String'));
            kdata.loop.PXturns = str2double(get(gui.PXturns,'String'));
        else
            set(gui.PXshape,'Enable','Off');
            set(gui.PXsize,'Enable','Off');
            set(gui.PXcurrent,'Enable','Off');
            set(gui.PXturns,'Enable','Off');
            set(gui.PX8dir,'Enable','Off');
            kdata.measure.PX = 0;
            set(gui.PXramp,'Enable','Off');
            set(gui.PXramptime,'Enable','Off');
            set(gui.pulsetype, 'Value',1);
            onEditPulseType;
            %kdata.loop = rmfield(kdata.loop,{'PXsize','PXcurrent','PX8dir'});
        end
    end

    function onPXshape(a,b)
        kdata.loop.PXshape = get(gui.PXshape,'Value');
        if kdata.loop.PXshape == 2
            set(gui.PX8dir,'Enable','On','String',num2str(kdata.loop.PX8dir));
        else
            set(gui.PX8dir,'Enable','Off','String','');
        end
    end

    function onPXsize(a,b)
        kdata.loop.PXsize = str2double(get(gui.PXsize,'String'));
    end

    function onPXcurrent(a,b)
        tmp = str2double(get(gui.PXcurrent,'String'));
        if tmp > 0
            kdata.loop.PXsign = 1;
        else
            kdata.loop.PXsign = -1;
        end
        kdata.loop.PXcurrent = abs(str2double(get(gui.PXcurrent,'String')));
        kdata.loop.PXturns  = str2double(get(gui.PXturns,'String'));
%         kdata.loop.I = str2double(get(gui.PXcurrent,'String'))*str2double(get(gui.PXturns,'String'));
    end

    function onPX8dir(a,b)
        kdata.loop.PX8dir  = str2double(get(gui.PX8dir,'String'));
    end

    function onPXramp(a,b)
        tmp = get(gui.PXramp,'Value');
        switch tmp
            case 1
                kdata.loop.usePXramp = false;
                kdata.loop.PXramp = 'none';
                set(gui.PXramptime,'Enable','Off');
            case 2
                kdata.loop.usePXramp = true;
                kdata.loop.PXramp = 'midi';
                set(gui.PXramptime,'Enable','On');
            case 3
                kdata.loop.usePXramp = true;
                kdata.loop.PXramp = 'lin';
                set(gui.PXramptime,'Enable','On');
            case 4
                kdata.loop.usePXramp = true;
                kdata.loop.PXramp = 'linexp';
                set(gui.PXramptime,'Enable','On');
            case 5
                kdata.loop.usePXramp = true;
                kdata.loop.PXramp = 'exp';
                set(gui.PXramptime,'Enable','On');
        end
    end

    function onPXramptime(a,b)
        kdata.loop.PXramptime = get(gui.PXramp,'Value')./1e3;
    end

    function onLoopShow(a,b)
        % NOTE: the main loop is centered at (0,0)
        % position figure window right of "MRS Kernel" window
        mrsmain = findobj('Type','Figure','Name','MRS Kernel');
        mpos = get(mrsmain,'Position');
        % check if there is already a figure window open
        isfig = findobj('Type','Figure','Name','loop layout');
        if isempty(isfig)        
            lfig = figure('NumberTitle','off','Name','loop layout','Position',[mpos(1)+mpos(3)+5 mpos(2) 500 500],'Toolbar','none');
            set(lfig, 'PaperUnits', 'points','PaperSize', [500 500],'PaperPosition', [0 0 500 500]);
            ax1 = axes('Tag','loop');
        else
            % reset axes;
            ax1 = findobj('Type','Axes','Tag','loop');
            cla(ax1);
            ll = findall(ax1,'Type','Line');
            delete(ll);
        end
        hold(ax1,'on');
        
        % 5 degree increments for plotting
        phi = linspace(0,2*pi,73);
        switch kdata.loop.shape
            case 1 % circular
                D = kdata.loop.size(1); R = D/2;
                x1 = R.*cos(phi); y1 = R.*sin(phi);
                plot(x1,y1,'k-','Parent',ax1); 
                plot(x1,y1,'g--','Parent',ax1);
            case 2 % square
                D = kdata.loop.size(1); R = D/2;
                x1 = [-R R R -R -R]; y1 = [-R -R R R -R];
                plot(x1,y1,'k-','Parent',ax1);
                plot(x1,y1,'g--','Parent',ax1);
            case 3 % circular-eight
                D = kdata.loop.size(1); R = D/2;
                orient = kdata.loop.eightoritn;
                % centered around 0
                cent = [R*cosd(orient+180) R*sind(orient+180);R*cosd(orient) R*sind(orient)];
                % centered around main loop
%                 cent = [0 0;D*cosd(-orient) D*sind(-orient)];
                x1 = cent(1,1) + R.*cos(phi); y1 = cent(1,2) + R.*sin(phi);
                x2 = cent(2,1) + R.*cos(phi); y2 = cent(2,2) + R.*sin(phi);
                plot(x1,y1,'k-','Parent',ax1);
                plot(x1,y1,'g--','Parent',ax1);
                plot(x2,y2,'k-','Parent',ax1,'HandleVisibility','off');
                plot(x2,y2,'g--','Parent',ax1,'HandleVisibility','off');
            case 4 % square-eight
                D = kdata.loop.size(1); R = D/2;
                orient = kdata.loop.eightoritn;
                % 1st loop
                x1 = [-R R R -R -R;-R -R R R -R]; x1 = x1';
                x1(:,1) = x1(:,1) - R;
                % 2nd loop
                x2(:,1) = x1(:,1) + D;
                x2(:,2) = x1(:,2);
                Rm = [cosd(-orient) -sind(-orient); sind(-orient) cosd(-orient)];
                x1 = x1*Rm;
                x2 = x2*Rm;                            
                plot(x1(:,1),x1(:,2),'k-','Parent',ax1);
                plot(x1(:,1),x1(:,2),'g--','Parent',ax1);
                plot(x2(:,1),x2(:,2),'k-','Parent',ax1,'HandleVisibility','off');
                plot(x2(:,1),x2(:,2),'g--','Parent',ax1,'HandleVisibility','off');
            case 5 % in-loop
                D1 = kdata.loop.size(1); R1 = D1/2;
                D2 = kdata.loop.size(2); R2 = D2/2;
                x1 = R1.*cos(phi); y1 = R1.*sin(phi);
                x2 = R2.*cos(phi); y2 = R2.*sin(phi);
                plot(x1,y1,'k-','Parent',ax1);
                plot(x2,y2,'g--','Parent',ax1);
            case 6 % sep-loop
                D1 = kdata.loop.size(1); R1 = D1/2;
                D2 = kdata.loop.size(2); R2 = D2/2;
                orient = kdata.loop.eightoritn;
                sep = kdata.loop.eightsep;
                x1 = R1.*cos(phi); y1 = R1.*sin(phi);
                x2 = R2.*cos(phi) + sep.*cosd(orient); y2 = R2.*sin(phi) + sep.*sind(orient);
                plot(x1,y1,'k-','Parent',ax1);
                plot(x2,y2,'g--','Parent',ax1);
            case {7,8}
                D = kdata.loop.size(1); R = D/2;
                x1 = R.*cos(phi); y1 = R.*sin(phi);
                plot(x1,y1,'k-','Parent',ax1); 
                plot(0,0,'g+','MarkerSize',15,'Parent',ax1);
        end
        
        % check for prepolarisation loop
        if get(gui.PXcheck,'Value') == 2            
            switch kdata.loop.PXshape
                case 1 % circular
                    PXD = kdata.loop.PXsize(1); PXR = PXD/2;
                    x1 = PXR.*cos(phi); y1 = PXR.*sin(phi);
                    plot(x1,y1,'r:','Parent',ax1);
                case 2 % circular-eight
                    PXD = kdata.loop.PXsize(1); PXR = PXD/2;
                    orient = kdata.loop.PX8dir;
                    PXcent = [PXR*cosd(orient+180) PXR*sind(orient+180);PXR*cosd(orient) PXR*sind(orient)];
                    x1 = PXcent(1,1) + PXR.*cos(phi); y1 = PXcent(1,2) + PXR.*sin(phi);
                    x2 = PXcent(2,1) + PXR.*cos(phi); y2 = PXcent(2,2) + PXR.*sin(phi);
                    plot(x1,y1,'r:','Parent',ax1);
                    plot(x2,y2,'r:','Parent',ax1,'HandleVisibility','off');
            end            
            % legend
            legend(ax1,'Tx','Rx','Px','Location','best');            
        else
            % legend
            legend(ax1,'Tx','Rx','Location','best');
        end
               
        set(ax1,'XLimMode','auto','YLimMode','auto');
        axis equal; box on;
        xlabel('x [m]'); ylabel('y [m]');
        hold(ax1,'off');
        limx = get(ax1,'XLim'); limy = get(ax1,'YLim');
        set(ax1,'XLim',[limx(1) limx(2)].*1.1,'YLim',[limy(1) limy(2)].*1.1);
    end

%% Model Callbacks
    function onModMaxZ(a,b)
        kdata.model.zmax = str2double(get(gui.ModMaxZ, 'String'));
        kdata.model = MakeZvec(kdata.model, kdata.earth);
    end

    function onModSetZ(a,b)
        kdata.model = SetZGui(kdata.loop.size(1), length(kdata.measure.pm_vec), kdata.model);
        set(gui.ModelZvec, ...
            'Data', [(1:length(kdata.model.z))' kdata.model.z' kdata.model.Dz'])
    end

%% Loop Callbacks
    function onMeasSetQ(a,b)
        [kdata.measure.pm_vec, kdata.measure.Imax_vec] = SetQGui(kdata.measure.pm_vec, kdata.measure.taup1);
        switch get(gui.pulsesequence,'Value')
            case {1,2}
                kdata.measure.pm_vec_2ndpulse = kdata.measure.pm_vec;
            case 3
                kdata.measure.pm_vec_2ndpulse = 2*kdata.measure.pm_vec;
        end    
%         uiwait()
        set(gui.MeasQvec, ...
            'Data', [(1:length(kdata.measure.pm_vec))' kdata.measure.pm_vec' (kdata.measure.Imax_vec)'])  % change when set Q
    end

%% adiabatic Callbacks
    function onEditPulseSequence(a,b)
        kdata.measure.pulsesequence = get(gui.pulsesequence,'Value');
        switch kdata.measure.pulsesequence
                case 1 % FID
                    set(gui.pulsetype,'Enable','on');
                    onEditPulseType;
                case 2 % T1
                    % default is B-field sensor as Rx and Px switch-off
                    set(gui.LoopShape,'Value',8);
                    onLoopShape;
                    set(gui.pulsetype,'Enable','on','Value',3);
                    onEditPulseType;
                case 3 % T2
                    set(gui.pulsetype,'Enable','off','Value',1);
                    onEditPulseType;
        end
    end

    function onEditPulseType(a,b)
        kdata.measure.pulsesequence = get(gui.pulsesequence,'Value');
        kdata.measure.pulsetype = get(gui.pulsetype, 'Value');
        %if ~kdata.measure.flag_loadAHP
            switch kdata.measure.pulsetype
                case 1 % standard
                    set(gui.edit_taup1,'Enable','On');
                    set(gui.edit_df,'Enable','On');
                    set(gui.pulsesequence,'Enable','on');
                    set(gui.advancedAP,'Enable','off');
                case 2 % adiabatic
                    set(gui.edit_taup1,'Enable','On');
                    set(gui.edit_df,'Enable','Off');
                    set(gui.pulsesequence,'Value',1,'Enable','off');
                    set(gui.advancedAP,'Enable','on');
                case 3 % Px switch-off
                    set(gui.edit_taup1,'Enable','Off');
                    set(gui.edit_df,'Enable','Off');
                    set(gui.advancedAP,'Enable','off');
                    set(gui.PXcheck,'Value',2);
                    onPXcheck;
                    switch kdata.measure.pulsesequence
                        case 1 % FID (a switch-off ramp is needed here)
                            set(gui.PXramp,'Value',2);
                            onPXramp;
                        otherwise % normal Px will also do
                            set(gui.PXramp,'Value',1);
                            onPXramp;
                    end                    
            end
        %end
    end

    function ontaup1CellEdit(a,b)
        kdata.measure.taup1 = str2double(get(gui.edit_taup1, 'String'));
        if kdata.measure.pulsetype==2
            kfig = findobj('Name', 'Set Adiabatic Pulse Parameter');
            if ~isempty(kfig)
                delete(kfig)
            end      
            drawpulseshape  % function to draw pulse shape  
        end
    end

    function oneditdf(a,b)
        kdata.measure.df = str2double(get(gui.edit_df, 'String')); 
    end
          
%% Earth Callbacks
    function onEarthB0(a,b)
        kdata.earth.erdt = str2double(get(gui.EarthB0,'String'))*1e-9; % nT-2-T
        kdata.earth.f = kdata.gammaH*kdata.earth.erdt/(2*pi);  % RD: why negative Lfrq?? TH: because Levitt ;-)
        kdata.earth.w_rf = kdata.earth.f*2*pi;
        kdata.measure.Imod.Qf0 = kdata.earth.f+kdata.measure.Imod.Qdf; 
        set(gui.EarthF,'String',num2str(round(kdata.earth.f*10)/10));
    end

    function onEarthW0(a,b)
        kdata.earth.f = str2double(get(gui.EarthF, 'String'));
        kdata.earth.w_rf = kdata.earth.f*2*pi;
        kdata.earth.erdt = kdata.earth.f*(2*pi)/kdata.gammaH;
        kdata.measure.Imod.Qf0 = kdata.earth.f+kdata.measure.Imod.Qdf; 
        set(gui.EarthB0,'String',num2str(round(kdata.earth.erdt*1e9)))
    end

    function onEarthInkl(a,b)
        kdata.earth.inkl = str2double(get(gui.EarthInkl, 'String'));
    end

    function onEarthDecl(a,b)
        kdata.earth.decl = str2double(get(gui.EarthDecl, 'String'));
    end

    function onEarthAqT(a,b)
        kdata.earth.temp = str2double(get(gui.AquaTemp, 'String'));
    end

    function onEarthRes(a,b)
       kdata.earth.res = get(gui.EarthRes, 'Value');
       switch kdata.earth.res
           case 0
               set(gui.EarthResMod,   'Enable', 'on')
               set(gui.EarthLayerAdd, 'Enable', 'on')
               set(gui.EarthLayerRem, 'Enable', 'on')
               set(gui.EarthLoadRes,  'Enable', 'on')
           case 1
               set(gui.EarthResMod,   'Enable', 'off')
               set(gui.EarthLayerAdd, 'Enable', 'off')
               set(gui.EarthLayerRem, 'Enable', 'off')
               set(gui.EarthLoadRes,  'Enable', 'off') 
       end
    end

    function onEarthLayerAdd(a,b)
        kdata.earth.nl = kdata.earth.nl+1;
        if kdata.earth.nl>1
            set(gui.EarthLayerRem, 'Enable', 'on');
        else
            set(gui.EarthLayerRem, 'Enable', 'off');
        end
%         kdata.earth.zm = (kdata.model.zmax/kdata.earth.nl:kdata.model.zmax/kdata.earth.nl:kdata.model.zmax-1);
        kdata.earth.zm = linspace(kdata.model.zmax/kdata.earth.nl,kdata.model.zmax,kdata.earth.nl-1);
        kdata.earth.sm = [kdata.earth.sm kdata.earth.sm(end)];
        set(gui.EarthResMod, ...
            'Data', [(1:length(kdata.earth.sm))' [kdata.earth.zm inf]' 1./kdata.earth.sm'])
    end

    function onEarthLayerRem(a,b)
        kdata.earth.nl = kdata.earth.nl-1;
        if kdata.earth.nl>1
            set(gui.EarthLayerRem, 'Enable', 'on');
        else
            set(gui.EarthLayerRem, 'Enable', 'off');
        end
        kdata.earth.zm(end) = [];
        kdata.earth.sm(end) = [];
        set(gui.EarthResMod, ...
            'Data', [(1:length(kdata.earth.sm))' [kdata.earth.zm inf]' 1./kdata.earth.sm'])
    end

    function onEarthResCellEdit(hTable, EdtData)
        switch EdtData.Indices(2)
            case 2
                kdata.earth.zm(EdtData.Indices(1)) = EdtData.NewData;
            case 3
                kdata.earth.sm(EdtData.Indices(1)) = 1/EdtData.NewData;
        end
        set(gui.EarthResMod, ...
            'Data', [(1:length(kdata.earth.sm))' [kdata.earth.zm inf]' 1./kdata.earth.sm'])
    end

    function onEarthLoadRes(a,b)
        [file.resname,file.respath] = uigetfile({'*.*'},'MultiSelect','off','open resistivity');
        res = dlmread([file.respath,file.resname]);% res(:,end)
        
        kdata.earth.zm = res(:,1)'; kdata.earth.zm(end) = [];
        kdata.earth.sm = 1./res(:,2)';
        kdata.earth.nl = length(kdata.earth.sm);
        
        set(gui.EarthResMod, ...
            'Data', [(1:length(kdata.earth.sm))' [kdata.earth.zm inf]' 1./kdata.earth.sm'])
    end

    function Initialize()
        proclog = struct();
        [kpath, filename, ext] = fileparts(sounding_pathdirfile);
        proclog = mrs_load_proclog([kpath filesep], [filename ext]);
        kfile   = [filename '.mrsk'];
    end

    function onSaveAndQuit(a,b)
        outfile = [kpath filesep kfile];
        save(outfile, 'kdata');
        fprintf(1,'kdata successfully saved to %s\n', outfile);
        uiresume;
        delete(gui.Window)
    end

    function onQuitWithoutSave(a,b)
        uiresume;
        delete(gui.Window)
    end

%% Function to draw pulse shape
    function drawpulseshape(a,b)
        if get(gui.pulsetype,'value') == 2
            dat = SetAPGUI(kdata.measure);
            kdata.measure.fmod = dat.fmod;
            kdata.measure.Imod = dat.Imod;
        end
    end

if standalone == 0
    uiwait(gui.Window)
end
end

%% Adiabatic pulse GUI
function APdat = SetAPGUI(measure)
APdat = CreateAPDat();
APgui = CreateAPGui();


    function APdat = CreateAPDat()
        APdat        = struct();
        APdat.Imod   = measure.Imod;
        APdat.fmod   = measure.fmod;
        APdat.flag_loadAHP   = max(measure.flag_loadAHP);
        if APdat.flag_loadAHP==1 % AHP pulse loaded
            APdat.t   = APdat.Imod.t_pulse(1,:);
            APdat.Imax_vec = measure.Imax_vec;
            APdat.I   = APdat.Imod.I;
            APdat.df  = APdat.fmod.df;
            APdat.enable = 'off';
            APdat.Imod.flag_Q=0;
        else % if no AHP pulse is loaded
            APdat.t = linspace(0,measure.taup1,100);
            [APdat.I, APdat.df] = mychirp(APdat.t, APdat.fmod, APdat.Imod);
            APdat.enable = 'on';
        end
        if APdat.Imod.flag_Q==1
            APdat.enabledQflag='on';
        else
            APdat.enabledQflag='off';
        end
    end

    function APgui = CreateAPGui()
        
        APgui.getfig = figure( ...
            'Name', 'Set Adiabatic Pulse Parameter', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'Toolbar', 'none', ...
            'HandleVisibility', 'on' );
        pos = get(APgui.getfig, 'Position');
        set(APgui.getfig, 'Position', [pos(1), pos(2) 800 300])
        
        parabox = uipanel('FontSize',12,...
            'Position',[.53 .05 .45 .9]);
        
        APgui.figFM = subplot(1,4,1);% frequency modulation
            plot(APdat.t,APdat.df,'-', 'linewidth', 3);
            xlabel('t [s]');ylabel('df [Hz]');
            xlim([0 max(APdat.t)]); 
        APgui.figIM = subplot(1,4,2);% frequency modulation
            if APdat.flag_loadAHP==1
                inputI = APdat.I(:,:);
                out = [];
                for p = 1:size(inputI)
                    B = 1/25*ones(25,1);
                    out(p,:) = filter(B,1,inputI(p,:));
                end
                plot(APdat.t,out./repmat(APdat.Imax_vec(:),1,size(out,2)),'-', 'linewidth', 2);hold on
                xlabel('t [s]');ylabel('I/I_{max} [ ]');
                %ylim([0 1.2]);
                xlim([0 max(APdat.t)]);
            else
                plot(APdat.t,APdat.I,'-', 'linewidth', 3);
                xlabel('t [s]');ylabel('I [Hz]');
                xlim([0 max(APdat.t)]);   
            end
                      

        %  right panel with dialogs
        uicontrol('Style', 'Text', 'Parent', parabox, 'String', 'frequency modulation','Position',[1 225 220 20]);
        APgui.FmodShape = uicontrol(...
            'Style', 'popupmenu', ...
            'Parent', parabox, ...
            'Enable', APdat.enable, ...
            'Value', APdat.fmod.shape,...
            'String', {'linear', 'tanh GMR', 'tanh MIDI'},...
            'Callback', @onfmod, 'Position',[220 230 80 20]);
        uicontrol('Style', 'Text', 'Parent', parabox, 'String', ' min [Hz], max [Hz], A, B','Position',[1 200 220 20]);
        APgui.Fmodstartdf = uicontrol(...
            'Style', 'Edit', ...
            'Parent', parabox, ...
            'Enable', APdat.enable, ...
            'String', num2str(APdat.fmod.startdf),...
            'Callback', @onfmodstartdf,'Position',[180 200 40 20]);
        APgui.Fmodenddf = uicontrol(...
            'Style', 'Edit', ...
            'Parent', parabox, ...
            'Enable', APdat.enable, ...
            'String', num2str(APdat.fmod.enddf),...
            'Callback', @onfmodenddf,'Position',[220 200 40 20]);
        APgui.FmodA = uicontrol(...
            'Style', 'Edit', ...
            'Parent', parabox, ...
            'Enable', 'off', ...
            'String', num2str(APdat.fmod.A),...
            'Callback', @onfmodA,'Position',[260 200 40 20]);
        APgui.FmodB = uicontrol(...
            'Style', 'Edit', ...
            'Parent', parabox, ...
            'Enable', 'off', ...
            'String', num2str(APdat.fmod.B),...
            'Callback', @onfmodB,'Position',[300 200 40 20]);
  
        uicontrol('Style', 'Text', 'Parent', parabox, 'String', 'current modulation','Position',[1 175 220 20]);
        APgui.Imod = uicontrol('Style', 'popupmenu', ...
            'Parent', parabox, ...
            'Enable', APdat.enable, ...
            'String', {'linear', 'tanh GMR', 'tanh MIDI'},...
            'Value', APdat.Imod.shape,...
            'Callback', @onImod,'Position',[220 175 80 20]);
        uicontrol('Style', 'Text', 'Parent', parabox, 'String', ' start [A], end [A], A, B' ,'Position',[1 150 220 20]);
        APgui.ImodstartI = uicontrol(...
            'Style', 'Edit', ...
            'Parent', parabox, ...
            'Enable', APdat.enable, ...
            'String', num2str(APdat.Imod.startI),...
            'Callback', @onImodstartI,'Position',[180 150 40 20]);
        APgui.ImodendI = uicontrol(...
            'Style', 'Edit', ...
            'Parent', parabox, ...
            'Enable', APdat.enable, ...
            'String', num2str(APdat.Imod.endI),...
            'Callback', @onImodendI,'Position',[220 150 40 20]);
        APgui.ImodA = uicontrol(...
            'Style', 'Edit', ...
            'Parent', parabox, ...
            'Enable', APdat.enable, ...
            'String', num2str(APdat.Imod.A),...
            'Callback', @onImodA,'Position',[260 150 40 20]);
        APgui.ImodB = uicontrol(...
            'Style', 'Edit', ...
            'Parent', parabox, ...
            'Enable', APdat.enable, ...
            'String', num2str(APdat.Imod.B),...
            'Callback', @onImodB,'Position',[300 150 40 20]);
        
        APgui.checkbox_ImodQ = uicontrol(...
            'Style', 'checkbox', ...
            'Parent', parabox, ...
            'String','add mod. by coil (Q-factor/df)',...
            'Value', APdat.Imod.flag_Q, ...
            'Enable', APdat.enable, ...
            'Callback', @onCheckboxImodQ,'Position',[1 125 220 20]);
        APgui.Q = uicontrol(...
            'Style', 'Edit', ...
            'Parent', parabox, ...
            'Enable', APdat.enabledQflag, ...
            'String', num2str(APdat.Imod.Q), ...
            'Callback', @onEditQ,'Position',[180 125 40 20]);
        APgui.Qdf = uicontrol(...
            'Style', 'Edit', ...
            'Parent', parabox, ...
            'Enable', APdat.enabledQflag, ...
            'String', num2str(APdat.Imod.Qdf), ...
            'Callback', @onEditQdf,'Position',[220 125 40 20]);
        APgui.checkbox_ImodRamp = uicontrol(...
            'Style', 'checkbox', ...
            'Parent', parabox, ...
            'String','add mod. by ramp up',...
            'Value', 0, ...
            'Enable', 'off', ...
            'Callback', @onCheckboxImodRamp,'Position',[1 100 220 20]);
        
        APgui.return   = uicontrol('Style', 'pushbutton', 'Parent', parabox, 'String', 'return', 'Callback', @onReturn,'Position',[1 1 355 40]);
    end
    
    % freq parameter
    function onfmod(a,b)
        APdat.fmod.shape = get(APgui.FmodShape, 'Value');
        switch APdat.fmod.shape
            case 1
                set(APgui.FmodA,'enable','off')
                set(APgui.FmodB,'enable','off')
            case 2
                set(APgui.FmodA,'enable','off')
                set(APgui.FmodB,'enable','off')
            case 3
                set(APgui.FmodA,'enable','on')
                set(APgui.FmodB,'enable','on')
        end
        APGuiDrawPulseShape
    end
    function onfmodstartdf(a,b)
        APdat.fmod.startdf = str2double(get(APgui.Fmodstartdf, 'String'));
        APGuiDrawPulseShape
    end
    function onfmodenddf(a,b)
        APdat.fmod.enddf = str2double(get(APgui.Fmodenddf, 'String'));
        APGuiDrawPulseShape
    end
    function onfmodA(a,b)
        APdat.fmod.A = str2double(get(APgui.FmodA, 'String'));
        APGuiDrawPulseShape
    end
    function onfmodB(a,b)
        APdat.fmod.B = str2double(get(APgui.FmodB, 'String'));
        APGuiDrawPulseShape
    end
    % current parameter
    function onImod(a,b)
        APdat.Imod.shape = get(APgui.Imod, 'Value');
        switch APdat.Imod.shape
            case 1
                set(APgui.ImodA,'enable','off')
                set(APgui.ImodB,'enable','off')
            case 2
                set(APgui.ImodA,'enable','off')
                set(APgui.ImodB,'enable','off')
            case 3
                set(APgui.ImodA,'enable','on')
                set(APgui.ImodB,'enable','on')
        end
        APGuiDrawPulseShape      
    end
    function onImodstartI(a,b)
        APdat.Imod.startI = str2double(get(APgui.ImodstartI, 'String'));
        APGuiDrawPulseShape
    end
    function onImodendI(a,b)
        APdat.Imod.endI = str2double(get(APgui.ImodendI, 'String'));
        APGuiDrawPulseShape
    end
    function onImodA(a,b)
        APdat.Imod.A = str2double(get(APgui.ImodA, 'String'));
        APGuiDrawPulseShape
    end
    function onImodB(a,b)
        APdat.Imod.B = str2double(get(APgui.ImodB, 'String'));
        APGuiDrawPulseShape
    end

    function onCheckboxImodQ(a,b)
        switch get(APgui.checkbox_ImodQ, 'Value')
            case 1 % enable Q-modulation               
                set(APgui.Q,  'Enable', 'On')
                set(APgui.Qdf,'Enable', 'On')
                APdat.Imod.flag_Q = 1;
                APGuiDrawPulseShape       
            case 0 % disable Q-modulation
                set(APgui.Q,          'Enable', 'Off')
                set(APgui.Qdf,        'Enable', 'Off')
                APdat.Imod.flag_Q = 0;
                APGuiDrawPulseShape
        end
    end
    function onEditQ(a,b)
        APdat.Imod.Q = str2double(get(APgui.Q, 'String'));
        APGuiDrawPulseShape  
    end
    function onEditQdf(a,b)
        APdat.Imod.Qdf = str2double(get(APgui.Qdf, 'String'));
        APGuiDrawPulseShape  
    end

    function onReturn(a,b)
        uiresume(gcbf)
        delete(APgui.getfig)
    end

    function APGuiDrawPulseShape
        [APdat.I, APdat.df] = mychirp(APdat.t, APdat.fmod, APdat.Imod);
        subplot(APgui.figFM);% frequency modulation
            plot(APdat.t,APdat.df,'-', 'linewidth', 3);
            xlabel('t [s]');ylabel('df [Hz]');
            xlim([0 max(APdat.t)]);
        subplot(APgui.figIM);% frequency modulation
            plot(APdat.t,APdat.I,'-', 'linewidth', 3);
            xlabel('t [s]');ylabel('I [Hz]');
            xlim([0 max(APdat.t)]);
    end
uiwait(gcf)
end

%% Z DISCRETIZATION GUI
function zmod = SetZGui(sloop, nq, zmod)
zfig = findobj('Name', 'Set z values');
if ~isempty(zfig)
    delete(zfig)
end
zmod = CreateZDat(sloop, nq, zmod);
zgui = CreateZGui();
% initialize fields
onQspacing()
onSetZ()

    function zmod = CreateZDat(sloop, nq, zmod)
        zmod.z_space = 1;
        zmod.zmax = 1.5*sloop;
        if nq < 24
            zmod.nz = 96;
        else
            zmod.nz = 4*nq;
        end
        zmod.sinh_zmin = sloop/500;
        zmod.LL_dzmin = sloop/500;
        zmod.LL_dzmax = sloop/50;
        zmod.LL_dlog = sloop/5;
    end

    function zgui = CreateZGui()
        
        zgui.getzfig = figure( ...
            'Name', 'Set z values', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'Toolbar', 'none', ...
            'HandleVisibility', 'on' );
        pos = get(zgui.getzfig, 'Position');
        set(zgui.getzfig, 'Position', [pos(1), pos(2) 400 300])
        
        %uiextras.set( zgui.getzfig, 'DefaultBoxPanelPadding', 5)
        %uiextras.set( zgui.getzfig, 'DefaultHBoxPadding', 2)
        
        uigetzf  = uiextras.HBox('Parent', zgui.getzfig);
        uigetzb1 = uiextras.VBox('Parent', uigetzf);
        zgui.ztab = uitable('Parent', uigetzb1);
        set(zgui.ztab, ...
            'Data', [(1:length(zmod.z))' zmod.z' zmod.Dz'], ...
            'ColumnName', {'#', 'z', 'dz'}, ...
            'ColumnWidth', {30 60 60}, ...
            'RowName', [], ...
            'ColumnEditable', false);
        
        uigetzb1a = uiextras.VBox('Parent', uigetzf);
        zgui.zax  = axes('Parent', uigetzb1a);
        pos = get(zgui.zax, 'Outerposition');
        set(zgui.zax, ...
            'Position', pos, ...
            'box', 'on', ...
            'XTickLabel', [], ...
            'YTickLabel', [])
        
        % right panel with dialogs
        uigetzb2 = uiextras.VBox('Parent', uigetzf, 'Padding', 5);
        
        uigetzh1  = uiextras.HBox('Parent', uigetzb2);
        zgui.Zmax_t = uicontrol('Style', 'text', 'Parent', uigetzh1, 'String', 'max depth');
        zgui.Zmax   = uicontrol('Style', 'edit', 'Parent', uigetzh1, 'String', num2str(zmod.zmax), 'Callback', @onZmax);
        
        uigetzh2      = uiextras.HBox('Parent', uigetzb2);
        zgui.Zspacing = uicontrol('Style', 'popupmenu', 'Parent', uigetzh2, 'String', {'sinh', 'loglin'}, 'Value', 1, 'Enable', 'on',  'Callback', @onQspacing);
               
        zgui.uigetzv3 = uiextras.VBox('Parent', uigetzb2);
        
        uigetzh4      = uiextras.HBox('Parent', uigetzb2);
        zgui.Qset     = uicontrol('Style', 'pushbutton', 'Parent', uigetzh4, 'String', 'set', 'Callback', @onSetZ);
        
        uigetzh5      = uiextras.HBox('Parent', uigetzb2);
        zgui.return   = uicontrol('Style', 'pushbutton', 'Parent', uigetzh5, 'String', 'return', 'Callback', @onReturn);
        
        set(uigetzb2, 'Sizes', [28 28 -1 28 28])
        
        set(uigetzf, 'Sizes', [170 60 170])
        
        
    end

    function onQspacing(a,b)
        acontrls = get(zgui.uigetzv3, 'Children');
        delete(acontrls)
        zmod.z_space = get(zgui.Zspacing, 'Value');
        switch zmod.z_space
            case 1 %sinh
                uigetzv3h1 = uiextras.HBox('Parent', zgui.uigetzv3);
                zgui.sinh_zmint = uicontrol('Style', 'text', 'Parent', uigetzv3h1, 'String', 'z min');
                zgui.sinh_zmin  = uicontrol('Style', 'edit', 'Parent', uigetzv3h1, 'String', num2str(zmod.sinh_zmin), 'Callback', @onSinhZmin);
                uigetzv3h2 = uiextras.HBox('Parent', zgui.uigetzv3);
                zgui.sinh_nzt   = uicontrol('Style', 'text', 'Parent', uigetzv3h2, 'String', '# layer');
                zgui.sinh_nz    = uicontrol('Style', 'edit', 'Parent', uigetzv3h2, 'String', num2str(zmod.nz), 'Callback', @onNz);
                uigetzv3h3 = uiextras.HBox('Parent', zgui.uigetzv3);
                set(zgui.uigetzv3, 'Sizes', [28 28 -1])
            case 2 %linlog
                uigetzv3h1 = uiextras.HBox('Parent', zgui.uigetzv3);
                zgui.ll_dzmint    = uicontrol('Style', 'text', 'Parent', uigetzv3h1, 'String', 'dz min');
                zgui.ll_dzmin     = uicontrol('Style', 'edit', 'Parent', uigetzv3h1, 'String', num2str(zmod.LL_dzmin), 'Callback', @onLLZmin);
                uigetzv3h2 = uiextras.HBox('Parent', zgui.uigetzv3);
                zgui.ll_dlogt = uicontrol('Style', 'text', 'Parent', uigetzv3h2, 'String', 'depth log');
                zgui.ll_dlog  = uicontrol('Style', 'edit', 'Parent', uigetzv3h2, 'String', num2str(zmod.LL_dlog), 'Callback', @onLLZminlog);
                uigetzv3h3 = uiextras.HBox('Parent', zgui.uigetzv3);
                zgui.ll_dzmaxt   = uicontrol('Style', 'text', 'Parent', uigetzv3h3, 'String', 'dz max');
                zgui.ll_dzmax    = uicontrol('Style', 'edit', 'Parent', uigetzv3h3, 'String', num2str(zmod.LL_dzmax), 'Callback', @onLLdZlin);
                uigetzv3h4 = uiextras.HBox('Parent', zgui.uigetzv3);
                set(zgui.uigetzv3, 'Sizes', [28 28 28 -1])
        end
        
    end

    function onSetZ(a,b)
        zmod = MakeZvec(zmod);
        set(zgui.ztab, ...
            'Data', [(1:length(zmod.z))' zmod.z' zmod.Dz'])
        zgui.zax; cla; hold on; axis ij
        for n = 1:length(zmod.z)
            plot([0 1], [zmod.z(n) zmod.z(n)], 'k-')
        end
    end

    function onReturn(a,b)
        uiresume(gcbf)
        delete(zgui.getzfig)
    end

    function onSinhZmin(a,b)
        zmod.sinh_zmin = str2double(get(zgui.sinh_zmin, 'String'));
    end

    function onNz(a,b)
        zmod.nz = str2double(get(zgui.sinh_nz, 'String'));
    end

    function onLLZmin(a,b)
        zmod.LL_dzmin = str2double(get(zgui.ll_dzmin, 'String'));        
    end

    function onLLZminlog(a,b)
        zmod.LL_dlog = str2double(get(zgui.ll_dlog, 'String'));
    end

    function onLLdZlin(a,b)
        zmod.LL_dzmax = str2double(get(zgui.ll_dzmax, 'String'));
    end
    function onZmax(a,b)
        zmod.zmax = str2double(get(zgui.Zmax, 'String'));
    end

uiwait(gcf)
end

%% PULSE MOMENTS GUI
function [pm_vec, Imax_vec] = SetQGui(pm_vec, taup1)

Imax_vec = pm_vec./taup1; % only true for on-res excitation

qdat = CreateQDat();
qgui = CreateQGui();


    function qdat = CreateQDat()
        qdat        = struct();
        qdat.nq     = length(pm_vec);
        qdat.qmin   = min(pm_vec);
        qdat.qmax   = max(pm_vec);
        qdat.qspace = 2;
    end

    function qgui = CreateQGui()
        
        qgui.getqfig = figure( ...
            'Name', 'Set q values', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'Toolbar', 'none', ...
            'HandleVisibility', 'on' );
        pos = get(qgui.getqfig, 'Position');
        set(qgui.getqfig, 'Position', [pos(1), pos(2) 300 300])
        
        %uiextras.set( qgui.getqfig, 'DefaultBoxPanelPadding', 5)
        %uiextras.set( qgui.getqfig, 'DefaultHBoxPadding', 2)
        
        uigetqf  = uiextras.HBox('Parent', qgui.getqfig);
        uigetqb1 = uiextras.VBox('Parent', uigetqf);
        qgui.qtab = uitable('Parent', uigetqb1);
        set(qgui.qtab, ...
            'Data', [(1:length(pm_vec))' pm_vec' (Imax_vec)'], ...
            'ColumnName', {'#', 'q [As]','max(I) [A]'}, ...
            'ColumnWidth', {20 65 65 }, ...
            'RowName', [], ...
            'ColumnEditable', true);
        
        % right panel with dialogs
        uigetqb2 = uiextras.VBox('Parent', uigetqf, 'Padding', 5);
        
        uigetqh1  = uiextras.HBox('Parent', uigetqb2);
        qgui.Qn_t = uicontrol('Style', 'text', 'Parent', uigetqh1, 'String', '# of q');
        qgui.Qn   = uicontrol('Style', 'edit', 'Parent', uigetqh1, 'String', num2str(length(pm_vec)), 'Callback', @onQnumber);
        
        uigetqh2 = uiextras.HBox('Parent', uigetqb2);
        qgui.QLin = uicontrol('Style', 'radiobutton', 'Parent', uigetqh2, 'String', 'lin', 'Value', 0, 'Enable', 'on',  'Callback', @onQLin);
        qgui.QLog = uicontrol('Style', 'radiobutton', 'Parent', uigetqh2, 'String', 'log', 'Value', 1, 'Enable', 'off', 'Callback', @onQLog);
        
        uigetqh3   = uiextras.HBox('Parent', uigetqb2);
        qgui.Qmin_t = uicontrol('Style', 'text', 'Parent', uigetqh3, 'String', 'q min');
        qgui.Qmin   = uicontrol('Style', 'edit', 'Parent', uigetqh3, 'String', num2str(min(pm_vec)), 'Callback', @onQmin);
        
        uigetqh4   = uiextras.HBox('Parent', uigetqb2);
        qgui.Qmax_t = uicontrol('Style', 'text', 'Parent', uigetqh4, 'String', 'q max');
        qgui.Qmax   = uicontrol('Style', 'edit', 'Parent', uigetqh4, 'String', num2str(max(pm_vec)), 'Callback', @onQmax);
        
        uigetqh5 = uiextras.HBox('Parent', uigetqb2);
        qgui.Qset = uicontrol('Style', 'pushbutton', 'Parent', uigetqh5, 'String', 'set', 'Callback', @onUpdateQTable);
        
        uigetqh6 = uiextras.HBox('Parent', uigetqb2);
        
        uigetqh7 = uiextras.HBox('Parent', uigetqb2);
        uicontrol('Style', 'pushbutton', 'Parent', uigetqh7, 'String', 'Return', 'Callback', @getqreturn)
        
        
        set(uigetqb2, 'Sizes', [28 28 28 28 28 -1 28])
        
        set(uigetqf, 'Sizes', [170 130])
    end


    function onQnumber(a,b)
        qdat.nq = str2double(get(qgui.Qn, 'String'));
    end

    function onQLin(a,b)
        qdat.qspace = 1;
        set(qgui.QLin, 'Enable', 'off', 'Value', 1)
        set(qgui.QLog, 'Enable', 'on',  'Value', 0)
    end

    function onQLog(a,b)
        qdat.qspace = 2;
        set(qgui.QLin, 'Enable', 'on',  'Value', 0)
        set(qgui.QLog, 'Enable', 'off', 'Value', 1)
    end

    function onQmin(a,b)
        qdat.qmin = str2double(get(qgui.Qmin, 'String'));
    end

    function onQmax(a,b)
        qdat.qmax = str2double(get(qgui.Qmax, 'String'));
    end

    function getqreturn(a,b)
        uiresume(gcbf)
        delete(qgui.getqfig)
    end

    function onUpdateQTable(a,b)
        switch qdat.qspace
            case 1
                pm_vec   = linspace(qdat.qmin, qdat.qmax, qdat.nq);
                Imax_vec = pm_vec./taup1;
            case 2
                pm_vec = logspace(log10(qdat.qmin), log10(qdat.qmax), qdat.nq);
                Imax_vec = pm_vec./taup1;                
        end 
        set(qgui.qtab, ...
            'Data', [(1:length(pm_vec))' pm_vec' (Imax_vec)'])
    end
uiwait(gcf)
end
