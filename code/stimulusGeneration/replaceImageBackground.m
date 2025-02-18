function outImg = replaceImageBackground(inImg, oldBG, newBG, doFeather, featherTargetVal)

global img iter

img = inImg;

nRows = size(img, 1); 
nCols = size(img, 2);

%start filling in from the 4 corners
for ri = [1 nRows] 
    for ci=[1 nCols]
        if img(ri,ci)==oldBG
            iter = 0;
            replaceContiguousImagePatch(sub2ind([nRows nCols],ri,ci), oldBG, newBG, doFeather, featherTargetVal);
        end
    end
end

outImg = img;