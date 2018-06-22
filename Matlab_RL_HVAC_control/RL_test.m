function [eplus_in_curr, userdata] = RadiantControlFileBaseline(cmd,eplus_out_prev, eplus_in_prev, time, stepNumber, userdata)
if strcmp(cmd,'init')
  addpath('./RL_lib_test2')
  % for 24h - 720 timesteps (30 steps/h); 1440(60st/h)
  % For four days 96h - 384 (4st/h)
epsilon1 = 0.7; % Initial value
epsilon2 = 0.7; % Initial value
epsilon3 = 0.7; % Initial value

discount = 0.8;
learnRate = 0.99;
  successRate =1;
  % Temperature setpoint and actual temp state space definition
  tsps = [15:0.2:26];
  temps = tsps;  % setting the same
  actions = [0, -0.1, 0.1];
  powers = [0:50:12000];
 % [states, R, Q] = RL_setup_test(tsps, temps, powers, actions);
    
  load Q1.mat;
  load Q2.mat;
  load Q3.mat;
  load states.mat
  load R.mat
  % Eligibility trace
E = zeros(size(Q1));
   
   z3 = [20, 15, 0];
   z2 = [20, 15, 0];
   z1 = [20, 15, 0];
    [next_state, state_index3] = min(abs(sum(states - repmat(z3,[size(states,1),1]).^2, 2)));
      
       if (rand()>epsilon1) && rand()<=successRate
        	[~,action_idx3] = max(Q3(state_index3,:)); % Pick the action the Q matrix thinks is best!
       else
             action_idx3 = randi(length(actions),1); % Random action!
       end
    action_idx3
    act = actions(action_idx3); % Taking  chosen action
    eplus_in_prev
  %%    Update  Q matrix (z1 has to be updated at this step)
  z3_new = [20, eplus_out_prev.temp3(end), eplus_out_prev.Power1(end)];
  z2_new = [20, eplus_out_prev.temp2(end), eplus_out_prev.Power2(end)];
  z1_new = [20, eplus_out_prev.temp1(end), eplus_out_prev.Power3(end)];
 [~, new_state_index3] = min(sum(abs(states - repmat(z3_new,[size(states,1),1])).^2, 2)); % Interpolate again to find the new state the system is closest to.
 %OLD_one = Q(next_state_index, action_idx)
 %% Updating Action-Value function with Sarsa | Q - value function V
  Q3(state_index3, action_idx3) = Q3(state_index3,action_idx3) + learnRate * ( R(new_state_index3) ...
      + discount*max(Q3(new_state_index3,:)) - Q3(state_index3,action_idx3));
    Q2(state_index3, action_idx3) = Q2(state_index3,action_idx3) + learnRate * ( R(new_state_index3) ...
      + discount*max(Q2(new_state_index3,:)) - Q2(state_index3,action_idx3));
    Q1(state_index3, action_idx3) = Q1(state_index3,action_idx3) + learnRate * ( R(new_state_index3) ...
      + discount*max(Q1(new_state_index3,:)) - Q1(state_index3,action_idx3));
  
  userdata.currState3 = z3_new;
  userdata.currState2 = z2_new;
  userdata.currState1 = z1_new;
  eplus_in_curr.tsp1 = 20+act;
  eplus_in_curr.tsp2 = 20+act;
  eplus_in_curr.tsp3 = 20+act;
  userdata.old_tsp3 =  eplus_in_curr.tsp3;
  userdata.old_tsp2 =  eplus_in_curr.tsp2;
  userdata.old_tsp1 =  eplus_in_curr.tsp1;
  userdata.Q1 = Q1;
  userdata.Q2 = Q2;
  userdata.Q3 = Q3;
  userdata.states = states;
  userdata.R = R;
  save('./RL_lib_test2/Q1.mat','Q1');
  save('./RL_lib_test2/Q2.mat','Q2');
  save('./RL_lib_test2/Q3.mat','Q3');
  save('./RL_lib_test2/states.mat','states');
  save('./RL_lib_test2/R.mat','R');
  
epsilonDecay = 0.999; % Decay factor per iteration.
epsilon1 = epsilon1*epsilonDecay;
epsilon2 = epsilon2*epsilonDecay;
epsilon3 = epsilon3*epsilonDecay;
  userdata.epsilon1 = epsilon1;userdata.epsilon2 = epsilon2;userdata.epsilon3 = epsilon3;
elseif strcmp(cmd,'normal')
    
   z3_new = [eplus_in_prev.tsp3(end), eplus_out_prev.temp3(end), eplus_out_prev.Power1(end)];
   z2_new = [eplus_in_prev.tsp2(end), eplus_out_prev.temp2(end), eplus_out_prev.Power2(end)];
   z1_new = [eplus_in_prev.tsp1(end), eplus_out_prev.temp1(end), eplus_out_prev.Power3(end)];
   temperature = [z1_new(2),z2_new(2),z3_new(2)]
   Q3 = userdata.Q3;
   Q2 = userdata.Q2;
   Q1 = userdata.Q1;
   addpath('./RL_lib_test2')
   %load Q.mat;
   R = userdata.R;
   actions = [ 0, -0.1, 0.1];
   states = userdata.states;
   %%
successRate = 1;
epsilon1 = userdata.epsilon1; % Initial value
epsilon2 = userdata.epsilon2; % Initial value
epsilon3 = userdata.epsilon3; % Initial value
epsilonDecay = 0.98; % Decay factor per iteration.

discount = 0.8;
learnRate = 0.99;  
   %% curr state
    z3 = userdata.currState3;
    z2 = userdata.currState2;
    z1 = userdata.currState1;

     [~, state_index3] = min(sum(abs(states - repmat(z3,[size(states,1),1])).^2, 2));
     [~, state_index2] = min(sum(abs(states - repmat(z2,[size(states,1),1])).^2, 2));
     [~, state_index1] = min(sum(abs(states - repmat(z1,[size(states,1),1])).^2, 2));
           
       action_idx3 = ChooseAction(epsilon3, succRate, actions, state_index3,Q3);
       action_idx2 = ChooseAction(epsilon2, succRate, actions, state_index2,Q2);
       action_idx1 = ChooseAction(epsilon1, succRate, actions, state_index1,Q1);
           
        act3 = actions(action_idx3); % Taking  chosen action (which way change TSP)
        act2 = actions(action_idx2);
        act1 = actions(action_idx1);
         
   %% New state acquired 
z3_new
 [~, new_state_index3] = min(sum(abs(states - repmat(z3_new,[size(states,1),1])).^2, 2)); % Interpolate again to find the new state the system is closest to.
next_action_idx3 = ChooseAction(epsilon3, succRate, actions, new_state_index3,Q3);

 q_target3 = error(discount,  R(new_state_index3), Q3(new_state_index3,next_action_idx3),  Q3(state_index3,action_idx3));
 
 %--------------------------------------------------------------------
  [~, new_state_index2] = min(sum(abs(states - repmat(z2_new,[size(states,1),1])).^2, 2)); % Interpolate again to find the new state the system is closest to.
next_action_idx2= ChooseAction(epsilon2, succRate, actions, new_state_index2,Q2);

 q_target2 = error(discount,  R(new_state_index2), Q2(new_state_index2,next_action_idx2),  Q2(state_index2,action_idx2));
 %_-----------------------------------------------------------------------------------
  [~, new_state_index1] = min(sum(abs(states - repmat(z1_new,[size(states,1),1])).^2, 2)); % Interpolate again to find the new state the system is closest to.
next_action_idx1 = ChooseAction(epsilon1, succRate, actions, new_state_index1,Q1);

 q_target1 = error(discount,  R(new_state_index3), Q3(new_state_index3,next_action_idx3),  Q3(state_index3,action_idx3));
    % Output
    indexes = [ state_index1, new_state_index1;state_index2, new_state_index2;state_index3, new_state_index3;]
%     epsilon
    
  %  Best_Q = discount*max(Q3(new_state_index3,:));
     % ---------------------------------------------------------------------------------------------
    userdata.currState3 = z3_new;
    userdata.currState2 = z2_new;
    userdata.currState1 = z1_new;
    eplus_in_curr.tsp1 = userdata.old_tsp1 + act1;
    eplus_in_curr.tsp2 = userdata.old_tsp2 + act2;
    eplus_in_curr.tsp3 = userdata.old_tsp3 + act3;
         
    userdata.old_tsp3 = eplus_in_curr.tsp3;
    userdata.old_tsp2 = eplus_in_curr.tsp2;
    userdata.old_tsp1 = eplus_in_curr.tsp1;
    
    userdata.Q3 = Q3;
    userdata.Q2 = Q2;
    userdata.Q1 = Q1;
    %TSPs = [ userdata.old_tsp1, userdata.old_tsp3, userdata.old_tsp3]
    stepNumber
    if  stepNumber> 1435
            save('./RL_lib_test2/Q1.mat','Q1');
            save('./RL_lib_test2/Q2.mat','Q2');
            save('./RL_lib_test2/Q3.mat','Q3');
            disp 'Data saved ____________________'
    end
 epsilon1 = epsilon1*epsilonDecay;
 epsilon2 = epsilon2*epsilonDecay;
 epsilon3 = epsilon3*epsilonDecay;
userdata.epsilon1 = epsilon1;
userdata.epsilon2 = epsilon2;
userdata.epsilon3 = epsilon3;
end
