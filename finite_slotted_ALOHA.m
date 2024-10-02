clear all; close all; clc;
sourceNumber = 10;
carrier_num = 1;
%carrier_state = zeros(1,carrier_num); %Boolean
%Adapt QPSK
count=1;
simulationTime=1e5;
EDT_occasion_num = 1;
%total_num = EDT_occasion_num*carrier_num;
%需重新考慮traffic load 計算方式
%Test for different number of carrier
for lambda=[0:0.2:8] %Simulation for different traffic load.
%lambda = 2;
%for carrier_num = 1:30
        sourceStatus = zeros(1,sourceNumber);
        Record_carrier = zeros(1,sourceNumber);
        Record_EDT = zeros(1,sourceNumber);
        % 0: idle source
        % 1: active
        attemptSource = zeros(EDT_occasion_num,carrier_num);
        pcktTransmissionAttempts = 0;
        %nodeDelay = zeros(1, sourceNumber);
        %sumDelay=0;
        ackdPacketCount = 0;
        pcktCollisionCount = 0;
        burstSlot = 0;
        pr=lambda/sourceNumber; %此行導致throughput不隨UE量增加，因throughput只受lambda影響
        %fileID = fopen('lambda5.txt','w');
        time = 0;
        while time < simulationTime
            time = time+1;%Time pass by
            %fprintf(fileID, 'slot = %i \n'
            % , currentSlot);
            transmissionAttemptsEachSlot = zeros(EDT_occasion_num,carrier_num);
            %Memoryless Bernoulli trial (May need modification)
            for source = 1:sourceNumber %For each UE
                if sourceStatus(source) == 0 && rand(1) <= pr % new packet coming
                    sourceStatus(source) = 1;
                    %nodeDelay(source)=0;
                    Chosen_carrier = randi(carrier_num);
                    Chosen_EDT = randi(EDT_occasion_num);
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
            for i = 1:EDT_occasion_num
                for j = 1:carrier_num
                    if transmissionAttemptsEachSlot(i,j) == 1 %No collision
                        burstSlot = burstSlot + 1; 
                        ackdPacketCount = ackdPacketCount + 1;
                        %sumDelay = sumDelay+nodeDelay(attemptSource);
                        sourceStatus(attemptSource(i,j)) = 0;
                        Record_EDT(attemptSource(i,j)) = 0;
                        Record_carrier(attemptSource(i,j)) = 0;
                        %fprintf(fileID, 'station %d packet is successfull with delay %d \n', attemptSource, nodeDelay(attemptSource));
                    elseif transmissionAttemptsEachSlot(i,j)>1 %Collision happens
                        burstSlot = burstSlot + 1; 
                        pcktCollisionCount = pcktCollisionCount+1;
                        %fprintf(fileID, 'COLLISION Happens \n');
                    end
                end
            end
            
        end
        
        trafficOffered(1,count) = pcktTransmissionAttempts / time;
        %     if ackdPacketCount == 0
        %         meanDelay = simulationTime; % theoretically, if packets collide continously, the delay tends to infinity
        %     else
        %         meanDelay = sumDelay/ackdPacketCount;
        %     end
        allslot = time*EDT_occasion_num*carrier_num;
        throughput(1,count) = ackdPacketCount / allslot;
        pcktCollisionProb(1,count) = pcktCollisionCount / burstSlot;
        %fclose(fileID);
        count=count+1
end

%% plot
figure(1)
carrier_number = 1:30;
plot(trafficOffered(1,:),throughput(1,:), '-x')
%plot(carrier_number(1,:),throughput(1,:), '-x')
title('Average Throughput of Finite-Station Slotted ALOHA')
xlabel('G (Offered Traffic)')
%xlabel('number of frequency carriers')
ylabel('Average Throughput')
hold on;
G=[0:0.2:8];
%S=G.*(1-G/10).^(10-1);
%plot(G,S);
%hold on;
%plot(trafficOffered(2,:),throughput(2,:), '-s')
%hold on;
%S=G.*(1-G/25).^(25-1);
%plot(G,S);
%hold on;
%plot(trafficOffered(3,:),throughput(3,:), '-o')
%hold on;
%S=G.*(1-G/50).^(50-1);
%plot(G,S);
%legend('simulation, M=10', 'analytical, M=10','simulation, M=25', 'analytical, M=25', 'simulation, M=50', 'analytical, M=50');
grid on

figure(2)
plot(trafficOffered(1,:),pcktCollisionProb(1,:), '-x')
%plot(carrier_number(1,:),pcktCollisionProb(1,:), '-x')
title('Collision Probability of Finite-Station Slotted ALOHA')
xlabel('G (Offered Traffic)')
%xlabel('number of frequency carriers')
ylabel('Collision Prob')
hold on;
G=[0:0.2:8];
%S=1-G.*(1-G/10).^(10-1)-(1-G/10).^(10);
%plot(G,S);
%hold on;
%plot(trafficOffered(2,:),pcktCollisionProb(2,:), '-s')
%hold on;
%S=1-G.*(1-G/25).^(25-1)-(1-G/25).^(25);
%plot(G,S);
%hold on;
%plot(trafficOffered(3,:),pcktCollisionProb(3,:), '-o')
%hold on;
%S=1-G.*(1-G/50).^(50-1)-(1-G/50).^(50);
%plot(G,S);
%legend('simulation, M=10', 'analytical, M=10','simulation, M=25', 'analytical, M=25', 'simulation, M=50', 'analytical, M=50');
grid on
