function t = checkRunTiming_catLoc(task)

t.runDuration  = task.tRunEnd - task.tRunStart;
t.runDurationError = t.runDuration - task.goalRunDuration;

d = task.runTrials;

firstStimDurs = d.tISI1Ons - d.tstimulus1Ons;
firstDurErrors = firstStimDurs - task.durations.stimulus;
t.meanFirstStimDurError = mean(firstDurErrors);
t.firstStimDurErrorRange = [min(firstDurErrors) max(firstDurErrors)];

eval(sprintf('lastStimDurs = d.tISI%iOns - d.tstimulus%iOns;', task.org.stimPerTrial, task.org.stimPerTrial));
lastDurErrors = lastStimDurs - task.durations.stimulus;
t.meanLastStimDurError = mean(lastDurErrors);
t.lastStimDurErrorRange = [min(lastDurErrors) max(lastDurErrors)];

trialDurs = d.tTrialEnd - d.tTrialStart;
trialDurErrors = trialDurs - task.durations.trial;
t.meanTrialDurError = mean(trialDurErrors);
t.trialDurErrorRange = [min(trialDurErrors) max(trialDurErrors)];

trialStartErrors = (d.tstimulus1Ons + task.tRunStart) - task.trialGoalStarts(1:task.org.trialsPerRun);
t.meanTrialStartError = mean(trialStartErrors);
t.trialStartErrorRange = [min(trialStartErrors) max(trialStartErrors)];

