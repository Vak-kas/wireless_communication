clear varibales;
clc;

%% Test Setting
nSymbol = 3000;
SNR_dB =10;
M = 4; %  M=2 -> BPSK, M=4 -> QPSK, M=8 -> 8-PSK


norm = true ; %정규화 여부
fading = false; % 페이딩 채널 여부 , true 시 페이딩 채널, false 시 AWGN 채널
Repeat_time = 3; % FEC를 위한 반복 횟수, FEC를 하지 않을 거면 1로 설정, 할 거면 다른 숫자 입력



%% Preparation(DATA)

bit_data = randi([0, 1], 1, nSymbol );
SNR_linear = 10^(SNR_dB/10); %Signal Power
FEC_bit_data = repmat(bit_data, 1, Repeat_time);

%% Mapping
data = zeros(1, nSymbol/log2(M));
if M==2
    data(bit_data==1) = 1;
    data(bit_data==0) = 0;

elseif M==4
    for i = 1:nSymbol/2
        two_bit = [bit_data(2*i-1) bit_data(2*i)];
        if two_bit ==[0 0]
            data(i)= 0;
        elseif two_bit == [0 1]
            data(i) = 1;
        elseif two_bit == [1 1]
            data(i) = 2;
        elseif two_bit == [1 0]
            data(i) = 3;
        end
    end
end


%% Transmitter - Modulation (BPSK)
% 0-> cos(2 pi fct) / s2(left) -> -1
% 1-> cos(2 pi fct) s1 (right) -> 1


if M==2
    % modulated_symbol(data==1) = 1;
    % modulated_symbol(data==0) = -1;
    modulated_symbol = BPSK_Mapping(data);

elseif M == 4
    modulated_symbol = QPSK_Mapping(data);
    modulated_symbol(data == 0) = (1+1j)/sqrt(2);%00
    modulated_symbol(data == 1) = (-1+1j)/sqrt(2);%01
    modulated_symbol(data == 2) = (1-1j)/sqrt(2);%11
    modulated_symbol(data == 3) = (-1-1j)/sqrt(2);%10

end


figure(11);
plot(real(modulated_symbol), imag(modulated_symbol), "b*");
xlim([-2, 2]); ylim([-2, 2]);
xlabel("in-Phase");
ylabel("Quadrature");
grid on;





%% Transmission System
%r(n) = h(n) * y(n) + z(n)
transmit_power = SNR_linear; % 출력세기 (y(n))
h = sqrt(1/2)*(randn(1, length(modulated_symbol)) + 1j*randn(1, length(modulated_symbol)) ); %무선 채널의 개수(h(n))
transmission_symbol = sqrt(transmit_power)*modulated_symbol;
noise = sqrt(1/2)*(randn(1, length(modulated_symbol)) +1j*randn(1, length(modulated_symbol)) );



%% Receiver - Demodulation 
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

if M==2
    recovered_data = BPSK_DeMapping(received_symbol);
elseif M==4
    recovered_data = QPSK_DeMapping(received_symbol);
end


figure(11);
hold on;
plot(real(received_symbol)/sqrt(transmit_power), imag(received_symbol)/sqrt(transmit_power), "ro");

%% recovered bit data
recovered_bit_data = zeros(1, length(FEC_bit_data));

if M==2
    recovered_bit_data(recovered_data == 1) = 1;
    recovered_bit_data(recovered_data == 0) = 0;
elseif M==4
    for i = 1:length(recovered_data)
        data_value = recovered_data(i);
        % recovered_data(i) 값에 따라서 recovered_bit_data 배열에 적절한 값 할당
        switch data_value
            case 0
                recovered_bit_data(2*i - 1) = 0;
                recovered_bit_data(2*i) = 0;
            case 1
                recovered_bit_data(2*i - 1) = 0;
                recovered_bit_data(2*i) = 1;
            case 2
                recovered_bit_data(2*i - 1) = 1;
                recovered_bit_data(2*i) = 1;
            case 3
                recovered_bit_data(2*i - 1) = 1;
                recovered_bit_data(2*i) = 0;
            otherwise
                error('Unexpected data value.');
        end
    end
end













%% Mapping Function

% BPSK
function [modulated_symbol] = BPSK_Mapping(data)
    modulated_symbol = zeros(1, length(data));

    modulated_symbol(data==1) = (1+1j)/sqrt(2);
    modulated_symbol(data==0) = (-1-1j)/sqrt(2);


end


function [recovered_data] = BPSK_DeMapping(received_symbol)
    recovered_data = zeros(1, length(received_symbol));

    recovered_data(real(received_symbol) + imag(received_symbol) > 0) = 1;
    recovered_data(real(received_symbol) + imag(received_symbol) < 0) = 0;

end

% QPSK
function [data] = QPSK_Mapping(data)
    modulated_symbol = zeros(1, length(data));

    modulated_symbol(data == 0) = (1+1j)/sqrt(2);%00
    modulated_symbol(data == 1) = (-1+1j)/sqrt(2);%01
    modulated_symbol(data == 2) = (-1-1j)/sqrt(2);%11
    modulated_symbol(data == 3) = (1-1j)/sqrt(2);%10

end

function [recovered_data] = QPSK_DeMapping(received_symbol)
    recovered_data = zeros(1, length(received_symbol));
    recovered_data(real(received_symbol) > 0 & imag(received_symbol) > 0) = 0;
    recovered_data(real(received_symbol) < 0 & imag(received_symbol) > 0) = 1;
    recovered_data(real(received_symbol) > 0 & imag(received_symbol) < 0) = 2;
    recovered_data(real(received_symbol) < 0 & imag(received_symbol) < 0) = 3;


end





