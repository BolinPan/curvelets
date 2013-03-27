function [measAngs,measDist,inCurvs,outCurvs,measBndry,inDist,numImPts] = getBoundary3(coords,img,object,imgName,distThresh)

% getBoundary3.m
% This function takes the coordinates of the boundary endpoints as inputs, scales them appropriately, and constructs the boundary line segments. 
% A line is then extended in both directions from the center of each curvelet and the angle of intersection with the boundary is found. 
% 
% Inputs:
% 
% coords - the locations of the endpoints of each line segment making up the boundary
% 
% img - the image being measured
% 
% object - a struct containing the center and angle of each measured curvelet, generated by the newCurv function
%
% distThresh - number of pixels from boundary we should evaluate curvelets
%
% Output:
% 
% histData = the bins and counts of the angle histogram
% inCurvs - curvelets that are considered
% outCurvs - curvelets that are not considered
% measBndry = points on the boundary that are associated with each curvelet
% inDist = distance between boundary and curvelet for each curvelet considered
% numImPts = number of points in the image that are near to the boundary
%
%
% Carolyn Pehlke, Laboratory for Optical and Computational Instrumentation, November 2010
% Update by Jeremy Bredfeldt, Sept 2012

imHeight = size(img,1);
imWidth = size(img,2);
rows = coords(:,2);
cols = coords(:,1);
% structs that will hold the boundary line segments and the lines from the
% curvelets
lineSegs(1:length(coords)-1) = struct('slope',[],'intercept',[],'pointVals',[],'angle',[],'intAngles',[],'intLines',[],'intDist',[],'allAngles',[]);
curvLines(1:length(object)) = struct('center',[],'angle',[],'slope',[],'orthoSlope',[],'intercept',[],'orthoIntercept',[],'orthoPvals',[],'pointVals',[]);

% finding every point in the boundary line segments and calculating the
% angle of the segment
totalSegPts = [];
totalAngs = [];
for aa = 2:length(coords)
    
    [seg_pts, abs_ang] = GetSegPixels([rows(aa-1), cols(aa-1)],[rows(aa), cols(aa)]);
    totalSegPts = [totalSegPts; seg_pts];
    abs_ang = abs_ang*180/pi; %convert to degrees
    if abs_ang < 0
        abs_ang = abs_ang + 180;
    end
    totalAngs = [totalAngs, abs_ang*ones(1,length(seg_pts))];
    
end

%Check the proximity of the curvelet center to the boundary. If
%it's close then consider this curvelet, if it's too far, then
%don't consider this curvelet.
allBoundaryPoints = totalSegPts;
allBoundaryAngles = totalAngs;
allCenterPoints = vertcat(object.center);
[idx_dist,dist] = knnsearch(allBoundaryPoints,allCenterPoints); %returns nearest dist to each curvelet

%Make a list of points in the image (points scattered throughout the image)
C = floor(imWidth/20); %use at least 20 per row in the image, this is done to speed this process up
[I, J] = ind2sub(size(img),1:C:imHeight*imWidth);
allImPoints = [I; J]';
%Get list of image points that are a certain distance from the boundary
[~,dist_im] = knnsearch(allBoundaryPoints(1:3:end,:),allImPoints); %returns nearest dist to each point in image
%threshold distance
inIm = dist_im <= distThresh;
%count number of points
inPts = allImPoints(inIm);
numImPts = length(inPts)*C;

%Threshold the curvelets away that are too far from the boundary
inIdx = dist <= distThresh;
inCurvs = object(inIdx);
inDist = dist(inIdx);
in_idx_dist = idx_dist(inIdx); %these are the indices that are within the distance threshold


inCurvsLen = length(inCurvs);
measAngs = nan(1,inCurvsLen);
measDist = nan(1,inCurvsLen);
measBndry = nan(inCurvsLen,2);

for i = 1:inCurvsLen
    %Get all points along the curvelet and orthogonal curvelet
    [lineCurv orthoCurv] = getPointsOnLine(inCurvs(i),imWidth,imHeight);
    %Get the intersection between the curvelet line and boundary    
    [intLine, iLa, iLb] = intersect(lineCurv,allBoundaryPoints,'rows');
    if (~isempty(intLine))
        %get the closest distance from the curvelet center to the
        %intersection (get rid of the farther one(s))
        [idxLineDist, lineDist] = knnsearch(intLine,inCurvs(i).center);
        boundaryAngle = allBoundaryAngles(iLb(idxLineDist));
        boundaryDist = lineDist;
        boundaryPt = allBoundaryPoints(iLb(idxLineDist),:);
    else
%         [intOrtho, iOa, iOb] = intersect(orthoCurv,allBoundaryPoints,'rows');
%         if (~isempty(inOrtho))
%             %use the orthogonal intersection point
%             [idxOrthoDist, orthoDist] = knnsearch(intOrtho,inCurvs(bb).center);
%             boundaryAngle = allBoundaryAngles(iOb(idxOrthoDist));
%             boundaryDist = orthoDist;
%             boundaryPt = allBoundaryPoints(iOb(idxOrthoDist),:);            
%         else
            %use the closest distance
            boundaryAngle = allBoundaryAngles(in_idx_dist(i));
            boundaryDist = inDist(i);
            boundaryPt = allBoundaryPoints(in_idx_dist(i),:);            
%         end
    end 

    
    if (abs(inCurvs(i).angle) > 180)
        %fix curvelet angle to be between 0 and 180 degrees
        inCurvs(i).angle = abs(inCurvs(i).angle) - 180;
    end
    tempAng = abs(180-inCurvs(i).angle - boundaryAngle);
    if tempAng > 90
        %get relative angle between 0 and 90
        tempAng = 180-tempAng;
    end    
    
    measAngs(i) = tempAng;
    measDist(i) = boundaryDist;
    measBndry(i,:) = boundaryPt;    
end

measAngs = measAngs';
measDist = measDist';

outIdx = dist > distThresh;
outCurvs = object(outIdx);

end

     
function [lineCurv orthoCurv] = getPointsOnLine(object,imWidth,imHeight)
    center = object.center;
    angle = object.angle;
    slope = -tand(angle);
    orthoSlope = -tand(angle + 90); %changed from tand(obj.ang) to -tand(obj.ang + 90) 10/12 JB
    intercept = center(1) - (slope)*center(2);
    orthoIntercept = center(1) - (orthoSlope)*center(2);
    
    [p1 p2] = getIntImgEdge(slope, intercept, imWidth, imHeight, center);
    [lineCurv, ~] = GetSegPixels(p1,p2);
    
    %Not using the orthogonal slope for anything now
    [p1 p2] = getIntImgEdge(orthoSlope, orthoIntercept, imWidth, imHeight, center);
    [orthoCurv, ~] = GetSegPixels(p1,p2);
    
end

function [pt1 pt2] = getIntImgEdge(slope, intercept, imWidth, imHeight, center)
    %Get intersection with edge of image
    %upper left corner of image is 0,0
    
    %check for infinite slope
    if (isinf(slope))
        pt1 = [0 center(2)];
        pt2 = [imHeight center(2)];
        return;
    end
    
    y1 = round(slope*0 + intercept); %intersection with left edge
    y2 = round(slope*imWidth + intercept); %intersection with right edge
    x1 = round((0-intercept)/slope); %intersection with top edge
    x2 = round((imHeight-intercept)/slope); %intersection with bottom edge
    
    img_int_pts = zeros(2,2); %image boundary intersection points
    ind = 1;
    if (y1 > 0 && y1 < imHeight)
        img_int_pts(ind,:) = [y1 0];
        ind = ind + 1;
    end
    
    if (y2 > 0 && y2 < imHeight)
        img_int_pts(ind,:) = [y2 imWidth];
        ind  = ind + 1;
    end
    
    if (x1 > 0 && x1 < imWidth)
        img_int_pts(ind,:) = [0 x1];
        ind = ind + 1;
    end
    
    if (x2 > 0 && x2 < imWidth)
        img_int_pts(ind,:) = [imHeight x2];
        ind = ind + 1;
    end
    
    pt1 = img_int_pts(1,:);
    pt2 = img_int_pts(2,:);
end
