function p = checkRunTaskPerformance_catLoc(task, trialsDone)

%compute hit and false alarm rates
%first find the times when a target event happened 
respTimes = task.runTrials.tRes;
respTimes = respTimes(~isnan(respTimes));

%start off assuming each response is a false alarm. The code below fills it in with 0s when
%they are actually hits. 
respFA = true(size(respTimes));



if task.whichTask==1 %one-back task
    targTrls = find(task.runTrials.stimRepeat(1:trialsDone)); 
    targStims = task.runTrials.repeatStimNum(targTrls);
else %fixation color task
    targTrls = find(task.runTrials.fixColorChange(1:trialsDone));
    targStims = task.runTrials.fixColorChangeStimNum(targTrls);
end

nTargs = length(targTrls);
targHits = false(1,nTargs);
hitRTs = NaN(1,nTargs);
for tii=1:nTargs
    eval(sprintf('tEvent = task.runTrials.tstimulus%iOns(%i);', targStims(tii), targTrls(tii)));
    tDiffs = respTimes - tEvent;
    hitResps = tDiffs>task.minResponseTime & tDiffs<task.maxResponseTime;
    if any(hitResps)
        hitI = find(hitResps);
        respFA(hitI(1)) = false;
        targHits(tii) =  true;
        hitRTs(tii) = tDiffs(hitI(1));
    end
end

%number of target events (same as number of trials with target events)
p.nTargEvents = nTargs;
%count hits
p.nHits = sum(targHits);
%hit rate is number of hits / number of trials with target events 
p.hitRate = p.nHits/p.nTargEvents; 

%RT on hit trials: 
p.geoMeanHitRT = 10^mean(log10(hitRTs(targHits)));
p.meanHitRT = mean(hitRTs(targHits));

%number of false alarms (button presses that weren't within the correct
%time window after a target)
p.nFalseAlarms = sum(respFA);
%false alarm rate: number of false alarms divided by number of trials with
%no target 
p.falseAlarmRate = sum(respFA)/(trialsDone-nTargs);
%another way to calculate: proportion of button presses that were false
%alarms 
p.propRespsFalseAlarms = mean(respFA);

        
        
    
    