classdef VBoxFlex < uiextras.VBox
    %VBoxFlex  A dynamically resizable vertical layout
    %
    %   obj = uiextras.VBoxFlex() creates a new dynamically resizable
    %   vertical box layout with all parameters set to defaults. The output
    %   is a new layout object that can be used as the parent for other
    %   user-interface components.
    %
    %   obj = uiextras.VBoxFlex(param,value,...) also sets one or more
    %   parameter values.
    %
    %   See the <a href="matlab:doc uiextras.VBoxFlex">documentation</a> for more detail and the list of properties.
    %
    %   Examples:
    %   >> f = figure( 'Name', 'uiextras.VBoxFlex example' );
    %   >> b = uiextras.VBoxFlex( 'Parent', f );
    %   >> uicontrol( 'Parent', b, 'Background', 'r' )
    %   >> uicontrol( 'Parent', b, 'Background', 'b' )
    %   >> uicontrol( 'Parent', b, 'Background', 'g' )
    %   >> uicontrol( 'Parent', b, 'Background', 'y' )
    %   >> set( b, 'Sizes', [-1 100 -2 -1], 'Spacing', 5 );
    %
    %   See also: uiextras.HBoxFlex
    %             uiextras.VBox
    %             uiextras.Grid
    
    %   Copyright 2009 The MathWorks, Inc.
    %   $Revision: 324 $ 
    %   $Date: 2010-08-06 16:30:39 +0100 (Fri, 06 Aug 2010) $
    
    properties
        ShowMarkings = 'on'  % Show markings on the draggable dividers [on|off]
    end % public methods
    
    properties( SetAccess = private, GetAccess = private )
        SelectedDivider = -1
    end % private properties
    
    methods
        
        function obj = VBoxFlex( varargin )
            %VBoxFlex  Create a VBoxFlex layout
            
            % First step is to create the parent class. We pass the
            % arguments (if any) just incase the parent needs setting
            obj@uiextras.VBox( varargin{:} );

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
                error( 'GUILayout:VBoxFlex:InvalidArgument', ...
                    'Property ''ShowMarkings'' may only be set to ''on'' or ''off''.' )
            end
            % Apply
            obj.ShowMarkings = lower( value );
            obj.redraw();
        end % set.ShowMarkings
        
    end % accessor methods
        
    methods( Access = protected )
        
        function redraw( obj )
            %redraw  Redraw container contents.
            
            % Remove dividers before computing sizes so that the dividers
            % don't appear as children
            delete( findall( obj.UIContainer, 'Tag', 'UIExtras:VBoxFlex:Divider' ) );

            % Now simply call the grid redraw
            % First simply call the grid redraw
            [widths,heights] = redraw@uiextras.VBox(obj);
            sizes = obj.Sizes;
            nChildren = numel( obj.getValidChildren() );
            padding = obj.Padding;
            spacing = obj.Spacing;
            
            % Get container width and height
            totalPosition = ceil( getpixelposition( obj.UIContainer ) );
            totalHeight = totalPosition(4);
            
            % Now also add some dividers
            mph = uiextras.MousePointerHandler( obj.Parent );
            for ii = 1:nChildren-1
                if any(sizes(1:ii)<0) && any(sizes(ii+1:end)<0)
                    % Both dynamic, so add a divider
                    position = [padding + 1, ...
                        totalHeight - sum( heights(1:ii) ) - padding - spacing*ii + 1, ...
                        widths(ii), ...
                        max(1,spacing)];
                    % Create the divider widget
                    uic = uiextras.makeFlexDivider( ...
                        obj.UIContainer, ...
                        position, ...
                        get( obj.UIContainer, 'BackgroundColor' ), ...
                        'Horizontal', ...
                        obj.ShowMarkings );
                    set( uic, 'ButtonDownFcn', @obj.onButtonDown, ...
                        'Tag', 'UIExtras:VBoxFlex:Divider' );
                    setappdata( uic, 'WhichDivider', ii );
                    % Add it to the mouse-over handler
                    mph.register( uic, 'top' );
                end
            end
        end % redraw
        
        function onButtonDown( obj, source, eventData ) %#ok<INUSD>
            %onButtonDown  user has clicked on a divider
            
            figh = ancestor( source, 'figure' );
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
            
            % Set our new callbacks
            set( figh, ...
                'WindowButtonMotionFcn', @obj.onButtonMotion, ...
                'WindowButtonUpFcn', {@obj.onButtonUp, oldProps, oldState}, ...
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
            
            obj.SelectedDivider = source;
        end % onButtonDown
        
        function onButtonMotion( obj, source, eventData ) %#ok<INUSD>
            %onButtonMotion  user is dragging a divider
            figh = ancestor( source, 'figure' );
            cursorpos = get( figh, 'CurrentPoint' );
            pos0 = getpixelposition( obj.UIContainer, true );
            dividerpos = get( obj.SelectedDivider, 'Position' );
            dividerpos(2) = cursorpos(2) - pos0(2) - round(obj.Spacing/2) + 1;
            set( obj.SelectedDivider, 'Position', dividerpos );
        end % onButtonMotion
        
        function onButtonUp( obj, source, eventData, oldFigProps, oldState )
            %onButtonUp  user has finished dragging a divider
            
            % Deliberately call the motion function to ensure any last
            % movement is captured
            obj.onButtonMotion( source, eventData );
            
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
                        error( 'GUILayout:FlexLayout:BadInteractionMode', 'Interaction mode ''%s'' not recognised', oldState );
                end
            end
            
            % Work out which divider was moved and which are the resizable
            % elements either side of it
            newPos = get( obj.SelectedDivider, 'Position' );
            origPos = getappdata( obj.SelectedDivider, 'OriginalPosition' );
            whichDivider = getappdata( obj.SelectedDivider, 'WhichDivider' );
            obj.SelectedDivider = -1;
            delta = newPos(2) - origPos(2);
            sizes = obj.Sizes;
            % Convert all flexible sizes into pixel units
            totalPosition = ceil( getpixelposition( obj.UIContainer ) );
            totalHeight = totalPosition(4);
            heights = obj.calculatePixelSizes( totalHeight );
            
            bottomelement = find( sizes(1:whichDivider)<0, 1, 'last' );
            topelement = find( sizes(whichDivider+1:end)<0, 1, 'first' )+whichDivider;
            
            % Now work out the new sizes. Note that we must ensure the size
            % stays negative otherwise it'll stop being resizable
            change = sum(sizes(sizes<0)) * delta / sum( heights(sizes<0) );
            sizes(topelement) = min( -0.000001, sizes(topelement) + change );
            sizes(bottomelement) = min( -0.000001, sizes(bottomelement) - change );
            
            % Setting the sizes will cause a redraw
            obj.Sizes = sizes;
        end % onButtonUp
        
        function onBackgroundColorChanged( obj, source, eventData ) %#ok<INUSD>
            %onBackgroundColorChanged  Callback that fires when the container background color is changed
            %
            % We need to make the dividers match the background, so redarw
            % them
            obj.redraw();
        end % onChildRemoved
        
    end % protected methods
    
end % classdef