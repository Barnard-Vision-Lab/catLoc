%% function task = setupTrialStructure_catLoc(task)
% This function adds to the "task" structure a field "trialStruct", which
% is itself a struct. It defines the "segments" of each trial. A segment is an 
% an interval of time in which a particular stimulus is displayed, for
% instance, or the subject responds. Each segment has a number, a name, and
% fields checkEye (whether fixation breaks are detected) and checkResp
% (whether the code listens for a button press during that segment). 

function task = setupTrialStructure_catLoc(task)

%setup segments. There are only two types of segments, stimulus and ISI.
%They alternate.

nSegments    = task.org.stimPerTrial*2; 
segmentNames = cell(1,nSegments);
stimSegment  = mod(1:nSegments,2);
stimNum      = zeros(1,nSegments);

for si=1:nSegments
    %alternate stimulus and ISI
    if stimSegment(si)
        stimNum(si) = ceil(si/2);
        segmentNames{si} = sprintf('stimulus%i', stimNum(si));
    else
        segmentNames{si} = sprintf('ISI%i', ceil(si/2));
    end
end

checkEye     = true(1,nSegments); %whether to check for fixation breaks; 
checkResp    = true(1,nSegments); %whether to check for manual response; only during response interval
doMovie      = false(1,nSegments); %in case some segments are 'movies' that need updating every frame



%set durations
durations = zeros(1,nSegments);
durations(stimSegment==1) = task.durations.stimulus;
durations(stimSegment==0) = task.durations.ISI;

%shorten the last ISI by some buffer period 
isiis = find(stimSegment==0); 
lastISI = isiis(end);
durations(lastISI) = durations(lastISI) - task.durations.interTrialBufferTime;

trialStruct.nSegments      = nSegments;
trialStruct.segmentNames   = segmentNames;
trialStruct.stimSegment    = stimSegment;
trialStruct.stimNum        = stimNum;
trialStruct.checkEye       = checkEye;
trialStruct.checkResp      = checkResp;
trialStruct.doMovie        = doMovie;
trialStruct.durations      = durations;

task.trialStruct = trialStruct;
