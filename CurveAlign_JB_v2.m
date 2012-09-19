function CurveAlign_JB_v2

clc;
clear all;
close all;

global imgName

P = NaN*ones(16,16);
P(1:15,1:15) = 2*ones(15,15);
P(2:14,2:14) = ones(13,13);
P(3:13,3:13) = NaN*ones(11,11);
P(6:10,6:10) = 2*ones(5,5);
P(7:9,7:9) = 1*ones(3,3);

guiCtrl = figure('Resize','on','Units','pixels','Position',[25 75 300 650],'Visible','off','MenuBar','none','name','CurveAlign Control','NumberTitle','off','UserData',0);
guiFig = figure('Resize','on','Units','pixels','Position',[200 425 300 300],'Visible','off','MenuBar','none','name','CurveAlign Figure','NumberTitle','off','UserData',0);
guiRecon = figure('Resize','on','Units','pixels','Position',[210 615 100 100],'Visible','off','MenuBar','none','name','CurveAlign Reconstruction','NumberTitle','off','UserData',0);
guiHist = figure('Resize','on','Units','pixels','Position',[220 605 100 100],'Visible','off','MenuBar','none','name','CurveAlign Histogram','NumberTitle','off','UserData',0);
guiTable = figure('Resize','on','Units','pixels','Position',[230 595 100 100],'Visible','off','MenuBar','none','name','CurveAlign Results Table','NumberTitle','off','UserData',0);

defaultBackground = get(0,'defaultUicontrolBackgroundColor');
set(guiCtrl,'Color',defaultBackground);
set(guiFig,'Color',defaultBackground);
set(guiRecon,'Color',defaultBackground);
set(guiHist,'Color',defaultBackground);
set(guiTable,'Color',defaultBackground);

set(guiCtrl,'Visible','on');
%set(guiFig,'Visible','on');
%set(guiRecon,'Visible','on');
%set(guiHist,'Visible','on');
%set(guiTable,'Visible','on');

imgPanel = uipanel('Parent', guiFig,'Units','normalized','Position',[0 0 1 1]);
imgAx = axes('Parent',imgPanel,'Units','normalized','Position',[0 0 1 1]);

reconPanel = axes('Parent',guiRecon,'Units','normalized','Position',[0 0 1 1]);

histPanel = axes('Parent',guiHist);

valuePanel = uitable('Parent',guiTable,'ColumnName','Angles','Units','normalized','Position',[.15 .2 .25 .6]);
rowN = {'Mean','Median','Standard Deviation','Coef of Alignment'};
statPanel = uitable('Parent',guiTable,'RowName',rowN,'Units','normalized','Position',[.45 .4 .45 .2]);

% button to select an image file
imgOpen = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Get Images','FontUnits','normalized','FontSize',.25,'Units','normalized','Position',[0 .85 .5 .1],'callback','ClickedCallback','Callback', {@getFile});

% button to select a boundary in a .csv file
loadBoundary = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Get Boundary','FontUnits','normalized','FontSize',.25,'UserData',[],'Units','normalized','Position',[.5 .85 .5 .1],'callback','ClickedCallback','Callback', {@boundIn});

% button to run measurement
imgRun = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Run','FontUnits','normalized','FontSize',.25,'Units','normalized','Position',[0 .75 .5 .1]);

% button to reset gui
imgReset = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Reset','FontUnits','normalized','FontSize',.25,'Units','normalized','Position',[.5 .75 .5 .1],'callback','ClickedCallback','Callback',{@resetImg});

% text box for taking in curvelet threshold "keep"
keepLab1 = uicontrol('Parent',guiCtrl,'Style','text','String','Enter % of coefs to keep, as decimal:','FontUnits','normalized','FontSize',.18,'Units','normalized','Position',[0 .3 .75 .1]);
keepLab2 = uicontrol('Parent',guiCtrl,'Style','text','String','(default is .001)','FontUnits','normalized','FontSize',.15,'Units','normalized','Position',[0.25 .275 .3 .1]);
enterKeep = uicontrol('Parent',guiCtrl,'Style','edit','String','.001','BackgroundColor','w','Min',0,'Max',1,'UserData',[],'Units','normalized','Position',[.75 .35 .25 .05],'Callback',{@get_textbox_data});

% panel to contain output checkboxes
guiPanel = uipanel('Parent',guiCtrl,'Title','Select Output: ','Units','normalized','Position',[0 .07 1 .225]);

% checkbox to display the image reconstructed from the thresholded
% curvelets
makeRecon = uicontrol('Parent',guiPanel,'Style','checkbox','Enable','off','String','Reconstructed Image','Min',0,'Max',3,'Units','normalized','Position',[.075 .75 .8 .1]);

% checkbox to display a histogram
makeHist = uicontrol('Parent',guiPanel,'Style','checkbox','Enable','off','String','Histogram','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.075 .57 .8 .1]);

% checkbox to display a compass plot
makeCompass = uicontrol('Parent',guiPanel,'Style','checkbox','Enable','off','String','Compass Plot','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.075 .39 .8 .1]);

% checkbox to output list of values
makeValues = uicontrol('Parent',guiPanel,'Style','checkbox','Enable','off','String','Values','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.075 .188 .8 .1]);

% listbox containing names of active files
listLab = uicontrol('Parent',guiCtrl,'Style','text','String','Selected Images: ','FontUnits','normalized','FontSize',.2,'HorizontalAlignment','left','Units','normalized','Position',[0 .6 1 .1]);
imgList = uicontrol('Parent',guiCtrl,'Style','listbox','BackgroundColor','w','Max',1,'Min',0,'Units','normalized','Position',[0 .425 1 .25]);

% set font
set([guiPanel keepLab1 keepLab2 enterKeep listLab makeCompass makeValues makeRecon  makeHist imgOpen imgRun imgReset loadBoundary],'FontName','FixedWidth')
set([keepLab1 keepLab2],'ForegroundColor',[.5 .5 .5])
set([imgOpen imgRun imgReset loadBoundary],'FontWeight','bold')
set([keepLab1 keepLab2],'HorizontalAlignment','left')

%initialize gui
set([imgRun makeHist makeRecon enterKeep makeValues makeCompass loadBoundary],'Enable','off')
set([makeRecon makeHist makeCompass makeValues],'Value',3)
%set(guiFig,'Visible','on')

% initialize variables used in some callback functions
coords = [-1000 -1000];
aa = 1;
imgSize = [0 0];
rows = [];
cols = [];


%--------------------------------------------------------------------------
% callback function for imgOpen
    function getFile(imgOpen,eventdata)
        
        [fileName pathName] = uigetfile({'*.tif';'*.tiff';'*.jpg';'*.jpeg';'*.*'},'Select Image(s)','MultiSelect','on');

        if ~iscell(fileName)
            img = imread(fullfile(pathName,fileName));
            if size(img,3) > 1
                img = img(:,:,1);
            end
            figure(guiFig);
            imshow(img,'Parent',imgAx);
            imgSize = size(img);
            %displayImg(img,imgPanel)
            
            files = {fileName};
            setappdata(imgOpen,'img',img);
            info = imfinfo(fullfile(pathName,fileName));
            imgType = strcat('.',info.Format);
            imgName = getFileName(imgType,fileName);
            setappdata(imgOpen,'type',info.Format)
            colormap(gray);
        else
            files = fileName;
            numFrames = length(fileName);
            fil = fileName{1};
            img = imread(fullfile(pathName,fil));
            if size(img,3) > 1
                img = img(:,:,1);
            end
            figure(guiFig);
            imshow(img,'Parent',imgAx);
            imgSize = size(img);
            %displayImg(img,imgPanel)
            
            getWait = waitbar(0,'Loading Images...','Units','inches','Position',[5 4 4 1]);
            stack = cell(1,numFrames);
            for pp = 1:numFrames
                waitbar(pp/numFrames)
                stack{pp} = imread(fullfile(pathName,fileName{pp}));
                info = imfinfo(fullfile(pathName,fileName{pp}));
                imgType{pp} = strcat('.',info.Format);
            end
            imgName = cellfun(@(x,y) getFileName(x,y),imgType,fileName,'UniformOutput',false);
            setappdata(imgOpen,'img',stack)
            close(getWait)
        end
        set([keepLab1 keepLab2],'ForegroundColor',[0 0 0])
        set(guiFig,'UserData',0)
        
        if ~get(guiFig,'UserData')
            set(guiFig,'WindowKeyPressFcn',@startPoint)
            coords = [-1000 -1000];
            aa = 1;
        end
        
        setappdata(imgOpen,'type',info.Format)        
        set(imgList,'String',files)
        set(imgList,'Callback',{@showImg})
        set(imgRun,'Callback',{@runMeasure})
        set([makeRecon makeHist makeCompass makeValues imgRun loadBoundary enterKeep],'Enable','on')
        set(imgOpen,'Enable','off')
        set(guiFig,'Visible','on');
        %set(t1,'Title','Image')  

    end

%--------------------------------------------------------------------------
% callback function for enterKeep text box
    function get_textbox_data(enterKeep,eventdata)
        usr_input = get(enterKeep,'String');
        usr_input = str2double(usr_input);
        set(enterKeep,'UserData',usr_input)
    end

%--------------------------------------------------------------------------
% function for calculating statistics
    function stats = makeStats(vals,tempFolder,imgName)
         aveAngle = mean(vals);
         medAngle = median(vals);
         stdAngle = std(vals); 
         if getappdata(guiFig,'boundary') == 1
             refStd = 48.107;
         else
             refStd = 52.3943;
         end
        
         alignMent = 1-(stdAngle/refStd); 
       
         stats = vertcat(aveAngle,medAngle,stdAngle,alignMent);
         saveStats = fullfile(tempFolder,strcat(imgName,'_stats.csv'));
         csvwrite(saveStats,stats)
    end



%--------------------------------------------------------------------------
% callback function for loadBoundary button
    function boundIn(loadBoundary,eventdata)
        [fileName,pathName] = uigetfile('*.csv','Select file containing boundary points: ');
        inName = fullfile(pathName,fileName);
        set(loadBoundary,'UserData',1);
        setappdata(guiFig,'boundary',1)
        set([enterKeep imgRun makeHist makeRecon makeValues makeCompass],'Enable','On')
        coords = csvread(inName);
        hold(imgAx); 
        plot(imgAx,coords(:,1),coords(:,2),'r')
        plot(imgAx,coords(:,1),coords(:,2),'*y')
        hold off
        set(loadBoundary,'Enable','Off');
    end
    

%--------------------------------------------------------------------------
% callback function for imgRun
    function runMeasure(imgRun,eventdata)
        tempFolder = uigetdir(' ','Select Output Directory:');
        IMG = getappdata(imgOpen,'img');
        keep = get(enterKeep,'UserData');   
        %reconPanel = uipanel(t3,'Units','normalized','Position',[0 0 1 1]);
        %boundingbox = get(tabGroup,'Position');
        %width = boundingbox(3);
        %height = boundingbox(4);
                    
        set([imgRun makeHist makeRecon enterKeep imgOpen loadBoundary makeCompass makeValues],'Enable','off')
        
        if isempty(keep)
            keep = .001;
        end
        
        if get(loadBoundary,'UserData')
                setappdata(guiFig,'boundary',1)
        elseif ~get(guiFig,'UserData')
            coords = [0,0];
        else
            [fileName,pathName] = uiputfile('*.csv','Specify output file for boundary coordinates:');
            fName = fullfile(pathName,fileName);
            csvwrite(fName,coords);
        end
        
        runWait = waitbar(0,'Calculating...','Units','inches','Position',[5 4 4 1]);
        waitbar(0.1)
        
        if iscell(IMG)
           [histData,recon,comps,values,stats] = cellfun(@(x,y) processImage(x,y,tempFolder,keep,coords),IMG,imgName,'UniformOutput',false);
           h = histData{1}; r = recon{1}; c = comps{1}; v = values{1}; s = stats{1};          
        else
           [histData,recon,comps,values,stats] = processImage(IMG,imgName,tempFolder,keep,coords);
           h = histData; r = recon; c = comps; v = values; s = stats;
        end
        waitbar(0.2)
        if (get(makeHist,'Value') == get(makeHist,'Max'))
            %set(guiHist,'Title','Histogram')
            set(makeHist,'UserData',1)
            setappdata(makeHist,'data',histData) 
            n = h(1,:);
            x = h(2,:);           
            bar(x,n,'Parent',histPanel)
            set(guiHist,'Visible','on');
        end
        waitbar(0.4)
        if (get(makeRecon,'Value') == get(makeRecon,'Max'))
            %set(guiRecon,'Title','Reconstruction')
            set(makeRecon,'UserData',1)
            setappdata(makeRecon,'data',recon)
            %displayImg(r,reconPanel)
            imshow(r,'Parent',reconPanel);
            set(guiRecon,'Visible','on');
        end
        waitbar(0.5)
%         if (get(makeCompass,'Value') == get(makeCompass,'Max'))
%             set(t4,'Title','Compass Plot')
%             set(makeCompass,'Userdata',1)
%             setappdata(makeCompass,'data',comps)
%             U = c(1,:);
%             V = c(2,:);
%             compass(compassPanel,U,V)
%         end
        waitbar(0.7)
        if(get(makeValues,'Value') == get(makeValues,'Max'))
            %set(guiTable,'Title','Values')
            set(makeValues,'Userdata',1)
            setappdata(makeValues,'data',values)
            setappdata(makeValues,'stats',stats)
            set(valuePanel,'Data',v)
            set(statPanel,'Data',s)
            set(guiTable,'Visible','on');
        end
        
        set(enterKeep,'String',[])
        set([keepLab1 keepLab2],'ForegroundColor',[.5 .5 .5])
        %set([makeRecon makeHist,makeValues makeCompass],'Value',0)
 
        waitbar(1)
        close(runWait)
    end

%--------------------------------------------------------------------------
% function for processing an image
    function [histData,recon,comps,values,stats] = processImage(IMG, imgName, tempFolder, keep, coords)
         
        [object, Ct, inc] = newCurv(IMG,keep);
            
            if getappdata(guiFig,'boundary') == 1
                angles = getBoundary(coords,IMG,object,imgName)';  
                bins = 0:5:90;
            else
                angs = vertcat(object.angle);
                angles = group5(angs,inc);
                bins = min(angles):inc:max(angles);                
            end
            [n xout] = hist(angles,bins);imHist = vertcat(n,xout);
            
             if (get(makeHist,'Value') == get(makeHist,'Max'))
                    histData = imHist;
                    saveHist = fullfile(tempFolder,strcat(imgName,'_hist.csv'));
                    tempHist = circshift(histData,1);
                    csvwrite(saveHist,tempHist');
             else
                 histData = 0;
             end
             
             if (get(makeRecon,'Value') == get(makeRecon,'Max'))
                temp = ifdct_wrapping(Ct,0);
                recon = real(temp);
                saveRecon = fullfile(tempFolder,strcat(imgName,'_reconstructed'));
                fmt = getappdata(imgOpen,'type');
                imwrite(recon,saveRecon,fmt)
             else
                 recon = 0;
             end
             
             if (get(makeCompass,'Value') == get(makeCompass,'Max'))
                U = cosd(xout).*n;
                V = sind(xout).*n;
                comps = vertcat(U,V);
                saveComp = fullfile(tempFolder,strcat(imgName,'_compass_plot.csv'));
                csvwrite(saveComp,comps);
             else
                 comps = 0;
             end
             
             if(get(makeValues,'Value') == get(makeValues,'Max'))
                 values = angles;
                 stats = makeStats(values,tempFolder,imgName);
                 saveValues = fullfile(tempFolder,strcat(imgName,'_values.csv'));
                 csvwrite(saveValues,values);
             else
                 values = 0;
                 stats = makeStats(values,tempFolder,imgName);
             end            

    end

%--------------------------------------------------------------------------
% keypress function for the main gui window
    function startPoint(guiFig,evnt)
        if strcmp(evnt.Key,'alt')
        
            set(guiFig,'WindowKeyReleaseFcn',@stopPoint)
            set(guiFig,'WindowButtonDownFcn',@getPoint)
            set(guiFig,'Pointer','custom','PointerShapeCData',P,'PointerShapeHotSpot',[8,8]);
                      
        end
    end
    
%--------------------------------------------------------------------------
% boundary creation function that records the user's mouse clicks while the
% alt key is being held down
    function getPoint(guiFig,evnt2)
       
       figSize = get(guiFig,'Position');
       aspectImg = imgSize(1)/imgSize(2); %horiz/vert
       aspectFig = figSize(3)/figSize(4); %horiz/vert
       if aspectImg < aspectFig
           %vert limiting dimension
           scaleImg = figSize(4)/imgSize(2);
           vertOffset = 0;
           horizOffset = round((figSize(3) - scaleImg*imgSize(1))/2);
       else
           %horiz limiting dimension
           scaleImg = figSize(3)/imgSize(1);
           vertOffset = round((figSize(4) - scaleImg*imgSize(2))/2);
           horizOffset = 0;           
       end
       
       if ~get(guiFig,'UserData') 
           coords(aa,:) = get(guiFig,'CurrentPoint');
           %convert the selected point from guiFig coords to actual image
           %coordinages
           curRow = round((figSize(4)-(coords(aa,2) + vertOffset))/scaleImg);
           curCol = round((coords(aa,1) - horizOffset)/scaleImg);
           rows(aa) = curRow;
           cols(aa) = curCol;
           aa = aa + 1;

           figure(guiFig);
           hold on;
           ca = get(guiFig,'CurrentAxes');
           plot(ca,cols,rows,'r');
           plot(ca,cols,rows,'*y');
           %plot(ca,50,50,'r');
           %plot(ca,50,50,'*y');
           
           setappdata(guiFig,'rows',rows);
           setappdata(guiFig,'cols',cols);
       end
    end

%--------------------------------------------------------------------------
% terminates boundary creation when the alt key is released
    function stopPoint(guiFig,evnt4)
            
            set(guiFig,'UserData',1)
            set(guiFig,'WindowButtonUpFcn',[]) 
            set(guiFig,'WindowKeyPressFcn',[])
            setappdata(guiFig,'boundary',1)
            coords(:,2) = getappdata(guiFig,'rows');
            coords(:,1) = getappdata(guiFig,'cols');
            set([enterKeep makeValues makeHist makeRecon],'Enable','on')
            set(guiFig,'Pointer','default');
    
    end

%--------------------------------------------------------------------------
% returns the user to the measurement selection window
    function resetImg(resetClear,eventdata)
        CurveAlign_JB_v2
    end

end    