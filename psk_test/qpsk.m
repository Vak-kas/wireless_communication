clear variables;
clc;

%%Parameters
SNR_dB = -10:1:20;
SNR_linear = 10.^(SNR_dB/10); %Signal Power

%% Preparation(DATA)
nSymbol = 10;
M = 8;  %2 = BPSK, 4 = QPSK, 8 = 8-PSK, 16 = 16QAM
data = randi([0, M-1], 1, nSymbol );
%bitstream = [0, 1, 0, 0, 1, 1, 1, 0];

%% Transmitter - Modulation (BPSK)
% 0-> cos(2 pi fct) / s2(left) -> -1
% 1-> cos(2 pi fct) s1 (right) -> 1

modulated_symbol = zeros(1, nSymbol);

if M==2
    % modulated_symbol(data==1) = 1;
    % modulated_symbol(data==0) = -1;
    modulated_symbol(data==1) = (1+1j)/sqrt(2);
    modulated_symbol(data==0) = (-1-1j)/sqrt(2);
elseif M == 4
    modulated_symbol(data == 0) = (1+1j)/sqrt(2);%00
    modulated_symbol(data == 1) = (-1+1j)/sqrt(2);%01
    modulated_symbol(data == 2) = (1-1j)/sqrt(2);%11
    modulated_symbol(data == 3) = (-1-1j)/sqrt(2);%10

elseif M == 8
    modulated_symbol(data == 0) = (1); %000; (1,0) 좌표에 위치
    modulated_symbol(data == 1) = (1+1j)/sqrt(2); %001;(1, 1)/sqrt(2) 좌표 위치
    modulated_symbol(data == 2) = (1j); %010; (1,0) 좌표에 위치
    modulated_symbol(data == 3) = (-1+1j)/sqrt(2); %011;(1, 1)/sqrt(2) 좌표 위치
    modulated_symbol(data == 4) = (-1); %100; (1,0) 좌표에 위치
    modulated_symbol(data == 5) = (-1-1j)/sqrt(2); %101;(1, 1)/sqrt(2) 좌표 위치
    modulated_symbol(data == 6) = (-1j); %110; (1,0) 좌표에 위치
    modulated_symbol(data == 7) = (1-1j)/sqrt(2); %111;(1, 1)/sqrt(2) 좌표 위치


end

figure(11);
plot(real(modulated_symbol), imag(modulated_symbol), "b*");
xlim([-5, 5]); ylim([-5, 5]);
xlabel("in-Phase");
ylabel("Quadrature");
grid on;

%% Transmission System
transmit_power = 5; %Signal Strength 
transmission_symbol = sqrt(transmit_power)*modulated_symbol;   %y(n) : 송신기 출력 신호
AWGN = sqrt(1/2)*(randn(1, (nSymbol)) + 1j*randn(1, (nSymbol)) );
% transmission_symbol = sqrt(transmit_power)*modulated_symbol + AWGN;
%I^2R, V^2/r, VI == P



%% Receiver - Demodulation (BPSK)
received_symbol = transmission_symbol + AWGN;

recovered_data = zeros(1, nSymbol);
figure(11);
hold on;
plot(real(received_symbol), imag(received_symbol), "ro");



if M==2
    recovered_data(real(received_symbol) + imag(received_symbol) > 0) = 1;
    recovered_data(real(received_symbol) + imag(received_symbol) < 0) = 0;
elseif M==4
    for i = 1:1:nSymbol
        a = real(received_symbol(i));
        b = imag(received_symbol(i));

        if a>0 && b>0
            recovered_data(i) = 0;
        elseif a>0 &&  b<0
            recovered_data(i) = 2;
        elseif a<0 && b>0
            recovered_data(i) = 1;
        else
            recovered_data(i) = 3;
        end
    end

elseif M==8


end



%%
%SER = Symbol Error Rate
SER = sum(data ~=recovered_data)/nSymbol;


