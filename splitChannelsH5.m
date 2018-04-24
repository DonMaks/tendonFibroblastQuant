clear all;
in = 'J:\Data_Tino\LD_1-76-xx\';
infolder = strcat(in, 'Images\');
outfolderChannel1 = strcat(in, 'ImagesChannelDead\');
outfolderChannel2 = strcat(in, 'ImagesChannelAll\');
outfolderTraining = strcat(in, 'ImagesTraining\');


filelist = dir(fullfile(infolder,'*.tf8'));
k = length(filelist);
nTrainingImages = 10;
trainingImageIndices = round(linspace(1, k, nTrainingImages));


for i = 1:k
    disp('Loading Data:')
    data = loadtiff(strcat(infolder, filelist(i).name));
    
    n = size(data,3);
    
    arrayStackC1 = data(:,:,2:2:n);
    arrayStackC2 = data(:,:,1:2:n);
    arrayStackC1 = flip(arrayStackC1, 3);
    arrayStackC2 = flip(arrayStackC2, 3);
    
%     %Convert to 8-bit by mapping 0-2000 to 0-255 range
%     arrayStackC1 = uint8(mat2gray(arrayStackC1, [0 1500])*255);
%     arrayStackC2 = uint8(mat2gray(arrayStackC2, [0 1500])*255);
    
    outputFileNameC1 = strcat(outfolderChannel1, filelist(i).name(1:end-4), '.h5');
    outputFileNameC2 = strcat(outfolderChannel2, filelist(i).name(1:end-4), '.h5');
    outputFileNameTraining = strcat(outfolderTraining, filelist(i).name(1:end-4), '.h5');
    
    
    disp('Writing Stack Channel 1:')
    h5create(outputFileNameC1, '/export', size(arrayStackC1), 'Datatype', 'uint16', 'ChunkSize', [128 64 8]);
    h5write(outputFileNameC1, '/export', arrayStackC1);
    disp('done!');
    
    disp('Writing Stack Channel 2:')
    h5create(outputFileNameC2, '/export', size(arrayStackC2), 'Datatype', 'uint16', 'ChunkSize', [128 64 8]);
    h5write(outputFileNameC2, '/export', arrayStackC2);
    disp('done!');
    
    % Cut out the middle column of every nTrainingImages-th image and save
    % it in /ImagesTraining for classification training
    if ismember(i, trainingImageIndices)
        disp(strcat('Writing Stack Training:', {' '}, num2str(i)));
        x = size(arrayStackC2, 1);
        y = size(arrayStackC2, 2);
        trainingStack = arrayStackC2(x/8*3+1:x/8*3+x/4, y/8*3+1:y/8*3+y/4, :);
        h5create(outputFileNameTraining, '/export', size(trainingStack), 'Datatype', 'uint16', 'ChunkSize', [128 64 8]);
        h5write(outputFileNameTraining, '/export', trainingStack);
    end


        
end
