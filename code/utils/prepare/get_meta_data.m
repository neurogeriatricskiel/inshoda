function s = get_meta_data(path_name)
    % 
    % Get the meta info from the `unisens.xml` file stored in the given
    % path.
    %
    % Input arguments:
    %   path_name : str
    %     The path where the sensor data and `unisens.xml` are stored.
    % 
    % Returns:
    %   s : struct
    %
    % Requires:
    %   xml2struct.m
    % 
    
    % Initialize empty output struct
    s = struct('bodyLocation', '', ...
        'sensorData', struct('name', '', 'type', [], 'Fs', '', 'data', [], 'timestamps', [], 'unit', ''), ...
        'startDate', datetime(datestr(now)), ...
        'stopDate', datetime(datestr(now)), ...
        'duration', '');

    % Read data using `xml2struct.m`
    info = xml2struct(fullfile(path_name, 'unisens.xml'));
    
    % Get sensor location
    for idx_attr = 1:length(info.unisens.customAttributes.customAttribute)
        % Each custom attribute is a 1x1 struct, with fields:
        %   Text       : ''
        %   Attributes : 1x1 struct with fields `key` and `value`
        key   = info.unisens.customAttributes.customAttribute{1, idx_attr}.Attributes.key;
        value = info.unisens.customAttributes.customAttribute{1, idx_attr}.Attributes.value;

        if strcmpi(key, 'sensorLocation')
            s.bodyLocation = value;
            break;
        end
    end

    % Get initial timestamp and calculate final timestamp
    timestampStart = info.unisens.Attributes.timestampStart;
    s.startDate = datetime(timestampStart, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS');
    
    duration = str2double(info.unisens.Attributes.duration);
    s.duration = duration;
    s.stopDate = s.startDate + seconds(duration);

    % Get sampling frequencies
    cnt = 0;
    for idx_sig = 1:length(info.unisens.signalEntry)
        sig_type = info.unisens.signalEntry{1, idx_sig}.Attributes.contentClass;
        if any(ismember({'acc', 'angularRate', 'press', 'temp'}, sig_type))
            sig_units = info.unisens.signalEntry{1, idx_sig}.Attributes.unit;
            sig_fs    = info.unisens.signalEntry{1, idx_sig}.Attributes.sampleRate;
            sig_file  = info.unisens.signalEntry{1, idx_sig}.Attributes.id;
            
            cnt = cnt + 1;
            s.sensorData(cnt).name = sig_type;
            s.sensorData(cnt).type = sig_file;
            s.sensorData(cnt).Fs   = str2double(sig_fs);
            s.sensorData(cnt).unit = sig_units;
        else
            continue;
        end
    end    
end