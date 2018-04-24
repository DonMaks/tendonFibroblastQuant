function coloredStack = imoverlay3Dcol(imStack, colMaskStack)
    if size(imStack, 4)==1
        imageStack(:,:,:,1) = imStack;
        imageStack(:,:,:,2) = imStack;
        imageStack(:,:,:,3) = imStack;
    else
        imageStack = imStack;
    end

    coloredStack = zeros(size(imageStack));
    coloredStack(:,:,:,1) = imageStack(:,:,:,1) + colMaskStack(:,:,:,1)*0.5;
    coloredStack(:,:,:,2) = imageStack(:,:,:,2) + colMaskStack(:,:,:,2)*0.5;
    coloredStack(:,:,:,3) = imageStack(:,:,:,3) + colMaskStack(:,:,:,3)*0.5;
    coloredStack(coloredStack>1) = 1;
end       