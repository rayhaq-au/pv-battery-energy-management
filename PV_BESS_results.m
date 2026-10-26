
%% PV-BESS EMS: Results and Visualization
% Run after simulating PV_BESS_EMS.slx

%% 1. Extract simulation data
t_soc = out.SOC.Time;
soc = squeeze(out.SOC.Data);

t_batt = out.P_batt.Time;
p_batt = squeeze(out.P_batt.Data);

p_import = squeeze(out.P_grid_import.Data);
p_export = squeeze(out.P_grid_export.Data);

% Convert SOC to percentage
soc_percent = 100 * soc;

%% 2. Plot battery state of charge
figure;
plot(t_soc, soc_percent, 'LineWidth', 2);
hold on;
yline(20, '--r', 'Minimum SOC');
yline(95, '--g', 'Maximum SOC');
grid on;
xlabel('Time (hours)');
ylabel('SOC (%)');
title('Battery State of Charge');
ylim([0 100]);

%% 3. Plot battery charging and discharging
figure;
stairs(t_batt, p_batt, 'LineWidth', 1.8);
yline(0, 'k-');
grid on;
xlabel('Time (hours)');
ylabel('Battery Power (kW)');
title('Battery Charging and Discharging');

%% 4. Plot grid import and export
figure;
plot(t_batt, p_import, 'LineWidth', 1.8);
hold on;
plot(t_batt, p_export, 'LineWidth', 1.8);
grid on;
xlabel('Time (hours)');
ylabel('Power (kW)');
title('Grid Import and Export');
legend('Grid Import', 'Grid Export', 'Location', 'best');

%% 5. Display key results
fprintf('\n--- PV-BESS EMS Results ---\n');
fprintf('Minimum simulated SOC: %.2f%%\n', min(soc_percent));
fprintf('Maximum simulated SOC: %.2f%%\n', max(soc_percent));
fprintf('Maximum charging power: %.2f kW\n', max(p_batt));
fprintf('Maximum discharging power: %.2f kW\n', -min(p_batt));
fprintf('Peak grid import: %.2f kW\n', max(p_import));
fprintf('Peak grid export: %.2f kW\n', max(p_export));
