function MRSWorkflow()

% allow only one instance of MRSWorkflow
wfig = findobj('Name', 'MRS Workflow');
if wfig
    delete(wfig)
end

% initialize mrsproject
mrsproject.path = [];
mrsproject.data.status      = 0;
mrsproject.data.dir         = '';
mrsproject.kernel.status    = 0;
mrsproject.kernel.dir       = '';
mrsproject.inversion.status = 0;
mrsproject.inversion.dir    = '';

gui  = createInterface();

    function gui = createInterface()
        set(0,'Units','pixels')
        scrsize = get(0, 'Screensize');
        gui.wWindow = figure;
        set(gui.wWindow, ...
            'Name', 'MRS Workflow', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'Toolbar', 'none', ...
            'HandleVisibility', 'on' );
       
        % no OuterPosition --> using Position
        set(gui.wWindow, 'Position', [20 scrsize(4)-400 570 350])
        
        uiextras.set( gui.wWindow, 'DefaultBoxPanelFontSize', 12);
        uiextras.set( gui.wWindow, 'DefaultBoxPanelFontWeight', 'bold')
        uiextras.set( gui.wWindow, 'DefaultBoxPanelPadding', 5)
        uiextras.set( gui.wWindow, 'DefaultHBoxPadding', 2)
        uiextras.set( gui.wWindow, 'DefaultVBoxPadding', 2)
        
        gui.wToolbar = uitoolbar(gui.wWindow);
        [X map]  = imread('new.png');
        newicon = ind2rgb(X,map);
        [X map]  = imread('open.png');
        openicon = ind2rgb(X,map);
        [X map]  = imread('save.png');
        saveicon = ind2rgb(X,map);
        uipushtool(gui.wToolbar, 'CData', newicon, 'ClickedCallback', @onNewPrj)
        uipushtool(gui.wToolbar, 'CData', openicon, 'ClickedCallback', @onOpenPrj);
        uipushtool(gui.wToolbar, 'CData', saveicon, 'ClickedCallback', @onSavePrj);
        
        %% create workflow boxes
        gui.wVBox = uiextras.VBox('Parent', gui.wWindow);
        
        gui.wProjectPanel   = uiextras.BoxPanel('Parent', gui.wVBox, 'Title', 'Project');
        gui.wImportPanel    = uiextras.BoxPanel('Parent', gui.wVBox, 'Title', 'Process', 'TitleColor',[0.5 0.5 0.5]);
      
        set(gui.wVBox, 'Sizes', [70 -1])
        
        %% create project box
        gui.project.box_h1   = uiextras.HBox('Parent', gui.wProjectPanel);
        gui.project.box_h1v1 = uiextras.VBox('Parent', gui.project.box_h1);
        gui.project.text_setpath  = uicontrol(...
            'Style', 'Text', ...
            'Parent', gui.project.('box_h1v1'), ...
            'String', 'Project Path');
        uiextras.HBox( 'Parent', gui.project.box_h1v1);
        set(gui.project.box_h1v1, 'Sizes', [30 -1])
        
        gui.project.box_h1v2  = uiextras.VBox('Parent', gui.project.box_h1);
        gui.project.edit_path = uicontrol(...
            'Style', 'Edit', ...
            'HorizontalAlignment', 'right', ... 
            'Parent', gui.project.('box_h1v2'), ...
            'String', mrsproject.path, ...
            'FontSize', 7, ...
            'Enable', 'off');
        uiextras.HBox( 'Parent', gui.project.box_h1v2);
        set(gui.project.box_h1v2, 'Sizes', [30 -1])
        
        set(gui.project.box_h1, 'Sizes', [100 -1])
        
        %% create process box
        gui.process.box_h1   = uiextras.HBox('Parent', gui.wImportPanel);
        gui.process.box_h1v1 = uiextras.VBox('Parent', gui.process.box_h1);
        gui.process.pushbutton_add = uicontrol(...
            'Style', 'Pushbutton', ...
            'Enable', 'off',...
            'Parent', gui.process.('box_h1v1'), ...
            'String', 'Add sounding',...
            'Callback', @onAddSounding);
        gui.process.pushbutton_remove = uicontrol(...
            'Style', 'Pushbutton', ...
            'Enable', 'off',...
            'Parent', gui.process.('box_h1v1'), ...
            'String', 'Remove sounding',...
            'Callback', @onRemoveSounding);
        gui.process.pushbutton_info = uicontrol(...
            'Style', 'Pushbutton', ...
            'Enable', 'off',...
            'Parent', gui.process.('box_h1v1'), ...
            'String', 'Info');
        gui.process.pushbutton_mrsmodelling = uicontrol(...
            'Style', 'Pushbutton', ...
            'Enable', 'off',...
            'Parent', gui.process.('box_h1v1'), ...
            'String', 'MRSmod',...
            'Callback', @onMRSmod);
        uiextras.HBox( 'Parent', gui.process.box_h1v1); % required for padding with 'Sizes' -1
        set(gui.process.box_h1v1, 'Sizes', [28 28 28 28 -1])
        
        gui.process.box_h1v2 = uiextras.VBox('Parent', gui.process.box_h1);
        gui.process.pushbutton_mrsimport = uicontrol(...
            'Style', 'Pushbutton', ...
            'Enable', 'off',...
            'Parent', gui.process.('box_h1v2'), ...
            'String', 'MRSSigPro',...
            'FontWeight','bold',...
            'Callback', @onMRSSignalPro);
        gui.process.pushbutton_mrsfit = uicontrol(...
            'Style', 'Pushbutton', ...
            'Enable', 'off',...
            'Parent', gui.process.('box_h1v2'), ...
            'String', 'MRSFit',...
            'FontWeight','bold',...
            'Callback', @onMRSFit);
        gui.process.pushbutton_mrst1 = uicontrol(...
            'Style', 'Pushbutton', ...
            'Enable', 'off',...
            'Parent', gui.process.('box_h1v2'), ...
            'String', 'MRST1',...
            'FontWeight','bold',...
            'Callback', @onMRST1);
        gui.process.pushbutton_mrskernel = uicontrol(...
            'Style', 'Pushbutton', ...
            'Enable', 'off',...
            'Parent', gui.process.('box_h1v2'), ...
            'String', 'MRSKernel',...
            'FontWeight','bold',...
            'Callback', @onMRSKernel);
        gui.process.pushbutton_mrsinversion = uicontrol(...
            'Style', 'Pushbutton', ...
            'Enable', 'off',...
            'Parent', gui.process.('box_h1v2'), ...
            'String', 'MRSInversion',...
            'FontWeight','bold',...
            'Callback', @onMRSInversion);
        gui.process.pushbutton_mrsT1inversion = uicontrol(...
            'Style', 'Pushbutton', ...
            'Enable', 'off',...
            'Parent', gui.process.('box_h1v2'), ...
            'String', 'MRST1Inversion',...
            'FontWeight','bold',...
            'Callback', @onMRST1Inversion);
        uiextras.HBox( 'Parent', gui.process.box_h1v2); % required for padding with 'Sizes' -1
        set(gui.process.box_h1v2, 'Sizes', [28 28 28 28 28 28 -1])
        
        gui.process.box_h1v3 = uiextras.VBox('Parent', gui.process.box_h1);
        gui.process.table_soundings = uitable('Parent', gui.process.box_h1v3);
        set(gui.process.table_soundings, ...
            'Enable','off',...
            'ColumnName', {' ', 'File', 'SigPro', 'Fit', 'T1', 'K', 'Inv'}, ...
            'ColumnWidth', {30 100 50 30 30 30 30}, ...
            'ColumnFormat', {'logical','char','logical','logical','logical','logical','logical','logical'},...
            'Data',{false, '', 0,0,0,0,0},...
            'RowName', [], ...
            'ColumnEditable', [true false false false false false false false]);
                
        set(gui.process.box_h1v3, 'Sizes', -1)
        
        % set sizes after creation of all widgets
        set(gui.process.box_h1, 'Sizes', [100 100 -1])
    end

    %% ICON NEW PROJECT ---------------------------------------------------
    function onNewPrj(a,b)
        
        inifile = mrs_readinifile;
        if strcmp(inifile.MRSWorkflow.file,'none') == 1
            inifile.MRSWorkflow.path = [pwd filesep];
            inifile.MRSWorkflow.file = 'mrs_project';
        end
        
        [filename,filepath] = uiputfile({...
            '*.mrsp','MRSMatlab project'; '*.*','All Files' },...
            'Save MRSMatlab project file',...
            [inifile.MRSWorkflow.path inifile.MRSWorkflow.file]);
        
        if filepath == 0;
            disp('Aborting...')
            return
        end
        
        mrsproject.path      = filepath;
        mrsproject.file      = filename;
        mrsproject.data      = struct();    % reset 
        mrsproject.kernel    = struct();    % reset
        mrsproject.inversion = struct();    % reset
        mrs_updateinifile([mrsproject.path mrsproject.file],0);
        save_mrsproject;
        refreshworkflow;
    end

    %% ICON OPEN PROJECT --------------------------------------------------
    function onOpenPrj(a,b)
        
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
        mrsproject = in.mrsproject;
        mrs_updateinifile([mrsproject.path mrsproject.file],0);
        save_mrsproject;
        refreshworkflow();
    end

    %% ICON SAVE PROJECT --------------------------------------------------
    function onSavePrj(a,b)
        save_mrsproject;
    end

    %% PUSHBUTTON ADD SOUNDING --------------------------------------------
    function onAddSounding(a,b)
        
        sounding_paths = ext_uipickfiles(...
            'FilterSpec', mrsproject.path, ...
            'Prompt','Add directories that contain the MRS Soundings'...
            );
            if ~iscell(sounding_paths)   % aborting (on CANCEL button)
                return
            end
        
        for iS = 1:length(sounding_paths)
            sounding_path = cell2mat(sounding_paths(iS));
            sounding_dir  = sounding_path(length(mrsproject.path)+1:end);

            ip = length(mrsproject.data);
            if ~isfield(mrsproject.data, 'dir') % first sounding that is added
                ip = 0;
            end
            mrsproject.data(ip+1).dir         = sounding_dir;
            mrsproject.data(ip+1).status      = 0;
            mrsproject.kernel(ip+1).dir       = '';
            mrsproject.kernel(ip+1).status    = 0;
            mrsproject.inversion(ip+1).dir    = '';
            mrsproject.inversion(ip+1).status = 0;
        end
        
        % reset T1 fitting status (if 1 -> 0), so that new soundings will
        % be included in next T1 fitting
        for iS = 1:length(mrsproject.data)
            if mrsproject.data(iS).status > 8
                mrsproject.data(iS).status = mrsproject.data(iS).status-8;
            end
        end
        
        refreshworkflow();
    end

    %% PUSHBUTTON REMOVE SOUNDING -----------------------------------------
    function onRemoveSounding(a,b)
        procme                    = SelectedSounding;
        mrsproject.data(procme)   = [];
        mrsproject.kernel(procme) = [];
        mrsproject.inversion(procme) = [];
        % reset T1 fitting status (if 1 -> 0)
        for iS = 1:length(mrsproject.data)
            if mrsproject.data(iS).status > 8
                mrsproject.data(iS).status = mrsproject.data(iS).status-8;
            end
        end        
        refreshworkflow;
    end    

    %% PUSHBUTTON MRS SignalProcessing ----------------------------------------------
    function onMRSSignalPro(a,b)
        
        procme = AllowOnlyOneSounding(SelectedSounding);    % get sounding
        if procme < 1; return; end                        % abort
        
        sounding_file = MRSSignalPro(...
            [mrsproject.path mrsproject.data(procme).dir filesep],...
            mrsproject.data(procme).status); % do Import
        if sounding_file == -1
            % "Quit without save" selected in MRSImport
        else % update status/gui/file
            mrsproject.data(procme).status = 1;
            mrsproject.data(procme).file   = sounding_file;
            save_mrsproject;
        end
        refreshworkflow;
    end

%     %% PUSHBUTTON MRS NOISEREDUCTION --------------------------------------
%     function onMRSNoisereduction(a,b)
%         
%         procme = AllowOnlyOneSounding(SelectedSounding);    % get sounding
%         if procme < 1; return; end                        % abort
%         
%         welldone = MRSNoisereduction([mrsproject.path mrsproject.data(procme).dir filesep mrsproject.data(procme).file]);
%         if welldone
%             mrsproject.data(procme).status = bitor(mrsproject.data(procme).status, 2); % add 2
%             save_mrsproject;
%         else
%             disp('MRSNoiserduction returned without saving proclog\n')
%         end
%         refreshworkflow;
%     end

    %% PUSHBUTTON MRS FIT -------------------------------------------------
    function onMRSFit(a,b)
        
        procme = AllowOnlyOneSounding(SelectedSounding);    % get sounding
        if procme < 1; return; end                        % abort

        welldone = MRSFit([mrsproject.path  mrsproject.data(procme).dir filesep mrsproject.data(procme).file]);
        if welldone
            if mrsproject.data(procme).status > 8 % T1 fit has been carried out before; reset T1 fit to 0
                mrsproject.data(procme).status = mrsproject.data(procme).status - 8;
            end
            mrsproject.data(procme).status = bitor(mrsproject.data(procme).status, 4);  % add 4
            save_mrsproject;
        else
            disp('MRSFit returned without saving proclog\n')
        end
        refreshworkflow;
    end

    %% PUSHBUTTON MRS T1 --------------------------------------------------
    % currently disabled by MMP
    % check if necessary if MRST1Inversion is used?
    function onMRST1(a,b)
        
        % use all soundings in MRSWorkflow table
        soundings    = get(gui.process.table_soundings, 'Data');
        
        % only proceed if all soundings have status > 3 (i.e., fitted)
        if min([mrsproject.data.status]) >= bin2dec('0101')
            T1data = MRST1(mrsproject);
            if isstruct(T1data)     % if returned with save instruction
                for iS = 1:size(soundings,1)
                    mrsproject.data(iS).status = bitor(mrsproject.data(iS).status, 8);  % add 8
                end
                mrsproject.T1 = T1data;
                save_mrsproject;
            else
                disp('MRST1 returned without saving T1data\n')
            end
        else
            msgbox({'Error:'; ...
                    'T1 processing only allowed if all soundings have been fitted!'; ...
                    'Aborting...'},'Selection error','error')
        end
        refreshworkflow;
    end

    %% PUSHBUTTON MRS KERNEL ----------------------------------------------
    function onMRSKernel(a,b)
        
        procme = AllowOnlyOneSounding(SelectedSounding);    % get sounding
        if procme == -1; return;                        % abort
        elseif procme == 0
            procme = 1;
            mrsproject.kernel(procme).file = MRSKernel(...
                [mrsproject.path  ...
                 mrsproject.file]);
        else
            mrsproject.kernel(procme).file = MRSKernel(...
                [mrsproject.path  ...
                 mrsproject.data(procme).dir filesep ...
                 mrsproject.data(procme).file]);            
        end 
        if mrsproject.kernel(procme).file == -1
            disp(' ')
            disp('MRSKernel returned without saving proclog')
            mrsproject.kernel(procme).file = ''; 
            procme = 0;
        else
            mrsproject.kernel(procme).status = 1;
            save_mrsproject;
        end
        refreshworkflow;
    end

    %% PUSHBUTTON MRS INVERSION -------------------------------------------
    function onMRSInversion(a,b)
        
        procme = AllowOnlyOneSounding(SelectedSounding);    % get sounding
        if procme < 1; return; end                        % abort
        
        dfile = ([mrsproject.path  mrsproject.data(procme).dir filesep mrsproject.data(procme).file]);
        kfile = ([mrsproject.path  mrsproject.data(procme).dir filesep mrsproject.kernel(procme).file]);
        if mrsproject.inversion(procme).status
           % ifile=[];
            ifile = ([mrsproject.path  mrsproject.data(procme).dir filesep mrsproject.inversion(procme).file]);
        else
            ifile=[];
        end
        
        mrsproject.inversion(procme).file = MRSQTInversion(dfile, kfile, ifile);
        if ~isempty(mrsproject.inversion(procme).file)
            mrsproject.inversion(procme).status = 1;
            save_mrsproject;
        else
            disp('MRSInversion returned without saving proclog\n')
        end
        refreshworkflow;
    end
%% PUSHBUTTON MRS T1 INVERSION
    function onMRST1Inversion(a,b)
        projectfile = [mrsproject.path mrsproject.file];
        MRST1Inversion(projectfile);
    end
%% PUSHBUTTON MRS MODELLING -------------------------------------------
    function onMRSmod(a,b)
        
        procme = AllowOnlyOneSounding(SelectedSounding);    % get sounding
        if procme == -1; return; end                        % abort
        if procme == 0; 
           kfile = ([mrsproject.path  mrsproject.kernel(1).file]);
           welldone = MRSModelling(kfile);
           if welldone % reload project
               in = load([mrsproject.path mrsproject.file], '-mat');
               mrsproject = in.mrsproject;
               refreshworkflow();
           end
        else
           kfile = ([mrsproject.path  mrsproject.kernel(procme).dir filesep mrsproject.kernel(procme).file]);
           welldone = MRSModelling(kfile); 
        end % only kernel exist
%         dfile = ([mrsproject.path  mrsproject.data(procme).dir filesep mrsproject.data(procme).file]);
        
%         if ~isempty(mrsproject.kernel(procme).file)
%             mrsproject.inversion(procme).status = 1;
%             save_mrsproject;
%         else
%             disp('MRSInversion returned without saving proclog\n')
%         end
        refreshworkflow;
    end

    %% FUNCTION REFRESH WORKFLOW ------------------------------------------
    function refreshworkflow()
        
        set(gui.project.edit_path, 'String', [mrsproject.path mrsproject.file])
        
        % update data table for each entry in mrsproject.data
        if isfield(mrsproject.data, 'dir')
            n_data = length(mrsproject.data);
            data   = cell(n_data,7);
            for n  = 1:n_data
                proc_status = dec2bin(mrsproject.data(n).status,4);
                data{n,1} = false;
                data{n,2} = char(mrsproject.data(n).dir);
                data{n,3} = logical(str2double(proc_status(4)));
                data{n,4} = logical(str2double(proc_status(2)));
                data{n,5} = logical(str2double(proc_status(1)));                
                data{n,6} = logical(mrsproject.kernel(n).status);
                data{n,7} = logical(mrsproject.inversion(n).status);
            end
            set(gui.process.table_soundings, 'Data', data)
            
            if isempty(mrsproject.data(1).dir)
                set(gui.process.pushbutton_remove, 'Enable', 'off')
                set(gui.process.pushbutton_mrsimport, 'Enable', 'off')
                set(gui.process.pushbutton_mrsfit, 'Enable', 'off')
                set(gui.process.table_soundings, 'Enable', 'off')
            else
                set(gui.process.pushbutton_add, 'Enable', 'on')
                set(gui.process.pushbutton_remove, 'Enable', 'on')
                set(gui.process.pushbutton_mrsimport, 'Enable', 'on')
                set(gui.process.pushbutton_mrsfit, 'Enable', 'on')
                %set(gui.process.pushbutton_mrst1, 'Enable', 'on')
                set(gui.process.pushbutton_mrsT1inversion, 'Enable', 'on')
                set(gui.process.pushbutton_mrskernel, 'Enable', 'on')
                set(gui.process.pushbutton_mrsinversion, 'Enable', 'on')
                set(gui.process.pushbutton_mrsmodelling, 'Enable', 'on')
                set(gui.process.table_soundings, 'Enable', 'on')
            end
        else
            set(gui.process.table_soundings,'Data',{false,'',0,0,0,0,0}) 
            set(gui.process.pushbutton_mrskernel, 'Enable', 'on')
            if ~isempty(mrsproject.kernel)
                set(gui.process.pushbutton_mrsmodelling, 'Enable', 'on')
            end
%             n_data = length(mrsproject.kernel);
%             for n  = 1:n_data
%                 
%             end
        end
        set(gui.process.pushbutton_add, 'Enable', 'on')     
    end

    %% FUNCTION SELECTED SOUNDING -----------------------------------------
    function procme = SelectedSounding()
        % determine which sounding is ticked for processing
        soundings = get(gui.process.table_soundings, 'Data');
        procme = cell2mat(soundings(:,1));        
    end

    %% FUNCTION ALLOW ONLY ONE SOUNDING -----------------------------------
    function procme = AllowOnlyOneSounding(procme)
        % check for field data processing vs. modelling
        if isfield(mrsproject.data, 'dir') % soundings available
            if length(procme(procme==1)) ~= 1   % abort if more than one is selected
                msgbox({'Error in tickbox selection in "Import data":'; ...
                    'Only one sounding can be selected for processing!'; ...
                    'Aborting...'},'Selection error','error')
                procme = -1;
            end
        else % no soundings available --> modeling
            procme = 0;
        end
    end

    %% FUNCTION SAVE MRSPROJECT -------------------------------------------
    function save_mrsproject()
        % ask before overwriting?
        save([mrsproject.path mrsproject.file], 'mrsproject');
        fprintf(1,'mrsproject saved to %s\n', mrsproject.path);
    end

end
