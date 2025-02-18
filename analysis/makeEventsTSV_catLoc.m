%% function [taskName] = makeEventsTSV_catLoc(matF, outF)
% creates a BIDS-compatible spreadsheet in .tsv format with stimulus/task
% events for the catLoc experiment. 
% Inputs
% - matF: full address of a .mat file that was output for 1 run of catLoc,
% containing the "task" structure that has the "runTrials" table attached
% to it, with 1 row for each trial 
% - outF: full address, minus the file-type extension, of the output file. 
% 
% Outputs
% - taskName: character string, either "catLocOneBack" or "catLocFixation",
% depending on which task was run. 

function [taskName] = makeEventsTSV_catLoc(matF, outF)

if ~exist(matF, 'file')
    error('Can not find input mat file: %s', matF);
end
    
load(matF,'task');

if task.whichTask==1
    taskName = 'catLocOneback';
    taskNameShort = 'oneback';
elseif task.whichTask==2 || task.whichTask==0
    taskName = 'catLocFixation';
    taskNameShort = 'fixation';
else
    keyboard
end

D = task.runTrials;

T = table;
%onset: onset (in seconds) from beginning of acquisition of first volume 
%BIDS requires that this TSV file does not correct onset times for volumes
%deleted by scanner nor dummy (nonsteady-state) volumes that are included
%but should be discounted. That must happen later.
T.onset = D.tTrialStart;  

%stimulus/trial duration is already there in task.runTrials (4s)

%trial_type: Primary categorisation of each trial to identify them as instances of the experimental conditions
T.trial_type = D.category;
T.trial_type_index = D.categoryI;

%response time: only for hit trials 
T.response_time = NaN(size(D.tRes)); 
if task.whichTask==1 %one-back task
    targTrls = find(task.runTrials.stimRepeat)'; 
    targStims = task.runTrials.repeatStimNum(targTrls);
else %fixation color task
    targTrls = find(task.runTrials.fixColorChange)';
    targStims = task.runTrials.fixColorChangeStimNum(targTrls)';
end
respTimes = task.runTrials.tRes;
respTimes = respTimes(~isnan(respTimes));

nTargs = length(targTrls);
for tii=1:nTargs
    eval(sprintf('tEvent = task.runTrials.tstimulus%iOns(%i);', targStims(tii), targTrls(tii)));
    tDiffs = respTimes - tEvent;
    hitResps = tDiffs>task.minResponseTime & tDiffs<task.maxResponseTime;
    if any(hitResps)
        hitI = find(hitResps);
        T.response_time(targTrls(tii)) = tDiffs(hitI(1));
    end
end

%add task name, in case it wasnt set properly in task.runTrials
D.taskName = repmat({taskNameShort},size(D,1),1);

%now just add the rest of the data table to this one 
T = [T D];

%process fixation breaks? 

%write out to CSV
csvF = [outF '.csv'];
writetable(T, csvF, 'delimiter','tab');

%rename from csv to tsv
tsvF = [outF '.tsv'];
movefile(csvF, tsvF);

    
    
