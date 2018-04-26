% Author: Max Hess
%
% Email: hess.max.timo@gmail.com
%
% Date: 4. April 2018 
% Last revision: 4. April 2018
%
% Description:
% A MATLAB script that generates and executes a batch processing command
% for an ilastik classifier. The user specifies the locations of a
% pre-trained ilastik Pixel Classifier, and input folder containing the
% images to be processed and an output folder. In this version pixel
% classification probabilities are exported as 8-bit multipage .tif files.
% For a full description of ilastik command line acess visit:
% http://ilastik.org/documentation/basics/headless.html
%
% DISCLAIMER:
% The user has to install ilastik beforehand and go through the pixel
% classification workflow to generate a trained pixel classifier. This
% script only works with Windows and the user needs permission to access
% the directory where the ilastik executable is stored.


initial_directory = pwd;
working_directory = uigetdir('C:\Program Files\', 'Select the directory containing the ilastik executable.');
%working_directory = 'C:\Program Files\ilastik-1.3.0\';
cd(working_directory);

[project_name, project_path] = uigetfile('*.ilp', 'Select a pretrained ilastik Pixel Classification project.');
project = strcat(project_path, project_name);
%project = 'C:\Users\Maks\Documents\Scripts\Tino8bitH5.ilp';
%input_folder = 'E:\Data_Tino\LD_1-76-xx\ImagesChannelAll\';

input_folder = uigetdir(initial_directory, 'Select the directory containing the images to be classified.');
input_folder = strcat(input_folder, '\');
%input_folder = 'C:\Users\Maks\Documents\Data\ImagesChannelAllH5\';
output_folder = uigetdir(initial_directory, 'Select the output directory.');
output_folder = strcat(output_folder, '\');
%output_folder = 'C:\Users\Maks\Documents\Data\Probabilities\';

output_name = '{nickname}.h5';
output_format = 'hdf5';
export_source = 'Probabilities Stage 2';
export_channels = '[(None, None, None, 0), (None, None, None, 1)]';




command = strcat('.\run-ilastik.bat --headless --project="', project,...
                 '" --output_format="', output_format, '" --export_source="', export_source,...
                 '" --cutout_subregion="', export_channels, '" --',...
                 'output_filename_format="', output_folder, output_name, '"');
files = dir(fullfile(input_folder, '*.h5'));
files_table = struct2table(files);
full_files = {};

for i = 1:length(files)
    full_files{i} = strcat('"', input_folder, files_table.name{i}, '"');
end

% for i = 1:length(files)-15
%     full_files{i} = strcat(input_folder, files_table.name{i+15});
% end

string = strjoin(full_files);

full_command = strcat(command, {' '}, string);
full_command = full_command{1};
disp(full_command);
system(full_command);