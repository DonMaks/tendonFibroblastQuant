clear all;

in = 'J:\Data_Stefania\';
quality = 'uint8'; % either 'uint8' or 'uint16'
maxIntensity = 'automatic'; % either 'automatic' or the value of the 16bit image mapped to 255
nTrainingImages = 10; % Number of images from the dataset used for training the classifier
nImagesToLookAtForScaling = 10; % Number of images looked at for evaluating the data range


infolder = strcat(in, 'Images\');
outfolderChannel1 = strcat(in, 'ImagesChannelDead8bit\');
outfolderChannel2 = strcat(in, 'ImagesChannelAll8bit\');
outfolderTraining = strcat(in, 'ImagesTraining8bit\');

filelist = dir(fullfile(infolder,'*.tif'));
k = length(filelist);

trainingImageIndices = round(linspace(1, k, nTrainingImages));
scalingImageIndices = round(linspace(1, k, nImagesToLookAtForScaling));


maximum.Channel1 = zeros(1, nImagesToLookAtForScaling);
maximum.Channel2 = zeros(1, nImagesToLookAtForScaling);
f = 1;
for i = 1:k
    if ismember(i, scalingImageIndices)
        data = loadtiff(strcat(infolder, filelist(i).name));
        n = size(data,3);
        arrayStackC1 = data(:,:,2:2:n);
        arrayStackC2 = data(:,:,1:2:n);
        maximum.Channel1(f) = max(arrayStackC1(:));
        maximum.Channel2(f) = max(arrayStackC2(:));
        f = f+1;
    end
end

        



for i = 1:k
    disp('Loading Data:')
    data = loadtiff(strcat(infolder, filelist(i).name));
    n = size(data,3);
    arrayStackC1 = data(:,:,2:2:n);
    arrayStackC2 = data(:,:,1:2:n);
    arrayStackC1 = flip(arrayStackC1, 3);
    arrayStackC2 = flip(arrayStackC2, 3);
    
    disp(max(arrayStackC1(:)));
    disp(max(arrayStackC2(:)));
    
    if strcmp(quality, 'uint8')
        %Convert to 8-bit by mapping 0-maxIntensity to 0-255 range
        arrayStackC1 = uint8(mat2gray(arrayStackC1, [0 round(mean(maximum.Channel1))])*255);
        arrayStackC2 = uint8(mat2gray(arrayStackC2, [0 round(mean(maximum.Channel2))])*255);
    end
    
    outputFileNameC1 = strcat(outfolderChannel1, filelist(i).name(1:end-4), '.h5');
    outputFileNameC2 = strcat(outfolderChannel2, filelist(i).name(1:end-4), '.h5');
    outputFileNameTraining = strcat(outfolderTraining, filelist(i).name(1:end-4), '.h5');
    
    
    disp('Writing Stack Channel 1:')
    h5create(outputFileNameC1, '/export', size(arrayStackC1), 'Datatype', quality, 'ChunkSize', [128 64 8]);
    h5write(outputFileNameC1, '/export', arrayStackC1);
    disp('done!');
    
    disp('Writing Stack Channel 2:')
    h5create(outputFileNameC2, '/export', size(arrayStackC2), 'Datatype', quality, 'ChunkSize', [128 64 8]);
    h5write(outputFileNameC2, '/export', arrayStackC2);
    disp('done!');
    
    % Cut out the middle column of every nTrainingImages-th image and save
    % it in /ImagesTraining for classification training
    if ismember(i, trainingImageIndices)
        disp(strcat('Writing Stack Training:', {' '}, num2str(i)));
        x = size(arrayStackC2, 1);
        y = size(arrayStackC2, 2);
        trainingStack = arrayStackC2(x/8*3+1:x/8*3+x/4, y/8*3+1:y/8*3+y/4, :);
        h5create(outputFileNameTraining, '/export', size(trainingStack), 'Datatype', quality, 'ChunkSize', [128 64 8]);
        h5write(outputFileNameTraining, '/export', trainingStack);
    end


        
end
