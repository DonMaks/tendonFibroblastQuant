function coloredStack = imoverlay3D(imStack, maskStack, color)
    if size(imStack, 4)==1
        imageStack(:,:,:,1) = imStack;
        imageStack(:,:,:,2) = imStack;
        imageStack(:,:,:,3) = imStack;
    else
        imageStack = imStack;
    end

    coloredStack = zeros(size(imageStack));
    coloredStack(:,:,:,1) = imageStack(:,:,:,1) + color(1) * maskStack;
    coloredStack(:,:,:,2) = imageStack(:,:,:,2) + color(2) * maskStack;
    coloredStack(:,:,:,3) = imageStack(:,:,:,3) + color(3) * maskStack;
    coloredStack(coloredStack>1) = 1;
end
        