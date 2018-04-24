function [ResultsSummary, ResultsTable, OutImages, plot] = processImageStack_optimized_16bit(data, parameters)
    if sum(sum(sum(data.mask)))/numel(data.mask) > 0.5 %invert the data.mask if the background is 1 and the cells 0
        data.mask = mat2gray(~data.mask);
    end

    %% Parameters
    DEAD_THRESHOLD_RATIO = parameters.deadThresholdRatio; %empirically determined threshold for mean intensity of nuclei between the two channels
    DOWN_SAMPLE_FACTOR = parameters.downSamplingFactor; %Set to 0 for no downsampling or the factor by with to downsample the images in x and y dimensions
    imageScale = parameters.scale; %x, y and z dimensions in [um/px]

    %% Donwsample data
    if DOWN_SAMPLE_FACTOR
        downSampleVector = [DOWN_SAMPLE_FACTOR, DOWN_SAMPLE_FACTOR, 1];
        data.mask = imresize(data.mask, DOWN_SAMPLE_FACTOR); %imresize only in x and y dimension
        data.imageAll = imresize(data.imageAll, DOWN_SAMPLE_FACTOR);
        data.imageDead = imresize(data.imageDead, DOWN_SAMPLE_FACTOR);
        data.dataAll = imresize(data.dataAll, DOWN_SAMPLE_FACTOR);
        data.dataDead = imresize(data.dataDead, DOWN_SAMPLE_FACTOR);
        imageScale = imageScale./downSampleVector;
    end

    pixelVolume = prod(imageScale); %Voxel volume in [um^3]
    VOLUME_THRESHOLD = parameters.volumeThreshold / pixelVolume; %Volume threshold in pixel
    VOLUME_THRESHOLD_MAX = parameters.volumeThresholdMax / pixelVolume;

    maskAlive = zeros(size(data.mask));
    maskDead = zeros(size(data.mask));
    maskArtefacts = zeros(size(data.mask));
    maskMerged = zeros(size(data.mask));

    %% Computation

    connComp = bwconncomp(data.mask, 6);
    propConnComp = regionprops(connComp);
    n = length(propConnComp);
    Results = struct('index', {}, 'volume', {}, 'zpos', {}, 'meanAll', {}, 'stdAll', {},...
                     'maxAll', {}, 'minAll', {}, 'meanDead', {}, 'stdDead', {},...
                     'maxDead', {}, 'minDead', {}, 'ratio', {}, 'difference', {}, 'type', {}, 'nPixel', {});
    
    flattend_all = data.dataAll(:);
    flattend_dead = data.dataDead(:);

    for i = 1:n
        % second approach
        pixelIndices = connComp.PixelIdxList(i);
        pixelIndices = pixelIndices{1};
        blobPixelAll = double(flattend_all(pixelIndices));
        blobPixelDead = double(flattend_dead(pixelIndices));
        channelsRatio = mean(blobPixelDead)/mean(blobPixelAll);
        area = propConnComp(i).Area;
        centroid = round(propConnComp(i).Centroid);
        alive = channelsRatio < DEAD_THRESHOLD_RATIO; %a cell is alive if the ratio between the two channes is above a threshold
        

        if area > VOLUME_THRESHOLD && area < VOLUME_THRESHOLD_MAX && alive %Right volume for being a nucleus and alive -> type = 1 = alive
            maskAlive(pixelIndices) = 1;
            type = 1;
        elseif area > VOLUME_THRESHOLD && area < VOLUME_THRESHOLD_MAX && ~alive %Right volume but dead -> type = 0 = dead
            maskDead(pixelIndices) = 1;
            type = 0;
        elseif area <= VOLUME_THRESHOLD %Insufficient volume -> type = 2 = artefact
            maskArtefacts(pixelIndices) = 1;
            type = 2;
        elseif area >= VOLUME_THRESHOLD_MAX
            maskMerged(pixelIndices) = 1;
            type = 3;
        end
        Results(end+1) = struct('index', {i}, 'volume', {length(blobPixelAll)*pixelVolume}, 'zpos', {centroid(3)},... 
                                'meanAll', {mean(blobPixelAll)}, 'stdAll', {std(blobPixelAll)},...
                                'maxAll', {max(blobPixelAll)}, 'minAll', {min(blobPixelAll)},...
                                'meanDead', {mean(blobPixelDead)}, 'stdDead', {std(blobPixelDead)},...
                                'maxDead', {max(blobPixelDead)}, 'minDead', {min(blobPixelDead)},...
                                'ratio', {channelsRatio}, 'difference', {mean(blobPixelDead)-mean(blobPixelAll)},...
                                'type', {type}, 'nPixel', {length(blobPixelAll)});
    end
    
    clear cells flattend_all flattend_dead L;
    volumes = [Results.volume];
    alive = [Results.type] == 1;
    resultsArray = alive(volumes>parameters.volumeThreshold & volumes<parameters.volumeThresholdMax);
    ResultsSummary = struct('name', {parameters.name}, ...
                            'cellsTotal', {length(resultsArray)},...
                            'cellsAlive', {sum(resultsArray)},...
                            'cellsDead', {sum(~resultsArray)}, ...
                            'artefacts', {length(alive)-length(resultsArray)}, ...
                            'parameters', {parameters});

    %% Visualize
    if parameters.saveVisualization
        fullImage = imoverlay3D(data.imageAll, maskAlive, [0 0.5 0]);
        fullImage = imoverlay3D(fullImage, maskDead, [0.5 0 0]);
        fullImage = imoverlay3D(fullImage, maskArtefacts, [0 0.15 0.35]);
        fullImage = imoverlay3D(fullImage, maskMerged, [0.15 0 0.35]);
        OutImages.full = concatImages(data.imageAll, data.imageDead, fullImage);
        OutImages.full = im2uint8(OutImages.full);
    else
        OutImages.full = NaN;
    end
    clear maskAlive maskArtefacts maskDead;
    
    if parameters.saveCellImage
        L = labelmatrix(connComp);
        randomColorMap = rand(n, 3);
        cells = label2rgb3d(L, randomColorMap);
        cells_negative = 1-cells;
        OutImages.cell = imoverlay3Dcol(data.imageAll, cells_negative);
        OutImages.cell = im2uint8(OutImages.cell);
    else
        OutImages.cell = NaN;
    end
    
    %OutImages = struct('full', im2uint16(fullImage), 'alive', im2uint16(maskAlive), 'dead', im2uint16(maskDead), 'artefacts', im2uint16(maskArtefacts), 'imgall', im2uint16(data.imageAll), 'imgdead', im2uint16(data.imageDead));
    ResultsTable = struct2table(Results);
    plot = struct('rat', ResultsTable.ratio, 'dif', ResultsTable.difference, 'all', ResultsTable.meanAll, 'dead', ResultsTable.meanDead);
end