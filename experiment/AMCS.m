clear variables;
clc;

%% Prepare
% n = rng(10);
nSymbol = 10000; % 비트 수
SNR_dB = 5; %SNR값
SNR_linear = 10^(SNR_dB/10); %Signal Power

L1 = 0.6;  % 
L2 = 1.2;
%% 히스토 그램 그래프 보기
% max = 10000000;
% h  = sqrt(1/2) * (randn(1, max)) + 1j*randn(1, max); % h 무선 채널 생성
% figure(11);
% histogram(abs(h));

%% 실험 시작
BPSK_count = 0; %BPSK쓴 개수
QPSK_count = 0; %QPSK쓴 개수
QAM_count = 0; %16QAM쓴 개수

BPSK_err_count = 0; %BPSK 로 왔을 때 오류 수
QPSK_err_count = 0; %QPSK로 왔을 떄 오류수
QAM_err_count = 0; %16QAM으로 왔을 때 오류수


bit_data = randi([0 1], 1, nSymbol+3); % nSymbol+3 만큼 비트 생성 (만약 비트수가 9999개까지 왔을 때, 다음에 최대로 사용할 수 있는 비트수 4개 해서 nSymbol + 3개
recovered_bit_data = zeros(1, 0); % 수신받은 비트  저장하는 배열
max = nSymbol;
h  = sqrt(1/2) * (randn(1, max)) + 1j*randn(1, max); % h 무선 채널 생성
noise = sqrt(1/2)*(randn(1,max) +1j*randn(1, max) ); % 노이즈 생성

h_index = 1; % h (무선채널) 인덱스
data_index = 1; % 데이터 인덱스 
while true
    if nSymbol < data_index % while 문 종료 조건 : nSymbol 개수 만큼 다 사용했을 때
        break;
    end
    
    %L1보다 h의 절대값이 작은 경우
    if abs(h(h_index)) <= L1 % -> BPSK로 설정
        data = bit_data(data_index);
        modulated_symbol = BPSK_Mapping(data);
        data_index = data_index+1;
        
    %L1과 L2 사이에 있을 경우   
    elseif abs(h(h_index)) > L1 && abs(h(h_index)) <=L2
        b_data = zeros(1, 2);
        b_data(1) = bit_data(data_index);
        b_data(2) = bit_data(data_index+1);
        data = QPSK_bit2data(b_data);
        
        modulated_symbol = QPSK_Mapping(data);
        data_index = data_index+2;

    %L2보다 큰 경우
    else
        b_data = zeros(1, 4);
        b_data(1) = bit_data(data_index);
        b_data(2) = bit_data(data_index+1);
        b_data(3) = bit_data(data_index+2);
        b_data(4) = bit_data(data_index+3);
        data = QAM_bit2data(b_data);
        modulated_symbol = QAM_Mapping(data);
        data_index = data_index+4;
    end

    transmit_power = SNR_linear;
    tmp= modulated_symbol * h(h_index) * sqrt(transmit_power) + noise(h_index);
    received_symbol = tmp/h(h_index);
    



    %L1보다 h의 절대값이 작은 경우
    if abs(h(h_index)) <= L1 % -> BPSK로 설정
        recovered_data = BPSK_DeMapping(received_symbol);
        BPSK_count =  BPSK_count+1;
        temp = BPSK_data2bit(recovered_data);

        if recovered_data ~=data
            BPSK_err_count = BPSK_err_count+1;
        end
        
    %L1과 L2 사이에 있을 경우   
    elseif abs(h(h_index)) > L1 && abs(h(h_index)) <=L2
        recovered_data = QPSK_DeMapping(received_symbol);
        QPSK_count = QPSK_count+1;
        temp = QPSK_data2bit(recovered_data);
        if recovered_data ~=data
            QPSK_err_count = QPSK_err_count+1;
        end

    %L2보다 큰 경우
    else
        recovered_data= QAM_DeMapping(received_symbol, transmit_power);
        temp = QAM_data2bit(recovered_data);
        QAM_count = QAM_count+1;
        if recovered_data ~=data
            QAM_err_count = QAM_err_count+1;
        end

    end
    recovered_bit_data = cat(2, recovered_bit_data, temp);
    h_index = h_index+1;
end

bit_data = bit_data(1:nSymbol);
recovered_bit_data= recovered_bit_data(1:nSymbol);


disp(["SNR_dB = ", num2str(SNR_dB), "BPSK = ", num2str(BPSK_err_count/BPSK_count), ...
    "QPSK = ", num2str(QPSK_err_count/QPSK_count), "16QAM = ", num2str(QAM_err_count/QAM_count), ...
    "AVG = " , num2str((BPSK_err_count + QPSK_err_count + QAM_err_count) / (BPSK_count + QPSK_count + QAM_count))] );


























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
 bit_data = zeros(1, length(data)*4);
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