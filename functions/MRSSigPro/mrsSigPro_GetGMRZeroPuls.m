function niQ = mrsSigPro_GetGMRZeroPuls(fdata)
    
    niQ = [];
    vQ  = [fdata.Q(:).q]';
    nQ  = [1:1:length(vQ)]';
    
    tabledata      = cell(size(nQ,1),1);
    tabledata(:,1) = {true};
    for iq=1:length(nQ)
        tabledata(iq,2) = {nQ(iq)};
        tabledata(iq,3) = {vQ(iq)};
    end
    
    % allow only one instance of gui
    oldfigure = findobj('Name', 'Select pulses used for calculating transfer function');
    if ~isempty(oldfigure)
        delete(oldfigure)
    end
    
    % create gui figure
    gui.figureID = figure( ...
        'Name', 'Select pulses used for calculating transfer function', ...
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
        'ColumnName', {'include', '#Q', 'pulse moment /A.s'}, ...
        'ColumnWidth', {50 50 100}, ...
        'ColumnEditable', [true false false], ...
        'ColumnFormat', {'logical','numeric','numeric'},...
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
        'Enable', 'on', ...
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
        userSelect = get(gui.table,'data');
        niQ        = nQ(cell2mat(userSelect(:,1))==1);
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
    end    

uiwait(gui.figureID)
end
