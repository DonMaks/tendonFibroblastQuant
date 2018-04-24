function volume = calculateVolume(radius, length, depth)
    segmentArea = calculateSegmentArea(radius, depth);
    volume = segmentArea * length;
end