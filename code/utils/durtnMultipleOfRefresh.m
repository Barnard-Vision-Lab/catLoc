%function realDur = durtnMultipleOfRefresh(goalDur, fps, tolerance)
%by Alex White
%
%Rounds a requested stimulus duration (goalDur) to be in multiple of the
%frame duration of a computer display with given refresh rate (fps) in Hz. 
%Revision Oct 15 2015: allow some tolerance, given that fps may be from a
%noisy estimate of true frame rate, causing for instance a rounding down by
%1 frame of a requested duration of 1 second on a 100 Hz display if
%measured fps is 99.999. 
function realDur = durtnMultipleOfRefresh(goalDur, fps, tolerance)

%If true refresh rate really is fps, and we were to round UP the number of frames, 
%duration would be this: 
roundUpDur = ceil(goalDur*fps)/fps;
%how much longer is this than the requested duration:
roundUpError = roundUpDur-goalDur;

%If that error is very small, then we should not do any rounding, rather than
%rounding down and losing a whole frame (or rounding up and getting too
%much)
if roundUpError<tolerance
    realDur = goalDur;
else %round down number of frames
    realDur=floor(goalDur*fps)/fps;
end
