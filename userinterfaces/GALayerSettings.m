function layer = GALayerSettings(gui,idata)
layer = [];
    idata = mrs_invQTGetGuiPara(gui,idata);
    if isfield(idata.para,'layer')
        if length(idata.para.layer)>idata.para.GAnLay
            idata.para.layer(idata.para.GAnLay+1:end)=[];
        end
        for nLayer=1:length(idata.para.layer)
            wc(nLayer)     = idata.para.layer(nLayer).watercontent;
            T2(nLayer)     = idata.para.layer(nLayer).T2;
            LB(nLayer)     = idata.para.layer(nLayer).LB;
            minTHK(nLayer) = idata.para.layer(nLayer).minTHK;
            maxTHK(nLayer) = idata.para.layer(nLayer).maxTHK;
        end
        for nLayer=length(idata.para.layer)+1:idata.para.GAnLay
            idata.para.layer(nLayer).watercontent=NaN;
            wc(nLayer)                      = NaN;
            idata.para.layer(nLayer).T2     = NaN;
            T2(nLayer)                      = NaN;
            idata.para.layer(nLayer).LB     = NaN;
            idata.para.layer(nLayer).minTHK = NaN;
            idata.para.layer(nLayer).maxTHK = NaN;
            LB(nLayer)                      = NaN;
            minTHK(nLayer)                  = NaN;
            maxTHK(nLayer)                  = NaN;
        end
        
    else
        for nLayer=1:idata.para.GAnLay
            idata.para.layer(nLayer).watercontent=NaN;
            wc(nLayer)                      = NaN;
            idata.para.layer(nLayer).T2     = NaN;
            T2(nLayer)                      = NaN;
            idata.para.layer(nLayer).LB     = NaN;
            idata.para.layer(nLayer).minTHK = NaN;
            idata.para.layer(nLayer).maxTHK = NaN;
            LB(nLayer)                      = NaN;
            minTHK(nLayer)                  = NaN;
            maxTHK(nLayer)                  = NaN; 
        end
    end
    

    screensz = get(0,'ScreenSize');
    GALayerPresetFig = figure( ...
        'Name', 'Restrictions to layer properties', ...
        'NumberTitle', 'off', ...
        'MenuBar', 'none', ...
        'Toolbar', 'none', ...
        'HandleVisibility', 'on' );
    set(GALayerPresetFig, 'Position', [400, screensz(4)-400, 600 200])

%    uiextras.set( GALayerPresetFig, 'DefaultBoxPanelPadding', 5)
%    uiextras.set( GALayerPresetFig, 'DefaultHBoxPadding', 2)

    GALayer_B1  = uiextras.VBox('Parent', GALayerPresetFig);
    GALayer_tab = uitable('Parent', GALayer_B1);
    set(GALayer_tab, ...
        'Data', [(1:idata.para.GAnLay)' LB' wc' T2' minTHK' maxTHK'], ...
        'ColumnName', {'#', 'lower layer boundary', 'water content', 'T_2*', 'minimum thickness', 'maximum thickness'}, ...
        'ColumnWidth', {30 120 80 50 120 120}, ...
        'RowName', [], ...
        'ColumnEditable', true);
    GALayer_return = uicontrol('Style', 'pushbutton', 'Parent', GALayer_B1, 'String', 'save', 'Callback', @onReturn);
    set(GALayer_B1, 'Sizes',[-1 25]) 
    
    function onReturn(a,b)
        tabData=get(GALayer_tab,'Data');
        for nLay=1:size(tabData,1)
            layer(nLay).LB           = tabData(nLay,2);
            layer(nLay).watercontent = tabData(nLay,3);
            layer(nLay).T2           = tabData(nLay,4);
            layer(nLay).minTHK       = tabData(nLay,5);
            layer(nLay).maxTHK       = tabData(nLay,6);
        end
        delete(GALayerPresetFig)
        uiresume(gui.panel_controls.figureid)
    end
    
uiwait(gui.panel_controls.figureid)
end 