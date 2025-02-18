function r = AnalyzeTrials_catLoc(d, minResponseTime, maxResponseTime)

presTrials = find(d.targPres);
abstTrials = find(~d.targPres);
npres = length(presTrials);
nabst = length(abstTrials);

respTimes = d.tRes;
respTimes = respTimes(~isnan(respTimes));

%start off assuming each response is a false alarm. The code below fills it in with 0s when
%they are actually hits. 
respFA = true(size(respTimes));

targHits = false(1,npres);
hitRTs = NaN(1,npres);

for tii=presTrials'
    eval(sprintf('tEvent = d.tstimulus%iOns(%i);', d.targStimNum(tii), tii));

    tDiffs = respTimes - tEvent;
    hitResps = tDiffs>minResponseTime & tDiffs<maxResponseTime;
    if any(hitResps)
        hitI = find(hitResps);
        respFA(hitI(1)) = false;
        targHits(tii) =  true;
        hitRTs(tii) = tDiffs(hitI(1));
    end
end

%number of target events (same as number of trials with target events)
r.nTargEvents = npres;
%count hits
r.nHits = sum(targHits);
%hit rate is number of hits / number of trials with target events 
r.hitRate = r.nHits/r.nTargEvents; 


%RT on hit trials: 
r.geoMeanHitRT = 10^mean(log10(hitRTs(targHits)));
r.meanHitRT = mean(hitRTs(targHits));


%number of false alarms (button presses that weren't within the correct
%time window after a target)
r.nFalseAlarms = sum(respFA);
%false alarm rate: number of false alarms divided by number of trials with
%no target 
r.falseAlarmRate = sum(respFA)/nabst;
%another way to calculate: proportion of button presses that were false
%alarms 
r.propRespsFalseAlarms = mean(respFA);

        
%Compute dprime
%set how much to correct hit rate or false alarm rate of 1 (or 0)
if npres<20
    ratecorr = 0.01;
else
    ratecorr = 1/(2*npres);
end
[r.dprime, r.crit, r.crit2, r.beta, r.usedHitR, r.usedFAR, r.dCorrected] = computeDCFromRates(r.hitRate,r.falseAlarmRate,npres,nabst,ratecorr);

%number of trials
r.ntrials = size(d,1);

