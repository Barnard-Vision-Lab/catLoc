function task = initializeData_catLoc(task)

numTrials = size(task.runTrials,1);

%empty matrix 
emptyMat = NaN(numTrials,1);

%add segment onset times 
for segI = 1:task.trialStruct.nSegments
    eval(sprintf('task.runTrials.t%sOns = emptyMat;',task.trialStruct.segmentNames{segI}));
end


%others from the Trial function 
trialVars = {'tTrialStart','tTrialEnd','tRes','fixBreak','trialDone','nFixBreakSegs', ...
              'tFixBreak','userQuit','chosenRes'...
              'didRecalib','quitDuringRecalib'};
          
for tdi = 1:numel(trialVars)
    eval(sprintf('task.runTrials.%s = emptyMat;',trialVars{tdi}));
end

%initialize variable that will be used to put each trial's data variables into vector 
task.emptyMat = emptyMat;
