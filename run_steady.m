function [simOut, metrics] = run_steady(varargin)
%RUN_STEADY Execute steady-state simulation for space lithium He-Xe Brayton model.
%   [simOut, metrics] = run_steady('StopTime', 500, 'Plot', false)
%
%   Name-Value Arguments:
%       'StopTime' - Simulation duration in seconds (default: 500)
%       'Plot'     - Boolean flag to generate summary figures (default: false)
%       'Model'    - Simulink model name (default: 'final_steady_24a')
%
%   Outputs:
%       simOut  - Simulink.SimulationOutput object containing all logged signals
%       metrics - Struct with final steady-state indicators and paper comparisons

    p = inputParser;
    addParameter(p, 'StopTime', 500, @(x) isnumeric(x) && isscalar(x) && x > 0);
    addParameter(p, 'Plot', false, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'Model', 'final_steady_24a', @ischar);
    parse(p, varargin{:});
    
    stopTime = p.Results.StopTime;
    doPlot = logical(p.Results.Plot);
    modelName = p.Results.Model;

    fprintf('=================================================================\n');
    fprintf('  Space Lithium He-Xe Brayton Cycle: Steady-State Runner\n');
    fprintf('  Target Model: %s.slx | StopTime: %.1f s\n', modelName, stopTime);
    fprintf('=================================================================\n');

    % 1. Environment initialization in base workspace
    fprintf('[1/4] Initializing environment in base workspace via start.m...\n');
    evalin('base', 'start;');
    evalin('base', 'clear ans out;'); % Clean stray variables from historical .mat files

    % 2. Model configuration check
    fprintf('[2/4] Loading model %s...\n', modelName);
    if ~bdIsLoaded(modelName)
        load_system(modelName);
    end
    cleanupModel = onCleanup(@() close_system(modelName, 0)); %#ok<NASGU>

    % Ensure stiff ODE solver
    set_param(modelName, 'Solver', 'ode15s');
    set_param(modelName, 'StopTime', num2str(stopTime));
    set_param(modelName, 'RelTol', '1e-6');
    set_param(modelName, 'AbsTol', '1e-8');

    % 3. Run simulation
    fprintf('[3/4] Running Simulink simulation (ode15s, RelTol=1e-6, AbsTol=1e-8)...\n');
    t_start = tic;
    simOut = sim(modelName, 'StopTime', num2str(stopTime));
    elapsed = toc(t_start);
    fprintf('      Simulation finished in %.2f seconds.\n', elapsed);

    % 4. Extract and calculate metrics
    fprintf('[4/4] Extracting steady-state thermodynamic indicators...\n\n');
    
    P_Rx_kW = simOut.P_sw.Data(end) / 1000;
    T_coreIn_K = simOut.V_T_coreIn.Data(end);
    T_tin_K = simOut.V_T_tin.Data(end);
    WT_kW = simOut.WT_sw.Data(end) / 1000;
    Wc_kW = simOut.Wc_sw.Data(end) / 1000;
    Wnet_kW = WT_kW - Wc_kW;
    eta_th_pct = (Wnet_kW / P_Rx_kW) * 100;

    % Paper Table 5.2 / Table 5.4 Benchmark References
    bench_P_Rx_kW = 2664.0;
    bench_T_coreIn_K = 1443.27;
    bench_T_tin_K = 1500.0;
    bench_N_rpm = 55090.0;
    bench_Wnet_kW = 1000.0; % 1 MWe nominal
    bench_eta_pct = (bench_Wnet_kW / bench_P_Rx_kW) * 100;

    metrics = struct();
    metrics.StopTime_s = stopTime;
    metrics.ElapsedTime_s = elapsed;
    metrics.P_Rx_kW = P_Rx_kW;
    metrics.T_coreIn_K = T_coreIn_K;
    metrics.T_tin_K = T_tin_K;
    metrics.WT_kW = WT_kW;
    metrics.Wc_kW = Wc_kW;
    metrics.Wnet_kW = Wnet_kW;
    metrics.Efficiency_pct = eta_th_pct;

    % Print Comparison Table
    fprintf('| Parameter | Model Output | Paper 5.2 Benchmark | Abs Deviation | Rel Deviation |\n');
    fprintf('|---|---:|---:|---:|---:|\n');
    printRow('Reactor Thermal Power (kW)', P_Rx_kW, bench_P_Rx_kW, 'kW');
    printRow('Core Inlet Temperature (K)', T_coreIn_K, bench_T_coreIn_K, 'K');
    printRow('Turbine Inlet Temp (K)', T_tin_K, bench_T_tin_K, 'K');
    printRow('Turbine Power WT (kW)', WT_kW, NaN, 'kW');
    printRow('Compressor Power Wc (kW)', Wc_kW, NaN, 'kW');
    printRow('Net Output Power (kWe)', Wnet_kW, bench_Wnet_kW, 'kWe');
    printRow('Thermal Efficiency (%)', eta_th_pct, bench_eta_pct, '%');
    fprintf('\n');

    if doPlot
        figure('Name', 'Steady-State Response', 'Position', [100, 100, 900, 600]);
        subplot(3, 1, 1);
        plot(simOut.tout, simOut.P_sw.Data / 1000, 'b-', 'LineWidth', 1.5);
        grid on; ylabel('P_{Rx} [kW]'); title('Reactor Thermal Power');
        
        subplot(3, 1, 2);
        plot(simOut.tout, simOut.WT_sw.Data / 1000, 'r-', 'LineWidth', 1.5); hold on;
        plot(simOut.tout, simOut.Wc_sw.Data / 1000, 'b--', 'LineWidth', 1.5);
        plot(simOut.tout, (simOut.WT_sw.Data - simOut.Wc_sw.Data) / 1000, 'k-.', 'LineWidth', 1.5);
        grid on; ylabel('Power [kW]'); legend('Turbine WT', 'Compressor Wc', 'Net W_{net}');
        
        subplot(3, 1, 3);
        plot(simOut.tout, simOut.V_T_coreIn.Data, 'm-', 'LineWidth', 1.5); hold on;
        plot(simOut.tout, simOut.V_T_tin.Data, 'g--', 'LineWidth', 1.5);
        grid on; xlabel('Time [s]'); ylabel('Temperature [K]');
        legend('Core Inlet T_{coreIn}', 'Turbine Inlet T_{tin}');
    end
end

function printRow(name, val, bench, unit)
    if isnan(bench)
        fprintf('| %-28s | %10.2f %-3s | %19s | %13s | %13s |\n', ...
            name, val, unit, 'N/A', 'N/A', 'N/A');
    else
        absDev = val - bench;
        relDev = (absDev / bench) * 100;
        fprintf('| %-28s | %10.2f %-3s | %15.2f %-3s | %+10.2f %-3s | %+11.2f%% |\n', ...
            name, val, unit, bench, unit, absDev, unit, relDev);
    end
end
