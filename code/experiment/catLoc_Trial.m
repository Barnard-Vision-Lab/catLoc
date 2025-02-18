%% function [trialRes, task] = catLoc_Trial(scr,task,trialI,goalStartTime)
% 
% This function runs a single trial of the catLoc experiment. One trial is
% 4 image frames flashing on and off. 
% 
% Inputs: 
% - scr: screen struct, inhereted from the Run function 
% - task: struct inherited from the Run function (originally set up in
% the Params function)
% - trialI: trial number, to pull out from the pre-planned table
%   task.runTrials. 
% - goalStartTime: time at which the first segment should begin. 
% 
% Outputs: 
% - trialRes: a struct of results from this trial, including timestamps of
%   each stimulus, any button-presses, etc.
% - task: the same task struct as was input. 

function [trialRes, task] = catLoc_Trial(scr,task,trialI,goalStartTime)

%Pull out one row from the runTrials table. Now "td" is a struct that
%defines all the variables for this trial. 

td = task.runTrials(trialI,:);

% clear keyboard buffer
KbEventFlush(-3); %note: I used to use FlushEvents('KeyDown'), but that seemed to require >20 ms! 

if task.EYE>0
    % predefine gaze position boundary information
    cxm = task.fixation.posX;
    cym = task.fixation.posY;
    chk = task.fixCkRad;
    
    circleCheck = length(chk)==1; %if fixation check is a circle or rectangle
    
    ctrx = scr.centerX; ctry = scr.centerY;  ctrpx = 3;
    
    % draw trial information on EyeLink operator screen
    Eyelink('command','clear_screen 0');
    
    Eyelink('command','draw_filled_box %d %d %d %d 15', round(ctrx-ctrpx), round(ctry-ctrpx), round(ctrx+ctrpx), round(ctry+ctrpx));    % fixation
    if circleCheck
        Eyelink('command','draw_filled_box %d %d %d %d 15', round(cxm-chk/8), round(cym-chk/8), round(cxm+chk/8), round(cym+chk/8));    % fixation
        Eyelink('command','draw_box %d %d %d %d 15', cxm-chk, cym-chk, cxm+chk, cym+chk);                   % fix check boundary
    else
        Eyelink('command','draw_filled_box %d %d %d %d 15', round(cxm-chk(1)/8), round(cym-chk(2)/8), round(cxm+chk(1)/8), round(cym+chk(2)/8));    % fixation
        Eyelink('command','draw_box %d %d %d %d 15', cxm-chk(1), cym-chk(2), cxm+chk(1), cym+chk(2));                   % fix check boundary
    end
    
    % This supplies a title at the bottom of the eyetracker display
    Eyelink('command', 'record_status_message ''Run %d, Trial %d of %d''', task.runNumber, td.trialNum, size(task.runTrials,1));
    % this marks the start of the trial
    Eyelink('message', 'TRIALID %d', td.trialNum);
end

%pull out trialStruct, which has some useful info
ts = task.trialStruct;

%% Run the trial: continuous loop that advances through each section

%Initialize counters for trial events:
segment          = 0; %start counter of segments
fri              = 0; %counter of movie frames
segStartTs       = NaN(size(ts.durations));
chosenRes        = NaN;
tRes             = NaN;
fixBreak         = 0;
nFixBreaks       = 0;
tFixBreak        = NaN;
nPressedQuit     = 0; %number of times subject presssed quit. 2 to abort

if any(ts.doMovie)
    frameTimes = NaN(1,ts.framesPerMovie);
end

tTrialStart      = GetSecs;

if task.EYE>0
    Eyelink('message', 'Trial_START %d', td.trialNum);
    Eyelink('message', 'Trial_Start_Condition %d %d', td.task, td.categoryI);

    Eyelink('message', 'SYNCTIME');		% zero-plot time for EDFVIEW
end

t = tTrialStart;


updateSegment = true; %start 1st segment immediately

doStimLoop = true;

while doStimLoop
    % Time counter
    if segment > 0
        t = GetSecs-segStartTs(segment);
        %update segment if this segment's duration is over, and it's not the last one
        updateSegment = t>(ts.durations(segment)-scr.flipTriggerTime) && segment < ts.nSegments;
    end
    
    if updateSegment
        lastSeg = segment;
        doIncrement = segment < ts.nSegments;
        while doIncrement
            segment = segment + 1;
            %stop at the last segment, and skip segments with duration 0:
            doIncrement = segment < ts.nSegments && ts.durations(segment) == 0;
        end
        
        segmentName = ts.segmentNames{segment};
        thisSegKeyPressed = false;
        thisSegFixBreak   =  false;
        
        %change fixation color? 
        if td.fixColorChange && ts.stimNum(segment)==td.fixColorChangeStimNum
            %increment the dot color index, modulus the number of colors
            task.fixation.dotColorI = mod(task.fixation.dotColorI + td.fixColorChangeIncrement, task.fixation.nColrs);
            %the mod operation returns 0 if dotColorI==nColors, so needs correction: 
            task.fixation.dotColorI(task.fixation.dotColorI==0) = task.fixation.nColrs;
        end
    end
    
    %update screen at switch of segment or if we're drawing the movie
    updateScreen = updateSegment || (ts.doMovie(segment) && fri < task.framesPerMovie);
    
    if updateScreen
        if ~ts.doMovie(segment)
            if segment == 1 %immediately start first segment
                goalFlipTime = goalStartTime;
            else
                goalFlipTime = segStartTs(lastSeg) + ts.durations(lastSeg) - scr.flipLeadTime;
            end
        else
            fri = fri+1; %update movie frame counter
            if fri==1
                goalFlipTime = segStartTs(lastSeg) + ts.durations(lastSeg) - scr.flipLeadTime;
            else
                goalFlipTime = frameTimes(fri-1)+ts.movieFrameDur - scr.flipLeadTime;
            end
        end
       
        %DRAW THE STIMULI 
        if ts.stimSegment(segment) && ~strcmp(td.category, 'blank')
            Screen('DrawTexture', scr.main, task.textures(td.trialNum, ts.stimNum(segment)), [], squeeze(task.textRect));
        end
        
         
        %draw fixation on top of everything else 
        drawFixation_catLoc(task, scr);

       
        %Flip screen:
        Screen(scr.main,'DrawingFinished');
        tFlip = Screen('Flip', scr.main, goalFlipTime);
        
        if ts.doMovie(segment)
            frameTimes(fri) = tFlip;
        end
        if updateSegment
            segStartTs(segment) = tFlip;
            if task.EYE>0 %send some eyelink messages
                Eyelink('message', sprintf('EVENT_%sOnset', segmentName));
            end
        end
        
        %Screenshots:
               %mainImg=Screen('GetImage', scr.main);
               %save(sprintf('trl%i_seg%i.mat',td.trialNum, segment),'mainImg');
            %   pause;

    end
    
    %Check for keypress
    if ts.checkResp(segment)
        [keyPressed, tKey] = checkTarPress(task.buttons.resp);
        
        %determine whether this was the correct response given task events (and
        %this was the first time keypress detected
        if keyPressed>0 && ~thisSegKeyPressed %only record first keypress  
            chosenRes = keyPressed;
            if keyPressed ~= task.buttons.quit
                tRes = tKey;
                endSegment = false;

                thisSegKeyPressed = true;

            else %subject pressed quit key
                nPressedQuit = nPressedQuit + 1;
                endSegment = (nPressedQuit>1); %end if they press quite twice 
            end
            
            %if one of the correct keys was pressed, set duration of this segment so that it ends immediately
            if endSegment
                ts.durations(segment) = t;
            end
        end
    end
    
    %Check eye position
    if task.EYE > 0 && ts.checkEye(segment)
        [x,y] = getCoord(scr, task);
        %if either eye is outside of fixation region, count as fixation break
        if circleCheck
            badeye = any(sqrt((x-cxm).^2+(y-cym).^2)>chk);
        else
            if task.horizOnlyFixCheck
                %fixation break only if horizontal position is a valid number but deviates too
                %much, and vertical position does NOT deviate. In other
                %words, only if observer looks horizontally at the words. 
                %The goal here is to allow blinks. 
                badeye = any(abs(x-cxm)>chk(1)) && ~isnan(x) && x>0 && x<scr.xres && any(abs(y-cym)<chk(2)) && ~isnan(y) && y>0 && y<scr.yres;
                %this doesn't quite work because around the time of a blink,
                %the eye position seems to deviate horizontally as well
%                 if badeye
%                    fprintf(1,'\nfix break with x = %.1f (dev. of %.1f, over %.1f), y = %.1f (dev. of %.1f, over %.1f)\n',x,abs(x-cxm),chk(1),y,abs(y-cym),chk(2));
%                 end
            else
                badeye = any(abs(x-cxm)>chk(1)) || any(abs(y-cym)>chk(2));
            end
        end
        
        if badeye
            fixBreak = true;
            if ~thisSegFixBreak
                nFixBreaks = nFixBreaks+1;
                thisSegFixBreak = true;
                tFixBreak = GetSecs;
                if task.EYE>0, Eyelink('message', 'EVENT_fixationBreak'); end
            end
        end
    end
    
    %Check if it's time to  break out of this stimulus presentation loop
    %if in the last segment, and its duration is within 1 frame of being over
    if segment == ts.nSegments
        %allow to abort if user pressed q button twice
        doStimLoop = (GetSecs-segStartTs(segment)) < (ts.durations(segment)-scr.fd) && nPressedQuit < 2;
    end
end

%% wrap up 
if task.EYE>0
    Eyelink('message', 'Trial_END %d', td.trialNum);
end

trialDone = true;


%save onset times of each segment, relative to START OF SCAN (aka run)
for segI = 1:ts.nSegments
    eval(sprintf('trialRes.t%sOns = segStartTs(%i) - task.tRunStart;',ts.segmentNames{segI},segI));
end

trialRes.tTrialStart   = tTrialStart - task.tRunStart;
trialRes.tTrialEnd     = GetSecs - task.tRunStart;
trialRes.tRes          = tRes - task.tRunStart;
trialRes.tFixBreak     = tFixBreak - task.tRunStart;

trialRes.fixBreak      = 1*fixBreak; %convert from logical to double
trialRes.nFixBreakSegs = nFixBreaks;

trialRes.chosenRes = chosenRes;
trialRes.trialDone = trialDone;
trialRes.userQuit = 1*(nPressedQuit>1);

