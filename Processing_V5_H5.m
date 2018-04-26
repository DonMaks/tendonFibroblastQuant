clear variables;
cd('T:\Documents\tendonFibroblastQuant');



%% Parameters
%parameters.scale = [0.619 0.619 1]; % physical x y and z dimensions in [um]
parameters.scale = [0.3095 0.3095 2];
parameters.deadThresholdRatio = 0.14; % meanChannelDead/meanChannelAll threshold 
parameters.volumeThreshold = 50; % minimum volume to still be considered a nucleus [um3]
parameters.volumeThresholdMax = 800; % maximum volume to still be considered a nucleus [um3]
parameters.maskThreshold = 0.7; % Threshold at which the ilastik probabilities are considered true foreground
parameters.measurementDepth = 100; % [um] 
parameters.downSamplingFactor = 0; %
parameters.calculateVolume = false;
parameters.measuredVolume = NaN;
parameters.saveVisualization = false;
parameters.saveCellImage = false;
%rootfolder = 'T:\Documents\Project\Data\Testdata\';
%rootfolder = 'J:\Data_Tino\LD_1-76-xx\';
rootfolder = 'P:\Data_Stefania\';

results_folder = strcat(rootfolder, 'Results_', strrep(strrep(char(datetime), ':', '-'), ' ', '-'), '\');
if ~(7==exist(results_folder, 'dir'))
    mkdir(results_folder)
end

outfileSummary = strcat(results_folder, '01_ResultsSummary.csv');
folder = strcat(rootfolder, 'ImagesChannelAll\');
files = dir(fullfile(folder,'*.h5'));

%write header to summary file and parameter file
header = {'Name', 'TotalCellCount', 'AliveCells', 'DeadCells', 'Artefacts', 'Volume'};
header = strjoin(header, ',');
fid = fopen(outfileSummary, 'w+');
fprintf(fid,'%s\n',header);
fclose(fid);
writeStruct(strcat(results_folder, '00_Parameters.txt'), parameters);

res = struct();
for i = 1:length(files)
    filename_ext = files(i).name;
    filename = filename_ext(1:end-3);
    filename_fields = strsplit(filename, '_');
    %% Load data
    disp(strcat('Starting with ', filename));
    disp('Loading Data:');
    tic
    [data, parameters] = loadDataH5(rootfolder, filename, parameters);
    %scale = [0.3095 0.3095 2];
    toc

    
    %% Find Start of imagestack and crop out the region the be evaluated (better performance)
    disp('Crop image stack:')
    tic
    parameters.startIndex = findStartIndex(data);
    parameters.endIndex = parameters.startIndex + ceil(parameters.measurementDepth/parameters.scale(3));
    if parameters.startIndex > 1
        parameters.startIndex = parameters.startIndex-1; %add a layer at the beginning
    end
    
    try
        data.mask = data.mask(:,:,parameters.startIndex:parameters.endIndex);
        data.imageAll = data.imageAll(:,:,parameters.startIndex:parameters.endIndex);
        data.imageDead = data.imageDead(:,:,parameters.startIndex:parameters.endIndex);
        data.dataAll = data.dataAll(:,:,parameters.startIndex:parameters.endIndex);
        data.dataDead = data.dataDead(:,:,parameters.startIndex:parameters.endIndex);
    catch
        data.mask = data.mask(:,:,parameters.startIndex:end);
        data.imageAll = data.imageAll(:,:,parameters.startIndex:end);
        data.imageDead = data.imageDead(:,:,parameters.startIndex:end);
        data.dataAll = data.dataAll(:,:,parameters.startIndex:end);
        data.dataDead = data.dataDead(:,:,parameters.startIndex:end);
        parameters.actualMeasurementDepth = size(data.mask, 3)*parameters.scale(3);
    end
    toc
    %% GUI for user defined measurement of tendon diameter for volume calculation
    if parameters.calculateVolume
        disp('Manual tendon volume measurement:');
        tic
        Tendon=struct('length',{0},'diameter',{0}, 'radius', {0});
        sizingFig=figure;
        set(sizingFig,'name','Select specimen diameter and length, then press "enter measurement"');
        btn = uicontrol('Style', 'pushbutton', 'String', 'Enter Measurement','Backgroundcolor','r','FontWeight','bold',...
                'Position', [round(sizingFig.Position(2)/2)-90 10 200 20],...
                'Callback', ...
                'Tendon.length = apiLength.getDistance(); Tendon.diameter = apiDiameter.getDistance(); Tendon.radius = Tendon.diameter/2; close;');

        % use the image in the middle of the stack
        image = data.imageAll(:,:,round((size(data.imageAll, 3) / 2)));
        sizingImage = imshow(imadjust(image));  
        % Convert XData and YData to microns using conversion factor.
        XDataInMicrons = get(sizingImage,'XData')*parameters.scale(1); 
        YDataInMicrons = get(sizingImage,'YData')*parameters.scale(1);

        % Set XData and YData of image to reflect desired units.    
        set(sizingImage,'XData',XDataInMicrons,'YData',YDataInMicrons);    
        set(gca,'XLim',XDataInMicrons,'YLim',YDataInMicrons);

        % Specify initial position of distance tool on image.
        lengthLine = imdistline(gca,[200 200],[24 308]);
        diameterLine = imdistline(gca,[100 100],[181 230]);

        % Define API parameters (for user interface in figure)
        apiDiameter = iptgetapi(diameterLine);
        apiDiameter.setColor('green');
        apiLength = iptgetapi(lengthLine);
        apiLength.setColor('blue');
        apiDiameter.setLabelTextFormatter('%02.0f microns = diameter');  
        apiLength.setLabelTextFormatter('%02.0f microns = length');  

        fcn = makeConstrainToRectFcn('imline',get(gca,'XLim'),get(gca,'YLim'));
        apiDiameter.setDragConstraintFcn(fcn);
        apiLength.setDragConstraintFcn(fcn);
        waitfor(gcf);
        parameters.endIndex = ceil(parameters.startIndex + Tendon.diameter/3/parameters.scale(3));
        parameters.measuredVolume = calculateVolume(Tendon.radius, Tendon.length, Tendon.diameter/3);
        toc
    end
    
    

    %% Run blob detection on cropped stacks and get the results
    disp('Process image stack:');
    tic

    [ResultsSummary, ResultsTable, OutImages, plt] = processImageStack_optimized_16bit(data, parameters);
    try
        res.(filename_fields{5}) = plt;
    catch
        res.(strcat('e', num2str(i))) = plt;
    end
    ResultsSummary.volume = parameters.measuredVolume;
    
    toc
    
    %% Save the results
    disp('Save results table:');
    tic
    
    writetable(ResultsTable, strcat(results_folder, filename, '.csv'));
    
    toc
    
    disp('Save results summary:');
    tic
    
    save(strcat(results_folder, filename,'.mat'), 'ResultsSummary', 'plt');
    
    toc
    
    disp('Save outimages:');
    tic
    
    if parameters.saveVisualization
        writeColorStack(OutImages.full, strcat(results_folder , filename, '_full.tif'))
    end
    
    if parameters.saveCellImage
        writeColorStack(OutImages.cell, strcat(results_folder, filename, '_cells.tif'))
    end
    toc
    
    disp('Write results table:');
    tic
    
    %append line to file
    line = {ResultsSummary.name, num2str(ResultsSummary.cellsTotal), ...
            num2str(ResultsSummary.cellsAlive), num2str(ResultsSummary.cellsDead), ...
            num2str(ResultsSummary.artefacts), num2str(ResultsSummary.volume)};
    string_line = strjoin(line, ',');
    fid = fopen(outfileSummary,'a');
    fprintf(fid,'%s\n',string_line);
    fclose(fid);
    toc
end