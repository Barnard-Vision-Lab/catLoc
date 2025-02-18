%% function [r] = AnalyzeSubject_catLoc(d)
% Analyze 1 subject's data from the FOVMRI experiment
%
% Inputs:
% - d: table with information about each trial
%
% Outputs:
% - r: one big results structure, with various matrices (e.g., PC for
%    proportion correct).
% - valsByIndex: a structure with one field that labels the parameter that corresponds to each dimension the
%    results matrices in "r".  Each field is a vector, and each value i in the vector
%    labels the value of the parameter for the ith level of that dimension
%    in the data matrix.
%
% by Alex L. White, University of Washington, 2019

function [r, valsByIndex] = AnalyzeSubject_catLoc(d)

minResponseTime = 0.200; %shortest time between target and response that can count as a hit
maxResponseTime = 2.000; %longest time between target and response that can cound as a hit

tasks = {'oneback','fixation'};


%make category lower case for better sorting 
d.origCategory = d.category;
d.origCategoryI = d.categoryI;

%d.category = lower(d.category); 
categories = unique(d.category);

categories = sort(categories);
nCat = length(categories);

%reset categoryI
[~,locb] = ismember(d.category, categories);
d.categoryI = locb;

%set when a target was present
d.targPres = false(size(d.task));
d.targStimNum = zeros(size(d.task));
for ti = 1:2
   taskTrials = d.task==ti;
   if ti==1  %one-back task
       targTrls = find(d.stimRepeat & taskTrials);
       targStims = d.repeatStimNum(targTrls);

   else %fixation color task
       targTrls = find(d.fixColorChange & taskTrials);
       targStims = d.fixColorChangeStimNum(targTrls);
   end     
   d.targPres(targTrls) = true;
   d.targStimNum(targTrls) = targStims;
end

d.reportedPresence = ~isnan(d.chosenRes); %any button is a report of target presence 

goodTrials = find(~d.userQuit);

%% Parameters by which to divide up the data:
%March 25 2022: planning to do only the fixation task, so not dividing
%trials by "task" any more 
splitParams = {'categoryI', 'side'};

%Construct splitTrials, which stores lists of trials that match each
%condition; and valsByIndex, a structure that serves as a guide to the
%resulting data matrices (label each dimension and each value within the
%dimensions).
nLevsPerParam = NaN(1,numel(splitParams));

for bpi=1:numel(splitParams)
    bp=splitParams{bpi};
    
    eval(sprintf('ulevs=unique(d.%s(goodTrials));',bp));
    
    nlevs=length(ulevs);
    if length(ulevs)>1
        eval(sprintf('splitTrials.%s{1}=1:numel(d.chosenRes);',bp));
        eval(sprintf('valsByIndex.%s(1)=NaN;',bp));
        nextra=1;
    else
        nextra=0;
    end
    nLevsPerParam(bpi)=nlevs+nextra;
    
    for li=1:nlevs
        eval(sprintf('splitTrials.%s{li+%i}=find(d.%s==ulevs(li));',bp,nextra,bp));
        eval(sprintf('valsByIndex.%s(li+%i)=ulevs(li);',bp,nextra));
    end
end

if bpi == 1, dSz=[1 nLevsPerParam];
else dSz = nLevsPerParam; end


%initialize the big matrices in the "r" structure that will store each variable
testr = AnalyzeTrials_catLoc(d(goodTrials,:), minResponseTime, maxResponseTime);  %find out what the output variables are by analyzing the whole data set together
vars = fieldnames(testr);
%initialize each matrix in r;
for vi=1:numel(vars)
    eval(sprintf('r.%s = NaN(dSz);', vars{vi}));
end

%% Create a huge command (called "cmd") to then execute with "eval"
% That command divides up trials according to each combination of all the parameters
% in splitParams and analyzes each subset of trials

%First, set up nested "for" loops to go through each condition;
trials0=1:numel(d.chosenRes);
cmd=''; itext='(';
for pni=1:numel(splitParams)
    pn=splitParams{pni};
    
    cmd=sprintf('%s \n%s',cmd,sprintf('for %sI=1:numel(splitTrials.%s)',pn,pn));
    cmd=sprintf('%s \n%s',cmd,sprintf('\ttrials%i=intersect(trials%i,splitTrials.%s{%sI});',pni,pni-1,pn,pn));
    itext=sprintf('%s%sI,',itext,pn);
end

itext=sprintf('%s)',itext(1:(end-1)));

%theseTrials: the list of trials that match this *combination( of conditions
cmd=sprintf('%s\n\t%s',cmd,sprintf('theseTrials=intersect(trials%i,goodTrials);',pni));

%CALL THE FUNCTION TO ANALYZE THIS SET OF TRIALS
cmd=sprintf('%s\n%s',cmd,'subRes=AnalyzeTrials_catLoc(d(theseTrials,:), minResponseTime, maxResponseTime);');


%Then store the data in the matrices in "r"
for vi=1:numel(vars)
    thisVar = vars{vi};
    cmd=sprintf('%s\n\t%s',cmd,sprintf('r.%s%s=subRes.%s;',thisVar,itext,thisVar));
end
for pni=1:numel(splitParams)
    cmd=sprintf('%s\nend',cmd);
end

%Now use "eval" to execute cmd
try
    eval(cmd)
catch me
    display(cmd);
    keyboard
end 


%% timing info

firstStimDurs = d.tISI1Ons - d.tstimulus1Ons;
r.meanFirstStimDur = mean(firstStimDurs);
r.minFirstStimDur = min(firstStimDurs);
r.maxFirstStimDur = max(firstStimDurs);

lastStimDurs = d.tISI4Ons - d.tstimulus4Ons;
r.meanLastStimDur = mean(lastStimDurs);
r.minLastStimDur = min(lastStimDurs);
r.maxLastStimDur = max(lastStimDurs);

trialDurs = d.tTrialEnd - d.tTrialStart;
r.meanTrialDurs = mean(trialDurs);
r.minTrialDurs = min(trialDurs);
r.maxTrialDurs = max(trialDurs);


r.minResponseTime = minResponseTime;
r.maxResponseTime = maxResponseTime;

valsByIndex.taskName = cat(2 ,{'All'}, tasks);
valsByIndex.category = cat(2, {'All'}, categories');
