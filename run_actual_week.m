%% RUN PV-BATTERY WEEKLY CASE
% Repository helper; original study files are preserved alongside this script.
% Run in MATLAB's Command Window (base workspace), not inside a function.
% The preparation script clears variables, closes figures, and recreates
% PV_BESS_Actual_Week.mat and PV_Production_Selected_Week.xlsx in this copy.
cd(fileparts(mfilename('fullpath')));
PV_BESS_Actual_Week

% Explicit starting conditions. The original setup script specifies 50%.
% Historical plots appear to start at 25%; use 0.25 to investigate that case.
SOC_initial = 0.50;

% Assert alignment before connecting the input profiles.
assert(numel(load_kW) == numel(P_pv_kW), 'Input lengths differ.');
assert(all(isfinite(load_kW)) && all(isfinite(P_pv_kW)), ...
    'Input powers must be finite.');
assert(all(abs(diff(t_h) - 0.25) < 1e-9), ...
    'Expected 15-minute input intervals.');

load_system(fullfile(pwd, 'PV_BESS_EMS.slx'));
% One simulation time unit represents one hour in this power/energy model.
% Settings apply in memory; the saved model file is not overwritten.
set_param('PV_BESS_EMS', 'SolverType', 'Fixed-step', ...
    'Solver', 'FixedStepDiscrete', 'FixedStep', '0.25', 'StopTime', '168');
set_param('PV_BESS_EMS/Solar PV Generation', 'SampleTime', '0.25', ...
    'Interpolate', 'off', 'OutputAfterFinalValue', 'Holding final value');
set_param('PV_BESS_EMS/Household Load', 'SampleTime', '0.25', ...
    'Interpolate', 'off', 'OutputAfterFinalValue', 'Holding final value');

out = sim('PV_BESS_EMS');
PV_BESS_results
if ~exist('results', 'dir')
    mkdir('results');
end
% Save complete inputs/results separately. The original preparation script's
% final MAT save contains PV inputs only.
save(fullfile('results', 'PV_BESS_weekly_run.mat'), ...
    'out', 'pv_ts', 'load_ts', 'P_pv_kW', 'load_kW', 't_h', 'dt', ...
    'SOC_initial');
fprintf('Saved results/PV_BESS_weekly_run.mat\n');
% Optional: PV_BESS_Portfolio_Plots (overwrites the historical plot snapshots).
