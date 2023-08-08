clear variables;
clc;

%% Test Setting
SNR_dB= -10:1:10;
SNR_linear = 10.^(SNR_dB/10); %Signal Power
BER = zeros(1, length(SNR_dB));
nSymbol = 100000; %비트 데이터 개수
M = 16; % QAM 종류


norm = true ; %정규화 여부
fading = true; % 페이딩 채널 여부 
Repeat_time = 3; % FEC를 위한 반복 횟수, FEC를 하지 않을 거면 1로 설정, 할 거면 다른 숫자 입력
method = 1; % 방법 1, 방법 2가 있으나, 방법 2는 현재 오류에 있음.


%% Preparation(DATA)
for k = 1:length(SNR_dB)
    bit_data = randi([0, 1], 1, nSymbol );
    %bitstream = [0, 1, 0, 0, 1, 1, 1, 0]
    
    %% FEC
    FEC_bit_data = repmat(bit_data, 1, Repeat_time);
    data = zeros(1, nSymbol/log2(M)*Repeat_time);
    
    %% setData
    if M==16
        for i = 1:nSymbol/log2(M)*Repeat_time
            four_bit = [FEC_bit_data(log2(M)*i-3) FEC_bit_data(log2(M)*i-2) FEC_bit_data(log2(M)*i-1) FEC_bit_data(log2(M)*i)];
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
    
        if norm == true
            modulated_symbol = modulated_symbol/sqrt(10);
        end
    
    else
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
    transmit_power = SNR_linear(k); % 출력세기 (y(n))
    transmission_symbol = sqrt(transmit_power)*modulated_symbol;
    noise_power = 1/sqrt(10);
    noise = (randn(1, nSymbol/log2(M)*Repeat_time) +1j*randn(1, nSymbol/log2(M)*Repeat_time) ) .* noise_power;
    
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
    
    %% method 1
    
    recovered_data = zeros(1, nSymbol/log2(M)*Repeat_time);
    if method == 1
        if M==16
            for i = 1:length(received_symbol)
                x = real(received_symbol(i))/sqrt(transmit_power);
                y = imag(received_symbol(i))/sqrt(transmit_power);
        
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
    
    % method 2
    elseif method ==2
        a = -3/sqrt(10);
        b = -1/sqrt(10);
        c = 1/sqrt(10);
        d = 3/sqrt(10);
        pos = [a+a*1j, a+b*1j, a+c*1j, a+d*1j, b+d*1j, b+c*1j, b+b*1j, b+a*1j, c+a*1j, c+b*1j, c+c*1j, c+d*1j, d+d*1j, d+c*1j, d+b*1j, d+a*1j];
    
    
    
        for i = 1:length(received_symbol)
            min_distance = 99999999;
            min_index = -1;
            tmp = received_symbol(i)./sqrt(10);
            for j = 1:length(pos)
    %             x = real(pos(j));
    %             y = imag(pos(j));
    %             w = real(tmp);
    %             z = imag(tmp);
    %             distance = sqrt((x-w)^2 + (y-z)^2);
                  distance = abs(pos(j) - tmp);
    
                if distance < min_distance
                    min_distance = distance;
                    min_index = j;
                end
    
            end
    
            recovered_data(i) = min_index-1;
        end
    
    
    
    
    end
    
    
    
    
    
    %% set Bit Data
     recovered_bit_data = zeros(1, nSymbol*Repeat_time);
    if M==16
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
    end
    
    %% FEC
    FEC_check = zeros(1, nSymbol);
    for i = 1:nSymbol
        s = 0;
        for j  = 1:Repeat_time
            s = s + recovered_bit_data(nSymbol*(j-1)+i);    
        end
        FEC_check(i) = round((s/Repeat_time));
    end

    BER(k) = sum(bit_data~=FEC_check)/nSymbol;
end

figure(100);
semilogy(SNR_dB, BER, "b"); grid on;
ylim([10^-5 1]); xlim([-10 10]);
ylabel("BER");
xlabel("SNR_dB");
    

