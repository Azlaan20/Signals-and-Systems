classdef app1gui < matlab.apps.AppBase
    properties (Access = public)
        UIFigure    matlab.ui.Figure
        Image   matlab.ui.control.image
        Slider_1 matlab.ui.control.Slider
        Slider_2 matlab.ui.control.Slider
        Slider_3 matlab.ui.control.Slider
        Slider_4 matlab.ui.control.Slider
        Slider_5 matlab.ui.control.Slider

        UIAxes matlab.ui.control.UIAxes
        TrackDropDown matlab.ui.control.DropDown
        PlayButton matlab.ui.control.Button
        StopButton matlab.ui.control.Button
        DropDown matlab.ui.control.DropDown
        RecButton matlab.ui.control.Button
        Lamp matlab.ui.control.Lamp
        Switch matlab.ui.control.RockerSwitch
        Knob matlab.ui.control.Knob
        Image2 matlab.ui.control.Image
    end

    properties (Access = private)

        isRec = 0
        isPlay = 0;
        fs = 44100;
        fk = [63,70.8,250,282,1000,1120,4000,4470,16000,17800];
        wn = 2 * pi * [63,66.9,70.8,75,250,266,282,299,1000,1060,1120,1190,4000,4220,4470,4730,16000,16800,17800,18800];
        fg = [63,250,1000,4000,16000];
        isStop = 0;
    end

    methods (Access = private)

        function a = den(app,k,Fs)

            thetak = 2*pi*app.fk(k)/Fs;
            if k>1 && k<11

                dthetak = (2*pi*app.fk(k+1)/Fs-2*pi*app.fk(k-1)/Fs)/2;
            elseif k == 1
                dthetak = 2*pi*app.fk(2)/Fs-2*pi*app.fk(1)/Fs;
            else
                dthetak = 2*pi*app.fk(11)/Fs - 2*pi*app*fk(10)/Fs;
            end
            pk = exp(-dthetak/2);
            a = [1 -2*pk*cos(thetak) pk^2];
        end

        function Mrplus = Mrp(app,Fs)
            M = zeros(20,21);
            M(:,22) = ones(20,1);
            sqW = Weight(app, app.Slider_1.Value,app.Slider_2.Value,app.Slider_3.Value,app.Slider_4.Value,app.Slider_5.Value);

            for n = 1:20
                for k = 1:11
                    M(n, 2*k-1) = 1/(den(app,k,Fs)*[1; exp(-app,wn(n)/Fs*1i);exp(-2*app.wn(n)/Fs*1i)]);
                    M(n,2*k) = exp(-app.wn(n)/Fs*1i)/(den(app,k,Fs)*[1;exp(-app.wn(n)/Fs*1i);exp(-2*app.wn(n)/Fs*1i)]);
                end
                M(n,:) = M(n,:)*sqW(n);
            end

            Mr = [real(M); imag(M)];
            Mrplus = (transpose(Mr)*Mr)\transpose(Mr);
        end

        function htr = target(app,G1,G2,G3,G4,G5)
            y = 10.^(1/20*pchip([-flip(app.fg) app.fg],[flip([G1,G2,G3,G4,G5]) [G1,G2,G3,G4,G5]], linspace(-app.fs/2,app.fs/2,2^16)))';
            phase = unwrap(imag(-hilbert(log(y))));
            phase = phase(32769:64124);

            i = 1;
            fi = zeros(1,20);
            for w = app.wn/(2*pi)
                if round(w*length(phase)/21100) > length(phase)
                    fi(i) = phase(length(phase));
                else
                    fi(i) = phase(round(w*length(phase)/21100));
                end
                i = i + 1;
            end
            htr = [real(exp(1i*fi')); imag(exp(1i*fi'))];
        end

        function popt = num(app, htr, Mrplus)
            popt = Mrplus*htr;
        end

        function yk = filterNew(app,bWithIndex,xk1,ybuffer,xbuffer,Fs,n)
            yk = filter(bWithIndex', den(app,n,Fs), xk1,filtic(bWithIndex', den(app,n,Fs), ybuffer, xbuffer));
        end

        function sqW = Weight(app,G1,G2,G3,G4,G5)
            ht = 10.^(1/20*pchip([10 app.fg], [G1,G2,G3,G4,G5], app.wn/(2*pi)))';
            sqW1 = zeros(20,1);

            for i = 1:20
                sqW1(i) = 1/ht(i);
            end

            sqW = sqW1;
        end
    end

    methods (Access = private)
        function Start(app)
            app.Lamp.Enable = 'off';
            tracks = struct2cell(dir('*.mp3'));
            tracks = tracks(1,:);
            app.TrackDropDown.Items = tracks;
            wav = struct2cell(dir('*.wav'));
            wav = wav(1,:);

            for i = 1:length(wav)
                app.TrackDropDown.Items(i+length(tracks(1,:))) = wav(i);
            end

            if isempty(app.TrackDropDown.Items) == 1
                uialert(app.UIFigure,'You current folder does not contain any audio files', 'Info', 'Icon', 'info');
            end
        end

        function play(app,event)
            if isempty(app.TrackDropDown.Items) == 2
                uialert(app.UIFigure,'No audio file found','Error','Icon','error');
            elseif app.isRec == 1
                uialert(app.UIFigure,'Stop recording before playback of a file','Tip','Icon','warning');
            elseif strcmp(app.PlayButton.Text,'Play') && app.isPlay == 0 && app.isRec == 0
                %Acquiring Audio File
                fileReader = dsp.AudioFileReader(char(app.TrackDropDown.Value),'SamplesPerFrame',1024);
                deviceWriter = audioDeviceWriter('SampleRate',fileReader.SampleRate);

                app.PlayButton.Text = 'Pause';
                app.isPlay = 1;
                app.fs = fileReader.SampleRate;
                Fs = app.fs;

                %Initializing the delays
                xbuffer1 = 0;
                xbuffer2 = 0;
                ybuffer1 = zeros(19,3);
                ybuffer2 = zeros(19,3);

                S1 = app.Slider_1.Value;
                S2 = app.Slider_2.Value;
                S3 = app.Slider_3.Value;
                S4 = app.Slider_4.Value;
                S5 = app.Slider_5.Value;

                Mrplus = Mrp(app,Fs);

                b = num(app,target(app,S1,S2,S3,S4,S5),Mrplus);

                dF = Fs/1024;
                f = -Fs/2:dF:Fs/2-dF;

                i = 0;
                %Playback loop
                while ~isDone(fileReader)
                    xk = fileReader();

                    if length(xk(1,:)) ~=2
                        xk = [xk,xk];
                        xk1 = xk(:,1)';
                        xk2 = xk(:,2)';
                    else
                        xk1 = xk(:,1)';
                        xk2 = xk(:,2)';
                    end

                    if strcmp(app.PlayButton.Text,'Play') == 1
                        %Pause loop
                        while strcmp(app.PlayButton.Text, ' Play') == 1 && app.isStop == 0
                            pause(1);
                        end
                    end

                    pause(0);

                    %Check to see if the slider configuration is being
                    %changed
                    if app.Slider_1.Value ~= S1 || app.Slider_2 ~= S2 || app.Slider_3.Value ~= S3 || S4 ~= app.Slider_4.Value || S5 ~= app.Slider_5.Value
                        S1 = app.Slider_1.Value;
                        S2 = app.Slider_2.Value;
                        S3 = app.Slider_3.Value;
                        S4 = app.Slider_4.Value;
                        S5 = app.Slider_5.Value;

                        Mrplus = Mrp(app,Fs);
                        b = num(app,target(app,S1,S2,S3,S4,S5),Mrplus);
                    end

                    %Filtering process
                    for n = 1:11
                        if n<11
                            ykNew1(n,:) = filterNew(app,b((2*n-1):(2*n)),xk1,ybuffer1(n,:),xbuffer1,Fs,n);
                            ykNew2(n,:) = filterNew(app,b((2*n-1):(2*n)),xk2,ybuffer2(n,:),xbuffer2,Fs,n);
                        else
                            ykNew1(n,:) = xk1*b(22);
                            ykNew2(n,:) = xk2*b(22);
                        end
                    end

                    yk1 = 0;
                    yk2 = 0;

                    for n = 1:11
                        yk1 = yk1 + ykNew1(n,:);
                        yk2 = yk2 + ykNew2(n,:);
                    end

                    %Playback of frame
                    deviceWriter([0.25*yk1',0.25*yk2']);

                    %Delay updates
                    xbuffer1 = flip(xk1(length(xk1)-1:length(xk1)));
                    xbuffer2 = flip(xk2(length(xk2)-1:length(xk2)));

                    for n = 1:10
                        ybuffer1(n,:) = flip(ykNew1(n,(length(ykNew1(n,:))-2):(length(ykNew1(n,:)))));
                        ybuffer2(n,:) = flip(ykNew2(n,(length(ykNew2(n,:))-2):(length(ykNew2(n,:)))));
                    end

                    %FFT Plot update if allowed
                    if mod(i, 51 - round(app.Knob.Value)) == 0 && strcmp(app.Switch.Value,'On') == 1
                        z = fftshift(fft(yk1));
                        area(app.UIAxes,f,abs(z)/1024)
                        drawnow limitrate;
                    end

                    if app.isStop == 1
                        release(fileReader);
                        release(deviceWriter);
                        app.PlayButton.Text = 'Play';
                        app.isPlay = 0;
                        app.isStop = 0;
                    end

                    i = i+1;

                end

                release(fileReader);
                release(deviceWriter);

                app.PlayButton.Text = 'Play';
                app.isPlay = 0;

            elseif strcmp(app.PlayButton.Text,'Play') && app.isPlay == 1
                app.PlayButton.Text = 'Pause';
            elseif app.isStop == 1
                release(fileReader);
                release(deviceWriter);
                app.PlayButton.Text = 'Play';
                app.isPlay = 0;
                app.isStop = 0;
            else
                app.PlayButton.Text = 'Play';
            end
        end

        %Button pushed function: RecButton
        function Rec(app, event)
            if app.isPlay == 1
                uialert(app.UIFigure,'Stop Playback before Recording', 'Tip', 'Icon','warning');
            elseif app.isRec == 0
                %Microphone Initialisation
                deviceReader = audioDeviceReader(44100,1024,'NumChannels',2);
                deviceWriter = audioDeviceWriter('SampleRate',deviceReader.SampleRate);
                app.Lamp.Enable = 'on';
                app.isRec = 1;
                app.RecButton.Text = 'Stop';

                %Initializing the delays
                xbuffer1 = 0;
                xbuffer2 = 0;
                ybuffer1 = zeros(10,3);
                ybuffer2 = zeros(10,3);

                S1 = app.Slider_1.Value;
                S2 = app.Slider_2.Value;
                S3 = app.Slider_3.Value;
                S4 = app.Slider_4.Value;
                S5 = app.Slider_5.Value;

                Fs = 44100;
                app.fs = Fs;
                Mrplus = Mrp(app,Fs);

                b = num(app,target(app,S1,S2,S3,S4,S5),Mrplus);

                dF = Fs/1024;

                f = -Fs/2:dF:Fs/2-dF;

                i = 1;

                %Record and playback loop
                while app.isRec == 1

                    %Acquiring the next frame
                    xk = deviceReader();
                    xk1 = xk(:,1)';
                    xk2 = xk(:,2)';

                    pause(0);

                    %Checking if the slider configuration has been changed
                    if app.Slider_1.Value ~= S1 || app.Slider_2.Value ~= S2 || app.Slider_3.Value ~= S3 || app.Slider_4.Value ~= S4 || app.Slider_5.Value ~= S5
                        S1 = app.Slider_1.Value;
                        S2 = app.Slider_2.Value;
                        S3 = app.Slider_3.Value;
                        S4 = app.Slider_4.Value;
                        S5 = app.Slider_5.Value;

                        %Calculations for the new filters
                        Mrplus = Mrp(app,Fs);
                        b = num(app,target(app,S1,S2,S3,S4,S5),Mrplus);
                    end

                    %Filtering Process
                    for n = 1:11
                        if n<11
                            ykNew1(n,:) = filterNew(app,b((2*n-1):(2*n)),xk1,ybuffer1(n,:),xbuffer1,Fs,n);
                            ykNew2(n,:) = filterNew(app,b((2*n-1):(2*n)),xk2,ybuffer2(n,:),xbuffer2,Fs,n);
                        else
                            ykNew1(n,:) = xk1*b(22);
                            ykNew2(n,:) = xk2*b(22);
                        end
                    end

                    yk1 = 0;
                    yk2 = 0;

                    for n = 1:11
                        yk1 = yk1 + ykNew1(n,:);
                        yk2 = yk2 + ykNew2(n,:);
                    end

                    %Playback of frame
                    deviceWriter([0.25*yk1',0.25*yk2']);

                    %Updating the delays
                    xbuffer1 = flip(xk1(length(xk1)-1:length(xk1)));
                    xbuffer2 = flip(xk2(length(xk2)-1:length(xk2)));
                    for n = 1:10
                        ybuffer1(n,:) = flip(ykNew1(n,(length(ykNew1(n,:))-2):(length(ykNew1(n,:)))));
                        ybuffer2(n,:) = flip(ykNew2(n,(length(ykNew2(n,:))-2):(length(ykNew2(n,:)))));
                    end

                    %FFT Plot Update if allowed
                    if mod(i, 51-round(app.Knob.Value)) == 0 && strcmp(app.Switch.Value,'On') == 1
                        z = fftshift(fft(yk1));
                        area(app.UIAxes,f,abs(z)/1024)
                        drawnow limitrate;
                    end

                    %Blinking of the lamp
                    if mod(i,15) == 0
                        if strcmp(app.Lamp.Enable,'on') == 1
                            app.Lamp.Enable = 'off';
                        else
                            app.Lamp.Enable = 'on';
                        end
                    end

                    i = i+1;
                end
                release(deviceReader);
                release(deviceWriter);

            else
                app.isRec = 0;
                app.RecButton.Text = 'Rec';
            end
        end

        function Stop(app,event)
            app.isStop = 1;
        end

        %Value changed function: DropDown
        %Setting the slider presets
        function Preset (app,event)
            value = app.DropDown.Value;
            if strcmp('Rock',value) == 1
                app.Slider_1.Value = 5;
                app.Slider_2.Value = 0;
                app.Slider_3.Value = -4;
                app.Slider_4.Value = 2;
                app.Slider_5.Value = 5;

            elseif strcmp('Flat', value) == 1
                app.Slider_1.Value = 0;
                app.Slider_2.Value = 0;
                app.Slider_3.Value = 0;
                app.Slider_4.Value = 0;
                app.Slider_5.Value = 0;

            elseif strcmp('Pop', value) == 1
                app.Slider_1.Value = 1;
                app.Slider_2.Value = 3;
                app.Slider_3.Value = -1;
                app.Slider_4.Value = -1;
                app.Slider_5.Value = -1;

            elseif strcmp('Bass', value) == 1
                app.Slider_1.Value = 12;
                app.Slider_2.Value = 8;
                app.Slider_3.Value = 2;
                app.Slider_4.Value = -4;
                app.Slider_5.Value = -10;

            elseif strcmp('Treble', value) == 1
                app.Slider_1.Value = -10;
                app.Slider_2.Value = -6;
                app.Slider_3.Value = 0;
                app.Slider_4.Value = 9;
                app.Slider_5.Value = 12;

            elseif strcmp('Vocal', value) == 1
                app.Slider_1.Value = -4;
                app.Slider_2.Value = 5;
                app.Slider_3.Value = 7;
                app.Slider_4.Value = 0;
                app.Slider_5.Value = -5;

            elseif strcmp('Classical',value) == 1
                app.Slider_1.Value = 1;
                app.Slider_2.Value = 2;
                app.Slider_3.Value = -6;
                app.Slider_4.Value = 0;
                app.Slider_5.Value = 0;

            elseif strcmp('Hip-Hop',value) == 1
                app.Slider_1.Value = 3;
                app.Slider_2.Value = 0;
                app.Slider_3.Value = -3;
                app.Slider_4.Value = 1;
                app.Slider_5.Value = 3;

            elseif strcmp('Dance',value) == 1
                app.Slider_1.Value = 7;
                app.Slider_2.Value = 0;
                app.Slider_3.Value = 0;
                app.Slider_4.Value = 2;
                app.Slider_5.Value = -2;

            elseif strcmp('Jazz',value) == 1
                app.Slider_1.Value = 3;
                app.Slider_2.Value = 0;
                app.Slider_3.Value = 3;
                app.Slider_4.Value = 0;
                app.Slider_5.Value = -1;

            elseif strcmp('Powerful',value) == 1
                app.Slider_1.Value = 7;
                app.Slider_2.Value = -2;
                app.Slider_3.Value = -4;
                app.Slider_4.Value = 5;
                app.Slider_5.Value = 8;

            elseif strcmp('Shitty Music',value) == 1
                app.Slider_1.Value = -13;
                app.Slider_2.Value = -13;
                app.Slider_3.Value = -13;
                app.Slider_4.Value = -13;
                app.Slider_5.Value = -13;

            elseif strcmp('MUU', value) == 1
                app.Slider_1.Value = 3;
                app.Slider_2.Value = 12;
                app.Slider_3.Value = -9;
                app.Slider_4.Value = -5;
                app.Slider_5.Value = 3;
            end
        end

        %Value Changing Function: Slider 1
        function Custom(app,event)
            app.DropDown.Value = 'Custom';
        end

        %Value Changing Function: Slider 2
        function Custom2(app,event)
            app.DropDown.Value = 'Custom';
        end

        %Value Changing Function: Slider 3
        function Custom3(app,event)
            app.DropDown.Value = 'Custom';
        end

        %Value Changing Function: Slider 4
        function Custom4(app,event)
            app.DropDown.Value = 'Custom';
        end

        %Value Changing Function: Slider 5
        function Custom5(app,event)
            app.DropDown.Value = 'Custom';
        end
    end

    %Component Initialization
    methods (Access = private)
        %Create UIFigure and Components
        function createComponents(app)
            %Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible','off');
            app.UIFigure.Color = [0.8 0.8 0.8];
            app.UIFigure.Position = [150 80 990 600];
            app.UIFigure.Name = ' UI Figure';

            %Create Image
            app.Image = uiimage(app.UIFigure);
            app.Image.Position = [0 0 990 600];
            app.Image.ImageSource = 'GUI.png';

            % Create Slider 1
            app.Slider_1 = uislider(app.UIFigure);
            app.Slider_1.Limits = [-13 13];
            app.Slider_1.MajorTicks = [];
            app.Slider_1.MajorTickLabels = {''};
            app.Slider_1.Orientation = 'vertical';
            app.Slider_1.ValueChangingFcn = createCallbackFcn(app, @Custom, true);
            app.Slider_1.MinorTicks = [];
            app.Slider_1.Position = [436 69 3 113];

            % Create Slider 2
            app.Slider_2 = uislider(app.UIFigure);
            app.Slider_2.Limits = [-13 13];
            app.Slider_2.MajorTicks = [];
            app.Slider_2.MajorTickLabels = {''};
            app.Slider_2.Orientation = 'vertical';
            app.Slider_2.ValueChangingFcn = createCallbackFcn(app, @Custom2, true);
            app.Slider_2.MinorTicks = [];
            app.Slider_2.Position = [464 69 3 113];

            % Create Slider 3
            app.Slider_3 = uislider(app.UIFigure);
            app.Slider_3.Limits = [-13 13];
            app.Slider_3.MajorTicks = [];
            app.Slider_3.MajorTickLabels = {''};
            app.Slider_3.Orientation = 'vertical';
            app.Slider_3.ValueChangingFcn = createCallbackFcn(app, @Custom3, true);
            app.Slider_3.MinorTicks = [];
            app.Slider_3.Position = [493 69 3 113];

            % Create Slider 4
            app.Slider_4 = uislider(app.UIFigure);
            app.Slider_4.Limits = [-13 13];
            app.Slider_4.MajorTicks = [];
            app.Slider_4.MajorTickLabels = {''};
            app.Slider_4.Orientation = 'vertical';
            app.Slider_4.ValueChangingFcn = createCallbackFcn(app, @Custom4, true);
            app.Slider_4.MinorTicks = [];
            app.Slider_4.Position = [522 69 3 113];

            % Create Slider 5
            app.Slider_5 = uislider(app.UIFigure);
            app.Slider_5.Limits = [-13 13];
            app.Slider_5.MajorTicks = [];
            app.Slider_5.MajorTickLabels = {''};
            app.Slider_5.Orientation = 'vertical';
            app.Slider_5.ValueChangingFcn = createCallbackFcn(app, @Custom5, true);
            app.Slider_5.MinorTicks = [];
            app.Slider_5.Position = [551 69 3 113];

            %Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            title(app.UIAxes, '')
            xlabel(app.UIAxes, '')
            ylabel(app.UIAxes, '')
            app.UIAxes.PlotBoxAspectRatio = [4.10230179028133 1 1];
            app.UIAxes.XLim = [50 14000];
            app.UIAxes.YLim = [0 0.1];
            app.UIAxes.ClippingStyle = 'rectangle';
            app.UIAxes.ColorOrder = [0.9216 0.3373 0;0.851 0.3255 0.098;0.9294 0.6941 0.1255;0.4941 0.1843 0.5569;0.4667 0.6745 0.1882;0.302 0.7451 0.9333;0.6353 0.0784 0.1843];
            app.UIAxes.GridColor = [1 1 1];
            app.UIAxes.MinorGridColor = [1 1 1];
            app.UIAxes.XTickLabel = '';
            app.UIAxes.XMinorTick = 'on';
            app.UIAxes.YTick = [];
            app.UIAxes.Color = [0 0 0];
            app.UIAxes.XMinorGrid = 'on';
            app.UIAxes.XScale = 'log';
            app.UIAxes.BackgroundColor = [0 0 0];
            app.UIAxes.Position = [78 325 771 260];

            % Create TrackDropDown
            app.TrackDropDown = uidropdown(app.UIFigure);
            app.TrackDropDown.Items = {};
            app.TrackDropDown.FontName = 'Batang';
            app.TrackDropDown.BackgroundColor = [0.651 0.651 0.651];

            app.TrackDropDown.Position = [88 253 124 30];
            app.TrackDropDown.Value = {};

            % Create PlayButton
            app.PlayButton = uibutton(app.UIFigure, 'push');
            app.PlayButton.ButtonPushedFcn = createCallbackFcn(app, @play, true);
            app.PlayButton.BackgroundColor = [0.651 0.651 0.651];
            app.PlayButton.FontName = 'Batang';
            app.PlayButton.Position = [235 253 69 30];
            app.PlayButton.Text = 'Play';

            % Create StopButton
            app.StopButton = uibutton(app.UIFigure, 'push');
            app.StopButton.ButtonPushedFcn = createCallbackFcn(app, @Stop, true);
            app.StopButton.BackgroundColor = [0.651 0.651 0.651];
            app.StopButton.FontName = 'Batang';
            app.StopButton.Position = [326 253 68 30];
            app.StopButton.Text = 'Stop';

            % Create DropDown
            app.DropDown = uidropdown(app.UIFigure);
            app.DropDown.Items = {'Flat', 'Rock', 'Pop', 'Bass', 'Treble', 'Vocal', 'Classical', 'Hip-Hop', 'Dance', 'Jazz', 'Powerfull', 'Shitty music', 'MUU', 'Custom'};
            app.DropDown.ValueChangedFcn = createCallbackFcn(app, @Preset, true);
            app.DropDown.FontName = 'Batang';
            app.DropDown.BackgroundColor = [0.651 0.651 0.651];
            app.DropDown.Position = [520 254 125 30];
            app.DropDown.Value = 'Flat';

            % Create RecButton
            app.RecButton = uibutton(app.UIFigure, 'push');
            app.RecButton.ButtonPushedFcn = createCallbackFcn(app, @Rec, true);
            app.RecButton.BackgroundColor = [0.651 0.651 0.651];
            app.RecButton.FontName = 'Batang';
            app.RecButton.Position = [769 253 65 30];
            app.RecButton.Text = 'Rec';

            % Create Lamp
            app.Lamp = uilamp(app.UIFigure);
            app.Lamp.Position = [842 253 29 29];
            app.Lamp.Color = [1 0 0];

            % Create Switch
            app.Switch = uiswitch(app.UIFigure, 'rocker');
            app.Switch.Orientation = 'horizontal';

            app.Switch.Visible = 'off';
            app.Switch.Tooltip = {'FFT off/on'};
            app.Switch.Position = [910 385 54 24];
            app.Switch.Value = 'On';

            % Create Knob
            app.Knob = uiknob(app.UIFigure, 'continuous');
            app.Knob.Limits = [1 50];
            app.Knob.MajorTicks = [1 50];
            app.Knob.MajorTickLabels = {''};
            app.Knob.MinorTicks = [10 20 30 40];
            app.Knob.Tooltip = {'FFT update frequency'};
            app.Knob.Position = [901 440 72 72];
            app.Knob.Value = 25;

            % Create Image2
            app.Image2 = uiimage(app.UIFigure);
            app.Image2.Position = [59 299 831 310];
            app.Image2.ImageSource = 'GUI frame.png';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    %App Creation and Deletion
    methods (Access = public)
        %Construct app
        function app = app1gui
            
            %Create UIFigure and components
            createComponents(app)

            %Register the app with App Designer
            registerApp(app, app.UIFigure)

            %Execute the startup function
            runStartupFcn(app, @Start)

            if nargout == 0
                clear app
            end
        end

        %Code that executes before the app deletion
        function delete(app)
            
            %Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end