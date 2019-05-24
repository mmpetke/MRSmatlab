
% Problem: dropdown menus in maingui can be changed... include uiwait in
% maingui?

function [fdata,proclog] = mrs_edit_proclog(maingui,fdata,proclog,iQ,irec,irx,isig)
    
    % update gui status
    mrs_setguistatus(maingui,1,'Editing processing history...')

    % gui variables
    temp_fdata   = fdata;       % temp structures required for cancelling
    temp_proclog = proclog;
    
    % assemble table data
    type = {'  keep',...
            '  (trim)',...
            '  despike',...
            '  local NC',...
            '  global NC',...
            '  calc global TF',...
            };
        
    id = find(...
        proclog.event(:,1) < 6 & ...        % exclude calc TF (6) & trim (101)
        proclog.event(:,2) == iQ & ...
        proclog.event(:,3) == irec & ...
        proclog.event(:,4) == irx & ...
        proclog.event(:,5) == isig); % find ids for this record
    
    % JW: resorting is dangerous - does this affect the chronology? It must
    %     be preserved. Why is the sort necessary?
%     id =  sort([id; find(proclog.event(:,1) == 6)]); % add calculation of transferfct. since this is not related to a specific record
    
    clog = proclog.event(id,:);
    
    tabledata      = cell(size(id,1),3);
    tabledata(:,1) = {true};
    
    for ilog = 1:size(clog,1)
        tabledata(ilog,2) = {id(ilog)}; 
        tabledata(ilog,3) = type(clog(ilog,1)); 
    end    
    
    % allow only one instance of gui
    oldfigure = findobj('Name', 'Processing log for current FID');
    if ~isempty(oldfigure)
        delete(oldfigure)
    end
    
   
    % create gui figure
    gui.figureID = figure( ...
        'Name', 'Processing log for current FID', ...
        'NumberTitle', 'off', ...
        'MenuBar', 'none', ...
        'Toolbar', 'none', ...
        'HandleVisibility', 'on' );
    
    % gui figure size
    screensz = get(0,'ScreenSize');
    set(gui.figureID, 'Position', [15 screensz(4)-375 220 250])

    mainbox = uiextras.VBox('Parent', gui.figureID);

    % gui table
    box_h1 = uiextras.HBox('Parent', mainbox);    
    gui.table = uitable('Parent', box_h1);
    set(gui.table, ...
        'CellEditCallback', @onEditTable, ...
        'ColumnName', {'do', 'ID', 'type'}, ...
        'ColumnWidth', {30 30 150}, ...
        'ColumnEditable', [true false false], ...
        'ColumnFormat', {'logical','numeric','char'},...
        'Data', tabledata, ...
        'RowName', []);
    
    % gui pushbuttons
    box_h2 = uiextras.HBox('Parent', mainbox);
    gui.edit_status = uicontrol(...
        'Style', 'Text', ...
        'Parent', box_h2, ...
        'Enable', 'off', ...
        'String', ' ');
    gui.pushbutton_save = uicontrol(...
        'Enable', 'off', ...
        'Style', 'Pushbutton', ...
        'Parent', box_h2, ...
        'String', 'SAVE', ...
        'Callback', @onSave);
    gui.pushbutton_cancel = uicontrol(...
        'Enable', 'on', ...
        'Style', 'Pushbutton', ...
        'Parent', box_h2, ...
        'String', 'CANCEL', ...
        'Callback', @onCancel);
    set(box_h2, 'Sizes', [-1 50 50])         
    
    set(mainbox, 'Sizes', [-1 30])
    
    function onSave(a,b)
        proclog = temp_proclog;
        fdata   = temp_fdata;
        uiresume(gui.figureID)
        delete(gui.figureID)
    end

    function onCancel(a,b)
        uiresume(gui.figureID)
        delete(gui.figureID)
    end

    function onEditTable(a,b)
        
        % enable save after editing
        set(gui.pushbutton_save,'Enable', 'on')

        % tick / untick events
        switch b.NewData
            case true  % tick all events up to user-ticked ID
                tabledata(1:b.Indices(1),1) = {true};
            case false  % untick all events later than user-ticked ID
                tabledata(b.Indices(1):end,1) = {false};
        end
        set(gui.table, 'Data', tabledata)   % update table

        % reset fid to unprocessed state
        temp_fdata.Q(iQ).rec(irec).rx(irx).sig(isig).t1 = fdata.Q(iQ).rec(irec).rx(irx).sig(isig).t0;
        temp_fdata.Q(iQ).rec(irec).rx(irx).sig(isig).v1 = fdata.Q(iQ).rec(irec).rx(irx).sig(isig).v0;

        % reprocess up to selected step
        repro = cell2mat(tabledata(cell2mat(tabledata(:,1))==1,2));
        temp_fdata = mrs_reprocess_proclog(temp_fdata, proclog, repro);

        % update temporary proclog
        eventlist = proclog.event;  % reset to original
        eventlist(cell2mat(tabledata(cell2mat(tabledata(:,1))==0,2)),:) = [];     % delete unticked events
        temp_proclog.event = eventlist;

        % plot
        mrsSigPro_plotdata(maingui,temp_fdata,temp_proclog);

        % bring gui figure to front
        figure(gui.figureID)

        % update maingui status
        mrs_setguistatus(maingui,1,'Editing processing history...')
    end    

uiwait(gui.figureID)
end
