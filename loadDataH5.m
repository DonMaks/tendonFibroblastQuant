function [data, parameters] = loadDataH5(filename, parameters)
    filename_probability = strcat(parameters.rootfolder, parameters.probfolder, filename, '.h5');
    filename_imageAll = strcat(parameters.rootfolder, parameters.allfolder, filename, '.h5');
    filename_imageDead = strcat(parameters.rootfolder, parameters.deadfolder, filename, '.h5');
    
    data.dataAll = h5read(filename_imageAll, '/export');
    data.imageAll = mat2gray(data.dataAll, [0, 2000]);
    data.dataDead = h5read(filename_imageDead, '/export');
    data.imageDead = mat2gray(data.dataDead, [0, 2000]);
    parameters.name = filename;

    probability = h5read(filename_probability, '/exported_data');
    probability = reshape(probability, size(data.dataAll));
    if verLessThan('matlab', '9.3')
        data.mask = zeros(size(probability));
        for i = 1:size(probability, 3)
            data.mask(:,:,i) = imbinarize(probability(:,:,i), parameters.maskThreshold);
        end
    else
        data.mask = imbinarize(probability, parameters.maskThreshold);
    end
    if sum(sum(sum(data.mask)))/numel(data.mask) > 0.6
        data.mask =~data.mask;
    end
    
end