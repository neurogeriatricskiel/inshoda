# Data Structure
The data were collected with [Movisens Move 4](https://www.movisens.com/en/products/activity-sensor/) sensor strapped to the lower back, to the wrist, and laterally just above the ankle joint. The devices were synchronized and set to record signals for seven days in a row (7 * 24 hours).

We tend to organize the data in a [BIDS-like structure](https://bids-specification.readthedocs.io/en/stable/) and we explain this in the sections below.

## Source data and raw data
The source data is the data that come directly from the devices. From the source data we derive raw data, which holds the same information but now is no longer in the Movisens proprietary format but in a MATLAB-based format. 

The data are organized in the following folder structure:
```
.
├── sourcedata/
│   ├── sub-BS2780/
│   │   ├── trackedpoint-CHEST/
│   │   │   ├── acc.bin
│   │   │   ├── angularrate.bin
│   │   │   ├── charging.bin
│   │   │   ├── movementacceleration_live.bin
│   │   │   ├── press.bin
│   │   │   ├── stateofcharge.bin
│   │   │   ├── stepcount_live.bin
│   │   │   ├── temp.bin
│   │   │   ├── tempmean_live.bin
│   │   │   └── unisens.xml
│   │   ├── trackedpoint-LEFTANK/
│   │   └── trackedpoint-LEFTWR/
│   └── ...
│       ├── ...
│       ├── ...
│       └── ...
└── rawdata/
    ├── sub-BS2780/
    │   ├── sub-BS2780_20220324.mat
    │   ├── sub-BS2780_20220325.mat
    │   ├── ...
    │   └── sub-BS2780_20220401.mat
    └── ...
        ├── ...
        ├── ...
        └── ...
```

## Raw data
After preparing the raw data folder structure, we end up with multiple `*.mat` files for each subject. The contents of such a file is a nested struct:

| bodyLocation | sensorData | startDate | stopDate | duration |
| ------------ | ---------- | --------- | -------- | -------- |
| 'chest'      | `1x4 struct` | `1x1 datetime` | `1x1 datetime` | [] |
| 'left_ankle' | `1x4 struct` | `1x1 datetime` | `1x1 datetime` | [] |
| 'left_wrist' | `1x4 struct` | `1x1 datetime` | `1x1 datetime` | [] |

As you can see there is an entry for each body location (that is, each row corresponds to a body location). For each entry, we have the body location, sensor data, start date, stop date, and duration.

The sensor data is organized as a struct itself, that looks like:

| name          | type              | Fs | data               | timestamps           | unit           |
| ------------- | ----------------- | -- | ------------------ | -------------------- | -------------- |
| 'acc'         | 'acc.bin'         | 64 | `5529600x3 double` | `5529600x1 datetime` | 'g'            |
| 'angularRate' | 'angularRate.bin' | 64 | `5529600x3 double` | `5529600x1 datetime` | 'dps'          |
| 'temp'        | 'temp.bin'        |  1 |   `86400x1 double` |   `86400x1 datetime` | 'Grad Celsius' |
| 'press'       | 'press.bin'       |  8 |  `691200x1 double` |  `691200x1 datetime` | 'Pa'           |

## Visualize the data

To visualize the data, for example the gyroscope data from the ankle-worn device, you can run the following lines:

```matlab
>> load('./rawdata/sub-subBS270/sub-BS2780_20220324.mat')
>> idx_loc = find(ismember({data.bodyLocation}, {'left_ankle'})==1,1,'first');
>> idx_sens = find(ismember({data(idx_loc).sensorData.name}, {'angularRate'})==1,1,'first')
>> gyr_data = data(idx_loc).sensorData(idx_sens).data;
>> figure; plot(gyro_data); grid minor;
```
