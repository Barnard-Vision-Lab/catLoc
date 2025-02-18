%% catLoc_Script: this is the script that you execute to start a run of the catLoc experiment 
%% to localize category-selective ventral temporal regions. 
% 
% You must edit this script to specify several variables, including: the sujbect ID 
% (which determines data file names), which display  you're using (which should have 
% an entry in the getDisplayParameters function), which task you wan to do in each run,
% whether you are doing eye-tracking with an Eyelink, which buttons the
% subject can press, and the TR. 
% 
% Before running this script, you need to: 
% - set all stimulus and task parameters in the catLoc_Params function. 
% - specify details about the screen used in the experiment, in the getDisplayParameters function. 
% - Run code to generate images of the stimuli:
%  stimulusGeneration/makeCatLocStimScript.m. The images are saved in catLoc/stimuli/{displayName}
%  and then loaded in during the experiment. 
% 
% NOTE: Edit this script to set up a full experimental session for 1 subject. 
% Below, you specify the total number of runs, and the task condition of
% each. But then you need to execute this script once for each run/scan. At
% the start of the first run, the code plans all trials for all the runs
% you have asked for. See the function catLoc_SetRunAndTrialOrder. 
% That plan is saved in /data/SID/SID_catLocRunInfo.mat
% (where SID is the subject ID entered below). Then upon each subsequent
% run, that file is loaded in to determine what happens next. 
%
% DATA: After each run, three data files are saved in catLoc/data/SID/SID_DATE/. 
% - A .mat file (e.g., SID_DATE_r01.mat for the 1st run). This
%   contains the task and scr functions. task.runTrials is a table with 1 row
%   per trial, saving alld ata. 
% - A .tsv file, which is a simple spreadsheet with 1 row per trial and
%   many columns that specify the stimulus events. This is designed for use
%   with fMRIPrep and glmSingle. 
% - a .edf file, with data from the Eyelink eye-tracker for that run. 
% 
% 
% Written by: Alex White, Barnard College. 
% Thanks to Kalanit Grill-Spector for the face, object and limb images, 
% and to Tony Norcia for the false fonts. 

clear all;

%% Enter the subject's ID
SID = 'xxx';

%% display name: this should  match an entry in getDisplayParameters
displayName = 'JuneProjector';

%% which task? 1 = one-back; 2=fixation 
%set this either to a single number to be applied to all runs, or to a
%vector with 1 number for each run: 
task = [1 1 1 1];

%% practice whether to do just a short practice block or a full scan
practice = 0;

%% do eye-tracking? 0=no, 1=yes
EYE = 0;

%which eye is tracked. set this just in case eye-tracker cant find the eye at scan start so doesnt wait forever.  
trackedEye = 'left';

%% TR duration 
TR = 1.5; 

%% SET HOW MANY RUNS (aka SCANS) TO DO NOW
numRuns = 4;
if length(task)==1
    task = ones(1,numRuns)*task;
else
    if length(task)~=numRuns
        error('set task vector for each of the %i runs', numRuns);
    end
        
end
%% which buttons the subject can press 
responseButtons = {'1!','2@','3#','4$','5%'}; %instruct kids to use the index finger but record all responses


%append all that to params
params.subj             = SID;
params.displayName      = displayName;
params.whichTasks       = task;
params.practice         = practice;
params.EYE              = EYE;
params.trackedEye       = trackedEye;
params.numRuns          = numRuns;
params.responseButtons  = responseButtons;
params.TR               = TR;

%% run the start function 
[runTask, scr, res] = catLoc_Start(params); 
res