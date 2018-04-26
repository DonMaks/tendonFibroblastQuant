function writeStruct(filename, struct)
    fid = fopen(filename, 'w');
    f = fields(struct);
    format = strcat('%-',string(max(cellfun('length', f))+3), 's: %-6.2f\r\n');
    for i = 1:length(f)
        if isnumeric(struct.(f{i}))
            if length(struct.(f{i}))==1
                fprintf(fid, format, f{i}, struct.(f{i}));
            elseif length(struct.(f{i}))>1
                for k = 1:length(struct.(f{i}))
                    fprintf(fid, format, strcat(f{i}, '_', string(k)) , struct.(f{1})(k));
                end
            end
        end
    end
    
    format2 = strcat('%-',string(max(cellfun('length', f))+3), 's: %-s\r\n');
    for i = 1:length(f)
        if ischar(struct.(f{i}))
            fprintf(fid, format2, f{i}, struct.(f{i}));
        end
        if islogical(struct.(f{i}))
            fprintf(fid, format2, f{i}, string(struct.(f{i})));
        end
    end
    
    fclose(fid);