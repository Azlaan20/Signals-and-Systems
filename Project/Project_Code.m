%% 5-Band Graphic Equalizer Design and Implementation

% Define center frequencies (Hz)
center_frequencies = [63, 250, 1000, 4000, 16000];

% Define Q and sampling frequency (Fs)
Q = 0.73;
Fs = 62000;

% Initialize filter order
filter_order = 4; % Adjust as needed

% Preallocate arrays for filter coefficients
B = cell(1, length(center_frequencies));
A = cell(1, length(center_frequencies));
f1 = [33.21, 131.79, 527.15, 2108.6, 8434.3];
f2 = [119.51, 474.25, 1897.0, 7588.0, 30352.1];


% Design Butterworth filters for each band
for i = 1:length(center_frequencies)
    fc = center_frequencies(i);
    
    % Design Butterworth bandpass filter
    [B{i}, A{i}] = butter(filter_order, [f1(i), f2(i)]/(Fs/2), 'bandpass');
end

% Plot the combined (sum) frequency response of all filters
combined_response = zeros(1024, 1);

for i = 1:length(center_frequencies)
    [H, F] = freqz(B{i}, A{i}, 1024, Fs);
    plot(F, 20*log10(abs(H)) + 20*log10(length(center_frequencies)), 'LineWidth', 1.5);
    hold on;
    combined_response = combined_response + abs(H).^2; % Accumulate squared magnitude
end

% Normalize the combined response
combined_response = 20*log10(sqrt(combined_response/length(center_frequencies)));

plot(F, 20*log10(abs(combined_response)), 'LineWidth', 1.5);

title('Combined Frequency Response of 5-Band Graphic Equalizer');
xlabel('Frequency (Hz)');
ylabel('Gain (dB)');
legend('Band 1', 'Band 2', 'Band 3', 'Band 4', 'Band 5', 'Combined');
hold off;
grid on;

%% Additional Information

% Display additional filter information
fprintf('Filter Information:\n');
for i = 1:length(center_frequencies)
    fprintf('Band %d - Center Frequency: %d Hz, Lower Frequency: %.2f Hz, Upper Frequency: %.2f Hz\n', i, center_frequencies(i), f1(i), f2(i));
end