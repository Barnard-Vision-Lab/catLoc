function instruct_catLoc(task,scr)

% clear keyboard buffer
KbEventFlush(-3);

%clear screen to background color
rubber(scr,[]);

Screen('TextFont',scr.main, task.instruct.fontName);
Screen('TextSize', scr.main, task.instruct.fontSize);
Screen('TextStyle', scr.main, task.instruct.fontStyle);

c=task.instruct.fontColor;
textSep=1.2;


if task.practice
    blockText = 'PRACTICE';
else
    blockText=sprintf('Scan %i of %i', task.runNumber, task.numRuns);
end


if task.whichTask==1
    instructText{1} = 'REPETITION TASK:';
    instructText{2} = sprintf('Press the button when you see an image repeat.');
else
    instructText{1} = 'DOT COLOR TASK';
    instructText{2} = sprintf('Press the button when you see the dot change color.');
end
instructText{3} = 'Look at the dot!';

continueText = 'Press any button to continue';
continueButton = task.buttons.resp;
finalText = 'Wait...';
startScanButton = KbName('t');

%% Draw a blank texture, to initalize all that functionality
blankTex = Screen('MakeTexture',scr.main,ones(10,10)*scr.bgColor);
Screen('DrawTexture', scr.main, blankTex, [], [10 10 20 20],[],scr.drawTextureFilterMode);

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
    
    Screen('TextStyle',sI,task.instruct.fontStyle); 
    
    vertPos = 2.2;
    for ii=1:length(instructText)
        vertPos = vertPos-textSep;
        ptbDrawFormattedText(sI,instructText{ii}, dva2scrPx(scr, 0, vertPos),c,true,true,false,false);
    end
    
    vertPos=vertPos-textSep;
    Screen('TextStyle',sI,2); %italic
    ptbDrawFormattedText(sI,continueText, dva2scrPx(scr, 0, vertPos),c,true,true,false,false);
    Screen('TextStyle',sI,task.instruct.fontStyle); %normal
    
    Screen(sI,'Flip');
    
end

keyPress = 0;
while ~keyPress
    [keyPress] = checkTarPress(continueButton);
end

WaitSecs(0.2);
% clear keyboard buffer
KbEventFlush(-3);  


%% wait for trigger to start
for sI = sIs
    vertPos = 0;
    ptbDrawFormattedText(sI,finalText, dva2scrPx(scr, 0, vertPos),c,true,true,false,false);
    Screen('Flip',sI);
end

WaitSecs(0.05);
keyPress = 0;
while ~keyPress
    [keyPress] = checkTarPress(startScanButton);
end


%% clear screen  
rubber(scr,[]);
for sI = sIs
    Screen(sI,'Flip');
end

