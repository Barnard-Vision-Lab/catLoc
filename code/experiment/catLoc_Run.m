%% [task, scr, runData] = catLoc_Run(task)
% Does 1 run of the catLoc MRI experiment, and saves data. 
%
% Inputs:
% - task structure, inhereted from the Params function  
%
% Outputs:
% - task: big structure about stimuli
% - scr: structure about screen
% - runData: structure with important data
%
% ALSO, after each run, three data files are saved in 
% catLoc/data/SID/SID_DATE/. 
% - A .mat file (e.g., SID_DATE_r01.mat for the 1st run). This
% contains the task and screen functions, and thus all data. 
% - A .tsv file, which is a simple spreadsheet with 1 row per trial and
% many columns that specify the stimulus events. This is designed for use
% with fMRIPrep and glmSingle. 
% - a .edf file, with data from the Eyelink eye-tracker for that run. 
%
% by Alex White, Barnard College

function [task, scr, runData] = catLoc_Run(task)

%% select trials for this run from allRunTrials
task.runTrials = task.allRunTrials(task.allRunTrials.runNum == task.runNumber, :);

task.whichTask = task.whichTasks(task.runNumber);

%% Initialize Screen
if task.reinitScreen
    [scr, task] = prepScreen_catLoc(task);
else %set this bgColor variable
    if scr.normalizedLums
        task.bgColor = task.bgLum;
    else
        task.bgColor = floor(task.bgLum*((2^scr.nBits)-1));
    end
end

%% Draw a line of text to alert the user that stimuli are loading, which takes a while:
c = [0 0 0];
Screen('TextFont',scr.main, task.instruct.fontName);
ptbDrawFormattedText(scr.main,'Loading stimuli...', dva2scrPx(scr, 0, 0),c,true,true,false,false);
Screen(scr.main,'Flip');


if task.EYE == 999 %dummy mode
    ShowCursor;
else
    HideCursor(scr.main);
end

%% get response keys (and disable keyboard, UnifyKeyNames)
task.buttons = setupKeys_catLoc(task);

%% %%%%%  Sounds
task = prepSounds(task);

%% make stimuli (colors, positions, find word images, etc)
task = makeStim_catLoc(task, scr);

%% Timing Parameters

fps = scr.fps;
task.fps = fps;

%SET EACH TIMING PARAM TO MULTIPLE OF FRAME DURATION
tps = fullFieldnames(task.time);
%and add them to structure task.durations:
for ti = 1:numel(tps)
    tv = tps{ti};
    eval(sprintf('task.durations.%s = durtnMultipleOfRefresh(task.time.%s, fps, task.durationRoundTolerance);', tv, tv));
end

task.runTrials.duration = ones(size(task.runTrials,1),1)*(task.time.trial-task.timeFudgeFactor); %make the duration exact, not rounded by screen refresh

%% setup trial structure (things that don't change across trials, like segment durations)
task = setupTrialStructure_catLoc(task);

%% make images of words for each trial
task = makeImageTextures_catLoc(task,scr);

%% Set where to store the data
[matFileName, eyelinkFileName, task] = setupDataFile_catLoc(task.runNumber, task);
%Extract the name of this m file
[st,i] = dbstack;
scr.codeFilename = st(min(i,length(st))).file;
task.codeFilename = scr.codeFilename;

%% %% initialize data structure
task = initializeData_catLoc(task);


%% %%%%%%%%%%%%%%%%
% Initialize eyelink and calibrate tracker
%%%%%%%%%%%%%%%%%%
if task.EYE > 0 %0= no eye-tracking at all; 1=tracking; 999=dummy mode
    
    [el, elStatus] = initializeEyelink(eyelinkFileName, task, scr);
    
    if elStatus == 1
        fprintf(1,'\nEyelink initialized with edf file: %s.edf\n\n',eyelinkFileName);
    else
        fprintf(1,'\nError in connecting to eyelink!\n');
    end
    
    if task.EYE == 1
        calibrateEyelink(el, task, scr);
    end
else
    el = [];
end

%% Start eyelink recording  - before trigger!
%if self-paced, eyetrack recording is turned on and off every trial;
%otherwise, need to start recording now
if task.EYE>0
    Eyelink('command','clear_screen');
    
    if task.EYE>0
        if Eyelink('isconnected')==el.notconnected		% cancel if eyeLink is not connected
            return
        end
    end
    [record, task] = startEyelinkRecording(el, task);
    
    % This supplies a title at the bottom of the eyetracker display
    Eyelink('command', 'record_status_message ''Start scan %d''', task.runNumber);
else
    record = false;
end

task.eyelinkIsRecording = record;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Instructions and wait for trigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if task.EYE > 1 %dummy mode
    ShowCursor;
else
    HideCursor(scr.main);
    HideCursor(scr.expScreen); %try again 
end

WaitSecs(0.5);

instruct_catLoc(task,scr);

%% Start scan
task.tRunStart = GetSecs;

%% prepare for trials
trialVars = task.runTrials.Properties.VariableNames;

ti = 0; %counter of trials
nTrials = size(task.runTrials,1);
doRunTrials = true;

%set goal times for each start
%relative to tRunStart+initialBlank
task.trialGoalStarts   = [0; cumsum(task.runTrials.duration)]+task.tRunStart+task.durations.initialBlank-scr.flipTriggerTime;

%% try to silence "t's", now that we got the trigger (because at CNI, the scanner sends a t every TR) 
otherKeysNoT = setdiff(task.buttons.otherKeys, KbName({'t'}));
RestrictKeysForKbCheck([task.buttons.resp otherKeysNoT]);
if ~IsWin
    ListenChar(2);
end
%% Initial blank period
drawFixation_catLoc(task, scr);
Screen('Flip', scr.main);
if task.EYE>0, Eyelink('message', 'INITIAL_BLANK_START'); end

WaitSecs(task.durations.initialBlank - task.durations.interTrialBufferTime);


%% Trial loop
while doRunTrials
    ti = ti + 1;
    
    %keep trials on regular pace
    if ti<=length(task.trialGoalStarts)
        trialGoalStart = task.trialGoalStarts(ti);
    else
        trialGoalStart = GetSecs;
        fprintf(1,'(FOVMRI_Block): Problem setting trial start time...');
    end
    
    %RUN ONE TRIAL
    [trialRes, task] = catLoc_Trial(scr,task,ti,trialGoalStart);
    
    
    %extract data
    if ti==1
        dataVars = fieldnames(trialRes);
        nDVars = numel(dataVars);
    end
    for di = 1:nDVars
        %check if this one was not initialized in initializeData function
        if task.runTrials.trialNum(ti)==1 && ~any(strcmp(trialVars,dataVars{di}))
            eval(sprintf('task.runTrials.%s = task.emptyMat;',dataVars{di}));
        end
        eval(sprintf('task.runTrials.%s(task.runTrials.trialNum(ti)) = trialRes.%s;',dataVars{di},dataVars{di}));
    end
    
    doRunTrials = (ti < nTrials) && ~trialRes.userQuit;
    
end

%% final blank
if isfield(task.durations, 'finalBlank')
    drawFixation_catLoc(task, scr);
    Screen('Flip', scr.main);
    if task.EYE>0, Eyelink('message', 'FINAL_BLANK_START'); end
    task.tFinalBlankStart = GetSecs;
    WaitSecs(task.durations.finalBlank + task.durations.interTrialBufferTime);
end
if task.EYE>0, Eyelink('message', 'RUN_END'); end

task.tRunEnd = GetSecs;


%Close textures (all at once)
alltex = task.textures(:);
Screen('Close',alltex(~isnan(alltex)));


task.endTime = clock;
task.el      = el;


%Priority(0); %set priority back to 0

%% End eye-movement recording and extract eye data

% shut down everything, get EDF file
% get eyelink data file on subject computer
if task.EYE>0
       
    %stop recording
    if task.eyelinkIsRecording
        Screen(el.window,'FillRect',el.backgroundcolour);   % hide display
        WaitSecs(0.1);
        Eyelink('stoprecording');             % record additional 100 msec of data end
        Eyelink('command','clear_screen');
        Eyelink('command', 'record_status_message ''ENDE''');
    end

    %close file
    Eyelink('closefile');
    
    %transfer file 
    status = Eyelink('ReceiveFile');
    if status == 0
        fprintf(1,'\n\nFile transfer went pretty well\n\n');
    elseif status < 0
        fprintf(1,'\n\nError occurred during file transfer\n\n');
    else
        fprintf(1,'\n\nFile has been transferred (%i Bytes)\n\n',status)
    end
        
    %shut down
    Eyelink('shutdown');
    
    
    %move edf file to data folder
    [success, message] = movefile(sprintf('%s.edf',task.eyelinkFileName),sprintf('%s.edf',task.dataFileName));
    if ~success
        fprintf(1,'\n\n\nWARNING: ERROR MOVING EDF FILE ON BLOCK %i\n', blockNum);
        fprintf(1,message);
        fprintf(1,'\n\n\n\n');
    end
    
end


%% collect run data and check timing
runData.trialsDone   = ti;
runData.taskPerformance = checkRunTaskPerformance_catLoc(task, ti-trialRes.userQuit);
runData.timingErrors = checkRunTiming_catLoc(task);
runData.tRunStart    = task.tRunStart;
runData.tRunEnd      = task.tRunEnd;
runData.userQuitMidBlock = trialRes.userQuit;


%% save run summary (only if not practice)
if ~task.practice
    theDate = [datestr(now,'yy') datestr(now,'mm') datestr(now,'dd')];
    dataFile = fullfile(task.subjDataFolder,sprintf('%s_%s_CatLocRun%iSummary.mat', task.subj, theDate, task.runNumber));
    
    %check if there was a prior file with this same name. If so, add an
    %integer to the end of it. 
    fileExists = exist(dataFile, 'file');
    dfi  = 1;
    while fileExists
        dfi = dfi+1;
        dataFile = fullfile(task.subjDataFolder,sprintf('%s_%s_CatLocRun%iSummary_%i.mat', task.subj, theDate, task.runNumber, dfi));
        fileExists = exist(dataFile, 'file');
    end
        
    save(dataFile,'runData');
    
    %save runInfo, which stores how many runs are done, etc 
    runNumber = task.runNumber;
    allRunTrials = task.allRunTrials;
    
    runFile = fullfile(task.subjFolder, sprintf('%s_catLocRunInfo.mat', task.subj));
    save(runFile, 'runNumber','allRunTrials');

end

%% save data
task.runData = runData;

save(sprintf('%s.mat',matFileName),'task','scr');

%create the events.tsv file for later analyzing with glm
makeEventsTSV_catLoc(sprintf('%s.mat',matFileName), sprintf('%s_events', matFileName));

%% final screen to give feedback
finalFeedback_catLoc(task,scr);


%% Shut down screen
% re-enable keyboard
if ~IsWin
    ListenChar(1);
end
ShowCursor;
% Screen(visual.main,'Resolution', scr.oldRes);
Screen('CloseAll');
RestoreCluts; %to undo effect of loading normalized gamma table


%switch screen back to the original resolution if necessary
if scr.changeRes && ~IsWin %crashes on windows laptop
    SetResolution(scr.expScreen,scr.oldRes);
end

% Close the audio device:
if task.usePortAudio
    PsychPortAudio('Close');
else
    Snd('Close');
end

%% print out some useful info
fprintf(1,'\n\nSaving data to: %s.mat\n',matFileName);
fprintf(1,'\nRun %i took %.2f s (%.2f min).\n',task.runNumber, runData.timingErrors.runDuration, runData.timingErrors.runDuration/60);
fprintf(1,'\tDuration error = %.2f s (relative to goal of %.2f s)\n\n', runData.timingErrors.runDurationError, task.goalRunDuration);
if task.whichTask==1
    fprintf(1,'\nPerformance on one-back task:');
else
    fprintf(1,'\nPerformance on fixation task:');
end
fprintf(1,'\nSubject correctly detected %i of %i targets (%i%% hits)',runData.taskPerformance.nHits, runData.taskPerformance.nTargEvents, round(100*runData.taskPerformance.hitRate));
fprintf(1,'\nThey also made %i false alarms (pressing button before a repetition or more than %i sec after one)', runData.taskPerformance.nFalseAlarms, task.maxResponseTime);



