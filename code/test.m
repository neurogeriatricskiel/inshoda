close all; clc; clearvars;

% Define file path, and load corresponding data
file_path = fullfile('/home/robbin/Projects/Brescia/test/rawdata/sub-BS2780', ...
        'sub-BS2780_20220324.mat');
load(fullfile('/home/robbin/Projects/Brescia/test/rawdata/sub-BS2780', ...
        'sub-BS2780_20220324.mat'));

% Directory to which the .csv file is written
[base_dir, file_name, file_ext] = fileparts(file_path);
[raw_data_dir, sub_id, ~] = fileparts(base_dir);
derived_data_dir = strrep(raw_data_dir, 'rawdata', 'deriveddata');

% Find the chest/low back-worn device, and the accelerometer data
idx_loc = find(ismember({data.bodyLocation}, {'chest'})==1,1,'first');
idx_sens = find(ismember({data(idx_loc).sensorData.name}, {'acc'})==1,1,'first');

% Get the data, sampling frequency, and timestamps
acc = data(idx_loc).sensorData(idx_sens).data;
fs = data(idx_loc).sensorData(idx_sens).Fs;
initial_timestamp = data(idx_loc).startDate;
ts = initial_timestamp + seconds((0:size(acc,1)-1)'/fs);

% Detect walking bouts
WBs = detectWBFromIMU_LowBack(acc, fs, 'initial_timestamp', initial_timestamp, 'visualize', true);

% Derive the cadence for each walking bout
% ... and for each walking the step time and length average, variability
% and asymmetry
cadence = round((40 * 60 * [WBs.steps]')./([WBs.end]'-[WBs.start]'));
output_matrix = zeros(length(cadence),6);
for iWB = 1:length(WBs)
    output_matrix(iWB,1) = mean(WBs(iWB).step_times);
    output_matrix(iWB,2) = std(WBs(iWB).step_times);
    output_matrix(iWB,3) = abs(mean(WBs(iWB).step_times(1:2:end))-mean(WBs(iWB).step_times(2:2:end)));
    output_matrix(iWB,4) = mean(WBs(iWB).step_lengths);
    output_matrix(iWB,5) = std(WBs(iWB).step_lengths);
    output_matrix(iWB,6) = abs(mean(WBs(iWB).step_lengths(1:2:end))-mean(WBs(iWB).step_lengths(2:2:end)));
end

% Accumulate data in table
T1 = table(ts([WBs.start]),ts([WBs.end]), seconds(ts([WBs.end])-ts([WBs.start])), ...
    [WBs.steps]', cadence, ... 
    'VariableNames', {'start', 'end', 'duration_s', 'number_of_steps', 'cadence'});
T2 = array2table(output_matrix, 'VariableNames', {'mean_step_time_s', 'step_time_variability_s', 'step_time_asymmetry', ...
    'mean_step_length_m', 'step_length_variability_m', 'step_length_asymmetry'});
T = [T1, T2];

% Write table to deriveddata folder
if ~isfolder(derived_data_dir)
    mkdir(derived_data_dir);
end
if ~isfolder(fullfile(derived_data_dir, sub_id))
    mkdir(fullfile(derived_data_dir, sub_id));
end
writetable(T, fullfile(derived_data_dir, sub_id, strcat(file_name, '.csv')));
