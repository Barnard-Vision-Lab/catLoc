function drawFixation_catLoc(task,scr)
% Draws a dot. 
% 
% Inputs: 
% - task and scr: standard structures 
%
% task has fields: 
% - dotColorI: index to pull out of task.fixation.dotColors

xy = [task.fixation.posX; task.fixation.posY];

Screen('DrawDots', scr.main, xy, task.fixation.dotDiamPix, task.fixation.dotColors(task.fixation.dotColorI,:), [], task.fixation.dotType);
