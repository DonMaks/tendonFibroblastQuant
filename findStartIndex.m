function startIndex = findStartIndex(data)
    for i = 1:size(data.mask, 3)
        current = data.mask(:,:,i);
        if sum(sum(current)) > 100
            %fprintf(string(sum(sum(current))));
            startIndex = i;
            break
        end
    end
end