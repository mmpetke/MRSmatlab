classdef GridFlex < uiextras.Grid
    %GridFlex  Container with contents arranged in a resizable grid
    %
    %   obj = uiextras.GridFlex() creates a new new grid layout with
    %   draggable dividers between elements. The number of rows and columns
    %   to use is determined from the number of elements in the RowSizes
    %   and ColumnSizes properties respectively. Child elements are
    %   arranged down column one first, then column two etc. If there are
    %   insufficient columns then a new one is added. The output is a new
    %   layout object that can be used as the parent for other
    %   user-interface components. The output is a new layout object that
    %   can be used as the parent for other user-interface components.
    %
    %   obj = uiextras.GridFlex(param,value,...) also sets one or more
    %   parameter values.
    %
    %   See the <a href="matlab:doc uiextras.GridFlex">documentation</a> for more detail and the list of properties.
    %
    %   Examples:
    %   >> f = figure();
    %   >> g = uiextras.GridFlex( 'Parent', f, 'Spacing', 5 );
    %   >> uicontrol( 'Parent', g, 'Background', 'r' )
    %   >> uicontrol( 'Parent', g, 'Background', 'b' )
    %   >> uicontrol( 'Parent', g, 'Background', 'g' )
    %   >> uiextras.Empty( 'Parent', g )
    %   >> uicontrol( 'Parent', g, 'Background', 'c' )
    %   >> uicontrol( 'Parent', g, 'Background', 'y' )
    %   >> set( g, 'ColumnSizes', [-1 100 -2], 'RowSizes', [-1 -2] );
    %
    %   See also: uiextras.Grid
    %             uiextras.HBoxFlex
    %             uiextras.VBoxFlex
    %             uiextras.Empty
    
    %   Copyright 2009-2010 The MathWorks, Inc.
    %   $Revision: 324 $
    %   $Date: 2010-08-06 16:30:39 +0100 (Fri, 06 Aug 2010) $
    
    properties
        ShowMarkings = 'on'  % Show markings on the draggable dividers [ on | off ]
    end % public methods
    
    properties( SetAccess = private, GetAccess = private )
        SelectedRowDivider = -1
        SelectedColumnDivider = -1
    end % private properties
    
    methods
        
        function obj = GridFlex( varargin )
            %GridFlex  Container with contents in a grid and movable dividers
            
            % First step is to create the parent class. We pass the
            % arguments (if any) just incase the parent needs setting
            obj@uiextras.Grid( varargin{:} );
            
            % Set some defaults
            obj.setPropertyFromDefault( 'ShowMarkings' );
            
            % Set user-supplied property values
            if nargin > 0
                set( obj, varargin{:} );
            end
        end % constructor
        
    end % public methods
    
    methods
        
        function set.ShowMarkings( obj, value )
            % Check
            if ~ischar( value ) || ~ismember( lower( value ), {'on','off'} )
                error( 'GUILayout:InvalidPropertyValue', ...
                    'Property ''ShowMarkings'' may only be set to ''on'' or ''off''.' )
            end
            % Apply
            obj.ShowMarkings = lower( value );
            obj.redraw();
        end % set.ShowMarkings
        
    end % accessor methods
    
    methods( Access = protected )
        
        function redraw( obj )
            %redraw  Redraw container contents
            
            % First simply call the grid redraw
            [widths,heights] = redraw@uiextras.Grid(obj);
            rowSizes = obj.RowSizes;
            columnSizes = obj.ColumnSizes;
            padding = obj.Padding;
            spacing = obj.Spacing;
            pos0 = ceil( getpixelposition( obj.UIContainer ) );
            
            % Now add the column dividers
            delete( findall( obj.Parent, 'Tag', 'UIExtras:GridFlex:ColumnDivider', 'Parent', obj.UIContainer ) );
            mph = uiextras.MousePointerHandler( obj.Parent );
            for ii = 1:numel(columnSizes)-1
                if any(columnSizes(1:ii)<0) && any(columnSizes(ii+1:end)<0)
                    % Both dynamic, so add a divider
                    position = [sum( widths(1:ii) ) + padding + spacing * (ii-1) + 1, ...
                        padding + 1, ...
                        max(1,spacing), ...
                        max(1,pos0(4)-2*padding)];
                    % Create the divider widget
                    uic = uiextras.makeFlexDivider( ...
                        obj.UIContainer, ...
                        position, ...
                        get( obj.UIContainer, 'BackgroundColor' ), ...
                        'Vertical', ...
                        obj.ShowMarkings );
                    set( uic, 'ButtonDownFcn', @obj.onColumnButtonDown, ...
                        'Tag', 'UIExtras:GridFlex:ColumnDivider' );
                    setappdata( uic, 'WhichDivider', ii );
                    % Add it to the mouse-over handler
                    mph.register( uic, 'left' );
                end
            end
            
            % Now add the row dividers
            delete( findall( obj.Parent, 'Tag', 'UIExtras:GridFlex:RowDivider', 'Parent', obj.UIContainer ) );
            for ii = 1:numel(rowSizes)-1
                if any(rowSizes(1:ii)<0) && any(rowSizes(ii+1:end)<0)
                    % Both dynamic, so add a divider
                    position = [padding + 1, ...
                        pos0(4) - sum( heights(1:ii) ) - padding - spacing*ii + 1, ...
                        max(1,pos0(3)-2*padding), ...
                        max(1,spacing)];
                    % Create the divider widget
                    uic = uiextras.makeFlexDivider( ...
                        obj.UIContainer, ...
                        position, ...
                        get( obj.UIContainer, 'BackgroundColor' ), ...
                        'Horizontal', ...
                        obj.ShowMarkings );
                    set( uic, 'ButtonDownFcn', @obj.onRowButtonDown, ...
                        'Tag', 'UIExtras:GridFlex:RowDivider' );
                    setappdata( uic, 'WhichDivider', ii );
                    % Add it to the mouse-over handler
                    mph.register( uic, 'top' );
                end
            end
        end % redraw
        
        function onRowButtonDown( obj, source, eventData ) %#ok<INUSD>
            figh = ancestor( source, 'figure' );
            % Remove all column dividers
            ch = allchild( obj.UIContainer );
            dividers = strcmpi( get( ch, 'Tag' ), 'GridFlex:ColumnDivider' );
            delete( ch(dividers) );
            % We need to store any existing motion callbacks so that we can
            % restore them later.
            oldProps = struct();
            oldProps.WindowButtonMotionFcn = get( figh, 'WindowButtonMotionFcn' );
            oldProps.WindowButtonUpFcn = get( figh, 'WindowButtonUpFcn' );
            oldProps.Pointer = get( figh, 'Pointer' );
            oldProps.Units = get( figh, 'Units' );

            % Make sure all interaction modes are off to prevent our
            % callbacks being clobbered
            zoomh = zoom( figh );
            r3dh = rotate3d( figh );
            panh = pan( figh );
            oldState = '';
            if isequal( zoomh.Enable, 'on' )
                zoomh.Enable = 'off';
                oldState = 'zoom';
            end
            if isequal( r3dh.Enable, 'on' )
                r3dh.Enable = 'off';
                oldState = 'rotate3d';
            end
            if isequal( panh.Enable, 'on' )
                panh.Enable = 'off';
                oldState = 'pan';
            end
            
            
            % Now hook up new callbacks
            set( figh, ...
                'WindowButtonMotionFcn', @obj.onRowButtonMotion, ...
                'WindowButtonUpFcn', {@obj.onRowButtonUp, oldProps, oldState}, ...
                'Pointer', 'top', ...
                'Units', 'Pixels' );
            % Make the divider visible
            cdata = get( source, 'CData' );
            if mean( cdata(:) ) < 0.5
                % Make it brighter
                cdata = 1-0.5*(1-cdata);
                newCol = 1-0.5*(1-get( obj.UIContainer, 'BackgroundColor' ));
            else
                % Make it darker
                cdata = 0.5*cdata;
                newCol = 0.5*get( obj.UIContainer, 'BackgroundColor' );
            end
            set( source, ...
                'BackgroundColor', newCol, ...
                'ForegroundColor', newCol, ...
                'CData', cdata );
            
            obj.SelectedRowDivider = source;
        end % onRowButtonDown
        
        function onRowButtonMotion( obj, source, eventData ) %#ok<INUSD>
            figh = ancestor( source, 'figure' );
            cursorpos = get( figh, 'CurrentPoint' );
            dividerpos = get( obj.SelectedRowDivider, 'Position' );
            pos0 = getpixelposition( obj.UIContainer, true );
            dividerpos(2) = cursorpos(2) - pos0(2) - round(obj.Spacing/2) + 1;
            set( obj.SelectedRowDivider, 'Position', dividerpos );
        end % onRowButtonMotion
        
        function onRowButtonUp( obj, source, eventData, oldFigProps, oldState )
            % Deliberately call the motion function to ensure any last
            % movement is captured
            obj.onRowButtonMotion( source, eventData );
            
            % Restore figure properties
            figh = ancestor( source, 'figure' );
            flds = fieldnames( oldFigProps );
            for ii=1:numel(flds)
                set( figh, flds{ii}, oldFigProps.(flds{ii}) );
            end
            
            % If the figure has an interaction mode set, re-set it now
            if ~isempty( oldState )
                switch upper( oldState )
                    case 'ZOOM'
                        zoom( figh, 'on' );
                    case 'PAN'
                        pan( figh, 'on' );
                    case 'ROTATE3D'
                        rotate3d( figh, 'on' );
                    otherwise
                        error( 'GUILayout:InvalidState', 'Invalid interaction mode ''%s''.', oldState );
                end
            end
            
            % Work out which divider was moved and which are the resizable
            % elements either side of it
            whichDivider = getappdata( obj.SelectedRowDivider, 'WhichDivider' );
            origPos = getappdata( obj.SelectedRowDivider, 'OriginalPosition' );
            newPos = get( obj.SelectedRowDivider, 'Position' );
            obj.SelectedRowDivider = -1;
            delta = newPos(2) - origPos(2) - round(obj.Spacing/2) + 1;
            sizes = obj.RowSizes;
            % Convert all flexible sizes into pixel units
            totalPosition = ceil( getpixelposition( obj.UIContainer ) );
            totalHeight = totalPosition(4);
            heights = obj.calculatePixelSizes( totalHeight, sizes );
            
            topelement = find( sizes(1:whichDivider)<0, 1, 'last' );
            bottomelement = find( sizes(whichDivider+1:end)<0, 1, 'first' )+whichDivider;
            
            % Now work out the new sizes. Note that we must ensure the size
            % stays negative otherwise it'll stop being resizable
            change = sum(sizes(sizes<0)) * delta / sum( heights(sizes<0) );
            sizes(topelement) = min( -0.000001, sizes(topelement) - change );
            sizes(bottomelement) = min( -0.000001, sizes(bottomelement) + change );
            
            % Setting the sizes will cause a redraw
            obj.RowSizes = sizes;
        end % onRowButtonUp
        
        function onColumnButtonDown( obj, source, eventData ) %#ok<INUSD>
            % Remove all row dividers
            figh = ancestor( source, 'figure' );
            ch = allchild( obj.UIContainer );
            dividers = strcmpi( get( ch, 'Tag' ), 'GridFlex:RowDivider' );
            delete( ch(dividers) );
            % We need to store any existing motion callbacks so that we can
            % restore them later.
            oldProps = struct();
            oldProps.WindowButtonMotionFcn = get( figh, 'WindowButtonMotionFcn' );
            oldProps.WindowButtonUpFcn = get( figh, 'WindowButtonUpFcn' );
            oldProps.Pointer = get( figh, 'Pointer' );
            oldProps.Units = get( figh, 'Units' );
            
            % Make sure all interaction modes are off to prevent our
            % callbacks being clobbered
            zoomh = zoom( figh );
            r3dh = rotate3d( figh );
            panh = pan( figh );
            oldState = '';
            if isequal( zoomh.Enable, 'on' )
                zoomh.Enable = 'off';
                oldState = 'zoom';
            end
            if isequal( r3dh.Enable, 'on' )
                r3dh.Enable = 'off';
                oldState = 'rotate3d';
            end
            if isequal( panh.Enable, 'on' )
                panh.Enable = 'off';
                oldState = 'pan';
            end
            
            % Now hook up new callbacks
            set( figh, ...
                'WindowButtonMotionFcn', @obj.onColumnButtonMotion, ...
                'WindowButtonUpFcn', {@obj.onColumnButtonUp, oldProps, oldState}, ...
                'Pointer', 'left', ...
                'Units', 'Pixels' );
            % Make the divider visible
            cdata = get( source, 'CData' );
            if mean( cdata(:) ) < 0.5
                % Make it brighter
                cdata = 1-0.5*(1-cdata);
                newCol = 1-0.5*(1-get( obj.UIContainer, 'BackgroundColor' ));
            else
                % Make it darker
                cdata = 0.5*cdata;
                newCol = 0.5*get( obj.UIContainer, 'BackgroundColor' );
            end
            set( source, ...
                'BackgroundColor', newCol, ...
                'ForegroundColor', newCol, ...
                'CData', cdata );
            obj.SelectedColumnDivider = source;
        end % onColumnButtonDown
        
        function onColumnButtonMotion( obj, source, eventData ) %#ok<INUSD>
            figh = ancestor( source, 'figure' );
            cursorpos = get( figh, 'CurrentPoint' );
            dividerpos = get( obj.SelectedColumnDivider, 'Position' );
            pos0 = getpixelposition( obj.UIContainer, true );
            dividerpos(1) = cursorpos(1) - pos0(1) - round(obj.Spacing/2) + 1;
            set( obj.SelectedColumnDivider, 'Position', dividerpos );
        end % onColumnButtonMotion
        
        function onColumnButtonUp( obj, source, eventData, oldFigProps, oldState )
            figh = ancestor( source, 'figure' );
            % Deliberately call the motion function to ensure any last
            % movement is captured
            obj.onColumnButtonMotion( source, eventData );
            
            % Restore figure properties
            flds = fieldnames( oldFigProps );
            for ii=1:numel(flds)
                set( figh, flds{ii}, oldFigProps.(flds{ii}) );
            end
            
            % If the figure has an interaction mode set, re-set it now
            if ~isempty( oldState )
                switch upper( oldState )
                    case 'ZOOM'
                        zoom( figh, 'on' );
                    case 'PAN'
                        zoom( figh, 'on' );
                    case 'ROTATE3D'
                        rotate3d( figh, 'on' );
                    otherwise
                        error( 'GUILayout:InvalidState', 'Invalid interaction mode ''%s''.', oldState );
                end
            end
            
            % Work out which divider was moved and which are the resizable
            % elements either side of it
            whichDivider = getappdata( obj.SelectedColumnDivider, 'WhichDivider' );
            origPos = getappdata( obj.SelectedColumnDivider, 'OriginalPosition' );
            newPos = get( obj.SelectedColumnDivider, 'Position' );
            obj.SelectedColumnDivider = -1;
            delta = newPos(1) - origPos(1) - round(obj.Spacing/2) + 1;
            sizes = obj.ColumnSizes;
            
            % Convert all flexible sizes into pixel units
            totalPosition = ceil( getpixelposition( obj.UIContainer ) );
            totalWidth = totalPosition(3);
            widths = obj.calculatePixelSizes( totalWidth, sizes );
            
            leftelement = find( sizes(1:whichDivider)<0, 1, 'last' );
            rightelement = find( sizes(whichDivider+1:end)<0, 1, 'first' )+whichDivider;
            
            % Now work out the new sizes. Note that we must ensure the size
            % stays negative otherwise it'll stop being resizable
            change = sum(sizes(sizes<0)) * delta / sum( widths(sizes<0) );
            sizes(leftelement) = min( -0.000001, sizes(leftelement) + change );
            sizes(rightelement) = min( -0.000001, sizes(rightelement) - change );
            
            % Setting the sizes will cause a redraw
            obj.ColumnSizes = sizes;
        end % onColumnButtonUp
        
        function onBackgroundColorChanged( obj, source, eventData ) %#ok<INUSD>
            %onBackgroundColorChanged  Callback that fires when the container background color is changed
            %
            % We need to make the dividers match the background, so redarw
            % them
            obj.redraw();
        end % onChildRemoved
        
    end % protected methods
    
end % classdef