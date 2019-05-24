function idata = mrs_invT1GetGuiPara(gui,idata)

% model space
idata.para.modelspace   = get(gui.para.soltype, 'Value');
idata.para.decaySpecMin = str2double(get(gui.para.decayMin,'String'));
idata.para.decaySpecMax = str2double(get(gui.para.decayMax,'String'));

idata.para.T1initialM   = str2double(get(gui.para.initialM,'String'));

% regularisation
idata.para.regpara      = str2double(get(gui.para.regpara,'String'));

% termination
idata.para.maxIteration = str2double(get(gui.para.Niter,'String'));

