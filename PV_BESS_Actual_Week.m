
%% PV-BESS EMS: Actual PV Data for One Week
clear;
clc;
close all;

%% 1. Import the Excel data


filename = 'PV_202510-202610.xlsx';

% Import the Excel data starting from row 3
T = readtable(filename, 'Range', 'A3');

% Rename the columns manually
T.Properties.VariableNames = { ...
    'Date', ...
    'WR4_P_Produktion', 'WR4_E_Day', ...
    'WR1_P_Produktion', 'WR1_E_Day', ...
    'WR2_P_Produktion', 'WR2_E_Day', ...
    'WR3_P_Produktion', 'WR3_E_Day', ...
    'Suntracker_P_Produktion', 'Suntracker_E_Day'};

% Convert the date column from text to datetime

T.Date = datetime(strtrim(T.Date), ...
    'InputFormat', 'dd.MM.yyyy HH:mm:ss,SSS');



%% 3. Select the required week
startDate = datetime(2025,11,10,0,0,0);
endDate   = datetime(2025,11,17,0,0,0);

weekData = T(T.Date >= startDate & T.Date < endDate, :);

%% 4. Check the selected data
fprintf('First timestamp: %s\n', string(weekData.Date(1)));
fprintf('Last timestamp:  %s\n', string(weekData.Date(end)));
fprintf('Number of samples: %d\n', height(weekData));

assert(height(weekData) == 672, ...
    'Expected 672 samples. Check the imported timestamps.');

%% 5. Combine PV power sources
% Assumption: production power is measured in watts.
% Verify the units in the original inverter documentation.


P_pv_W = weekData.WR1_P_Produktion + ...
         weekData.WR2_P_Produktion + ...
         weekData.WR3_P_Produktion + ...
         weekData.WR4_P_Produktion + ...
         weekData.Suntracker_P_Produktion;

P_pv_kW = P_pv_W / 1000;


%% Import household load data from Excel

loadFilename = 'PV_BESS_Household_Load_Profile_Nov2025-v2.xlsx';

% Read the correct worksheet
loadTable = readtable(loadFilename, ...
    'Sheet', 'Load_Profile_15min');

% Column 8 contains household active power in kW
load_kW = loadTable{:,8};

% Check that we have 672 samples
assert(length(load_kW) == 672, ...
    'Load profile must contain 672 samples.');

assert(length(P_pv_kW) == 672, ...
    'PV profile must contain 672 samples.');

% Sampling interval: 15 minutes = 0.25 hours
dt = 0.25;

% Time vector: 0 to 167.75 hours
t_h = (0:671)' * dt;

% Create input signals for Simulink
pv_ts = timeseries(P_pv_kW, t_h);
load_ts = timeseries(load_kW, t_h);

% Plot the two profiles
figure;

plot(t_h, P_pv_kW, 'LineWidth', 1.2);
hold on;
plot(t_h, load_kW, 'LineWidth', 1.2);

xlabel('Time (hours)');
ylabel('Power (kW)');
title('PV Generation and Household Demand');
legend('PV Generation', 'Household Load');
grid on;

% Save the input data
save('PV_BESS_Actual_Week.mat', ...
    'pv_ts', 'load_ts', 'P_pv_kW', ...
    'load_kW', 't_h', 'dt', 'weekData');

disp('PV and household load data are ready.');


% Convert watts to kilowatts
P_pv_kW = P_pv_W / 1000;

%% 6. Create the 15-minute time axis
dt = 0.25;                     % Hours
t_h = (0:height(weekData)-1)' * dt;

% Simulink input
pv_ts = timeseries(P_pv_kW, t_h);

%% 7. Plot actual PV production
figure('Color','w');

plot(t_h/24, P_pv_kW, 'LineWidth', 1.3);
grid on;
xlabel('Day of simulation');
ylabel('PV Power (kW)');
title('Actual PV Production: 10–16 November 2025');
xlim([0 7]);

%% 8. Save the selected week
save('PV_BESS_Actual_Week.mat', ...
    'weekData', 't_h', 'dt', 'P_pv_kW', 'pv_ts');

writetable(weekData, 'PV_Production_Selected_Week.xlsx');

fprintf('Weekly PV data prepared successfully.\n');
