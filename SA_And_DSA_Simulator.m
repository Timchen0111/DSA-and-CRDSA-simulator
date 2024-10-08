clear all; close all; clc;
sourceNumber = 150;
N_sc = 48;
N_EDT = 4;
%carrier_state = zeros(1,carrier_num); %Boolean
%Traffic generation
rate = 0.61;%FEC coding rate
M = 4;%Modulation: QPSK
N_pk = 0;%Average number of packets, related to G
T_EDT = 1;%Single EDT duration
packet_bit =328;%Packet bit length
replica_set = [1, 2, 3]; % DSA
count=1;
simulationTime=1e4;
%total_num = EDT_occasion_num*carrier_num;
%需重新考慮traffic load 計算方式
%Test for different number of carrier
%for lambda=[0:0.2:8] %Simulation for different traffic load.
for idx = 1:length(replica_set)
    N_replica = replica_set(idx); % 当前replica数
    %Packet_loss_ratio = zeros(length(replica_set), 91); 
    count = 1;
    for G= 0:1:90 %Simulation for different traffic load. Unit: kbps
        %Generate Poisson arrival
        G_ = G*1000;
        N_pk = G_*T_EDT/packet_bit;
        lambda = N_pk;%Calculate average number of packets
        % 0: idle source
        % 1: active
        attemptSource = zeros(N_EDT,N_sc);
        pcktTransmissionAttempts = 0;
        %nodeDelay = zeros(1, sourceNumber);
        %sumDelay=0;
        ackdPacketCount = 0;
        sendPacketCount = 0;
        pcktCollisionCount = 0;
        burstSlot = 0;
        pr = 1 - exp(-lambda/sourceNumber);  % 根據 Poisson 分佈來計算傳輸機率 此行導致throughput不隨UE量增加，因throughput只受lambda影響
        %fileID = fopen('lambda5.txt','w');
        time = 0;
        while time < simulationTime
            time = time+1;%Time pass by
            sourceStatus = zeros(1,sourceNumber);
            %fprintf(fileID, 'slot = %i \n'
            % , currentSlot);
            transmissionAttemptsEachSlot = zeros(N_EDT,N_sc);
            for source = 1:sourceNumber %For each UE
                if rand(1) <= pr % new packet coming
                    sendPacketCount = sendPacketCount+1;
                    sourceStatus(source) = 1; %Not decoded
                    Chosen_EDT_set = randperm(N_EDT,N_replica);
                    for replica = 1:N_replica
                        Chosen_carrier = randi(N_sc);
                        Chosen_EDT = Chosen_EDT_set(replica);
                        transmissionAttemptsEachSlot(Chosen_EDT,Chosen_carrier) = transmissionAttemptsEachSlot(Chosen_EDT,Chosen_carrier)+1;
                        attemptSource(Chosen_EDT,Chosen_carrier) = source; %Record the UE transmitting packet
                    end
                end
            end
            for i = 1:N_EDT
                for j = 1:N_sc
                    if transmissionAttemptsEachSlot(i,j) == 1 %No collision, not has been decoded
                        CurrentUE = attemptSource(i,j);
                        if sourceStatus(CurrentUE) == 1
                            ackdPacketCount = ackdPacketCount + 1;
                            sourceStatus(CurrentUE) = 0;
                        end
                    %elseif transmissionAttemptsEachSlot(i,j)>1 %Collision happens CRDSA需要，先不刪去 
                        %pcktCollisionCount = pcktCollisionCount+1;
                    end
                end
            end            
        end       
        Packet_loss_ratio(idx,count) = 1 - ackdPacketCount / sendPacketCount;
        count=count+1
    end
end
load = 0:1:90;
throughput = load.*(1-Packet_loss_ratio);
%% plot
figure(1)
plot(load(1,:),throughput(1,:), '-','color','red')
hold on;
plot(load(1,:),throughput(2,:), '-','color','green')
hold on;
plot(load(1,:),throughput(3,:), '-','color','blue')
%plot(carrier_number(1,:),throughput(1,:), '-x')
title('Average Throughput')
xlabel('G (Offered Traffic)')
%xlabel('number of frequency carriers')
ylabel('Average Throughput')
legend('SA', 'DSA N=2', 'DSA N=3','location','best'); % 添加图例
hold on;
grid on
%Collision_prob = log10(Collision_prob);
figure(2)
plot(load(1,:),Packet_loss_ratio(1,:), '-','color','red')
hold on;
plot(load(1,:),Packet_loss_ratio(2,:), '-','color','green')
hold on;
plot(load(1,:),Packet_loss_ratio(3,:), '-','color','blue')
title('Packet Loss Ratio')
xlabel('G (Offered Traffic)')
%xlabel('number of frequency carriers')
set(gca, 'YScale', 'log');
ylabel('Packet Loss Ratio')
legend('SA', 'DSA N=2', 'DSA N=3','location','best'); % 添加图例
hold on;
grid on
