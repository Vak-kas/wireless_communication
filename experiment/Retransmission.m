clear variables;
clc;


%% Prepare
% n = rng(10);
max = 10000000; %h의 최대 범위

M = 16; % M=4이면 QPSK, M=16이면 16QAM


nSymbol = 10000; % 비트 수
SNR_dB = 5; %SNR값
SNR_linear = 10^(SNR_dB/10); %Signal Power

test_time = 10; % 실험 반복 횟수
count_average = zeros(1, length(test_time)); % 각 실험마다 재전송이 일어난 횟수를 기록하는 배열 변수

%% 실험 시작

% test_time 만큼 반복
for i  = 1: test_time
    bit_data = randi([0 1], 1, nSymbol); % nSymbol 만큼 비트 생성
    h  = sqrt(1/2) * (randn(1, max)) + 1j*randn(1, max); % h 무선 채널 생성
    noise = sqrt(1/2)*(randn(1,max) +1j*randn(1, max) ); % 노이즈 생성



    % bit_data의 비트를 일정한 개수만큼 쪼개서 숫자로 변환 ex)0 0 1 1 -> 3 후 Mapping
    if M==2 

        data = BPSK_bit2data(bit_data);        %BPSK에서 bit -> data
        modulated_symbol = BPSK_Mapping(data); %BPSK맵핑
    elseif M==4
        data = QPSK_bit2data(bit_data);        %QPSK에서 bit -> data
        modulated_symbol = QPSK_Mapping(data); %QPSK 맵핑
    elseif M==16
        data = QAM_bit2data(bit_data);         %16QAM에서 bit->data
        modulated_symbol = QAM_Mapping(data);  %16QAM 맵핑
    end

    count_time = zeros(1, length(modulated_symbol)); %각 modulated_symbol를 보낼 때 마다 몇 번의 재전송이 있었는지 확인하는 배열
    transmit_power = SNR_linear; %전송 출력

    data_index = 1;%데이터 인덱스
    h_index = 1; %무선 채널 인덱스
    
    count = 0;
    received_symbol = zeros(1, length(modulated_symbol));
    recovered_data = zeros(1, length(modulated_symbol));


    while true
        % 보낼 비트를 전부 보냈으면 while문 탈출
        if data_index > length(modulated_symbol)
            break;
        end
    
        if M==4
            tmp = modulated_symbol(data_index) * h(h_index) * sqrt(transmit_power) + noise(h_index); %페이딩 채널에서 data 1개를 보냄
            received_symbol(data_index) = tmp/h(h_index); % 페이딩 데이터 복구
            recovered_data(data_index) = QPSK_DeMapping(received_symbol(data_index)); % QPSK로 디맵핑
            
            % 받은 값과 보낸 값이 다르다면, 재전송 요구 , 채널값 +1
            if recovered_data(data_index) ~= data(data_index)
                h_index = h_index+1;
                count = count+1;
            % 받은 값과 보낸 값이 같다면, 다음 비트 전송
            else
                count_time(data_index) = count;
                data_index  = data_index+1;
                h_index = h_index+1;
                count = 0;
    
            end
    
    
        elseif M==16
            tmp = modulated_symbol(data_index) * h(h_index) * sqrt(transmit_power) + noise(h_index);
            received_symbol(data_index) = tmp/h(h_index);
            recovered_data(data_index) = QAM_DeMapping(received_symbol(data_index), transmit_power);
            
            % 받은 값과 보낸 값이 다르다면, 재전송 요구 , 채널값 +1
            if recovered_data(data_index) ~= data(data_index)
                h_index = h_index+1;
                count = count+1;
            % 받은 값과 보낸 값이 같다면, 다음 비트 전송
            else
                count_time(data_index) = count;
                data_index  = data_index+1;
                h_index = h_index+1;
                count = 0;
    
            end

        end
        
 
    end
%     disp(count_time)
    %각 비트를 보냈을 때 재전송되는 수를 전부 다 더하고
    count_average(i) = sum(count_time);
end
    average = sum(count_average)/test_time; %test_time 개수로 나눠버리면 평균이 된다.
    disp(count_average);
    disp(average);




%% Mapping Function
% BPSK_Mapping
function [modulated_symbol] = BPSK_Mapping(data)
    modulated_symbol = zeros(1, length(data));

    modulated_symbol(data==1) = (1+1j)/sqrt(2);
    modulated_symbol(data==0) = (-1-1j)/sqrt(2);


end

% BPSK_DeMapping
function [recovered_data] = BPSK_DeMapping(received_symbol)
    recovered_data = zeros(1, length(received_symbol));

    recovered_data(real(received_symbol) + imag(received_symbol) > 0) = 1;
    recovered_data(real(received_symbol) + imag(received_symbol) < 0) = 0;

end

% QPSK_Mapping
function [modulated_symbol] = QPSK_Mapping(data)
    modulated_symbol = zeros(1, length(data));

    modulated_symbol(data == 0) = (1+1j)/sqrt(2);%00
    modulated_symbol(data == 1) = (-1+1j)/sqrt(2);%01
    modulated_symbol(data == 2) = (-1-1j)/sqrt(2);%11
    modulated_symbol(data == 3) = (1-1j)/sqrt(2);%10

end

% QPSK_Demapping
function [recovered_data] = QPSK_DeMapping(received_symbol)
    recovered_data = zeros(1, length(received_symbol));
    recovered_data(real(received_symbol) > 0 & imag(received_symbol) > 0) = 0;
    recovered_data(real(received_symbol) < 0 & imag(received_symbol) > 0) = 1;
    recovered_data(real(received_symbol) < 0 & imag(received_symbol) < 0) = 2;
    recovered_data(real(received_symbol) > 0 & imag(received_symbol) < 0) = 3;


end

%% bit2data
% bpsk bit data -> data
function [data]  = BPSK_bit2data(bit_data)
    data = zeros(1, length(bit_data));

    data(bit_data==1) = 1;
    data(bit_data==0) = 0;
end

% qpsk bit data -> data
function [data] = QPSK_bit2data(bit_data)
    data = zeros(1, length(bit_data)/2);
    for i = 1:length(bit_data)/2
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


%% data2bit
% BPSK
function [bit_data] = BPSK_data2bit(data)
    bit_data(data == 1) = 1;
    bit_data(data == 0) = 0;
end

%QPSK

function [bit_data] = QPSK_data2bit(data)
    bit_data = zeros(1, length(data)*2);

    for i = 1:length(data)
        data_value = data(i);
        % recovered_data(i) 값에 따라서 recovered_bit_data 배열에 적절한 값 할당
        switch data_value
            case 0
                bit_data(2*i - 1) = 0;
                bit_data(2*i) = 0;
            case 1
                bit_data(2*i - 1) = 0;
                bit_data(2*i) = 1;
            case 2
                bit_data(2*i - 1) = 1;
                bit_data(2*i) = 1;
            case 3
                bit_data(2*i - 1) = 1;
                bit_data(2*i) = 0;
            otherwise
                error('Unexpected data value.');
        end
    end
    
end

%% Transmission System

% AWGN
function [send_symbol] = AWGN_Channel(modulated_symbol, SNR_linear)
    transmit_power = SNR_linear; % 출력세기 (y(n))
    h = sqrt(1/2)*(randn(1, length(modulated_symbol)) + 1j*randn(1, length(modulated_symbol)) ); %무선 채널의 개수(h(n))
    transmission_symbol = sqrt(transmit_power)*modulated_symbol;
    noise = sqrt(1/2)*(randn(1, length(modulated_symbol)) +1j*randn(1, length(modulated_symbol)) );

    before_equlizer = transmission_symbol+noise;
    send_symbol = before_equlizer;
end


% fading
function [send_symbol] = FADING_Channel(modulated_symbol, SNR_linear)
    transmit_power = SNR_linear; % 출력세기 (y(n))
%     h = sqrt(1/2)*(randn(1, length(modulated_symbol)) + 1j*randn(1, length(modulated_symbol)) ); %무선 채널의 개수(h(n))
    transmission_symbol = sqrt(transmit_power)*modulated_symbol;
    noise = sqrt(1/2)*(randn(1, length(modulated_symbol)) +1j*randn(1, length(modulated_symbol)) );

    h = (randn(1, length(modulated_symbol)) + 1j * randn(1, length(modulated_symbol))); % 무선 채널의 개수(h(n))
    transmission_symbol = transmission_symbol.*h;
    before_equlizer = transmission_symbol+noise;

    send_symbol = before_equlizer./h;

end

%% 16QAM MAPPing, DeMapping
% 16QAM Mapping
function [modulated_symbol] = QAM_Mapping(data)
    modulated_symbol = zeros(1, length(data));
    
    modulated_symbol(data == 0) = (-3-3j)/sqrt(10);
    modulated_symbol(data == 1) = (-3-1j)/sqrt(10);
    modulated_symbol(data == 2) = (-3+1j)/sqrt(10);
    modulated_symbol(data == 3) = (-3+3j)/sqrt(10);
    modulated_symbol(data == 4) = (-1+3j)/sqrt(10);
    modulated_symbol(data == 5) = (-1+1j)/sqrt(10);
    modulated_symbol(data == 6) = (-1-1j)/sqrt(10);
    modulated_symbol(data == 7) = (-1-3j)/sqrt(10);
    modulated_symbol(data == 8) = (+1-3j)/sqrt(10);
    modulated_symbol(data == 9) = (1-1j)/sqrt(10);
    modulated_symbol(data == 10) = (1+1j)/sqrt(10);
    modulated_symbol(data == 11) = (1+3j)/sqrt(10);
    modulated_symbol(data == 12) = (3+3j)/sqrt(10);
    modulated_symbol(data == 13) = (3+1j)/sqrt(10);
    modulated_symbol(data == 14) = (3-1j)/sqrt(10);
    modulated_symbol(data == 15) = (3-3j)/sqrt(10);
    

end

% 16QAM DeMapping
function [recovered_data] = QAM_DeMapping(received_symbol, transmit_power)
    recovered_data = zeros(1, length(received_symbol));
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


%% 16QAM bit2data
function [data] = QAM_bit2data(bit_data)
    data = zeros(1, length(bit_data)/4);
    for i = 1:length(bit_data)/4
        four_bit = [bit_data(4*i-3) bit_data(4*i-2) bit_data(4*i-1) bit_data(4*i)];
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

%% 16QAM data2bit
function [bit_data] = QAM_data2bit(data)
 bit_data = zeros(1, legnth(data)*4);
    for i = 1:length(data)
        data_value = data(i);
        % recovered_data(i) 값에 따라서 recovered_bit_data 배열에 적절한 값 할당
        switch data_value
            case 0
                bit_data(4*i - 3) = 0;
                bit_data(4*i - 2) = 0;
                bit_data(4*i - 1) = 0;
                bit_data(4*i) = 0;
            case 1
                bit_data(4*i - 3) = 0;
                bit_data(4*i - 2) = 0;
                bit_data(4*i - 1) = 0;
                bit_data(4*i) = 1;
            case 2
                bit_data(4*i - 3) = 0;
                bit_data(4*i - 2) = 0;
                bit_data(4*i - 1) = 1;
                bit_data(4*i) = 1;
            case 3
                bit_data(4*i - 3) = 0;
                bit_data(4*i - 2) = 0;
                bit_data(4*i - 1) = 1;
                bit_data(4*i) = 0;
            case 4
                bit_data(4*i - 3) = 0;
                bit_data(4*i - 2) = 1;
                bit_data(4*i - 1) = 1;
                bit_data(4*i) = 0;
            case 5
                bit_data(4*i - 3) = 0;
                bit_data(4*i - 2) = 1;
                bit_data(4*i - 1) = 1;
                bit_data(4*i) = 1;
            case 6
                bit_data(4*i - 3) = 0;
                bit_data(4*i - 2) = 1;
                bit_data(4*i - 1) = 0;
                bit_data(4*i) = 1;
    
            case 7
                bit_data(4*i - 3) = 0;
                bit_data(4*i - 2) = 1;
                bit_data(4*i - 1) = 0;
                bit_data(4*i) = 0;
            case 8
                bit_data(4*i - 3) = 1;
                bit_data(4*i - 2) = 1;
                bit_data(4*i - 1) = 0;
                bit_data(4*i) = 0;
            case 9
                bit_data(4*i - 3) = 1;
                bit_data(4*i - 2) = 1;
                bit_data(4*i - 1) = 0;
                bit_data(4*i) = 1;
            case 10
                bit_data(4*i - 3) = 1;
                bit_data(4*i - 2) = 1;
                bit_data(4*i - 1) = 1;
                bit_data(4*i) = 1;
            case 11
                bit_data(4*i - 3) = 1;
                bit_data(4*i - 2) = 1;
                bit_data(4*i - 1) = 1;
                bit_data(4*i) = 0;
            case 12
                bit_data(4*i - 3) = 1;
                bit_data(4*i - 2) = 0;
                bit_data(4*i - 1) = 1;
                bit_data(4*i) = 0;
            case 13
                bit_data(4*i - 3) = 1;
                bit_data(4*i - 2) = 0;
                bit_data(4*i - 1) = 1;
                bit_data(4*i) = 1;
            case 14
                bit_data(4*i - 3) = 1;
                bit_data(4*i - 2) = 0;
                bit_data(4*i - 1) = 0;
                bit_data(4*i) = 1;
            case 15
                bit_data(4*i - 3) = 1;
                bit_data(4*i - 2) = 0;
                bit_data(4*i - 1) = 0;
                bit_data(4*i) = 0;
    
            otherwise
                error('Unexpected data value.');
        end
    end
end


%% Repeation FEC
function [Repeat_bit_data]  = REP_FEC(bit_data, Repeat_time)
    Repeat_bit_data = repmat(bit_data, 1, Repeat_time);
end

function [bit_data] = FEC_check(Repeat_bit_data, Repeat_time)
    bit_data = zeros(1, length(Repeat_bit_data/Repeat_time));
    for i = 1:nSymbol
        s = 0;
        for j  = 1:Repeat_time
            s = s + Repeat__bit_data(nSymbol*(j-1)+i);    
        end
        bit_data(i) = round((s/Repeat_time));
    end

end
