% Find the intersection point and angle between two lines

% inputs: center of curvelet, angle of curvelet, user defined region
% (line segments)

% output: angle between the two lines.  If no intersection returned angle
% is 0;

function [angle_tumor] = angleLine(center,angle,hull)

% break up the hull into line segments

hull = [hull;hull(1,:)];
len = size(hull);

for ii = 1:len(1)-1;
    line_seg{ii} = hull(ii:ii+1,:);
end

for ii = 1:length(line_seg)
    
    % first find another point on a line with the center point at specified
    % angle by fixing x
    
    % Check if angle is 270.  If so find intersection differently
    if angle == 270
        inf_flag = 1;
    else
        inf_flag = 0;
    end
    
    x_temp = 10;
    y_temp = x_temp * tan(angle*pi/180);

    xc = center(2) + x_temp;
    yc = center(1) + y_temp;
    
    % find the slope and y_int of line
    mc = (center(1) - yc)/(center(2) - xc);
    bc = yc - mc*xc;

    % find the slope and y_int of user define segment

    % check if slope of user defined line segment is inf and solve for
    % intersection appropriatly
    
    if line_seg{ii}(1,1) == line_seg{ii}(2,1) & inf_flag ==0;
       x_int = line_seg{ii}(1,1);
       y_int = mc * x_int + bc;
    elseif inf_flag ==0;
       mh = (line_seg{ii}(2,2) - line_seg{ii}(1,2))/(line_seg{ii}(2,1) - line_seg{ii}(1,1));
       bh = line_seg{ii}(2,2)- mh*line_seg{ii}(2,1);
       x_int = (bc - bh)/(mh - mc);
       y_int = mc * x_int + bc;
    else
       mh = (line_seg{ii}(2,2) - line_seg{ii}(1,2))/(line_seg{ii}(2,1) - line_seg{ii}(1,1));
       bh = line_seg{ii}(2,2)- mh*line_seg{ii}(2,1);
       x_int = center(2); 
       y_int = mh * x_int + bh;
    end
    
    int(ii,:) = [x_int,y_int];

    % now check to see if intersection point is within user defined line
    % segement

    d1 = sqrt( (x_int - line_seg{ii}(1,1))^2 + (y_int - line_seg{ii}(1,2))^2 );
    d2 = sqrt( (x_int - line_seg{ii}(2,1))^2 + (y_int - line_seg{ii}(2,2))^2 );
    d3 = sqrt( (line_seg{ii}(2,1) - line_seg{ii}(1,1))^2 + (line_seg{ii}(2,2) - line_seg{ii}(1,2))^2 );

    if d1 <= d3 && d2 <= d3
        isInLine = 1;
    else
        isInLine = 0;
    end

    % if intersection point is in line segement, calculate angle between
    % lines
    
    if isInLine == 1;
        x1 = line_seg{ii}(1,1);
        x2 = line_seg{ii}(2,1);
        x3 = center(2);
        x4 = xc;
        y1 = line_seg{ii}(1,2);
        y2 = line_seg{ii}(2,2); 
        y3 = center(1);
        y4 = yc;

        angle_temp(ii) = atan2(abs((x2-x1)*(y4-y3)-(x4-x3)*(y2-y1)),...
        (x2-x1)*(x4-x3)+(y2-y1)*(y4-y3))*180/pi;
    else
        angle_temp(ii) = 0;
    end
    
end

% if line intersects with 2 or more points of the hull, choose the intersection
% closer to the center of the curvelet

ind = find(angle_temp);

if length(ind) == 0;
    angle_tumor = 0;
elseif length(ind) ==1;
    angle_tumor = angle_temp(ind);
else
    for ii = 1:length(ind)
        int_point = int(ind(ii),:);
        d(ii) = sqrt( (center(2) - int_point(1))^2 + ( center(1) - int_point(2) )^2);
    end
    [val,spot] = min(d);
    angle_tumor = angle_temp(ind(spot));
end

if angle_tumor >90
    angle_tumor = 180-angle_tumor;
end


    
    



