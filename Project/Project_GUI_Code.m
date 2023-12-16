classdef Project_GUI_Code < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure             matlab.ui.Figure
        PLOTButton           matlab.ui.control.Button
        RESETButton          matlab.ui.control.Button
        PLAYButton           matlab.ui.control.Button
        LOADButton           matlab.ui.control.Button
        EditField_5          matlab.ui.control.EditField
        Slider_5             matlab.ui.control.Slider
        Band5fc16000HzLabel  matlab.ui.control.Label
        EditField_4          matlab.ui.control.EditField
        Slider_4             matlab.ui.control.Slider
        Band4fc4000HzLabel   matlab.ui.control.Label
        EditField_3          matlab.ui.control.EditField
        Slider_3             matlab.ui.control.Slider
        Band3fc1000HzLabel   matlab.ui.control.Label
        EditField_2          matlab.ui.control.EditField
        Slider_2             matlab.ui.control.Slider
        Band2fc250HzLabel    matlab.ui.control.Label
        EditField            matlab.ui.control.EditField
        Band1fc63HzLabel     matlab.ui.control.Label
        Slider               matlab.ui.control.Slider
        Meter                audio.ui.control.Meter
        UIAxes5              matlab.ui.control.UIAxes
        UIAxes4              matlab.ui.control.UIAxes
        UIAxes3              matlab.ui.control.UIAxes
        UIAxes2              matlab.ui.control.UIAxes
        UIAxes               matlab.ui.control.UIAxes

        % Additional properties for storing data
        audioFilePath
        audioSignal
        sampleRate
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: LOADButton
        function LOADButtonPushed(app, event)
            [file, path] = uigetfile('C:\Users\Azlaan\Music\*.*', 'Select an Audio File');

            % Check if the user canceled the file selection
            if isequal(file, 0) || isequal(path, 0)
                disp('User canceled the file selection.');
                return;
            end

            % Load the audio file
            audioFilePath = fullfile(path, file);
            [audioSignal, sampleRate] = audioread(audioFilePath);

            % Store information in app properties
            app.audioFilePath = audioFilePath;
            app.audioSignal = audioSignal;
            app.sampleRate = sampleRate;
        end

        % Button pushed function: PLOTButton
        function PLOTButtonPushed(app, event)
            % Design and apply filters here
            center_frequencies = [63, 250, 1000, 4000, 16000];
            Q = 0.73;
            desired_order = 3;
            Fs = app.sampleRate;

            % Preallocate arrays for filter coefficients
            B = cell(1, length(center_frequencies));
            A = cell(1, length(center_frequencies));
            f1 = [33.21, 131.79, 527.15, 2108.6, 8434.3];
            f2 = [119.51, 474.25, 1897.0, 7588.0, 30352.1];

            % Design Butterworth filters
            for i = 1:length(center_frequencies)
                fc = center_frequencies(i);
                [B{i}, A{i}] = butter(desired_order, [f1(i), f2(i)]/(Fs/2), 'bandpass');
            end

            % Apply filters to the input signal
            filtered_signals = cell(1, length(center_frequencies));
            for i = 1:length(center_frequencies)
                filtered_signals{i} = filter(B{i}, A{i}, app.audioSignal);
            end

            % Plot the original and filtered signals
            t = (0:length(app.audioSignal)-1) / app.sampleRate;

            plot(app.UIAxes, t, app.audioSignal);
            title(app.UIAxes, 'Original Signal');
            xlabel(app.UIAxes, 'Time (s)');
            ylabel(app.UIAxes, 'Amplitude');

            % Plot the filtered signals on separate axes
            for i = 1:length(center_frequencies)
                plot(app.UIAxes2, t, filtered_signals{i}, 'DisplayName', sprintf('Band %d', i));
                hold(app.UIAxes2, 'on');
            end

            title(app.UIAxes2, 'Filtered Signals');
            xlabel(app.UIAxes2, 'Time (s)');
            ylabel(app.UIAxes2, 'Amplitude');
            legend(app.UIAxes2, 'Location', 'northeastoutside');
            hold(app.UIAxes2, 'off');
        end

        function SliderValueChanged(app, event)
            % Get the current value of the slider
            sliderValue = app.Slider.Value;

            % Display the value in the edit field
            app.EditField.Value = num2str(sliderValue);
        end

        function Slider_2ValueChanged(app, event)
            % Get the current value of the slider
            sliderValue = app.Slider_2.Value;

            % Display the value in the edit field
            app.EditField_2.Value = num2str(sliderValue);
        end

        function Slider_3ValueChanged(app, event)
            % Get the current value of the slider
            sliderValue = app.Slider_3.Value;

            % Display the value in the edit field
            app.EditField_3.Value = num2str(sliderValue);
        end

        function Slider_4ValueChanged(app, event)
            % Get the current value of the slider
            sliderValue = app.Slider_4.Value;

            % Display the value in the edit field
            app.EditField_4.Value = num2str(sliderValue);
        end

        function Slider_5ValueChanged(app, event)
            % Get the current value of the slider
            sliderValue = app.Slider_5.Value;

            % Display the value in the edit field
            app.EditField_5.Value = num2str(sliderValue);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1137 553];
            app.UIFigure.Name = 'MATLAB App';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            title(app.UIAxes, 'Input Signal')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.AmbientLightColor = [0 0 0];
            app.UIAxes.Box = 'on';
            app.UIAxes.XGrid = 'on';
            app.UIAxes.XMinorGrid = 'on';
            app.UIAxes.YGrid = 'on';
            app.UIAxes.YMinorGrid = 'on';
            app.UIAxes.Position = [26 299 300 197];

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.UIFigure);
            title(app.UIAxes2, 'Output Signal')
            xlabel(app.UIAxes2, 'X')
            ylabel(app.UIAxes2, 'Y')
            zlabel(app.UIAxes2, 'Z')
            app.UIAxes2.Box = 'on';
            app.UIAxes2.XGrid = 'on';
            app.UIAxes2.XMinorGrid = 'on';
            app.UIAxes2.YGrid = 'on';
            app.UIAxes2.YMinorGrid = 'on';
            app.UIAxes2.Position = [349 289 292 219];

            % Create UIAxes3
            app.UIAxes3 = uiaxes(app.UIFigure);
            title(app.UIAxes3, 'Input Spectrum')
            xlabel(app.UIAxes3, 'X')
            ylabel(app.UIAxes3, 'Y')
            zlabel(app.UIAxes3, 'Z')
            app.UIAxes3.PlotBoxAspectRatio = [2.69491525423729 1 1];
            app.UIAxes3.Box = 'on';
            app.UIAxes3.XGrid = 'on';
            app.UIAxes3.XMinorGrid = 'on';
            app.UIAxes3.YGrid = 'on';
            app.UIAxes3.YMinorGrid = 'on';
            app.UIAxes3.Position = [20 6 313 265];

            % Create UIAxes4
            app.UIAxes4 = uiaxes(app.UIFigure);
            title(app.UIAxes4, 'Output Spectrum')
            xlabel(app.UIAxes4, 'X')
            ylabel(app.UIAxes4, 'Y')
            zlabel(app.UIAxes4, 'Z')
            app.UIAxes4.PlotBoxAspectRatio = [2.69491525423729 1 1];
            app.UIAxes4.Box = 'on';
            app.UIAxes4.XGrid = 'on';
            app.UIAxes4.XMinorGrid = 'on';
            app.UIAxes4.YGrid = 'on';
            app.UIAxes4.YMinorGrid = 'on';
            app.UIAxes4.Position = [359 1 292 276];

            % Create UIAxes5
            app.UIAxes5 = uiaxes(app.UIFigure);
            title(app.UIAxes5, 'Characteristic Frequency')
            xlabel(app.UIAxes5, 'X')
            ylabel(app.UIAxes5, 'Y')
            zlabel(app.UIAxes5, 'Z')
            app.UIAxes5.Box = 'on';
            app.UIAxes5.XGrid = 'on';
            app.UIAxes5.XMinorGrid = 'on';
            app.UIAxes5.YGrid = 'on';
            app.UIAxes5.YMinorGrid = 'on';
            app.UIAxes5.Position = [682 64 365 189];

            % Create Meter
            app.Meter = uiaudiometer(app.UIFigure);
            app.Meter.Position = [1056 64 69 190];

            % Create Slider
            app.Slider = uislider(app.UIFigure);
            app.Slider.Limits = [-12 12];
            app.Slider.MajorTickLabels = {'-12', '-9', '-6', '-3', '0', '3', '6', '9', '12'};
            app.Slider.Orientation = 'vertical';
            app.Slider.ValueChangedFcn = createCallbackFcn(app, @SliderValueChanged, true);
            app.Slider.MinorTicks = [-12 -11 -10 -9 -8 -7 -6 -5 -4 -3 -2 -1 0 1 2 3 4 5 6 7 8 9 10 11 12];
            app.Slider.Position = [696 358 3 150];

            % Create Band1fc63HzLabel
            app.Band1fc63HzLabel = uilabel(app.UIFigure);
            app.Band1fc63HzLabel.HorizontalAlignment = 'center';
            app.Band1fc63HzLabel.Position = [682 279 59 30];
            app.Band1fc63HzLabel.Text = {'Band 1 '; 'fc = 63 Hz'};

            % Create EditField
            app.EditField = uieditfield(app.UIFigure, 'text');
            app.EditField.Position = [682 321 55 22];

            % Create Band2fc250HzLabel
            app.Band2fc250HzLabel = uilabel(app.UIFigure);
            app.Band2fc250HzLabel.HorizontalAlignment = 'center';
            app.Band2fc250HzLabel.Position = [760 275 66 30];
            app.Band2fc250HzLabel.Text = {'Band 2 '; 'fc = 250 Hz'};

            % Create Slider_2
            app.Slider_2 = uislider(app.UIFigure);
            app.Slider_2.Limits = [-12 12];
            app.Slider_2.MajorTickLabels = {'-12', '-9', '-6', '-3', '0', '3', '6', '9', '12'};
            app.Slider_2.Orientation = 'vertical';
            app.Slider_2.ValueChangedFcn = createCallbackFcn(app, @Slider_2ValueChanged, true);
            app.Slider_2.MinorTicks = [-12 -11 -10 -9 -8 -7 -6 -5 -4 -3 -2 -1 0 1 2 3 4 5 6 7 8 9 10 11 12];
            app.Slider_2.Position = [772 358 3 150];

            % Create EditField_2
            app.EditField_2 = uieditfield(app.UIFigure, 'text');
            app.EditField_2.Position = [763 321 55 22];

            % Create Band3fc1000HzLabel
            app.Band3fc1000HzLabel = uilabel(app.UIFigure);
            app.Band3fc1000HzLabel.HorizontalAlignment = 'center';
            app.Band3fc1000HzLabel.Position = [837 279 73 30];
            app.Band3fc1000HzLabel.Text = {'Band 3 '; 'fc = 1000 Hz'};

            % Create Slider_3
            app.Slider_3 = uislider(app.UIFigure);
            app.Slider_3.Limits = [-12 12];
            app.Slider_3.MajorTickLabels = {'-12', '-9', '-6', '-3', '0', '3', '6', '9', '12'};
            app.Slider_3.Orientation = 'vertical';
            app.Slider_3.MinorTicks = [-12 -11 -10 -9 -8 -7 -6 -5 -4 -3 -2 -1 0 1 2 3 4 5 6 7 8 9 10 11 12];
            app.Slider_3.Position = [853 357 3 150];

            % Create EditField_3
            app.EditField_3 = uieditfield(app.UIFigure, 'text');
            app.EditField_3.Position = [844 321 55 22];

            % Create Band4fc4000HzLabel
            app.Band4fc4000HzLabel = uilabel(app.UIFigure);
            app.Band4fc4000HzLabel.HorizontalAlignment = 'center';
            app.Band4fc4000HzLabel.Position = [927 275 69 30];
            app.Band4fc4000HzLabel.Text = {'Band 4 '; 'fc = 4000Hz'};

            % Create Slider_4
            app.Slider_4 = uislider(app.UIFigure);
            app.Slider_4.Limits = [-12 12];
            app.Slider_4.MajorTickLabels = {'-12', '-9', '-6', '-3', '0', '3', '6', '9', '12'};
            app.Slider_4.Orientation = 'vertical';
            app.Slider_4.MinorTicks = [-12 -11 -10 -9 -8 -7 -6 -5 -4 -3 -2 -1 0 1 2 3 4 5 6 7 8 9 10 11 12];
            app.Slider_4.Position = [937 356 3 150];

            % Create EditField_4
            app.EditField_4 = uieditfield(app.UIFigure, 'text');
            app.EditField_4.Position = [932 321 55 22];

            % Create Band5fc16000HzLabel
            app.Band5fc16000HzLabel = uilabel(app.UIFigure);
            app.Band5fc16000HzLabel.HorizontalAlignment = 'center';
            app.Band5fc16000HzLabel.Position = [1017 279 79 30];
            app.Band5fc16000HzLabel.Text = {'Band 5 '; 'fc = 16000 Hz'};

            % Create Slider_5
            app.Slider_5 = uislider(app.UIFigure);
            app.Slider_5.Limits = [-12 12];
            app.Slider_5.MajorTickLabels = {'-12', '-9', '-6', '-3', '0', '3', '6', '9', '12'};
            app.Slider_5.Orientation = 'vertical';
            app.Slider_5.MinorTicks = [-12 -11 -10 -9 -8 -7 -6 -5 -4 -3 -2 -1 0 1 2 3 4 5 6 7 8 9 10 11 12];
            app.Slider_5.Position = [1029 357 3 150];

            % Create EditField_5
            app.EditField_5 = uieditfield(app.UIFigure, 'text');
            app.EditField_5.Position = [1029 321 55 22];

            % Create LOADButton
            app.LOADButton = uibutton(app.UIFigure, 'push');
            app.LOADButton.ButtonPushedFcn = createCallbackFcn(app, @LOADButtonPushed, true);
            app.LOADButton.BackgroundColor = [0 0.4471 0.7412];
            app.LOADButton.FontColor = [1 1 1];
            app.LOADButton.Position = [667 10 107 41];
            app.LOADButton.Text = 'LOAD';

            % Create PLAYButton
            app.PLAYButton = uibutton(app.UIFigure, 'push');
            app.PLAYButton.BackgroundColor = [0 0.4471 0.7412];
            app.PLAYButton.FontColor = [1 1 1];
            app.PLAYButton.Position = [787 10 92 41];
            app.PLAYButton.Text = 'PLAY';

            % Create RESETButton
            app.RESETButton = uibutton(app.UIFigure, 'push');
            app.RESETButton.BackgroundColor = [0 0.4471 0.7412];
            app.RESETButton.FontColor = [1 1 1];
            app.RESETButton.Position = [888 10 107 41];
            app.RESETButton.Text = 'RESET';

            % Create PLOTButton
            app.PLOTButton = uibutton(app.UIFigure, 'push');
            app.PLOTButton.ButtonPushedFcn = createCallbackFcn(app, @PLOTButtonPushed, true);
            app.PLOTButton.BackgroundColor = [0 0.4471 0.7412];
            app.PLOTButton.FontColor = [1 1 1];
            app.PLOTButton.Position = [1002 10 107 41];
            app.PLOTButton.Text = 'PLOT';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Project_GUI_Code

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end