function task = makeStim_catLoc(task, scr)
 
% Prepares stimuli for the catLoc experiment
% Calculates stimulus positions, prepares text and creates sounds 
% 
% Inputs and oututs: usual task and scr structures 


%% Fixation point:

%assumed to be at screen scenter 
task.fixation.posX  = scr.centerX;
task.fixation.posY  = scr.centerY;

%dot size: 
task.fixation.dotDiamPix = round(scr.ppd*task.fixation.dotDiameter);

%in case we are doing eye-tracking and checking fixation: 
scr.fixCkRad = round(task.fixCheckRad*scr.ppd);   % fixation check radius
scr.intlFixCkRad = round(task.initlFixCheckRad*scr.ppd);   % fixation check radius, for trial start



%% eyetracking 
task.fixCkRad = round(task.fixCheckRad*scr.ppd);   % fixation check radius
task.intlFixCkRad = round(task.initlFixCheckRad*scr.ppd);   % fixation check radius, for trial start


%% Text
Screen('TextFont',scr.main,task.instruct.fontName);
Screen('TextSize',scr.main,task.instruct.fontSize);
Screen('TextStyle',scr.main,0);


%% load useful statistics about the stimulus images 
