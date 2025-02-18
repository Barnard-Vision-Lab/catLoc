function finalFeedback_catLoc(task,scr)

% clear keyboard buffer
KbEventFlush(-3); % on the windows computer, this causes a crash" 

%clear screen to background color
rubber(scr,[]);

Screen('TextSize',scr.main,task.instruct.fontSize);
Screen('TextStyle', scr.main, task.instruct.fontStyle);

c=task.instruct.fontColor;
textSep=1.25;

tp = task.runData.taskPerformance;


if task.practice
    blockText = 'All done!';
else
    blockText=sprintf('Scan %i of %i complete!', task.runNumber, task.numRuns);
end


% if task.whichTask==1
% %     feedbackText{1} = 'Your performance on the one-back task:';
% %     feedbackText{2} = sprintf('You correctly detected %i of %i image repeats (%i%% hits)',tp.nHits, tp.nTargEvents, round(100*tp.hitRate));
% %     feedbackText{3} = sprintf('You also made %i false alarms (pressing button before a repetition or more than %i sec after one)', tp.nFalseAlarms, task.maxResponseTime);
%     
% else
% %     feedbackText{1} = 'Your performance on the dot color task:';
% %     feedbackText{2} = sprintf('You correctly detected %i of %i color changes (%i%% hits)',tp.nHits, tp.nTargEvents, round(100*tp.hitRate));
% %     feedbackText{3} = sprintf('You also made %i false alarms (pressing button before a change or more than %i sec after one)', tp.nFalseAlarms, task.maxResponseTime);
% end
feedbackText{1} = 'GOOD JOB!';

continueText = 'Press any button to continue';
continueButton = task.buttons.resp;

%%%%%
%% Now actually draw all the text

%to both screens if there are 2 non-mirrored screens open
if scr.nScreens==2 && ~scr.mirrored
    sIs = [scr.main, scr.otherWin];
else
    sIs = scr.main;
end

for sI = sIs
    
    vertPos = 3.5;
    ptbDrawFormattedText(sI,blockText, dva2scrPx(scr, 0, vertPos),c,true,true,false,false);
    
    Screen('TextStyle', scr.main, task.instruct.fontStyle);
    
    vertPos = 2.1;
    for ii=1:length(feedbackText)
        vertPos = vertPos-textSep;
        ptbDrawFormattedText(sI,feedbackText{ii}, dva2scrPx(scr, 0, vertPos),c,true,true,false,false);
    end
    
    vertPos=vertPos-textSep*1.2;
    Screen('TextStyle',sI,2); %italic
    ptbDrawFormattedText(sI,continueText, dva2scrPx(scr, 0, vertPos),c,true,true,false,false);
    Screen('TextStyle', scr.main, task.instruct.fontStyle);
    
    Screen(sI,'Flip');
    
end

keyPress = 0;
while ~keyPress
    [keyPress] = checkTarPress(continueButton);
end

WaitSecs(0.2);
% clear keyboard buffer
KbEventFlush(-3); % on the windows computer, this causes a crash" );




%% clear screen and button s
rubber(scr,[]);
for sI = sIs
    Screen(sI,'Flip');
end
KbEventFlush(-3); % on the windows computer, this causes a crash" 