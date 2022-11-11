clearvars; clc; close all;

% Set source directory
source_dir = '/home/robbin/Projects/Brescia/test/sourcedata';
[tmp, ~, ~] = fileparts(source_dir);
raw_dir = fullfile(tmp, 'rawdata');
clearvars tmp;

% Get list of subject ids
sub_ids = dir(fullfile(source_dir, 'sub-*'));

% Loop over the subject ids
for idx_sub = 1:length(sub_ids)

    % Get current subject id
    current_sub_id = sub_ids(idx_sub).name;
    fprintf('Parsing `%s`\n', current_sub_id);

    % Check if we have recordings for multiple sessions
    % e.g., ses-T1, ses-T2, ...
    sessions = dir(fullfile(...
        sub_ids(idx_sub).folder, sub_ids(idx_sub).name, 'ses*'));
    if ~isempty(sessions)
        % Loop over the session ids
        for idx_sess = 1:length(sessions)
            current_session = sessions(idx_sess).name;
            fprintf('... ... ... Parsing `%s`\n', current_session);

            % Do stuff
        end
    else
        % Get a list of devices
        devices = dir(fullfile(...
            sub_ids(idx_sub).folder, sub_ids(idx_sub).name, 'trackedpoint-*'));

        % Initialize placeholder struct
        s = struct('bodyLocation', [], 'sensorData', [], ...
            'startDate', [], 'stopDate', [], 'duration', []);
        for i = 1:length(devices)-1
            s = [s; ...
                struct('bodyLocation', [], 'sensorData', [], ...
                'startDate', [], 'stopDate', [], 'duration', [])];
        end

        % Loop over the devices
        for idx_device = 1:length(devices)
            fprintf('... Parsing `%s`\n', devices(idx_device).name);

            % Read data from current device
            s(idx_device) = get_data(fullfile(...
                devices(idx_device).folder, ...
                devices(idx_device).name));
        end

        % Split the data on a per-day basis
        data_by_date = split_data_by_date(s);

        % Save data
        for idx_date = 1:length(data_by_date)
            data = data_by_date(idx_date).data;
            date = datestr(data(1).startDate, 'yyyymmdd');
            out_file_name = strcat(...
                current_sub_id, ...
                '_', date, '.mat');

            if ~isfolder(raw_dir)
                mkdir(raw_dir);
            end
            if ~isfolder(fullfile(raw_dir, current_sub_id))
                mkdir(fullfile(raw_dir, current_sub_id))
            end
            save(fullfile(raw_dir,current_sub_id,out_file_name), '-v7.3', 'data');
        end
    end


end