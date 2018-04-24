function writeColorStack(imageStack, filename)
    if length(size(imageStack))~= 4
        error('The number of dimensions of your colored image stack must be 4!')
    end
    
    [w, h, d, c] = size(imageStack);
    options.color = true;
    options.message = false;
    options.compression = 'lwz';
    
    for i = 1:d
        if i ==1
            options.append = false;
            options.overwrite = true;
            image = reshape(imageStack(:,:,i,:), w, h, c);
            saveastiff(image, filename, options);
        else
            options.append = true;
            image = reshape(imageStack(:,:,i,:), w, h, c);
            saveastiff(image, filename, options);
        end
    end