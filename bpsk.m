clear variables
clc

%%
SNR_dB = -10:1:20;
SNR_linear = 10.^(SNR_dB/10); %Signal Power
SER = zeros(1, length(SNR_dB));
% parfor i = 1: length(SNR_dB);
for i = 1:1:length(SNR_dB)
    %% Preparation(DATA)
    nSymbol = 100000;
    M = 4;  %2 = BPSK, 4 = QPSK, 8 = 8-PSK, 16 = 16QAM
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

    
    end
    
%     figure(11);
%     plot(real(modulated_symbol), imag(modulated_symbol), "b*");
%     xlim([-5, 5]); ylim([-5, 5]);
%     xlabel("in-Phase");
%     ylabel("Quadrature");
%     grid on;
    
    
    %% Transmission System
    transmit_power = SNR_linear(i); %Signal Strength
    transmission_symbol = sqrt(transmit_power)*modulated_symbol;
    AWGN = sqrt(1/2)*(randn(1, nSymbol) +1j*randn(1, nSymbol) );
    % X~N(0, 1), AX~N(0, 1*a^2);
    % transmission_symbol = sqrt(transmit_power)*modulated_symbol + AWGN;
    %I^2R, V%2/t, VI == P
    
    
    %% Receiver - Demodulation (BPSK)
    % received_symbol = modulated_symbol;
    received_symbol = transmission_symbol + AWGN;
    
    recovered_data = zeros(1, nSymbol);
%     figure(11);
%     hold on;
%     plot(real(received_symbol), imag(received_symbol), "ro");
    
    if M==2
        recovered_data(real(received_symbol) + imag(received_symbol) > 0) = 1;
        recovered_data(real(received_symbol) + imag(received_symbol) < 0) = 0;
    elseif M==4
        for j = 1:1:nSymbol
            a = real(received_symbol(j));
            b = imag(received_symbol(j));
    
            if a>0 && b>0
                recovered_data(j) = 0;
            elseif a>0 &&  b<0
                recovered_data(j) = 2;
            elseif a<0 && b>0
                recovered_data(j) = 1;
            else
                recovered_data(j) = 3;
            end
        end 
    end 
    
    %%
    % SER
    SER(i) = sum(data ~= recovered_data)/nSymbol;
end

%% Ploting SER Curve
figure(100);
semilogy(SNR_dB, SER, "bo"); grid on;
ylim([10^-5 1]); xlim([-10 20]);
ylabel("SER");
xlabel("SNR(dB)");

%% Theory - SER(Symbol Error Rate)
% figure(100);
% hold on;
% if M==2
%     P_ser = 2*(M-1)/M* qfunc(sqrt(6*SNR_linear/(M^2-1)) );
%     semilogy(SNR_dB, P_ser, "b-");
% elseif M==4
% %     p_ser = 4*(1-1/sqrt(M))*qfunc(sqrt(3*SNR_linear/(M-1)) - 4*((11/sqrt(M))*))
% %     semilogy(SNR_dB, P_ser, "r-");
% end
% 
% 
% figure(100);
% legend("Sim", "Ana", "location", "northest");


