
%% PV-BESS Portfolio Plots
% Creates six plots for the LinkedIn project portfolio.
% Requires: out, pv_ts, load_ts
% Battery power: positive = charging, negative = discharging
% Simulation time is in hours; power is in kW.

clearvars -except out pv_ts load_ts
close all;
clc;

%% 1. Extract Simulink results

t = out.SOC.Time(:);
SOC = squeeze(out.SOC.Data);
SOC = SOC(:);

P_batt = squeeze(out.P_batt.Data);
P_batt = P_batt(:);

P_grid_import = squeeze(out.P_grid_import.Data);
P_grid_import = P_grid_import(:);

P_grid_export = squeeze(out.P_grid_export.Data);
P_grid_export = P_grid_export(:);

% Convert SOC to percentage if stored as a fraction
if max(SOC) <= 1.01
    SOC_pct = SOC * 100;
else
    SOC_pct = SOC;
end

% Interpolate PV and load inputs onto the simulation output times
t_pv = pv_ts.Time(:);
P_pv_input = squeeze(pv_ts.Data);
P_pv_input = P_pv_input(:);

t_load = load_ts.Time(:);
P_load_input = squeeze(load_ts.Data);
P_load_input = P_load_input(:);

% Interpolate inputs and hold the final sample if needed
P_pv = interp1(t_pv, P_pv_input, t, 'previous', 'extrap');
P_load = interp1(t_load, P_load_input, t, 'previous', 'extrap');

% Check for missing or invalid values
fprintf('PV NaN values: %d\n', sum(isnan(P_pv)));
fprintf('Load NaN values: %d\n', sum(isnan(P_load)));
fprintf('Simulation time range: %.4f to %.4f hours\n', ...
    min(t), max(t));
fprintf('PV input time range: %.4f to %.4f hours\n', ...
    min(t_pv), max(t_pv));
fprintf('Load input time range: %.4f to %.4f hours\n', ...
    min(t_load), max(t_load));
% Remove any accidental column-vector shape inconsistencies
P_pv = P_pv(:);
P_load = P_load(:);

assert(numel(t) == numel(SOC) && numel(t) == numel(P_batt), ...
    'Simulation output signals must have matching lengths.');

assert(all(isfinite(t)) && all(diff(t) > 0), ...
    'Simulation timestamps must be finite and increasing.');

assert(all(isfinite(P_pv)) && all(isfinite(P_load)), ...
    'PV and load data must be finite over the simulation interval.');

assert(all(isfinite(P_grid_import)) && ...
       all(isfinite(P_grid_export)), ...
    'Grid power data must be finite.');

% Make an output folder
if ~exist('PV_BESS_Plots', 'dir')
    mkdir('PV_BESS_Plots');
end

outFolder = 'PV_BESS_Plots';

% Common styling
set(groot, 'defaultFigureColor', 'w');
set(groot, 'defaultAxesFontSize', 11);
set(groot, 'defaultLineLineWidth', 1.5);

%% 2. Weekly SOC profile

fig = figure('Name', 'Weekly SOC');
plot(t, SOC_pct, 'LineWidth', 1.8);
hold on;
yline(20, '--r', 'Minimum SOC (20%)');
yline(95, '--g', 'Maximum SOC (95%)');

xlabel('Time (hours)');
ylabel('State of Charge (%)');
title('Battery State of Charge: 10-16 November 2025');
xlim([0 168]);
ylim([0 100]);
grid on;
box on;

exportgraphics(fig, fullfile(outFolder, ...
    '01_Weekly_SOC.png'), 'Resolution', 300);

%% 3. Weekly battery charging and discharging

fig = figure('Name', 'Battery Power');
plot(t, P_batt);
hold on;
yline(0, '-k');

xlabel('Time (hours)');
ylabel('Battery Power (kW)');
title('Battery Charging and Discharging');
legend('Battery Power', 'Zero Power', 'Location', 'best');
xlim([0 168]);
grid on;
box on;

exportgraphics(fig, fullfile(outFolder, ...
    '02_Battery_Power.png'), 'Resolution', 300);

%% 4. Weekly grid import and export

fig = figure('Name', 'Grid Power');
plot(t, P_grid_import, 'DisplayName', 'Grid Import');
hold on;
plot(t, P_grid_export, 'DisplayName', 'Grid Export');

xlabel('Time (hours)');
ylabel('Power (kW)');
title('Grid Import and Export');
legend('Location', 'best');
xlim([0 168]);
grid on;
box on;

exportgraphics(fig, fullfile(outFolder, ...
    '03_Grid_Import_Export.png'), 'Resolution', 300);

%% 5. One-day power balance
% Change selectedDay to any integer from 1 to 7.
% Day 1 = 10 November; Day 2 = 11 November, etc.

selectedDay = 2;

startHour = (selectedDay - 1) * 24;
endHour = selectedDay * 24;

idx = t >= startHour & t < endHour;

fig = figure('Name', 'Daily Power Balance');
plot(t(idx) - startHour, P_pv(idx), ...
    'DisplayName', 'PV Generation');
hold on;
plot(t(idx) - startHour, P_load(idx), ...
    'DisplayName', 'Household Load');
plot(t(idx) - startHour, P_batt(idx), ...
    'DisplayName', 'Battery Power');

yline(0, '-k');
xlabel('Time of Day (hours)');
ylabel('Power (kW)');
title(sprintf('PV, Household Load and Battery Power - Day %d', ...
    selectedDay));
legend('Location', 'best');
xlim([0 24]);
xticks(0:3:24);
grid on;
box on;

exportgraphics(fig, fullfile(outFolder, ...
    '04_Daily_Power_Balance.png'), 'Resolution', 300);

%% 6. Weekly energy balance
% Integrate power over time to obtain energy in kWh.
% Battery charge and discharge are reported separately.

E_pv = trapz(t, P_pv);
E_load = trapz(t, P_load);
E_grid_import = trapz(t, P_grid_import);
E_grid_export = trapz(t, P_grid_export);
E_batt_charge = trapz(t, max(P_batt, 0));
E_batt_discharge = trapz(t, max(-P_batt, 0));

energyNames = { ...
    'PV Generation', ...
    'Household Load', ...
    'Grid Import', ...
    'Grid Export', ...
    'Battery Charge', ...
    'Battery Discharge'};

energyValues = [ ...
    E_pv, E_load, E_grid_import, E_grid_export, ...
    E_batt_charge, E_batt_discharge];

fig = figure('Name', 'Weekly Energy Summary');
bar(energyValues);
xticks(1:numel(energyNames));
xticklabels(energyNames);
xtickangle(25);
ylabel('Energy (kWh)');
title('Weekly Energy Summary: 10-16 November 2025');
grid on;
box on;

exportgraphics(fig, fullfile(outFolder, ...
    '05_Weekly_Energy_Summary.png'), 'Resolution', 300);

%% 7. Battery SOC distribution

fig = figure('Name', 'SOC Distribution');
histogram(SOC_pct, 20);
hold on;
xline(20, '--r', 'Minimum');
xline(95, '--g', 'Maximum');

xlabel('State of Charge (%)');
ylabel('Number of Simulation Samples');
title('Distribution of Battery State of Charge');
grid on;
box on;

exportgraphics(fig, fullfile(outFolder, ...
    '06_SOC_Distribution.png'), 'Resolution', 300);

%% 8. Daily grid import and export energy

dailyImport = zeros(7,1);
dailyExport = zeros(7,1);

for d = 1:7
    dayStart = (d-1)*24;
    dayEnd = d*24;

    % Include each day's starting timestamp.
    % Exclude the following midnight to avoid double counting.
    dayIdx = t >= dayStart & t < dayEnd;

    if nnz(dayIdx) >= 2
        dailyImport(d) = trapz(t(dayIdx), ...
            P_grid_import(dayIdx));

        dailyExport(d) = trapz(t(dayIdx), ...
            P_grid_export(dayIdx));
    end
end

fig = figure('Name', 'Daily Grid Energy');
bar(1:7, [dailyImport dailyExport], 'grouped');

xlabel('Day of Week');
ylabel('Energy (kWh)');
title('Daily Grid Import and Export');
xticks(1:7);
xticklabels({'Mon 10','Tue 11','Wed 12', ...
             'Thu 13','Fri 14','Sat 15','Sun 16'});
legend('Grid Import', 'Grid Export', 'Location', 'best');
grid on;
box on;

exportgraphics(fig, fullfile(outFolder, ...
    '07_Daily_Grid_Energy.png'), 'Resolution', 300);

%% 9. Solar self-consumption and self-sufficiency

% These definitions assume the controller charges only from PV surplus.
% Verify the energy balance before using these metrics in a report.

if E_pv > 0
    solarSelfConsumption = ...
        100 * (E_pv - E_grid_export) / E_pv;
else
    solarSelfConsumption = NaN;
end

if E_load > 0
    loadSelfSufficiency = ...
        100 * (E_load - E_grid_import) / E_load;
else
    loadSelfSufficiency = NaN;
end

fprintf('\n===== WEEKLY PV-BESS RESULTS =====\n');
fprintf('PV generation:             %.2f kWh\n', E_pv);
fprintf('Household demand:          %.2f kWh\n', E_load);
fprintf('Grid import:               %.2f kWh\n', E_grid_import);
fprintf('Grid export:               %.2f kWh\n', E_grid_export);
fprintf('Battery charge:            %.2f kWh\n', E_batt_charge);
fprintf('Battery discharge:         %.2f kWh\n', E_batt_discharge);
fprintf('Solar self-consumption:    %.1f %%\n', ...
    solarSelfConsumption);
fprintf('Load self-sufficiency:     %.1f %%\n', ...
    loadSelfSufficiency);
fprintf('Minimum SOC:               %.1f %%\n', min(SOC_pct));
fprintf('Maximum SOC:               %.1f %%\n', max(SOC_pct));
fprintf('=================================\n');

% Save summary values for further analysis
summaryTable = table(energyNames(:), energyValues(:), ...
    'VariableNames', {'Metric', 'Energy_kWh'});

writetable(summaryTable, fullfile(outFolder, ...
    'Weekly_Energy_Summary.csv'));

fprintf('\nAll plots saved in folder: %s\n', outFolder);
