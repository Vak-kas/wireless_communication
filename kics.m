clear variables
clc

%% Prepare
SNR_dB = -10:1:20;
SNR_linear = 10.^(SNR_dB/10); %Signal Power

M = 2;  %2 = BPSK
nSymbol =4;
test_time = 10000;
alpha = 1.2;
% h = sqrt(1/2)*(randn(1, length(nSymbol)) + 1j*randn(1, length(nSymbol)) ); %무선 채널의 개수(h(n))
% noise = sqrt(1/2)*(  randn(1, nSymbol) +1j*randn(1, nSymbol) );

bit_data = ones(1, nSymbol);


SER = zeros(1, length(SNR_dB));
BER = zeros(1, length(SNR_dB));
for i = 1:1:length(SNR_dB)
    %% Preparation(DATA)
    BER_count = 0;
    SER_count = 0;

    for j = 1:test_time
        h = sqrt(1/2)*(randn(1, nSymbol) + 1j*randn(1, nSymbol) ); %무선 채널의 개수(h(n))
        noise = sqrt(1/2)*(  randn(1, nSymbol) +1j*randn(1, nSymbol) );
    
        %% key value (share)
        key = zeros(1, nSymbol);
        for k = 1:nSymbol
            if abs(h(k)) > alpha
                key(k) = 1;
            else
                key(k) = 0;
            end
        end
    
    
        data = XOR(bit_data, key);
        
        %% Transmitter - Modulation (BPSK)
        % 0-> cos(2 pi fct) / s2(left) -> -1
        % 1-> cos(2 pi fct) s1 (right) -> 1
        
        modulated_symbol = zeros(1, nSymbol);
        
        % modulated_symbol(data==1) = 1;
        % modulated_symbol(data==0) = -1;
        modulated_symbol(data==1) = (1+1j)/sqrt(2);
        modulated_symbol(data==0) = (-1-1j)/sqrt(2);
    
        
        % figure(11);
        % plot(real(modulated_symbol), imag(modulated_symbol), "b*");
        % xlim([-2, 2]); ylim([-2, 2]);
        % xlabel("in-Phase");
        % ylabel("Quadrature");
        % grid on;
        
        
        %% Transmission System
        % fading
        
        transmit_power = SNR_linear(i); % 출력세기 (y(n))
        transmission_symbol = sqrt(transmit_power)*modulated_symbol.*h + noise; %sqrt(P)*h*x + noise
    
        
        %% Receiver - Demodulation (BPSK)
        received_symbol = transmission_symbol./h; %equalizer
        
        % figure(11);
        % hold on;
        % plot(real(received_symbol)/sqrt(transmit_power), imag(received_symbol)/sqrt(transmit_power), "ro");
        
        recovered_data = zeros(1, nSymbol);
        recovered_data(real(received_symbol) + imag(received_symbol) > 0) = 1;
        recovered_data(real(received_symbol) + imag(received_symbol) < 0) = 0;  



        recovered_bit_data = XOR(recovered_data, key);
        flag = false;
        for p = 1:length(bit_data)
            a = bit_data(p);
            b = recovered_bit_data(p);
            if (a~=b)
                BER_count = BER_count+1;
                flag = true;
            end
        end

        if flag == true
            SER_count = SER_count+1;
        end

    


    end

    %%
    SER(i) = SER_count / test_time;
    BER(i) = BER_count / (test_time * nSymbol);
end

%% Ploting SER Curve
figure(100);
semilogy(SNR_dB, SER, "b-"); grid on;
ylim([10^-5 1]); xlim([-10 20]);
ylabel("SER");
xlabel("SNR(dB)");

%% Ploting BER Curve
figure(100);
hold on;
semilogy(SNR_dB, BER, "r-");


%% Theory - SER(Symbol Error Rate)
% figure(100);
% hold on;
% 
% P_ser = 2*(M-1)/M* qfunc(sqrt(6*SNR_linear/(M^2-1)) );
% semilogy(SNR_dB, P_ser, "b-");



function [result] = XOR(a, b)
    result = zeros(1, length(a));
    for i = 1:length(a)
        tmp = a(i) + b(i);
        if (tmp == 0 || tmp == 2)
            result(i) = 0;
        else
            result(i) = 1;
        end
    end
end
