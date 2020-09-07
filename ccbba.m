clc, close all, clear all
addpath('functions');

rng(1);

global DEBUG_LEVEL
DEBUG_LEVEL = 1;

DEP_AND = 1;
DEP_OR = 2;
DEP_EXC = -1;

TEMP_AFTER = 1;
TEMP_BEFORE = 0;

NUM_AGENTS = 5;                             % Number of agents
NUM_TASKS = 12;                             % Number of tasks
NUM_ACTIVITIES = 2;

MAX_TASKS_PER_AGENT = 10;

MAX_XY = 10;

% ADJ_MAT = diag(ones(NUM_AGENTS-1, 1), -1) + diag(ones(NUM_AGENTS-1, 1), 1);
ADJ_MAT = ones(NUM_AGENTS) - eye(NUM_AGENTS);


%% Agents and Tasks Initialization

global agents tasks activities
agents = Agent.empty(NUM_AGENTS, 0);
tasks = Task.empty(NUM_TASKS, 0);
activities = Activity.empty(NUM_ACTIVITIES, 0);

for i = 1:NUM_AGENTS
    agents(i) = Agent(i);
    agents(i).pos = randi(MAX_XY, 2, 1);
    agents(i).Lt = MAX_TASKS_PER_AGENT;
    agents(i).gi = ADJ_MAT(i, :);
end

for k = 1:NUM_ACTIVITIES
    activities(k) = Activity(k);
end

for j = 1:NUM_TASKS
    tasks(j) = Task(j);
    tasks(j).pos = randi(MAX_XY, 2, 1);
    tasks(j).target = randi(MAX_XY, 2, 1);
    tasks(j).reward = 100;
    tasks(j).k = randi(NUM_ACTIVITIES);
end

tasks(1).dep = [2, 7, 8, 9, 11; DEP_AND, DEP_EXC, DEP_EXC, DEP_EXC, DEP_EXC];
tasks(2).dep = [1, 7, 8, 9, 11; DEP_AND, DEP_EXC, DEP_EXC, DEP_EXC, DEP_EXC];
tasks(1).temp = [2; TEMP_BEFORE; 5];
tasks(7).dep = [8, 1, 2, 9, 11; DEP_AND, DEP_EXC, DEP_EXC, DEP_EXC, DEP_EXC];
tasks(8).dep = [7, 1, 2, 9, 11; DEP_AND, DEP_EXC, DEP_EXC, DEP_EXC, DEP_EXC];
tasks(7).temp = [8; TEMP_BEFORE; 5];
tasks(9).dep = [11, 1, 2, 7, 8; DEP_AND, DEP_EXC, DEP_EXC, DEP_EXC, DEP_EXC];
tasks(11).dep = [9, 1, 2, 7, 8; DEP_AND, DEP_EXC, DEP_EXC, DEP_EXC, DEP_EXC];
tasks(9).temp = [11; TEMP_BEFORE; 5];

tasks(3).dep = [4, 5, 6, 10, 12; DEP_AND, DEP_EXC, DEP_EXC, DEP_EXC, DEP_EXC];
tasks(4).dep = [3, 5, 6, 10, 12; DEP_AND, DEP_EXC, DEP_EXC, DEP_EXC, DEP_EXC];
tasks(3).temp = [4; TEMP_BEFORE; 5];
tasks(5).dep = [6, 3, 4, 10, 12; DEP_AND, DEP_EXC, DEP_EXC, DEP_EXC, DEP_EXC];
tasks(6).dep = [5, 3, 4, 10, 12; DEP_AND, DEP_EXC, DEP_EXC, DEP_EXC, DEP_EXC];
tasks(5).temp = [6; TEMP_BEFORE; 5];
tasks(10).dep = [12, 3, 4, 5, 6; DEP_AND, DEP_EXC, DEP_EXC, DEP_EXC, DEP_EXC];
tasks(12).dep = [10, 3, 4, 5, 6; DEP_AND, DEP_EXC, DEP_EXC, DEP_EXC, DEP_EXC];
tasks(10).temp = [12; TEMP_BEFORE; 5];

% tasks(2).dep = [1; DEP_AND];
% tasks(1).dep = [2; DEP_AND];
% tasks(2).temp = [1; TEMP_BEFORE; 0];
% tasks(1).temp = [2; TEMP_AFTER; 0];
% tasks(11).dep = [9; DEP_AND];
% tasks(11).temp = [9; TEMP_AFTER; 0];

fprintf('\tAgents Position:\n');
disp([agents.pos]);

fprintf('\tTasks Position:\n');
disp([tasks.pos]);

fprintf('\tTasks Activity:\n');
disp([tasks.k]);

for k = 1:NUM_ACTIVITIES
    fprintf('\tActivity %d Dependencies:\n', k);
    label = compose('%d', [activities(k).elements().id]);
    disp_table([activities(k).deps();
                activities(k).strats();
                activities(k).Nreq()], ...
               label, [label, {'Strat'}, {'Nreq'}]);
    fprintf('\tActivity %d Temporal Constraints:\n', k);
    disp_table(activities(k).temps(), label, label);
end

tasksLabel = compose('%d', [tasks.id]);
agentsLabel = compose('%d', [agents.id]);

%% Iteration

% agents(1).zi = [0 0 0 2 3];
% agents(1).ci(2) = 1000;
% agents(1).yi(5) = 999;
fprintf('\tAgents z:\n');
disp_table(get_z(), tasksLabel, agentsLabel);

for t = 1:100
    for i = 1:NUM_AGENTS
        agents(i).buildBundle();
%         fprintf('\tAgents z:\n');
%         disp_table(get_z(), tasksLabel, agentsLabel);
        for m = 1:NUM_AGENTS
            if ~ADJ_MAT(i, m)
                continue
            end
            agents(i).conflictRes(t, m, agents(m).gi, agents(m).zi, agents(m).yi, agents(m).si, agents(m).zetai)
%             fprintf('\tAgents z:\n');
%             disp_table(get_z(), tasksLabel, agentsLabel);
% 
%             fprintf('\tAgents y:\n');
%             disp_table(get_y(), tasksLabel, agentsLabel);
% 
%             fprintf('\tAgents zeta:\n');
%             disp_table(get_zeta(), tasksLabel, agentsLabel);
        end
%         fprintf('\tAgents z:\n');
%         disp_table(get_z(), tasksLabel, agentsLabel);
    end
    fprintf('\tAgents z:\n');
    disp_table(get_z(), tasksLabel, agentsLabel);

    fprintf('\tAgents y:\n');
    disp_table(get_y(), tasksLabel, agentsLabel);

    fprintf('\tAgents zeta:\n');
    disp_table(get_zeta(), tasksLabel, agentsLabel);
    
end

plotGridWorld;


%% Function

function disp_table(mat, VariableNames, RowNames)
    disp(array2table(mat, 'VariableNames', VariableNames, 'RowNames', RowNames));
end

function mat = get_y()
    global agents tasks
    mat = zeros(length(agents), length(tasks));
    for i = 1:length(agents)
        for j = 1:length(agents(i).yi)
            mat(i, j) = agents(i).yi(j);
        end
    end
end

function mat = get_z()
    global agents tasks
    mat = zeros(length(agents), length(tasks));
    for i = 1:length(agents)
        for j = 1:length(agents(i).zi)
            mat(i, j) = agents(i).zi(j);
        end
    end
end

function mat = get_zeta()
    global agents tasks
    mat = zeros(length(agents), length(tasks));
    for i = 1:length(agents)
        for j = 1:length(agents(i).zetai)
            mat(i, j) = agents(i).zetai(j);
        end
    end
end

function mat = get_nsat()
    global agents tasks
    mat = zeros(length(agents), length(tasks));
    for i = 1:length(agents)
        for j = 1:length(tasks)
            mat(i, j) = agents(i).nsat(j);
        end
    end
end

function mat = get_canBid()
    global agents tasks
    mat = zeros(length(agents), length(tasks));
    for i = 1:length(agents)
        for j = 1:length(tasks)
            mat(i, j) = agents(i).canBid(j);
        end
    end
end