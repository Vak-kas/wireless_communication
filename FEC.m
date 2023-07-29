clear variables;
clc;


%% Setting variable
SNR_dB = 2;
SNR_linear = 10^(SNR_dB/10); %Signal Power
BER = zeros(1, length(SNR_dB));
SER = zeros(1, length(SNR_dB));
Repeat_time = 1:2:20;  %FEC를 위해서 몇 번을 반복할 것인지
FEC_Per = zeros(1, length(Repeat_time));



%% Setting Test Env (여기서 세팅 설정 할 수 있음)
fading = false;      % true시 fading channel, false시 awgn채널
adapt_eq = false;  % true시 eqaulization 적용, false 시 미적용
M = 2; % BPSK =2, QPSK = 4, 8-Psk = 8 중에서 선택 
nSymbol = 100000; % 각 상황 테스트 비트 개수



for k = 1:length(Repeat_time)
    
    
    %% Preparation(DATA)
    bit_data = randi([0, 1], 1, nSymbol );
    %bitstream = [0, 1, 0, 0, 1, 1, 1, 0];
    
    
    
    %% setData
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
    
    
    elseif M==8
        for i = 1:nSymbol/3
            three_bit = [bit_data(3*i-2) bit_data(3*i-1) bit_data(3*i)];
            if three_bit == [0 0 0]
                data(i) = 0;
            elseif three_bit == [0 0 1]
                data(i) = 1;
            elseif three_bit == [0 1 1]
                data(i) = 2;
            elseif three_bit == [0 1 0]
                data(i) = 3;
            elseif three_bit == [1 1 0]
                data(i) = 4;
            elseif three_bit == [1 1 1]
                data(i) = 5;
            elseif three_bit == [1 0 1]
                data(i) = 6;
            elseif three_bit == [1 0 0]
                data(i) = 7;
            end
        end
    elseif M==16
    
    end
    
    %% FEC
    FEC_bit_data = repmat(bit_data, 1, Repeat_time(k));
    FEC_data = repmat(data, 1, Repeat_time(k));
    
    %% Transmitter - Modulation (BPSK)
    % 0-> cos(2 pi fct) / s2(left) -> -1
    % 1-> cos(2 pi fct) s1 (right) -> 1
    
    modulated_symbol = zeros(1, nSymbol/log2(M)*Repeat_time(k));
    
    for i = 1:Repeat_time(k)
        
        if M==2
            % modulated_symbol(data==1) = 1;
            % modulated_symbol(data==0) = -1;
            modulated_symbol(FEC_data==1) = (1+1j)/sqrt(2);
            modulated_symbol(FEC_data==0) = (-1-1j)/sqrt(2);
        elseif M == 4
            modulated_symbol(FEC_data == 0) = (1+1j)/sqrt(2);%00
            modulated_symbol(FEC_data == 1) = (-1+1j)/sqrt(2);%01
            modulated_symbol(FEC_data == 2) = (1-1j)/sqrt(2);%11
            modulated_symbol(FEC_data == 3) = (-1-1j)/sqrt(2);%10
        
        elseif M == 8
            modulated_symbol(FEC_data == 0) = (1); %000; (1,0) 좌표에 위치
            modulated_symbol(FEC_data == 1) = (1+1j)/sqrt(2); %001;(1, 1)/sqrt(2) 좌표 위치
            modulated_symbol(FEC_data == 2) = (1j); %010; (1,0) 좌표에 위치
            modulated_symbol(FEC_data == 3) = (-1+1j)/sqrt(2); %011;(1, 1)/sqrt(2) 좌표 위치
            modulated_symbol(FEC_data == 4) = (-1); %100; (1,0) 좌표에 위치
            modulated_symbol(FEC_data == 5) = (-1-1j)/sqrt(2); %101;(1, 1)/sqrt(2) 좌표 위치
            modulated_symbol(FEC_data == 6) = (-1j); %110; (1,0) 좌표에 위치
            modulated_symbol(FEC_data == 7) = (1-1j)/sqrt(2); %111;(1, 1)/sqrt(2) 좌표 위치
    
        end
    end
    
    
    %     figure(11);
    %     % plot(real(modulated_symbol), imag(modulated_symbol), "b*");
    %     xlim([-20, 20]); ylim([-20, 20]);
    %     xlabel("in-Phase");
    %     ylabel("Quadrature");
    %     grid on;
    
    
    %% Transmission System
    %r(n) = h(n) * y(n) + z(n)
    transmit_power = SNR_linear; % 출력세기 (y(n))
    h = sqrt(1/2)*(randn(1, length(modulated_symbol)) + 1j*randn(1, length(modulated_symbol)) ); %무선 채널의 개수(h(n))
    transmission_symbol = sqrt(transmit_power)*modulated_symbol;
    noise = sqrt(1/2)*(randn(1, nSymbol/log2(M)*Repeat_time(k)) +1j*randn(1, nSymbol/log2(M)*Repeat_time(k)) );
    
    %fading = true 일 경우에는 fading channel 을 지나는 것이고, 
    % fading = false 일 경우 AWGN 채널을 지나는 것으로 설정
    
    
    if fading == true
        transmission_symbol = transmission_symbol.*h;
    end
    
    %% Equalizer
    before_equlizer = transmission_symbol + noise;
    
    
    if adapt_eq == false
        received_symbol = before_equlizer;
    else
        received_symbol = before_equlizer./h;
    end
    
    
    %% Receiver - Demodulation 
    
    recovered_data = zeros(1, nSymbol/log2(M)*Repeat_time(k));
    
    
    if M==2
        recovered_data(real(received_symbol) + imag(received_symbol) > 0) = 1;
        recovered_data(real(received_symbol) + imag(received_symbol) < 0) = 0;
    
    
    elseif M==4
        recovered_data(real(received_symbol) > 0 & imag(received_symbol) > 0) = 0;
        recovered_data(real(received_symbol) < 0 & imag(received_symbol) > 0) = 1;
        recovered_data(real(received_symbol) > 0 & imag(received_symbol) < 0) = 2;
        recovered_data(real(received_symbol) < 0 & imag(received_symbol) < 0) = 3;
    
    
    elseif M==8
        phase_degrees = [0, 45, 90, 135, 180, 225, 270, 315, 360];
        data_mapping = [0, 1, 2, 3, 4, 5, 6, 7, 0];
        received_phase_degrees = (rad2deg(angle(received_symbol)));
        for i = 1:length(received_symbol)
            tmp = received_phase_degrees(i);
            if tmp<0
                tmp = tmp+360;
            end
            [~, index] = min(abs(tmp-phase_degrees), [], 2);
    
            recovered_data(i) = data_mapping(index);
        end
    
    
    end
    
    %     figure(11);
    %     hold on;
    %     plot(real(received_symbol), imag(received_symbol), "ro");
    
    
    
    
    %% set Bit Data
    recovered_bit_data = zeros(1, nSymbol*Repeat_time(k));
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
    
    elseif M==8
        for i = 1:length(recovered_data)
            data_value = recovered_data(i);
    
            switch data_value
                case 0
                    recovered_bit_data(3*i-2) = 0;
                    recovered_bit_data(3*i-1) = 0;
                    recovered_bit_data(3*i) = 0;
                case 1
                    recovered_bit_data(3*i-2) = 0;
                    recovered_bit_data(3*i-1) = 0;
                    recovered_bit_data(3*i) = 1;
                case 2
                    recovered_bit_data(3*i-2) = 0;
                    recovered_bit_data(3*i-1) = 1;
                    recovered_bit_data(3*i) = 1;
                case 3  
                    recovered_bit_data(3*i-2) = 0;
                    recovered_bit_data(3*i-1) = 1;
                    recovered_bit_data(3*i) = 0;
                case 4
                    recovered_bit_data(3*i-2) = 1;
                    recovered_bit_data(3*i-1) = 1;
                    recovered_bit_data(3*i) = 0;
                case 5
                    recovered_bit_data(3*i-2) = 1;
                    recovered_bit_data(3*i-1) = 1;
                    recovered_bit_data(3*i) = 1;
                case 6
                    recovered_bit_data(3*i-2) = 1;
                    recovered_bit_data(3*i-1) = 0;
                    recovered_bit_data(3*i) = 1;
                case 7
                    recovered_bit_data(3*i-2) = 1;
                    recovered_bit_data(3*i-1) = 0;
                    recovered_bit_data(3*i) = 0;
                otherwise
            end
        end
    end
    
    %% FEC
    FEC_check = zeros(1, nSymbol);
    for i = 1:nSymbol
        s = 0;
        for j  = 1:Repeat_time(k)
            s = s + recovered_bit_data(nSymbol*(j-1)+i);
            
        end
        FEC_check(i) = round((s/Repeat_time(k)));
    end
    


    FEC_Per(k) = sum(FEC_check~=bit_data)/nSymbol;





    
end


figure(100);
semilogy(Repeat_time, FEC_Per, "B"); grid on;
xlabel("Repeat_time");
ylabel("BER");









