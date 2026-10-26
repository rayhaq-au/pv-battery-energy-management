
%% PV + Battery Energy Management System
% Project: PV_BESS_EMS
% All power values are in kW.
% All energy values are in kWh.
% These are illustrative hourly profiles, not measured data.

clear;
clc;
close all;

%% 1. Simulation settings

dt = 1;                  % Time step in hours
t_h = (0:24)';            % Time vector: 0 to 24 hours

%% 2. Solar PV power profile

pv_kW = [ ...
    0 0 0 0 0 ...
    0.2 0.8 1.8 3.0 4.0 ...
    4.8 5.2 5.0 4.4 3.5 ...
    2.4 1.2 0.4 0 0 ...
    0 0 0 0 0]';

%% 3. Household electricity demand

load_kW = [ ...
    0.5 0.4 0.4 0.4 0.5 ...
    0.8 1.2 1.0 0.8 0.7 ...
    0.7 0.8 0.9 0.8 0.8 ...
    1.0 1.5 2.0 2.5 2.2 ...
    1.8 1.2 0.8 0.6 0.5]';

%% 4. Battery parameters

E_batt = 10;              % Battery capacity in kWh
P_charge_max = 3;         % Maximum charging power in kW
P_discharge_max = 3;      % Maximum discharging power in kW

SOC_initial = 0.50;       % Initial SOC = 50%
SOC_min = 0.20;           % Minimum SOC = 20%
SOC_max = 0.95;           % Maximum SOC = 95%

eta = 0.95;               % Charge/discharge efficiency

%% 5. Create Simulink input signals

% Append the final value so the inputs extend to t = 24 h.
pv_ts = timeseries(pv_kW, t_h);
load_ts = timeseries(load_kW, t_h);

%% 6. Plot the input profiles

figure;

subplot(2,1,1);
plot(t_h, pv_kW, 'LineWidth', 1.5);
grid on;
ylabel('PV Power (kW)');
title('Solar PV Generation');

subplot(2,1,2);
plot(t_h, load_kW, 'LineWidth', 1.5);
grid on;
xlabel('Time (hours)');
ylabel('Load Power (kW)');
title('Household Electricity Demand');

%% 7. Display parameter summary

fprintf('Battery capacity: %.1f kWh\n', E_batt);
fprintf('Initial SOC: %.0f%%\n', 100*SOC_initial);
fprintf('Minimum SOC: %.0f%%\n', 100*SOC_min);
fprintf('Maximum SOC: %.0f%%\n', 100*SOC_max);

fprintf('Number of hourly input samples: %d\n', ...
    numel(pv_kW));
