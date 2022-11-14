close all; clc; 
if exist('data', 'var')
    clearvars -except data
else
    clearvars all;
    load(fullfile('/home/robbin/Projects/Brescia/test/rawdata/sub-BS2780', ...
        'sub-BS2780_20220328.mat'));
end

idx_loc = find(ismember({data.bodyLocation}, {'chest'})==1,1,'first');
idx_sens = find(ismember({data(idx_loc).sensorData.name}, {'acc'})==1,1,'first');

acc = data(idx_loc).sensorData(idx_sens).data;
fs = data(idx_loc).sensorData(idx_sens).Fs;
initial_timestamp = data(idx_loc).startDate;

WBs = detectWBFromIMU_LowBack(acc, fs, 'initial_timestamp', initial_timestamp, 'visualize', true);