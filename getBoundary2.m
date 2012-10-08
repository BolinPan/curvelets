function [measAngs,measDist,inCurvs,outCurvs,measBndry] = getBoundary2(coords,img,object,imgName,distThresh)

% getBoundary.m
% This function takes the coordinates of the boundary endpoints as inputs, scales them appropriately, and constructs the boundary line segments. 
% A line is then extended in both directions from the center of each curvelet and the angle of intersection with the boundary is found. 
% 
% Inputs:
% 
% coords - the locations of the endpoints of each line segment making up the boundary
% 
% img - the image being measured
% 
% extent - the location of the lower left corner, width and height of the image in the figure window, in scaled units
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
% Carolyn Pehlke, Laboratory for Optical and Computational Instrumentation, November 2010
% Update by Jeremy Bredfeldt, Sept 2012

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
    
    lineSegs(aa-1).slope = (rows(aa) - rows(aa-1))/(cols(aa) - cols(aa-1));
    lineSegs(aa-1).intercept = rows(aa) - (cols(aa)*lineSegs(aa-1).slope);
    
    if isinf(lineSegs(aa-1).slope)
        lineSegs(aa-1).angle = 90;
    else
        lineSegs(aa-1).angle = atand(-lineSegs(aa-1).slope);
    end
    
    if lineSegs(aa-1).angle < 0
        lineSegs(aa-1).angle = lineSegs(aa-1).angle + 180;
    end
    
    if cols(aa-1) <= cols(aa)
        colVals = cols(aa-1):1:cols(aa);
    else
        colVals = cols(aa-1):-1:cols(aa);
    end
    
    rowVals = round(lineSegs(aa-1).slope * colVals + lineSegs(aa-1).intercept);
    lineSegs(aa-1).pointVals = horzcat(rowVals',colVals');
    
    %list of angles at each point on boundary
    lineSegs(aa-1).allAngles = ones(1,1*length(rowVals))*lineSegs(aa-1).angle;
end

%used for checking distance to boundary. this is a list of all points on
%the boundary, not in any specific order.
%Check the proximity of the curvelet center to the boundary. If
%it's close then consider this curvelet, if it's too far, then
%don't consider this curvelet.
%allBoundaryPoints = vertcat(lineSegs.pointVals);
%allBoundaryAngles = horzcat(lineSegs.allAngles);
allBoundaryPoints = totalSegPts;
allBoundaryAngles = totalAngs;
allCenterPoints = vertcat(object.center);
[idx_dist,dist] = knnsearch(allBoundaryPoints,allCenterPoints);

inIdx = dist <= distThresh;
inCurvs = object(inIdx);
inBoundaryPoints = allBoundaryPoints(idx_dist(inIdx),:);
inBoundaryAngles = allBoundaryAngles(idx_dist(inIdx))';
inDist = dist(inIdx);
inCurvAngles = 180-vertcat(object(inIdx).angle);
inRelAngles = abs(inBoundaryAngles - inCurvAngles);
idx1 = inRelAngles > 180;
inRelAngles(idx1) = inRelAngles(idx1) - 180;
idx2 = inRelAngles > 90;
inRelAngles(idx2) = 180 - inRelAngles(idx2);

outIdx = dist > distThresh;
outCurvs = object(outIdx);


measAngs = inRelAngles;
measDist = inDist;
measBndry = inBoundaryPoints;
% for bb = 1:length(inCurvs)
%     [lineCurv orthoCurv] = getPointsOnLine(inCurvs(bb),size(img,2));
%     %get intersection points between the curvelet line and the boundary
%     [intLine, iLa, iLb] = intersect(lineCurv,allBoundaryPoints,'rows');
%     %get intersection points between the line orthogonal to the curvelet
%     %and the boundary
%     [intOrtho, iOa, iOb] = intersect(orthoCurv,allBoundaryPoints,'rows');
%     
%     %get distance to boundary intersection points on line and ortholine
%     [idxLineDist, lineDist] = knnsearch(intLine,inCurvs(bb).center);
%     [idxOrthoDist, orthoDist] = knnsearch(intOrtho,inCurvs(bb).center);
% 
%     %get angle at boundary intersection point that is nearest to curvelet
%     %center
%     lEmpty = isempty(lineDist);
%     oEmpty = isempty(orthoDist);
%     if (~lEmpty && ~oEmpty) %check for empty situations
%         if (lineDist <= orthoDist && lineDist < distThresh)
%             %if the dist to int point on line is shorter, use that angle
%             boundaryAngle = allBoundaryAngles(iLb(idxLineDist));
%             boundaryDist = lineDist;
%             boundaryPt = allBoundaryPoints(iLb(idxLineDist),:);
%         elseif (lineDist > orthoDist && orthoDist < distThresh)
%             %if dist to int point on ortho line is shorter, use that angle
%             boundaryAngle = allBoundaryAngles(iOb(idxOrthoDist));
%             boundaryDist = orthoDist;
%             boundaryPt = allBoundaryPoints(iOb(idxOrthoDist),:);
%         else
%             %use the point that is closest to curvelet on boundary
%             boundaryAngle = allBoundaryAngles(idx_dist(bb));
%             boundaryDist = inDist(bb);
%             boundaryPt = allBoundaryPoints(idx_dist(bb),:);
%         end
%     elseif (lEmpty && ~oEmpty && orthoDist < distThresh)
%         boundaryAngle = allBoundaryAngles(iOb(idxOrthoDist));
%         boundaryDist = orthoDist;
%         boundaryPt = allBoundaryPoints(iOb(idxOrthoDist),:);
%     elseif (~lEmpty && oEmpty && lineDist < distThresh)
%         boundaryAngle = allBoundaryAngles(iLb(idxLineDist));
%         boundaryDist = lineDist;
%         boundaryPt = allBoundaryPoints(iLb(idxLineDist),:);
%     else
%         %use the point that is closest to curvelet on boundary
%         boundaryAngle = allBoundaryAngles(idx_dist(bb));
%         boundaryDist = inDist(bb);
%         boundaryPt = allBoundaryPoints(idx_dist(bb),:);
%     end
%     
%     if (abs(inCurvs(bb).angle) > 180)
%         %fix curvelet angle to be between 0 and 180 degrees
%         inCurvs(bb).angle = abs(inCurvs(bb).angle) - 180;
%     end
%     tempAng = abs(inCurvs(bb).angle - boundaryAngle);
%     if tempAng > 90
%         %get relative angle between 0 and 90
%         tempAng = 180-tempAng;
%     end
%     
%     measAngs(bb) = tempAng;
%     measDist(bb) = boundaryDist;
%     %measBndry(bb,:) = boundaryPt;
%     %max(lineSegs(cc).angle,curvLines(dd).angle) - min(lineSegs(cc).angle,curvLines(dd).angle);
%     
% end



% finding each point of the line passing through the centerpoint of the
% curvelet with slope of tan(curvelet angle)
% curvIdx = 0;
% 
% for bb = 1:length(object)   
%     
%     if (dist(bb) < distThresh) %distThresh is in pixels
%         curvIdx = curvIdx + 1;
%         curvLines(curvIdx).center = object(bb).center;
%         curvLines(curvIdx).angle = object(bb).angle;
%         curvLines(curvIdx).slope = -tand(object(bb).angle);
%         curvLines(curvIdx).orthoSlope = -tand(object(bb).angle + 90); %changed from tand(obj.ang) to -tand(obj.ang + 90) 10/12 JB
%         curvLines(curvIdx).intercept = object(bb).center(1) - (curvLines(curvIdx).slope)*object(bb).center(2);
%         curvLines(curvIdx).orthoIntercept = object(bb).center(1) - (curvLines(curvIdx).orthoSlope)*object(bb).center(2);
%         colVals = 1:size(img,2);
%         rowVals = round((curvLines(curvIdx).slope)*colVals + curvLines(curvIdx).intercept);
%         %plot(colVals,rowVals,'o');
%         curvLines(curvIdx).pointVals = horzcat(rowVals',colVals');
%         colVals2 = 1:size(img,2);
%         rowVals2 = round((curvLines(curvIdx).orthoSlope)*colVals + curvLines(curvIdx).orthoIntercept);
%         %plot(colVals2,rowVals2,'*r');
%         curvLines(curvIdx).orthoPvals = horzcat(rowVals2',colVals2'); 
%     end
% end
% 
% % finding the angles of intersection between the curvelet lines and the
% % boundary line segments
% for cc = 1:length(lineSegs)
%     for dd = 1:length(curvLines)
%         intersection1 = intersect(lineSegs(cc).pointVals,curvLines(dd).pointVals,'rows');
%         intersection2 = intersect(lineSegs(cc).pointVals,curvLines(dd).orthoPvals,'rows');
%         
%         if intersection1
%             tempAng(dd) = max(lineSegs(cc).angle,curvLines(dd).angle) - min(lineSegs(cc).angle,curvLines(dd).angle);
%             tempLines(dd) = dd;
%             tempDist(dd) = min(sqrt((curvLines(dd).center(1) - lineSegs(cc).pointVals(:,1)).^2 + (curvLines(dd).center(2) - lineSegs(cc).pointVals(:,2)).^2));
%         elseif intersection2
%             tempAng(dd) = max(lineSegs(cc).angle,curvLines(dd).angle) - min(lineSegs(cc).angle,curvLines(dd).angle);
%             tempLines(dd) = dd;
%             tempDist(dd) = min(sqrt((curvLines(dd).center(1) - lineSegs(cc).pointVals(:,1)).^2 + (curvLines(dd).center(2) - lineSegs(cc).pointVals(:,2)).^2));
%         else
%             tempAng(dd) = -1000;
%             tempLines(dd) = -1000;
%             tempDist(dd) = -1000;
%         end
%         
%     end
%     
%     idx = tempAng > -1000;
%     tempAng = tempAng(idx);
%     
%     idx = tempAng > 180;
%     tempAng(idx) = tempAng(idx) - 180;
%     
%     idx = tempAng > 90;
%     tempAng(idx) = 180 - tempAng(idx);
%     lineSegs(cc).intAngles = tempAng;
%     
%     idx = tempLines > -1000;
%     lineSegs(cc).intLines = tempLines(idx);
%     
%     idx = tempDist > -1000;
%     lineSegs(cc).intDist = tempDist(idx);
%         
% end
% 
% %lineSegs holds information about the segments of the boundary
% %some curvelet lines may intersect the boundary segments twice. deal with
% %that here:
% for ee = 1:length(lineSegs)-1
%     for ff = (ee+1):length(lineSegs)-1
%         
%         [intTest iEE iFF] = intersect(lineSegs(ee).intLines,lineSegs(ff).intLines);
%         if intTest
%             %We have found two segments that are associated with the same curvelet
%             %Check here for which segment is closer to the curvelet
%             distE = lineSegs(ee).intDist(iEE);
%             distF = lineSegs(ff).intDist(iFF);
%             idxE = distE >= distF;
%             idxF = distF > distE;
%             
%             %clear the one from the list that is farther
%             lineSegs(ee).intDist(idxE) = [];
%             lineSegs(ee).intLines(idxE) = [];
%             lineSegs(ee).intAngles(idxE) = [];
%             lineSegs(ff).intDist(idxF) = [];
%             lineSegs(ff).intLines(idxF) = [];
%             lineSegs(ff).intAngles(idxF) = [];
%         end
%     end
% end
% 
% % output
% measAngs = horzcat(lineSegs.intAngles);
% measDist = horzcat(lineSegs.intDist); %this is the distance from the curvelet center to the boundary


end

     
function [lineCurv orthoCurv] = getPointsOnLine(object,imWidth)
    center = object.center;
    angle = object.angle;
    slope = -tand(angle);
    orthoSlope = -tand(angle + 90); %changed from tand(obj.ang) to -tand(obj.ang + 90) 10/12 JB
    intercept = center(1) - (slope)*center(2);
    orthoIntercept = center(1) - (orthoSlope)*center(2);
    colVals = 1:imWidth;
    rowVals = round(slope*colVals + intercept);
    %plot(colVals,rowVals,'o');
    lineCurv = horzcat(rowVals',colVals');
    colVals2 = 1:imWidth;
    rowVals2 = round(orthoSlope*colVals + orthoIntercept);
    %plot(colVals2,rowVals2,'*r');
    orthoCurv = horzcat(rowVals2',colVals2'); 
end