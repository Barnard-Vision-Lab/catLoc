function imgScl = scaleIntensitiesToRange(img, goalRng, midLevel)

%pull out the valid pixel intensities:
levs = img(~isnan(img));

%de-mean:
%ml = the mean of intensities, or input midLevel
if nargin>2
    if ~isnan(midLevel) && ~isempty(midLevel)
        ml = midLevel;
    else
        ml = mean(levs);
    end
else
    ml = mean(levs);
end
%subtract out the mean
levsN = levs - ml;
%min of these normalized levels
minN = min(levsN);
%max of these normalized levels
maxN = max(levsN);

%create a new image with mean subtracted
imgScl = img-ml;

%scale pixels below the mean so the min reaches the lower bound requested
if abs(minN)>0 && ml>goalRng(1) %only works if some pixels go below the mean, and the mean is bigger than the lower bound requested
    lowerScale = (ml-goalRng(1))/abs(minN);
    imgScl(img<ml & ~isnan(img)) = imgScl(img<ml & ~isnan(img))*lowerScale;
end

%scale the pixels above the mean so the max reaches the upper bound requested
if maxN>0 && goalRng(2)>ml %only works if some pixels go above the mean, and the mean is less than the upper bound requested
    upperScale = (goalRng(2)-ml)/maxN;
    imgScl(img>ml & ~isnan(img)) = imgScl(img>ml & ~isnan(img))*upperScale;
end

%add back the mean:
imgScl = round(imgScl+ml);