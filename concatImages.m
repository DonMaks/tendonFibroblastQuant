function image = concatImages(image1, image2, image3)
    try
        value = intmax(class(image1));
    catch
        value = 1;
    end
    borderwidth = size(image1, 1)/256;
    border = ones(size(image1, 1), borderwidth, size(image1, 3), 3, class(image1));
    border = border * value;
    switch nargin
        case 3
            if size(image1, 4)==1
                image1 = cat(4, image1, image1, image1);
            end
            if size(image2, 4)==1
                image2 = cat(4, image2, image2, image2);
            end
            if size(image3, 4)==1
                image3 = cat(4, image3, image3, image3);
            end
            
            image = horzcat(image1, border, image2, border, image3);
        case 2
            if size(image1, 4)==1
                image1 = cat(4, image1, image1, image1);
            end
            if size(image2, 4)==1
                image2 = cat(4, image2, image2, image2);
            end
            image = horzcat(image1, border, image2);
        case 1
            image = image1;
    end
    