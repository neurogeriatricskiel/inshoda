function s = split_data_by_date(input_s)
    % 
    % Splits the data into several data structs such that each struct only
    % consists of the data from a single day.
    % 
    % Input arguments
    %   input_s : struct
    %     The input struct containing both data and meta data.
    % 
    % Returns:
    %   s : struct
    %     A struct of struct, with each struct organized as the input_s
    %     struct but with data split between the days.
    % 
    
    tic;  % start timer
    
    % Get the number of days
    num_days = sum(abs(diff(day(input_s(1).sensorData(1).timestamps)))>0)+1;
    
    % Initialize output struct - with all existing data
    s = struct('data', []);
    for i = 1:num_days
        s(i).data = input_s;
    end
      
    % Loop over the sensor
    for idx_device = 1:length(input_s)
        for idx_sens = 1:length(input_s(idx_device).sensorData)
            
            day_number = day(input_s(idx_device).sensorData(idx_sens).timestamps);
            if length(find(diff(day_number) ~= 0))+1 ~= num_days
                return
            end
            
            idx_split = find(diff(day_number) ~= 0) + 1;
            for i = 1:length(idx_split)
                if i == 1
                    s(i).data(idx_device).sensorData(idx_sens).data = s(i).data(idx_device).sensorData(idx_sens).data(1:idx_split(i)-1,:);
                    s(i).data(idx_device).sensorData(idx_sens).timestamps = s(i).data(idx_device).sensorData(idx_sens).timestamps(1:idx_split(i)-1,:);
                else
                    s(i).data(idx_device).sensorData(idx_sens).data = s(i).data(idx_device).sensorData(idx_sens).data(idx_split(i-1):idx_split(i)-1,:);
                    s(i).data(idx_device).sensorData(idx_sens).timestamps = s(i).data(idx_device).sensorData(idx_sens).timestamps(idx_split(i-1):idx_split(i)-1,:);
                end
                s(i).data(idx_device).startDate = s(i).data(idx_device).sensorData(idx_sens).timestamps(1);
                s(i).data(idx_device).stopDate = s(i).data(idx_device).sensorData(idx_sens).timestamps(end);
                s(i).data(idx_device).duration = [];
            end
            s(end).data(idx_device).sensorData(idx_sens).data = s(end).data(idx_device).sensorData(idx_sens).data(idx_split(end):end,:);
            s(end).data(idx_device).sensorData(idx_sens).timestamps = s(end).data(idx_device).sensorData(idx_sens).timestamps(idx_split(end):end,:);
            s(end).data(idx_device).startDate = s(end).data(idx_device).sensorData(idx_sens).timestamps(1);
            s(end).data(idx_device).stopDate = s(end).data(idx_device).sensorData(idx_sens).timestamps(end);
            s(end).data(idx_device).duration = [];

        end
    end
end
    