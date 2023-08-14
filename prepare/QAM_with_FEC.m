clear variables;
clc;

%% Test Setting
SNR_dB= 10;
SNR_linear = 10^(SNR_dB/10); %Signal Power

nSymbol = 10000; %비트 데이터 개수
M = 16; % QAM 종류


norm = true ; %정규화 여부
fading = true; % 페이딩 채널 여부 
Repeat_time = 1; % FEC를 위한 반복 횟수, FEC를 하지 않을 거면 1로 설정, 할 거면 다른 숫자 입력


%% Preparation(DATA)

bit_data = randi([0, 1], 1, nSymbol );
SNR_linear = 10^(SNR_dB/10); %Signal Power
FEC_bit_data = repmat(bit_data, 1, Repeat_time);

bit_data = randi([0, 1], 1, nSymbol );
    %bitstream = [0, 1, 0, 0, 1, 1, 1, 0]
    
%% FEC
FEC_bit_data = repmat(bit_data, 1, Repeat_time);
data = zeros(1, length(FEC_bit_data)/4);
    
%% setData
if M==16
    for i = 1:length(FEC_bit_data)/4
        four_bit = [FEC_bit_data(4*i-3) FEC_bit_data(4*i-2) FEC_bit_data(4*i-1) FEC_bit_data(4*i)];
        if four_bit == [0 0 0 0] % 0
            data(i) = 0;
        elseif four_bit == [0 0 0 1] % 1
            data(i) = 1;
        elseif four_bit == [0 0 1 1] % 2
            data(i) = 2;
        elseif four_bit == [0 0 1 0] % 3
            data(i) = 3;
        elseif four_bit == [0 1 1 0] % 4
            data(i) = 4;
        elseif four_bit == [0 1 1 1] % 5
            data(i) = 5;
        elseif four_bit == [0 1 0 1] % 6
            data(i) = 6;
        elseif four_bit == [0 1 0 0] % 7
            data(i) = 7;
        elseif four_bit == [1 1 0 0] % 8
            data(i) = 8;
        elseif four_bit == [1 1 0 1] % 9
            data(i) = 9;
        elseif four_bit == [1 1 1 1] % 10
            data(i) = 10;
        elseif four_bit == [1 1 1 0] % 11
            data(i) = 11;
        elseif four_bit == [1 0 1 0] % 12
            data(i) = 12;
        elseif four_bit == [1 0 1 1] % 13
            data(i) = 13;
        elseif four_bit == [1 0 0 1] % 14
            data(i) = 14;
        elseif four_bit == [1 0 0 0] % 15
            data(i) = 15;
        end
    end
end

%% Transmitter - Modulation (QAM)
modulated_symbol = zeros(1, length(data));

if M==16
    modulated_symbol = QAM_Mapping(data);
end


if norm == true
    modulated_symbol = modulated_symbol/sqrt(10);
end


%% plot modulated_symbol
figure(11);
plot(real(modulated_symbol), imag(modulated_symbol), "b*");
% xlim([-5, 5]); ylim([-5, 5]);
xlabel("Real");
ylabel("Imaginary");
grid on;



%% Transmission System
%r(n) = h(n) * y(n) + z(n)
transmit_power = SNR_linear; % 출력세기 (y(n))
transmission_symbol = sqrt(transmit_power)*modulated_symbol;
noise_power = 1/sqrt(10);
noise = (randn(1, length(modulated_symbol)) +1j*randn(1, length(modulated_symbol)) ) .* noise_power;

%fading = true 일 경우에는 fading channel 을 지나는 것이고, 
% fading = false 일 경우 AWGN 채널을 지나는 것으로 설정


if fading == true
    h = (randn(1, length(modulated_symbol)) + 1j * randn(1, length(modulated_symbol))); % 무선 채널의 개수(h(n))
    transmission_symbol = transmission_symbol.*h;
end

%% Equalizer
before_equlizer = transmission_symbol+noise;


if fading == true
    received_symbol = before_equlizer./h;
else
    received_symbol = before_equlizer;
end


figure(11);
hold on;
xlim([-2, 2]);
ylim([-2, 2]);
plot(real(received_symbol)/sqrt(transmit_power), imag(received_symbol)/sqrt(transmit_power), "ro");


%% DeMAPPING
recovered_data = QAM_DeMapping(received_symbol);



%% recovered_bit_data
%% set Bit Data
 recovered_bit_data = zeros(1, length(FEC_bit_data));
for i = 1:length(recovered_data)
    data_value = recovered_data(i);
    % recovered_data(i) 값에 따라서 recovered_bit_data 배열에 적절한 값 할당
    switch data_value
        case 0
            recovered_bit_data(4*i - 3) = 0;
            recovered_bit_data(4*i - 2) = 0;
            recovered_bit_data(4*i - 1) = 0;
            recovered_bit_data(4*i) = 0;
        case 1
            recovered_bit_data(4*i - 3) = 0;
            recovered_bit_data(4*i - 2) = 0;
            recovered_bit_data(4*i - 1) = 0;
            recovered_bit_data(4*i) = 1;
        case 2
            recovered_bit_data(4*i - 3) = 0;
            recovered_bit_data(4*i - 2) = 0;
            recovered_bit_data(4*i - 1) = 1;
            recovered_bit_data(4*i) = 1;
        case 3
            recovered_bit_data(4*i - 3) = 0;
            recovered_bit_data(4*i - 2) = 0;
            recovered_bit_data(4*i - 1) = 1;
            recovered_bit_data(4*i) = 0;
        case 4
            recovered_bit_data(4*i - 3) = 0;
            recovered_bit_data(4*i - 2) = 1;
            recovered_bit_data(4*i - 1) = 1;
            recovered_bit_data(4*i) = 0;
        case 5
            recovered_bit_data(4*i - 3) = 0;
            recovered_bit_data(4*i - 2) = 1;
            recovered_bit_data(4*i - 1) = 1;
            recovered_bit_data(4*i) = 1;
        case 6
            recovered_bit_data(4*i - 3) = 0;
            recovered_bit_data(4*i - 2) = 1;
            recovered_bit_data(4*i - 1) = 0;
            recovered_bit_data(4*i) = 1;

        case 7
            recovered_bit_data(4*i - 3) = 0;
            recovered_bit_data(4*i - 2) = 1;
            recovered_bit_data(4*i - 1) = 0;
            recovered_bit_data(4*i) = 0;
        case 8
            recovered_bit_data(4*i - 3) = 1;
            recovered_bit_data(4*i - 2) = 1;
            recovered_bit_data(4*i - 1) = 0;
            recovered_bit_data(4*i) = 0;
        case 9
            recovered_bit_data(4*i - 3) = 1;
            recovered_bit_data(4*i - 2) = 1;
            recovered_bit_data(4*i - 1) = 0;
            recovered_bit_data(4*i) = 1;
        case 10
            recovered_bit_data(4*i - 3) = 1;
            recovered_bit_data(4*i - 2) = 1;
            recovered_bit_data(4*i - 1) = 1;
            recovered_bit_data(4*i) = 1;
        case 11
            recovered_bit_data(4*i - 3) = 1;
            recovered_bit_data(4*i - 2) = 1;
            recovered_bit_data(4*i - 1) = 1;
            recovered_bit_data(4*i) = 0;
        case 12
            recovered_bit_data(4*i - 3) = 1;
            recovered_bit_data(4*i - 2) = 0;
            recovered_bit_data(4*i - 1) = 1;
            recovered_bit_data(4*i) = 0;
        case 13
            recovered_bit_data(4*i - 3) = 1;
            recovered_bit_data(4*i - 2) = 0;
            recovered_bit_data(4*i - 1) = 1;
            recovered_bit_data(4*i) = 1;
        case 14
            recovered_bit_data(4*i - 3) = 1;
            recovered_bit_data(4*i - 2) = 0;
            recovered_bit_data(4*i - 1) = 0;
            recovered_bit_data(4*i) = 1;
        case 15
            recovered_bit_data(4*i - 3) = 1;
            recovered_bit_data(4*i - 2) = 0;
            recovered_bit_data(4*i - 1) = 0;
            recovered_bit_data(4*i) = 0;

        otherwise
            error('Unexpected data value.');
    end
end

%% function

% 16QAM Mapping
function [modulated_symbol] = QAM_Mapping(data)
    modulated_symbol = zeros(1, length(data));
    
    modulated_symbol(data == 0) = (-3-3j);
    modulated_symbol(data == 1) = (-3-1j);
    modulated_symbol(data == 2) = (-3+1j);
    modulated_symbol(data == 3) = (-3+3j);
    modulated_symbol(data == 4) = (-1+3j);
    modulated_symbol(data == 5) = (-1+1j);
    modulated_symbol(data == 6) = (-1-1j);
    modulated_symbol(data == 7) = (-1-3j);
    modulated_symbol(data == 8) = (+1-3j);
    modulated_symbol(data == 9) = (1-1j);
    modulated_symbol(data == 10) = (1+1j);
    modulated_symbol(data == 11) = (1+3j);
    modulated_symbol(data == 12) = (3+3j);
    modulated_symbol(data == 13) = (3+1j);
    modulated_symbol(data == 14) = (3-1j);
    modulated_symbol(data == 15) = (3-3j);

end

% 16QAM DeMapping
function [recovered_data] = QAM_DeMapping(received_symbol)
    recovered_data = zeros(1, length(received_symbol));
    for i = 1:length(received_symbol)
        x = real(received_symbol(i))/sqrt(10);
        y = imag(received_symbol(i))/sqrt(10);

        if x <-2/sqrt(10) &&  x > -4/sqrt(10)
            if y>-4/sqrt(10) && y<-2/sqrt(10)
                recovered_data(i) = 0;
            elseif y>-2/sqrt(10) && y<0
                recovered_data(i) = 1;
            elseif y>0 && y<2/sqrt(10)
                recovered_data(i) = 2;
            elseif y>2/sqrt(10) && y<4/sqrt(10)
                recovered_data(i) = 3;
            end
        elseif x<0 && x >-2/sqrt(10)
            if y>-4/sqrt(10) && y<-2/sqrt(10)
                recovered_data(i) = 7;
            elseif y>-2/sqrt(10) && y<0
                recovered_data(i) = 6;
            elseif y>0 && y<2/sqrt(10)
                recovered_data(i) = 5;
            elseif y>2/sqrt(10) && y<4/sqrt(10)
                recovered_data(i) = 4;
            end
        elseif x>0 && x<2/sqrt(10)
            if y>-4/sqrt(10) && y<-2/sqrt(10)
                recovered_data(i) = 8;
            elseif y>-2/sqrt(10) && y<0
                recovered_data(i) = 9;
            elseif y>0 && y<2/sqrt(10)
                recovered_data(i) = 10;
            elseif y>2/sqrt(10) && y<4/sqrt(10)
                recovered_data(i) = 11;
            end
        elseif x>2/sqrt(10) &&  x<4/sqrt(10)
            if y>-4/sqrt(10) && y<-2/sqrt(10)
                recovered_data(i) = 15;
            elseif y>-2/sqrt(10) && y<0
                recovered_data(i) = 14;
            elseif y>0 && y<2/sqrt(10)
                recovered_data(i) = 13;
            elseif y>2/sqrt(10) && y<4/sqrt(10)
                recovered_data(i) = 12;
            end
        end
    end

end


    