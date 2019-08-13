
function [OutCount, OutBBox] = viplibobjtracker(Area, Centroid, BBox, Count,areaChangeFraction, centroidChangeFraction, maxConsecutiveMiss, minPersistenceRatio, alarmCount)
    
areaChangeFraction = areaChangeFraction/100;
centroidChangeFraction = centroidChangeFraction/100;

maxNumTracks = Count;%length(Area);

OutCount = zeros(1,class(Count));
OutBBox  = zeros(size(BBox),class(BBox));

persistent track;
track = [];
if isempty(track)
    track = repmat(empty_track,maxNumTracks,1);
end


%%%
if Count % if blobs were found
   % process tracks

   for i=1:double(Count) % scan through all the incoming blobs

       inCentroid = round(Centroid(i,:)/2);
       inArea     = round(double(Area(i))/2);
       inBBox     = BBox(i,:);
       
       found = false;
       for j=1:maxNumTracks
           T = track(j);
           if T.isTrackActive
               trackArea     = double(T.area);
               trackCentroid = double(T.centroid);
               
               areaRatio = abs(trackArea - inArea)/(trackArea+1);
               centDiff  = inCentroid - trackCentroid;
               centRatio = (centDiff'*centDiff)/inArea;
                           
               % Check if  object belongs to an existing track?
               if (areaRatio < areaChangeFraction)
                   if(centRatio < centroidChangeFraction)
                        found = true;
                        break;
                   end
               end
           end
       end
       
       if found % update existing track
           track(j).justHit = true;
           track(j).hitCount= track(j).hitCount + 1;
           disp(track(j).hitCount);
       else     % create new track
           % find first unused track
           for k=1:maxNumTracks
               if ~track(k).isTrackActive
                   break;
               end
           end
           % fill track information
           track(k).area = int32(inArea);
           track(k).centroid = int32(inCentroid);
           track(k).bbox = int32(inBBox);
           track(k).age = int32(1);
           track(k).hitCount = int32(1);
           track(k).missCount = int32(0);  
           track(k).justHit = true;
           track(k).isTrackActive = true;
       end
   end
          disp('*');

end

for i=1:maxNumTracks
    track(i).age = track(i).age + 1;
    % Find all tracks that were justHit and reset justHit flag
    % For the tracks that were just hit, increment hitCount and clear 
    if track(i).justHit
        track(i).justHit = false;
        track(i).missCount = int32(0); % clear consecutive misses
    else
        track(i).missCount = track(i).missCount + 1;
    end
    
    % Mark track for deletion if: 
    % consecutive misses exceeds maxConsecutiveMiss
    % ratio of hitCount to age drops below minPersistenceRatio
    deleteMissFlag  = (track(i).missCount > maxConsecutiveMiss);
    deleteRatioFlag = (track(i).hitCount < track(i).age*minPersistenceRatio);
    
    if (deleteMissFlag || deleteRatioFlag)
        track(i).isTrackActive = false;
    end
    %display_track(i);
end

% Determine which objects are stationary
OutCount = zeros(1,class(OutCount));
for i=1:maxNumTracks
    if track(i).hitCount >= alarmCount
        OutCount = OutCount + 1;
        y=wavread('C:\Users\Hp\Desktop\Group2(ABAND)\code\cropbuzzer.wav');
        sound(y);
        OutBBox(OutCount,:) = track(i).bbox;
    end
end

%disp(OutCount);
%%

function t = empty_track

t.area          = int32(0);
t.centroid      = int32([0 0]);
t.bbox          = int32([0 0 0 0]);
t.age           = int32(0);
t.hitCount      = int32(0);
t.missCount     = int32(0);
t.justHit       = false;
t.isTrackActive = false;