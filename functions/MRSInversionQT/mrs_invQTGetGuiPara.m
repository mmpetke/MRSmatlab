function idata = mrs_invQTGetGuiPara(gui,idata)

% kernel
idata.para.minThickness      = str2num(get(gui.para.modelDiscretisation,'String'));
idata.para.maxDepth          = str2double(get(gui.para.modelMaxDepth,'String'));

% gates
if get(gui.para.gateIntegration,'Value')
    idata.para.gates  = 1;
    idata.para.Ngates = str2double(get(gui.para.nGates,'String'));
else
    idata.para.gates = 0;
end

% include shift for gate integration logspace definition
idata.para.gatedt = idata.data.effDead*1; % makes sense?


% data type
idata.para.dataType   = get(gui.para.datatype,'Value');
idata.para.instPhase  = str2double(get(gui.para.instPhase,'String'));


% model space
idata.para.modelspace   = get(gui.para.soltype, 'Value');

idata.para.decaySpecMin = str2double(get(gui.para.decaySpecMin,'String'));
idata.para.decaySpecMax = str2double(get(gui.para.decaySpecMax,'String'));
idata.para.decaySpecN   = str2double(get(gui.para.decaySpecN,'String'));

idata.para.upperboundWater   = str2double(get(gui.para.upperboundWater,'String'));
idata.para.lowerboundWater   = str2double(get(gui.para.lowerboundWater,'String'));
idata.para.upperboundT2      = str2double(get(gui.para.decaySpecMax,'String'));
idata.para.lowerboundT2      = str2double(get(gui.para.decaySpecMin,'String'));

idata.para.GAthkMin          = str2double(get(gui.para.GAthkMin,'String'));
idata.para.GAthkMax          = str2double(get(gui.para.GAthkMax,'String'));
idata.para.GAnLay            = str2double(get(gui.para.GAnLay,'String'));
idata.para.GAstatistic       = str2double(get(gui.para.GAstatistic,'String'));
idata.para.membersOfPop      = str2double(get(gui.para.membersOfPop,'String'));
idata.para.numberOfPop       = str2double(get(gui.para.numbersOfPop,'String'));


% regularisation
idata.para.regVec    = str2double(get(gui.para.regtypeFixV,'String'));
idata.para.regMonoWC = str2double(get(gui.para.regtypeMonoWC,'String'));
idata.para.regMonoT2 = str2double(get(gui.para.regtypeMonoT2,'String'));
idata.para.struCoupling = get(gui.para.struCoupling,'Value');

% termination
idata.para.maxIteration = str2double(get(gui.para.maxIteration,'String'));
idata.para.minModelUpdate = str2double(get(gui.para.minModelUpdate,'String'));
idata.para.statisticRuns = str2double(get(gui.para.statisticRuns,'String'));



