roi = [1 1 5000 5000];
maxNumObj = 200;
alarmCount = 1;
maxConsecutiveMiss = 4;
areaChangeFraction = 50;
centroidChangeFraction = 50;
minPersistenceRatio = 0.7;
PtsOffset = int32(repmat([roi(1) roi(2) 0  0],[maxNumObj 1]));

%%
hVideoSrc = vision.VideoFileReader;
hVideoSrc.Filename = 'bag_bottle.mp4';
hVideoSrc.VideoOutputDataType = 'single';

hColorConv = vision.ColorSpaceConverter('Conversion', 'RGB to YCbCr');
hAutothreshold = vision.Autothresholder;
hAutothreshold.ThresholdScaleFactor = 1.3;
hClosing = vision.MorphologicalClose('Neighborhood',strel('square',5));

hBlob = vision.BlobAnalysis;
hBlob.MaximumCount = maxNumObj;
hBlob.MinimumBlobArea = 250;
%hBlob.MaximumBlobArea = 35000;
hBlob.ExcludeBorderBlobs = true;

hDrawRectangles1 = vision.ShapeInserter;
hDrawRectangles1.Fill = true;
hDrawRectangles1.FillColor='Custom';
hDrawRectangles1.CustomFillColor = [255 0 0];
hDrawRectangles1.Opacity = 0.2;

hDisplayCount = vision.TextInserter;
hDisplayCount.Text = '%4d';
hDisplayCount.Color = [255 255 255];
hDisplayCount.Font = 'LucidaTypewriterRegular';



hDrawRectangles2 = vision.ShapeInserter;
hDrawRectangles2.BorderColor='Custom';
hDrawRectangles2.CustomBorderColor = [255 0 0];

hDrawRectangles3 = vision.ShapeInserter;
hDrawRectangles3.BorderColor='Custom';
hDrawRectangles3.CustomBorderColor = [255 0 0];
videoInfo    = info(hVideoSrc);

hAllObjects = vision.VideoPlayer('Name','All Objects','Position',[20,60,videoInfo.VideoSize/3]);
hThresholdDisplay = vision.VideoPlayer('Name', 'Threshold','Position',[100,60,videoInfo.VideoSize/3]);
hAbandonedObjects = vision.VideoPlayer('Name', 'Abandoned Objects','Position',[1000,60,videoInfo.VideoSize/3]);

firsttime = true;
count = 1;
%%
while ~isDone(hVideoSrc)
    Im = step(hVideoSrc);
    imshow(Im);
 
  
    OutIm = Im(roi(1):end, roi(2):end, :);

    YCbCr = step(hColorConv, OutIm);
    CbCr  = complex(YCbCr(:,:,2), YCbCr(:,:,3));
    if firsttime
        firsttime = false;
        BkgY      = YCbCr(:,:,1);
        BkgCbCr   = CbCr;
    end
    SegY    = step(hAutothreshold, abs(YCbCr(:,:,1)-BkgY));
    SegCbCr = abs(CbCr-BkgCbCr) > 0.05;
    Segmented = step(hClosing, SegY | SegCbCr);
    [Area, Centroid, BBox] = step(hBlob, Segmented);
    Count = length(Area);
    %disp(Area);

imshow(Segmented); title('centroids');
hold on
plot(Centroid(:,1),Centroid(:,2), 'b*')
hold off
% 
% [B,L] = bwboundaries(Segmented,'noholes');
% subplot(2,1,2);
% imshow(Segmented);
% hold on
% for k = 1:length(B)
%    boundary = B{k};
%    plot(boundary(:,2), boundary(:,1), 'r', 'LineWidth', 2)
% end
% hold off
[OutCount, OutBBox] = viplibobjtracker(Area, Centroid, BBox, Count,areaChangeFraction, centroidChangeFraction, maxConsecutiveMiss,minPersistenceRatio, alarmCount);
count= count+1;
%%
    %Results
    Imr = step(hDrawRectangles1, Im, OutBBox);
    Imr(1:15,1:30,:) = 0;
    Imr = step(hDisplayCount, Imr, uint8(OutCount));
    step(hAbandonedObjects, Imr);

    Imr = step(hDrawRectangles2, Im, BBox);
    Imr(1:15,1:30) = 0;
    Imr = step(hDisplayCount, Imr,uint8( OutCount));
    step(hAllObjects, Imr);

    SegIm = step(hDrawRectangles3, repmat(Segmented,[1 1 3]), BBox);
    step(hThresholdDisplay, SegIm);

end
%if OutCount > 0
    %y=wavread('C:\Users\Hp\Desktop\Group2(ABAND)\code\cropbuzzer.wav');
    %sound(y);
%end
disp(OutCount);
release(hVideoSrc);