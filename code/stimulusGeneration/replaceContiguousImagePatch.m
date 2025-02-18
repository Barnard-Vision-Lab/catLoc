%% function img = replaceContiguousImagePatch(pis, oldLevel, newLevel, doFeather, featherTargetVal)
% replaces a contigouous section of an image with a new
% brightness color. It does so by recursively expanding out from
% an input image point until reaching the boundaries of that patch (that
% is, where intensities change). Only works on grayscale images.
%
% Note: the image being changed is a global variable "img" 
% This is required to avoid memory overlaod for images with a lot of pixels
% to be replaced. 
% 
% inputs:
% - pis: a vector of linear indices of pixels to set to the new background, and then
%   expand outward from.
% - oldLevel: existing intensity level to replace. Set to NaN if you want to be able to select whatever
%   brightness level lies at the selected pixel and fill in all contiguous neighboring pixels that have that
%   same brightness level with newLevel. So if oldLevel is NaN, then on the first
%   iteration, oldLevel is set to the level of the pixel initially selected.
% - newLevel: level to set pixels within this patch.
% - doFeather: boolean, whether to "feature" the edges of the patch. If
%   true, then when we reach a pixel at the boundary that isn't oldLevel,
%   we average its existing level with newLevel.
% - featherTargetVal: if doFeather is true and newLevel is NaN, then
%   averaging border pixels with newLevel won't work. So in that case, featherTargetVal is
%   the value you want to average border pixels with, when feathering. 
%
function replaceContiguousImagePatch(pis, oldLevel, newLevel, doFeather, featherTargetVal)

global img iter

maxIter =  30000;

iter = iter+1;

if nargin<5 
    featherTargetVal = 128;
elseif doFeather
    if isempty(featherTargetVal) || isnan(featherTargetVal)
        featherTargetVal=128;
    end
end

%if oldLevel is initially set to NaN and we're just given one pixel (which
%should be the case in first call to this function)
if isnan(oldLevel) && numel(pis)==1
%set oldLevel to the brightness level at the selected pixel
   oldLevel = img(pis);
%otherwise, only include pixels that actually have old brightness level
else
pis = pis(img(pis)==oldLevel);
end

if oldLevel~=newLevel
    %loop through pixels
    for pii=1:length(pis)
        %set this pixel to the new  brightness level
        img(pis(pii))=newLevel;
        %find that pixel's row and column:
        [ri, ci] = ind2sub(size(img), pis(pii));
        %find that pixels neighbors: one left, one right, one above, one below
        rs = [ri-1 ri+1 ri ri]; %rows
        cs = [ci    ci  ci-1 ci+1]; %columns
        %select only the pixels that are within the bounds of the image
        inrange = rs<=size(img,1) & rs>0 & cs<=size(img,2) & cs>0;
        rs = rs(inrange);
        cs = cs(inrange);
        %convert neighbor pixels from (row, column) to linear indices
        nis = sub2ind(size(img), rs, cs);
        
        %feathering: select neighbors that ARENT of this patch and average their brightness
        %with the new patch level
        if doFeather
            ois = nis(img(nis)~=oldLevel);
            %feathering wont quite work if newNevel is NaN... so we use the
            %other input variable featherTargetVal which defaults to 128
            if isnan(newLevel)
                img(ois) = mean([img(ois); ones(size(ois))*featherTargetVal]);
                
            else
                img(ois) = mean([img(ois); ones(size(ois))*newLevel]);
            end
        end
        
        %select only the neighbors that are the old background color
        nis = nis(img(nis)==oldLevel);
        
        %recursively call this function on any neighboring pixels that are
        %background
        if ~isempty(nis) && iter<=maxIter
            replaceContiguousImagePatch(nis, oldLevel, newLevel, doFeather);
        end
    end
end