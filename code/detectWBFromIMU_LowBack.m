function WBs = detectWBFromIMU_LowBack(acc, fs, varargin)
    % 
    % Detect walking bouts from a low back-worn IMU.
    % 
    % Parameters
    %     acc : Nx3 double
    %         Acceleration data (in g) with N time steps across 3 channels.
    %     fs : double
    %         Sampling frequency (in Hz).
    %
    % Optional parameters
    %     visualize : bool, default is False
    %         Whether to plot the preprocessed signals, or not.
    %
    
    for i = 1:2:length(varargin)
        if strcmpi(varargin{i}, 'visualize')
            visualize = varargin{i+1};
        elseif strcmpi(varargin{i}, 'initial_timestamp')
            initial_timestamp = varargin{i+1};
        end
    end
    if ~exist('visualize', 'var'); visualize = false; end
    if ~exist('initial_timestamp', 'var'); initial_timestamp = datetime; end

    WBs = struct();

    %% Identify the vertical axis
    [~, idx_vert] = max(mean(abs(acc(8*60*60*fs:20*60*60*fs,:)),1));

    %% Compute acceleration norm
    acc_N = sqrt(dot(acc, acc, 2));

    %% Resample data
    fs_new = 40;
    acc_N_40Hz = resample_data(acc_N, fs, fs_new);
    fs = fs_new;
    clearvars fs_new;

    %% Detrend and low-pass filter
    acc_N_40Hz_hpf = iir_highpass_filter(acc_N_40Hz);
    acc_N_40Hz_hpf_lpf = butter_lowpass_filter(acc_N_40Hz_hpf, fs, 3.5, 4);

    %% Smooth signal and enhance peaks
    acc_N_40Hz_hpf_lpf_cwt = cwt(acc_N_40Hz_hpf_lpf, 10, 'gaus2', 1/fs)';
    acc_N_40Hz_hpf_lpf_cwt_sgf = sgolayfilt(acc_N_40Hz_hpf_lpf_cwt, 1, 3);

    %% Peak selection
    thr_ampl = 0.1;  % amplitude threshold, in g
    [pkvals, ipks] = findpeaks(acc_N_40Hz_hpf_lpf_cwt_sgf, 'MinPeakHeight', thr_ampl, 'MinPeakDistance', fs/4);

    %% Idenfity walking bouts
    WBs = detect_walking_bouts(ipks, fs);

    % Threshold walking bouts on minimum number of steps
    thr_min_num_steps = 4;
    WBs([WBs.steps] < thr_min_num_steps) = [];

    % Convert walking bouts to binary vector
    walking = zeros(length(acc_N_40Hz_hpf_lpf_cwt_sgf),1);
    for iWB = 1:length(WBs)
        walking(WBs(iWB).start:WBs(iWB).end,:) = 1;
    end

    %% Visualize
    if visualize
        ts = initial_timestamp + seconds((0:1:size(walking,1)-1)'/fs);
        figure;
        ax1 = subplot(8, 1, 1);
        area(ax1, ts, walking, 'FaceColor', [0.929, 0.694, 0.125], 'LineStyle', 'none');
        grid minor;
        ax2 = subplot(8, 1, [2,3,4,5,6,7,8]);
        area(ax2, ts, walking, 'FaceColor', [0.929, 0.694, 0.125], 'FaceAlpha', 0.2, 'LineStyle', 'none');
        grid minor; hold on;
        plot(ax2, ts, acc_N_40Hz_hpf, 'Color', [0, 0, 0, 0.4], 'LineWidth', 2);
%         plot(ax1, ts, acc_N_40Hz_hpf_lpf, 'LineWidth', 2)
%         plot(ax1, ts, acc_N_40Hz_hpf_lpf_cwt, 'LineWidth', 2)
        plot(ax2, ts, acc_N_40Hz_hpf_lpf_cwt_sgf, 'LineWidth', 2)
        plot(ax2, ts(ipks), pkvals, 'o', 'MarkerSize', 6, 'MarkerEdgeColor', 'c', 'MarkerFaceColor', 'none', 'LineWidth', 3);
        ylabel('acceleration (in g)');
        linkaxes([ax1, ax2], 'x');
    end

    %% Calculate gait parameters
    WBs = calculate_gait_params(acc(:,idx_vert), fs, WBs);

    %% Filter steps
    WBs = select_WBs(WBs);

end

function resampled_data = resample_data(data, fs_old, fs_new)
    %
    % Resample data to a new sampling frequency.
    %
    % Parameters
    %     data : NxD double
    %         Data array with N samples across D channels.
    %     fs_old : int, float
    %         Sampling frequency (in Hz) at which data was recorded.
    %     fs_new : int, float
    %         Sampling frequency (in Hz) that is desired.
    % 
    % Returns
    %     resampled_data : N'xD double
    %         Data array after resampling with N' samples across D channels
    %
    if nargin < 3
        fs_new = 40;
    end

    N = size(data, 1);            % number of samples
    x = (1:1:N)';                 % sample points
    xq = (1:(fs_old/fs_new):N)';  % query points
    resampled_data = interp1(x, data, xq);
end

function filtered_data = butter_lowpass_filter(data, fs, fcut, order)
    % 
    % Apply a Butterworth low-pass filter to the data.
    % 
    % Parameters
    %     data : NxD double
    %         Data array with N samples across D channels.
    %     fs : int, float
    %         Sampling frequency (in Hz) of the data.
    %     fcut: int, float
    %         Cut-off frequency (in Hz).
    %     order: int
    %         Order of the filter. (In reality the order will be twice this
    %         number as we are using `filtfilt`.)
    % 
    % Returns
    %     filtered_data : NxD double
    %         Filtered data still with N samples across D channels
    %

    % Get filter coefficients
    [b, a] = butter(order, fcut/(fs/2), 'low');

    % Apply filter twice to the data
    filtered_data = filtfilt(b, a, data);
end

function filtered_data = iir_highpass_filter(data, varargin)
% 
    % Apply a IIR high-pass filter to detrend the data.
    % 
    % Parameters
    %     data : NxD double
    %         Data array with N samples across D channels.
    % 
    % Optional parameters
    %     b, a : array, int, float
    %         Filter coefficients to be used.
    % 
    % Returns
    %     filtered_data : NxD double
    %         Filtered data still with N samples across D channels
    %
    for i = 1:2:length(varargin)
        if strcmpi(varargin{i}, 'b')
            b = varargin{i+1};
        elseif strcmpi(varargin{i}, 'a')
            a = varargin{i+1};
        else
            error('Unrecognized input parameter.')
        end
    end
    if ~exist('b', 'var'); b = [1, -1]; end
    if ~exist('a', 'var'); a = [1, -0.995]; end

    % Apply filter twice to the data
    filtered_data = filtfilt(b, a, data);
end

function walking_bouts = detect_walking_bouts(ipks, fs)
    % 
    % Detect actual steps and identify walking bouts (locomotion periods).
    % 
    % Parameters
    %     ipks : double
    %         Array with identified indices of potential heel-strikes.
    %     fs : int, float
    %         Sampling frequency (in Hz) of the data.
    % 

    % Initialize
    idx_bout = 0;
    loc_flag = 0;
    thr_dur = 3.5*fs;
    walking_bouts = [];

    % Loop over the potential heel-strikes
    for i = 2:length(ipks)
        if (ipks(i)-ipks(i-1)) < thr_dur
            if loc_flag == 0
                % Increment counter for number of bouts
                idx_bout = idx_bout + 1;

                % Set start and end index for current bout
                walking_bouts(idx_bout).start = ipks(i-1);
                walking_bouts(idx_bout).end = ipks(i);

                % Add indices
                walking_bouts(idx_bout).indices = [ipks(i-1), ipks(i)];

                % Set initial number of steps
                walking_bouts(idx_bout).steps = 1;

                % Activate locomotion flag
                loc_flag = 1;
            else
                % Increment number of steps for current walking bout
                walking_bouts(idx_bout).steps = walking_bouts(idx_bout).steps + 1;

                % Add step to list of indices
                walking_bouts(idx_bout).indices = [...
                    walking_bouts(idx_bout).indices, ...
                    ipks(i)];

                % Update hte end index for the current bout
                walking_bouts(idx_bout).end = ipks(i);

                % Update the threshold for the interpeak distance
                thr_dur = 1.5 * fs + (ipks(i)-walking_bouts(idx_bout).start)/walking_bouts(idx_bout).steps;
            end
        else
            if loc_flag == 1
                % Deactivate the locomotion flag
                loc_flag = 0;
                
                % Reset the threshold for the interpeak distance
                thr_dur = 3.5 * fs;
            end
        end
    end
end

function WBs = calculate_gait_params(acc, fs, WBs, varargin)
    % 
    % Compute clinically relevant spatiotemporal gait parameters.
    % 
    % Parameters
    %     acc : NxD double
    %         Acceleration data (in g) with N time steps and D channels.
    %     fs : int, float
    %         Sampling frequency (in Hz).
    %     WBs : struct
    %         Struct with infos on the walking bouts.
    % 
    for i = 1:2:length(varargin)
        if strcmpi(varargin{i}, 'wearable_height')
            wearable_height = varargin{i+1};
        end
    end
    if ~exist('wearable_height', 'var'); wearable_height = 0.5; end

    % Convert acceleration signal
    acc = acc * 9.81;

    % Loop over the walking bouts
    for i = 1:length(WBs)

        % Initialize placeholder for step time and step length
        WBs(i).step_times = (WBs(i).indices(2:end) - WBs(i).indices(1:end-1))/fs;

        % 
        WBs(i).step_lengths = zeros(1,length(WBs(i).step_times));
        for j = 1:length(WBs(i).step_lengths)

            % Vertical velocity
            vel = cumtrapz((WBs(i).indices(j):WBs(i).indices(j+1))'/fs, ...
                acc(WBs(i).indices(j):WBs(i).indices(j+1)));
            vel = detrend(vel);

            % Vertical displacement
            pos = cumtrapz((WBs(i).indices(j):WBs(i).indices(j+1))'/fs, vel(1:end));

            % Height difference
            h = max(pos) - min(pos);

            % Approximate step length
            WBs(i).step_lengths(j) = 2 * sqrt(2 * wearable_height * h - h * h);
        end
    end
end

function WBs = select_WBs(WBs, varargin)
    % 
    % Filter the steps for each WBs such that the calculated step lenghts
    % and step time are in a physiologically reasonable range.
    % 
    % Parameters
    %      WBs : struct
    %           MATLAB struct with the walking bouts.
    %
    % Optional parameters
    %     thr_num_steps : int
    %         Minimum number of steps.
    %     thr_step_time : float, int, default is 0.1 - 2.0 s
    %         The mininum step time (s) for a valid step.
    %     thr_step_length : float, int, default is 0.075 - 4.0 m
    %         The minimum step lenght (m) for a valid step.
    for i = 1:2:length(varargin)
        if strcmpi(varargin{i}, 'thr_num_steps')
            thr_num_steps = varargin{i+1};
        elseif strcmpi(varargin{i}, 'thr_step_time')
            thr_step_time = varargin{i+1};
        elseif strcmpi(varargin{i}, 'thr_step_length')
            thr_step_length = varargin{i+1};
        end
    end
    if ~exist('thr_num_steps', 'var'); thr_num_steps = 4; end
    if ~exist('thr_step_time', 'var'); thr_step_time = [0.1, 2.0]; end
    if ~exist('thr_step_length', 'var'); thr_step_length = [0.075, 4.0]; end

    % Loop over the WBs
    for i = 1:length(WBs)
        
        % Loop backwards of the steps
        for j = length(WBs(i).steps):-1:2

            %
            if WBs(i).step_times(j) >= thr_step_time(1) && WBs(i).step_times(j) <= thr_step_time(2) ...
                    && WBs(i).step_lengths(j) >= thr_step_length(1) && WBs(i).step_lengths(j) <= thr_step_length(2)
                continue;
            else
                % TODO: exclude steps that do no fullfill the requirements
                fprintf('Hello, world!\n');
            end
        end
    end
end