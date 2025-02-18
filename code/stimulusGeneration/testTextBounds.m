textSize=48;
string='Good morning.';
font = 'PseudoSloan';
yPositionIsBaseline=0; % 0 or 1... this makes a difference! 

Screen('Preference', 'SkipSyncTests',1);
if IsWin
    Screen('Preference', 'TextRenderer', 0); %0=fast but no anti-aliasing; 1=high-quality slower, 2=FTGL (whatever that is)
else
    Screen('Preference', 'TextRenderer', 1); %0=fast but no anti-aliasing; 1=high-quality slower, 2=FTGL (whatever that is)
end
w=Screen('OpenWindow',0,255);
woff=Screen('OpenOffscreenWindow',w,[],[0 0 2*textSize*length(string) 2*textSize]);
Screen(woff,'TextFont',font);
Screen(woff,'TextSize',textSize);
t=GetSecs;
bounds=TextBounds(woff,string,yPositionIsBaseline)
fprintf('TextBounds took %.3f seconds.\n',GetSecs-t);
Screen('Close',woff);

%Show that it's correct by using the bounding box to frame the text.
x0=100;
y0=100;
Screen(w,'TextFont',font);
Screen(w,'TextSize',textSize);
Screen('DrawText',w,string,x0,y0,0,255,yPositionIsBaseline);
Screen('FrameRect',w,0,InsetRect(OffsetRect(bounds,x0,y0),-1,-1));
Screen('Flip',w);
Speak('Click to quit');
GetClicks;
Screen('Close',w);
