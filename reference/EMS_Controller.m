function [P_batt, P_grid_import, P_grid_export, SOC_next] = ...
    fcn(P_pv, P_load, SOC)
%#codegen

% Battery parameters
E_batt = 10;             % Battery capacity (kWh)
P_charge_max = 3;        % Maximum charging power (kW)
P_discharge_max = 3;     % Maximum discharging power (kW)
SOC_min = 0.20;          % Minimum state of charge
SOC_max = 0.95;          % Maximum state of charge
eta = 0.95;              % Battery efficiency
dt = 0.25;               % Simulation time step (hour)

% Calculate net PV power
P_net = P_pv - P_load;

% Initialize outputs
P_batt = 0;
P_grid_import = 0;
P_grid_export = 0;
SOC_next = SOC;

if P_net >= 0

    % PV generation exceeds demand
    surplus = P_net;

    % Maximum power the battery can accept
    available_capacity_power = ...
        max(0, (SOC_max - SOC) * E_batt / (eta * dt));

    % Charge battery using available PV surplus
    P_charge = min(surplus, P_charge_max);
    P_charge = min(P_charge, available_capacity_power);

    % Positive battery power means charging
    P_batt = P_charge;

    % Export any remaining surplus
    P_grid_export = max(0, surplus - P_charge);

    % Update battery SOC
    SOC_next = SOC + eta * P_charge * dt / E_batt;

else

    % Demand exceeds PV generation
    deficit = -P_net;

    % Maximum power available from the battery
    available_discharge_power = ...
        max(0, (SOC - SOC_min) * E_batt * eta / dt);

    % Discharge battery to cover the deficit
    P_discharge = min(deficit, P_discharge_max);
    P_discharge = min(P_discharge, available_discharge_power);

    % Negative battery power means discharging
    P_batt = -P_discharge;

    % Import any remaining deficit from the grid
    P_grid_import = max(0, deficit - P_discharge);

    % Update battery SOC
    SOC_next = SOC - P_discharge * dt / (eta * E_batt);

end

% Enforce SOC limits
SOC_next = min(max(SOC_next, SOC_min), SOC_max);

end


