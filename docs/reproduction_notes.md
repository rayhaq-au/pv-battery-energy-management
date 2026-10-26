# Reproduction and interpretation notes

## Archived files and preparation

Original MATLAB scripts, model, workbooks, MAT file and plot snapshots are preserved byte-for-byte from the author's folder. Generated `slprj/` and `.slxc` caches are excluded. The added runner and documentation are separate additions. No MATLAB simulation was rerun during packaging.

## Time conventions

The model uses hours as its numerical time unit: kW multiplied by hours yields kWh. The embedded controller and Unit Delay both use 0.25 h. The daily setup declares 1 h and provides 25 hourly points. The saved model stop time is 168, with automatic variable-step settings. The new weekly helper explicitly applies fixed discrete 0.25-hour execution and zero-order-held source inputs in memory.

A 672-point input covers timestamps from 0 to 167.75 h. Representing all 672 intervals requires a defined final interval through 168 h. The helper holds the last sample for that interval; it does not create a new measurement.

## Initialization and parameters

`PV_BESS_Actual_Week.m` begins with `clear`, so it removes parameters established by running the daily setup beforehand. It does not define `SOC_initial`, which the delay needs. The new helper defines it after preparation. Its 50% default follows `PV_BESS_setup.m`; historical figures appear to start near 25%. These different initial stored energies affect comparisons.

Controller constants are embedded separately from workspace setup parameters. Keep both consistent when exploring capacity, power or efficiency changes. `reference/EMS_Controller.m` is an extracted source snapshot; editing it alone does not change the embedded MATLAB Function block.

## Saved MAT snapshot

The weekly preparation script saves `PV_BESS_Actual_Week.mat` twice. The final save includes `weekData`, `t_h`, `dt`, `P_pv_kW` and `pv_ts`, but omits `load_kW` and `load_ts`. The saved file therefore does not by itself restore the whole weekly simulation input. The full annual workbook and load workbook are needed by the original import script. The helper saves full inputs and outputs separately after simulation.

Numeric arrays in the archived MAT file were inspected without MATLAB. MATLAB-specific table/timeseries objects were identified but not fully reconstructed outside MATLAB.

## Input data and alignment

The source workbook contains five production-power channels and daily-yield channels. The script sums the five power columns and assumes watts. Do not treat the daily-energy columns as power or infer units from filenames.

The selected week has 672 rows. The household table also has 672 rows, but a row-count match alone does not prove timestamp alignment. The script selects load by position rather than joining actual timestamps. Verify full timestamp agreement when substituting data.

Nonzero nighttime PV values and long linear ramps exist in the supplied source values. Their origin could involve upstream preparation, missing-data interpolation, channel definitions or measurement behavior; it is not established from these files alone. Zero-order holding within Simulink cannot fix anomalies already present in source inputs.

The household workbook describes itself as a measured-load template and includes quality/activity labels. These labels do not independently verify measurements. Formula-result caches are blank in parts of the workbook; MATLAB's script reads the numeric active-power column directly, not those cached summary formulas.

## Results and integration

Positive battery power means charging, unlike the discharge-positive convention in some other powertrain projects. The current SOC logging label mentions percent, but the signal is a fraction and the plotting script multiplies by 100.

`PV_BESS_Portfolio_Plots.m` reconstructs inputs with previous-sample interpolation and computes energy with `trapz`. That may not match the source blocks' interpolation in the archived model. For discrete interval-average power, interval-weighted sums with explicitly defined boundaries are preferable for reconciliation.

The daily integration excludes the following midnight before calling `trapz`, so a day's final interval is not fully represented. Daily sums therefore need not reconcile exactly to weekly totals. A zero-order-held input should be integrated over complete intervals with power at the interval start.

Before reporting self-consumption, self-sufficiency or battery benefits, check input/output power balance, battery efficiency losses, actual timestamps, endpoint treatment, and initial/final stored energy. The archived summary contains energy totals rather than a no-battery or tariff comparison.
