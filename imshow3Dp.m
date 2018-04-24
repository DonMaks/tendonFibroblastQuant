function imshow3Dp(image1, image2, image3)
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
            
            image = horzcat(image1, image2, image3);
        case 2
            if size(image1, 4)==1
                image1 = cat(4, image1, image1, image1);
            end
            if size(image2, 4)==1
                image2 = cat(4, image2, image2, image2);
            end
            image = horzcat(image1, image2);
        case 1
            image = image1;
    end
    figure('units','normalized','outerposition',[0 0 1 1])
    imshow3D(image);
end