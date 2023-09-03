
clear variables;
clc;


%% Prepare
% n = rng(10);
max = 10000000; %h의 최대 범위

nSymbol = 10000; % 비트 수
SNR_dB = -10; %SNR값
SNR_linear = 10^(SNR_dB/10); %Signal Power
transmit_power = SNR_linear;

L1 = 0.6;
L2 = 1.2;


%% 실험 시작


bit_data = randi([0 1], 1, nSymbol+3); % nSymbol+3 만큼 비트 생성
recovered_bit_data = zeros(1, 0); % 수신받은 비트  저장하는 배열

h  = sqrt(1/2) * (randn(1, max)) + 1j*randn(1, max); % h 무선 채널 생성
noise = sqrt(1/2)*(randn(1,max) +1j*randn(1, max) ); % 노이즈 생성

drop_count = 0; % 비트 전송 안 된 개수
retrans = 0; % 전체 재전송 횟수
count = 0 ; %테스트용


M = -1;
h_index = 1; % h (무선채널) 인덱스
data_index = 1; % 데이터 인덱스 
flag = false; % 재전송 중인 상태인가?

while true
    % 종료 조건
    if data_index > nSymbol
        break
    end

    % 재전송 상태가 아닌 순수 전송되는 상태일 때
    if flag == false

        % BPSK 로 전송되는 조건
        if abs(h(h_index)) <=L1
            data = bit_data(data_index);
            modulated_symbol = BPSK_Mapping(data);
            M=2;

        % QPSK로 전송되는 조건
        elseif abs(h(h_index)) > L1 && abs(h(h_index)) <=L2
            b_data = zeros(1, 2);
            b_data(1) = bit_data(data_index);
            b_data(2) = bit_data(data_index+1);
            data = QPSK_bit2data(b_data);
            modulated_symbol = QPSK_Mapping(data);
            M=4;

        % 16QAM으로 전송되는 조건
        else
            b_data(1) = bit_data(data_index);
            b_data(2) = bit_data(data_index+1);
            b_data(3) = bit_data(data_index+2);
            b_data(4) = bit_data(data_index+3);
            data = QAM_bit2data(b_data);
            modulated_symbol = QAM_Mapping(data);
            M=16;

        %전송 조건문 종료
        end



        % 최대 3회까지 전송해보기
        for i = 1:3
            flag = true; % 재전송 여부 판별, 3번 재전송을 했을 떄 끝까지 true 이면, while문에서 1단계 낮춰서 보낼 거.
            % 전송 
            tmp= modulated_symbol * h(h_index) * sqrt(transmit_power) + noise(h_index);
            received_symbol = tmp/h(h_index);
            % BPSK 전송일 때
            if M==2
                recovered_data = BPSK_DeMapping(received_symbol);
                temp = BPSK_data2bit(recovered_data);
                
                %데이터 일치시 정지
                if recovered_data == data
                    flag = false; %재전송 없이 순수한 상태로 넘어가기
                    data_index = data_index+1; % 데이터 비트 다음 걸로 넘어가기 
                    h_index = h_index+1;
                    break;
                end

            %QPSK 전송일 때
            elseif M==4
                recovered_data = QPSK_DeMapping(received_symbol);
                temp = QPSK_data2bit(recovered_data);

                %데이터 일치시 정지
                if recovered_data == data
                    flag = false;
                    data_index = data_index+2;
                    h_index = h_index+1;
                    break;
                end

            %QAM 전송일 때
            else
                recovered_data = QAM_DeMapping(received_symbol, transmit_power);
                temp = QAM_data2bit(recovered_data);
                % 데이터 일치시 
                if recovered_data == data
                    flag = false;
                    data_index = data_index+4;
                    h_index = h_index +1;
                    break;
                end

            end

            % 데이터 불일치시 ( 오류 발생시)
            h_index = h_index+1;
            retrans = retrans +1; %전체 재전송 횟수 +1
        end
%         disp(data_index)
        % 비트가 3회 내에 제대로 전송되었을 때 
        if flag == false
            recovered_bit_data = cat(2, recovered_bit_data, temp);


            
        % 단계를 1단계 낮추고 , 다시 재전송
        else
            % BPSK에서 더 내려갈 곳은 없기에, drop 시키고, 복구 비트데이터에는 -1를 넣는다.
            if M==2
                recovered_bit_data = cat(2, recovered_bit_data, -1);
                drop_count = drop_count+1;
                flag = false;
                data_index = data_index+1;
            % 나머지는 1단계 씩 M을 낮춰준다.
            elseif M==4
                M = 2;
            else
                M = 4;
            end
        end


    
    % 재전송 상태일 때 (flag = true)
    else
        %BPSK로 다시 전송
        if M==2
            for k = 1:length(b_data)
                data = b_data(k);
%                 disp(data);
                modulated_symbol = BPSK_Mapping(data);

                flag2 = true;

                for i = 1:3
                    % 전송 
                    tmp= modulated_symbol * h(h_index) * sqrt(transmit_power) + noise(h_index);
                    received_symbol = tmp/h(h_index);

                    recovered_data = BPSK_DeMapping(received_symbol);
                    temp = BPSK_data2bit(recovered_data);

                    %데이터 일치시 정지
                    if recovered_data == data
                        h_index = h_index+1;
                        flag2 = false;
                        break;
                    %데이터 불일치시, h_index 를 일단 1을 올려줌
                    else
                        h_index = h_index+1;
                        retrans = retrans+1;
                    end
                end

                %3회 전송 했는데도 오류 발생시 
                if flag2 == false
                    recovered_bit_data = cat(2, recovered_bit_data, temp);

                else
                    recovered_bit_data = cat(2, recovered_bit_data, -1);
                    drop_count = drop_count+1;
                    flag2 = false;
                end
                % b_data 에 있는 데이터들 전부 전송 완료 했으므로 , data_index 다음부터 다시 전송 시작

            end
            data_index = data_index+2;
            flag = false;





        %QPSK로 다시 전송 
        elseif M==4
            a = b_data(1:2);
            b = b_data(3:4);
            
            % a, b두 가지 반복
            for k = 1:2
                if k==1
                    data = QPSK_bit2data(a);
                else
                    data = QPSK_bit2data(b);
                end

                modulated_symbol = QPSK_Mapping(data);

                flag2 = true;

                for i = 1:3
                    tmp= modulated_symbol * h(h_index) * sqrt(transmit_power) + noise(h_index);
                    received_symbol = tmp/h(h_index);

                    recovered_data = QPSK_DeMapping(received_symbol);
                    temp = QPSK_data2bit(recovered_data);

                    if recovered_data == data
                        flag2 = false;
                        h_index = h_index+1;
                        break;
                    else
                        h_index = h_index+1;
                        retrans = retrans +1; %전체 재전송 횟수 +1
                    end

                % 3회 전송 완료
                end

                if flag2==false
                    recovered_bit_data = cat(2, recovered_bit_data, temp);
                    continue;
                else
                    tmp_bit_data = QPSK_data2bit(data);

                    for l = 1:length(tmp_bit_data)
                        data = tmp_bit_data(l);

                        modulated_symbol = BPSK_Mapping(data);
                        flag3 = true;

                        for i = 1:3
                            tmp= modulated_symbol * h(h_index) * sqrt(transmit_power) + noise(h_index);
                            received_symbol = tmp/h(h_index);

                            recovered_data = BPSK_DeMapping(received_symbol);
                            temp = BPSK_data2bit(recovered_data);

                            if recovered_data == data
                                h_index = h_index+1;
                                flag3 = false;
                                break;
                            else
                                h_index = h_index+1;
                                retrans = retrans +1; %전체 재전송 횟수 +1
                            end
                        end


                        if flag3 == false
                            recovered_bit_data = cat(2, recovered_bit_data, recovered_data);
                        else
                            recovered_bit_data = cat(2, recovered_bit_data, -1);
                            drop_count = drop_count+1;
                        end
                        flag3 = false;
   
                    end

                    flag2 = false;
                end

            end

            flag = false;
            data_index = data_index+4;
            
            


        %M==2 인지 4인지 확인하는 if문 종료
        end

    % 재전송인지, 아닌지 판단 조건문 종료(flag = true인지 false인지)
    end
% while문 종료
end


disp(["전체 재전송 횟수 : ", retrans, "전송 불가 횟수 : ", drop_count, ...
    "비율 : ", drop_count/retrans])







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
            s = s + Repeat_bit_data(nSymbol*(j-1)+i);    
        end
        bit_data(i) = round((s/Repeat_time));
    end

end
