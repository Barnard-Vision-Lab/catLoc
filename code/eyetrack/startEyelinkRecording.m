function [record, task] = startEyelinkRecording(el, task)


Eyelink('startrecording');	% start recording
% You should always start recording 50-100 msec before required otherwise you may lose a few msec of data
WaitSecs(task.time.startRecordingTime);

if task.EYE>=0
    key = 1;
    while key~= 0
        key = EyelinkGetKey(el);		% dump any pending local keys
    end
end

err = Eyelink('checkrecording'); 	% check recording status
if err==0
    record = 1;
    Eyelink('message', 'RECORD_START');
else
    record = 0;	% results in repetition of fixation check
    Eyelink('message', 'RECORD_FAILURE');
    fprintf(1,'\n\nRECORD_FAILURE !!!!!!!\n\n');
end

% determine recorded eye if not already set 
if ~isfield(task,'DOMEYE') && task.EYE>0
    task.DOMEYE = []; tStartWait = GetSecs;
    while isempty(task.DOMEYE) && ((GetSecs-tStartWait)<5) %wait no more than 5 s
        evt = Eyelink('newestfloatsample');
        task.DOMEYE = find(evt.gx ~= -32768);
    end
    if isempty(task.DOMEYE)
        %if you timed out and didnt get a sample, just set it
        if isfield(task,'trackedEye')
            if strcmpi(task.trackedEye, 'right')
                task.DOMEYE = 2;
            else
                task.DOMEYE = 1;
            end
        else
            task.DOMEYE = 1;
            fprintf(1,'(%s) WARNING: task.DOMEYE and task.trackedEye not set, and we stopped waiting after %.1f s to get an eye sample. Setting DOMEYE to 1\n', mfilename, GetSecs-tStartWait);
        end
    end
end