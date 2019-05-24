function idata = mrs_invQT1DMonoBlockGA_multicore(idata)

%% settings
nProcessors = str2num(getenv('NUMBER_OF_PROCESSORS')); % number of available processors
nProcessors = nProcessors-1; % save one for the rest of you work ;-)
nrOfEvals   = idata.para.numberOfPop; % number of runs


settings.multicoreDir        = '';
settings.nrOfEvalsAtOnce     = 1;
settings.maxEvalTimeSingle   = 60*60;
settings.masterIsWorker      = 1;
settings.useWaitbar          = 0;
settings.postProcessHandle   = '';
settings.postProcessUserData = {};


%% initialize 
currentDir = cd;
tmppath = which('MRSQTInversion.m'); 
path = fileparts(tmppath);
cd(path); cd('..');

thisID = feature('getpid');

[s,w] = dos('tasklist');
taskLines = textscan(w, '%s', 'delimiter', '\n');
taskLines = taskLines{1};

mIds = find(~cellfun(@isempty, strfind(taskLines, 'MATLAB')));
nProcessorsOpen = numel(mIds);

for iProc = 1:min(nProcessors-nProcessorsOpen,nrOfEvals-nProcessorsOpen)
    dos(['matlab -nodesktop -minimize -nosplash -r startMRSmatlab_multicore &']);
end % iProc

cd(currentDir);


%% start
parameterCell = cell(1, nrOfEvals);
for k = 1:nrOfEvals
  parameterCell{1,k} = {idata, k};
end
result = startmulticoremaster(@mrs_invQT1DMonoBlockGA, parameterCell, settings);

%% put together
idata.inv1Dqt = result{1}.inv1Dqt;
if nrOfEvals > 1
    for k = 2:nrOfEvals
        idata.inv1Dqt.blockMono.solution = [idata.inv1Dqt.blockMono.solution result{k}.inv1Dqt.blockMono.solution];
    end
end
%% check for misfit of all runs 
% MMP: decided to save all and decide during plot, makes it more flexible
% best model is put to #1 in the set
for iR=1:nrOfEvals
    misfit(iR) = idata.inv1Dqt.blockMono.solution(iR).dnorm;
end
[bestFit,index] = min(misfit);
tmp = idata.inv1Dqt.blockMono.solution(1);
idata.inv1Dqt.blockMono.solution(1) = idata.inv1Dqt.blockMono.solution(index);
idata.inv1Dqt.blockMono.solution(index) = tmp;
%idata.inv1Dqt.blockMono.solution(misfit > 1.05*bestFit) = [];


