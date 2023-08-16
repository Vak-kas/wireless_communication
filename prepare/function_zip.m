clear variables;
clc;
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


