clear all; close all; clc;
sourceNumber = 150;
N_sc = 48;
N_EDT = 3;
%carrier_state = zeros(1,carrier_num); %Boolean
%Traffic generation
rate = 0.61;%FEC coding rate
M = 4;%Modulation: QPSK
N_pk = 0;%Average number of packets, related to G
T_EDT = 1;%Single EDT duration
packet_bit =328;%Packet bit length
count=1;
simulationTime=1e4;
%total_num = EDT_occasion_num*carrier_num;
%需重新考慮traffic load 計算方式
%Test for different number of carrier
%for lambda=[0:0.2:8] %Simulation for different traffic load.
for G= 0:1:90 %Simulation for different traffic load. Unit: kbps
        %Generate Poisson arrival
        G_ = G*01000;
        N_pk = G_*T_EDT/packet_bit;
        lambda = N_pk;%Calculate average number of packets
        sourceStatus = zeros(1,sourceNumber);
        Record_carrier = zeros(1,sourceNumber);
        Record_EDT = zeros(1,sourceNumber);
        % 0: idle source
        % 1: active
        attemptSource = zeros(N_EDT,N_sc);
        pcktTransmissionAttempts = 0;
        %nodeDelay = zeros(1, sourceNumber);
        %sumDelay=0;
        ackdPacketCount = 0;
        pcktCollisionCount = 0;
        burstSlot = 0;
        pr = 1 - exp(-lambda/sourceNumber);  % 根據 Poisson 分佈來計算傳輸機率 此行導致throughput不隨UE量增加，因throughput只受lambda影響
        %fileID = fopen('lambda5.txt','w');
        time = 0;
        while time < simulationTime
            time = time+1;%Time pass by
            %fprintf(fileID, 'slot = %i \n'
            % , currentSlot);
            transmissionAttemptsEachSlot = zeros(N_EDT,N_sc);
            %Memoryless Bernoulli trial (May need modification)
            for source = 1:sourceNumber %For each UE
                if sourceStatus(source) == 0 && rand(1) <= pr % new packet coming
                    sourceStatus(source) = 1; 
                    %nodeDelay(source)=0;
                    Chosen_carrier = randi(N_sc);
                    Chosen_EDT = randi(N_EDT);
                    Record_carrier(source) = Chosen_carrier;
                    Record_EDT(source) = Chosen_EDT;
                    transmissionAttemptsEachSlot(Chosen_EDT,Chosen_carrier) = transmissionAttemptsEachSlot(Chosen_EDT,Chosen_carrier)+1;
                    pcktTransmissionAttempts = pcktTransmissionAttempts+1;
                    attemptSource(Chosen_EDT,Chosen_carrier) = source; %Record the UE transmitting packet
                    %fprintf(fileID, 'station %d is transmitting new packet \n', source);
                elseif sourceStatus(source)==1 % active packet
                    %nodeDelay(source) = nodeDelay(source)+1;
                    Chosen_carrier = Record_carrier(source);
                    Chosen_EDT = Record_EDT(source);
                    if rand(1) <= pr %Keep transmitting
                        transmissionAttemptsEachSlot(Chosen_EDT,Chosen_carrier) = transmissionAttemptsEachSlot(Chosen_EDT,Chosen_carrier)+1;
                        pcktTransmissionAttempts = pcktTransmissionAttempts+1;
                        attemptSource(Chosen_EDT,Chosen_carrier) = source;
                        %fprintf(fileID, 'station %d is transmitting backlogged packet \n', source);
                    end
                end
            end
            for i = 1:N_EDT
                for j = 1:N_sc
                    if transmissionAttemptsEachSlot(i,j) == 1 %No collision
                        ackdPacketCount = ackdPacketCount + 1;
                        %sumDelay = sumDelay+nodeDelay(attemptSource);
                        sourceStatus(attemptSource(i,j)) = 0;
                        Record_EDT(attemptSource(i,j)) = 0;
                        Record_carrier(attemptSource(i,j)) = 0;
                        %fprintf(fileID, 'station %d packet is successfull with delay %d \n', attemptSource, nodeDelay(attemptSource));
                    elseif transmissionAttemptsEachSlot(i,j)>1 %Collision happens 
                        pcktCollisionCount = pcktCollisionCount+1;
                        %Now, no retransmission
                        sourceStatus(attemptSource(i,j)) = 0;
                        Record_EDT(attemptSource(i,j)) = 0;
                        Record_carrier(attemptSource(i,j)) = 0;
                        %fprintf(fileID, 'COLLISION Happens \n');
                    end
                end
            end
            
        end
        
        %trafficOffered(1,count) = pcktTransmissionAttempts / time;
        %     if ackdPacketCount == 0
        %         meanDelay = simulationTime; % theoretically, if packets collide continously, the delay tends to infinity
        %     else
        %         meanDelay = sumDelay/ackdPacketCount;
        %     end
        Collision_prob(1,count) = pcktCollisionCount / (ackdPacketCount+pcktCollisionCount);
        %fclose(fileID);
        count=count+1
end
load = 0:1:90;
throughput = load.*(1-Collision_prob);
%% plot
figure(1)
plot(load(1,:),throughput(1,:), '-x')
%plot(carrier_number(1,:),throughput(1,:), '-x')
title('Average Throughput of Finite-Station Slotted ALOHA')
xlabel('G (Offered Traffic)')
%xlabel('number of frequency carriers')
ylabel('Average Throughput')
hold on;
grid on
%Collision_prob = log10(Collision_prob);
figure(2)
plot(load(1,:),Collision_prob(1,:), '-x')
title('Collision Probability of Finite-Station Slotted ALOHA')
xlabel('G (Offered Traffic)')
%xlabel('number of frequency carriers')
set(gca, 'YScale', 'log');
ylabel('Collision Prob')
hold on;
grid on
