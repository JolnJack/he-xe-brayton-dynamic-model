function [simOut, result] = run_dynamic(varargin)
%RUN_DYNAMIC Execute dynamic transient simulation and plot system responses.
%   [simOut, result] = run_dynamic('StopTime', 500, 'SavePlot', true)
%
%   Name-Value Arguments:
%       'StopTime'  - Simulation duration in seconds (default: 500)
%       'SavePlot'  - Boolean flag to save figure to disk (default: true)
%       'OutputDir' - Directory to save generated plot (default: 'figures')
%       'Model'     - Simulink model name (default: 'final_steady_24a')
%
%   Outputs:
%       simOut - Simulink.SimulationOutput object containing all logged signals
%       result - Summary struct with trajectory statistics

    p = inputParser;
    addParameter(p, 'StopTime', 500, @(x) isnumeric(x) && isscalar(x) && x > 0);
    addParameter(p, 'SavePlot', true, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'OutputDir', 'figures', @ischar);
    addParameter(p, 'Model', 'final_steady_24a', @ischar);
    parse(p, varargin{:});

    stopTime = p.Results.StopTime;
    savePlot = logical(p.Results.SavePlot);
    outputDir = p.Results.OutputDir;
    modelName = p.Results.Model;

    fprintf('=================================================================\n');
    fprintf('  Space Lithium He-Xe Brayton Cycle: Dynamic Transient Runner\n');
    fprintf('  Target Model: %s.slx | StopTime: %.1f s\n', modelName, stopTime);
    fprintf('=================================================================\n');

    % 1. Run simulation via run_steady
    [simOut, metrics] = run_steady('StopTime', stopTime, 'Plot', false, 'Model', modelName);

    % 2. Plot multi-panel system trajectory
    fprintf('[Dynamic Analysis] Rendering transient curves...\n');
    fig = figure('Name', 'System Dynamic Response', ...
                 'Units', 'pixels', 'Position', [100, 100, 1000, 750], ...
                 'Visible', 'off');

    t = simOut.tout;
    P_Rx = simOut.P_sw.Data / 1000;      % kW
    WT = simOut.WT_sw.Data / 1000;        % kW
    Wc = simOut.Wc_sw.Data / 1000;        % kW
    Wnet = WT - Wc;                       % kW
    T_coreIn = simOut.V_T_coreIn.Data;    % K
    T_tin = simOut.V_T_tin.Data;          % K

    % Panel 1: Reactor Power
    subplot(3, 1, 1);
    plot(t, P_Rx, 'b-', 'LineWidth', 1.8);
    yline(2664.0, 'r--', 'Paper Table 5.2 Nominal (2664 kW)', 'LineWidth', 1.2);
    grid on; box on;
    ylabel('P_{Rx} [kW]', 'FontSize', 11, 'FontWeight', 'bold');
    title('Reactor Thermal Power Trajectory', 'FontSize', 12, 'FontWeight', 'bold');
    legend('Simulated P_{Rx}', 'Paper Target', 'Location', 'best');

    % Panel 2: Turbomachinery Powers
    subplot(3, 1, 2);
    plot(t, WT, 'r-', 'LineWidth', 1.6); hold on;
    plot(t, Wc, 'b--', 'LineWidth', 1.6);
    plot(t, Wnet, 'k-.', 'LineWidth', 1.6);
    yline(1000.0, 'g:', '1.0 MWe Target', 'LineWidth', 1.2);
    grid on; box on;
    ylabel('Power [kW]', 'FontSize', 11, 'FontWeight', 'bold');
    title('TAC Turbomachinery Powers', 'FontSize', 12, 'FontWeight', 'bold');
    legend('Turbine W_T', 'Compressor W_c', 'Net Electric W_{net}', 'Location', 'best');

    % Panel 3: Key Temperatures
    subplot(3, 1, 3);
    plot(t, T_tin, 'r-', 'LineWidth', 1.6); hold on;
    plot(t, T_coreIn, 'm--', 'LineWidth', 1.6);
    yline(1500.0, 'r:', 'TIT Target (1500 K)', 'LineWidth', 1.0);
    yline(1443.27, 'm:', 'Core Inlet Target (1443.3 K)', 'LineWidth', 1.0);
    grid on; box on;
    xlabel('Time [s]', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('Temperature [K]', 'FontSize', 11, 'FontWeight', 'bold');
    title('Loop Temperatures (Turbine Inlet & Core Inlet)', 'FontSize', 12, 'FontWeight', 'bold');
    legend('T_{tin} (Turbine Inlet)', 'T_{coreIn} (Core Inlet)', 'Location', 'best');

    % 3. Save figure
    if savePlot
        if ~isfolder(outputDir)
            mkdir(outputDir);
        end
        plotFile = fullfile(outputDir, 'system_dynamic_response.png');
        saveas(fig, plotFile);
        fprintf('      Dynamic response curve saved to: %s\n', plotFile);
    end
    close(fig);

    result = struct();
    result.metrics = metrics;
    result.tFinal_s = t(end);
    result.P_Rx_final_kW = P_Rx(end);
    result.Wnet_final_kW = Wnet(end);
    result.T_tin_final_K = T_tin(end);
    result.T_coreIn_final_K = T_coreIn(end);

    fprintf('=================================================================\n');
    fprintf('  Dynamic run complete. Final P_Rx: %.2f kW, W_net: %.2f kW\n', ...
            result.P_Rx_final_kW, result.Wnet_final_kW);
    fprintf('=================================================================\n');
end
