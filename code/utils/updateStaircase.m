function [task] = updateStaircase(task,td,trialRes)

ii =1;
jj = td.whichStair;


if task.stairType == 1
    thisIntensity = trialRes.ISI;
    if task.stair.inLog10
        thisIntensity = log10(thisIntensity);
    end
    task.stair.q{ii, jj} = QuestUpdate(task.stair.q{td.locationI,td.whichStair},thisIntensity, trialRes.respCorrect);
    task.stair.q{ii, jj}.ntrials = task.stair.q{ii, jj}.ntrials+1;
elseif task.stairType == 2
    task.stair.q{ii, jj} = PAL_AMUD_updateUD(task.stair.q{ii, jj}, trialRes.respCorrect);
    if task.stair.dynamicStepSize %CHECK IF TIME TO HALF THE STEP SIZE
        if any(task.stair.q{ii, jj}.reversal(end)==task.stair.revsToReduceStep)
            task.stair.q{ii, jj}.stepSizeUp=task.stair.q{ii, jj}.stepSizeUp*0.5;
            task.stair.q{ii, jj}.stepSizeDown=task.stair.q{ii, jj}.stepSizeDown*0.5;
        elseif any(task.stair.q{ii, jj}.reversal(end)==task.stair.revsToIncreaseStep)
            task.stair.q{ii, jj}.stepSizeUp=task.stair.q{ii, jj}.stepSizeUp*2;
            task.stair.q{ii, jj}.stepSizeDown=task.stair.q{ii, jj}.stepSizeDown*2;
        end
    end
elseif  task.stairType == 3
    thisTargPres = td.categoryI==2;
    respPres = any(trialRes.chosenRes == task.buttons.pres);
    task.stair.ss{ii, jj} = updateSIAM(task.stair.ss{td.locationI,  td.whichStair},thisTargPres,respPres);
end



%% decide whether each staircase is done

if task.stairType==2
    stairsDone = false(task.stair.nSeparateConds,task.stair.nPerCond);
    for i=1:task.stair.nSeparateConds
        for c=1:task.stair.nPerCond
            stairsDone(i,c) = task.stair.q{i,c}.stop;
        end
    end
    
elseif task.stairType==3
    
    if task.stair.terminateByReversalCount
        stairsDone = false(task.stair.nSeparateConds,task.stair.nPerCond);
        propDones   = zeros(task.stair.nSeparateConds,task.stair.nPerCond);
        for i = 1:task.stair.nSeparateConds
            for c = 1:task.stair.nPerCond
                stairsDone(i,c) = task.stair.ss{i,c}.nRevStableSteps>=task.stair.nRevToStop;
                propDones(i,c)  = task.stair.ss{i,c}.nRevStableSteps/task.stair.nRevToStop;
            end
        end
        
    else
        stairsDone = false(task.stair.nTypes,task.stair.nPerType);
    end
end

task.stair.done = stairsDone;
