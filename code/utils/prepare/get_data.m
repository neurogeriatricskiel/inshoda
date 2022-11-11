function s = get_data(path_name)
    %
    % Gets the sensor data from a given path name. The data contains all
    % data from a single sensor for the entire measurement period.
    % 
    % Input arguments:
    %   path_name : str
    %     The path where the sensor data and `unisens.xml` are stored.
    % 
    % Returns:
    %   s : struct
    %
    % Requires:
    %   ./unisensMatlabTools/xml2struct.m
    %   ./unisensMatlabTools/unisensReadSignal.m
    %   ./get_meta_data.m
    % 

    % Provide access to unisensMatlabTools
    addpath(genpath('./unisensMatlabTools'))
    
    % Initialize the struct, and populate it with the meta data
    s = get_meta_data(path_name);
    
    % Loop over the sensors
    for idx_sens = 1:length(s.sensorData)
        
        % Get filename
        file_name = s.sensorData(idx_sens).type;
        
        % Read data in chunks of a day's data
        raw_data = [];
        for t = 0 : (24*60*60) : s.duration
            current_data = unisensReadSignal(path_name, file_name, t, 24*60*60);
            raw_data = [raw_data; current_data];
        end
        s.sensorData(idx_sens).data = raw_data;
        s.sensorData(idx_sens).timestamps = s.startDate + seconds((0:size(raw_data,1)-1)' / s.sensorData(idx_sens).Fs);
        
    end
end