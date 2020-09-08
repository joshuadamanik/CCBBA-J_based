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
NUM_DELIVERIES = 2;                             % Number of tasks
NUM_ACTIVITIES = 1;
NUM_BASES = 6;

MAX_XY = 10;
MAX_TRANSIT = 1;
MAX_TASKS_PER_AGENT = 10;

% ADJ_MAT = diag(ones(NUM_AGENTS-1, 1), -1) + diag(ones(NUM_AGENTS-1, 1), 1);
ADJ_MAT = ones(NUM_AGENTS) - eye(NUM_AGENTS);

BASE_POS = [1 2; 5 1; 5 4; 10 4; 2 6; 5 8]';
TASK_POS_TARGET = [1 2; 2 4; 1 3; 3 4; 5 3; 5 6; 6 4];
DELIVERY_POS_TARGET = [1 4; 5 4];

%% Initialization

global agents tasks activities bases deliveries
agents = Agent.empty(1, 0);
tasks = Task.empty(1, 0);
activities = Activity.empty(1, 0);
deliveries = Delivery.empty(1, 0);

for m = 1:NUM_BASES
    bases(m).id = m;
    bases(m).pos = BASE_POS(:, m);
end

for d = 1:NUM_DELIVERIES
    deliveries(d) = Delivery(d);
    deliveries(d).pos = DELIVERY_POS_TARGET(d, 1);
    deliveries(d).target = DELIVERY_POS_TARGET(d, 2);
    deliveries(d).reward = 100;
end

for i = 1:NUM_AGENTS
    agents(i) = Agent(i);
    agents(i).pos = randi(MAX_XY, 2, 1);
    agents(i).Lt = MAX_TASKS_PER_AGENT;
    agents(i).gi = ADJ_MAT(i, :);
end

for k = 1:NUM_ACTIVITIES
    activities(k) = Activity(k);
end

%% Calculating path for tasks


path = [];
path_d = [];
path_m = [];
path_n = [];
path_o = [];
n_path = 1;
nn = 1;
for d = 1:NUM_DELIVERIES
    
    for m = 0:MAX_TRANSIT
        new_path = nchoosek(1:NUM_BASES, m);
        
        for n = 1:size(new_path, 1)
            if ~isempty(new_path) && ( deliveries(d).pos == new_path(n, 1) || deliveries(d).target == new_path(n, end) )
                continue
            end
            
            last_pos = deliveries(d).pos;
            for o = 1:size(new_path, 2)
                path(n_path, :) = [last_pos, new_path(n, o)];
                path_d(n_path) = d;
                path_m(n_path) = m;
                path_n(n_path) = nn;
                path_o(n_path) = o;
                
                n_path = n_path + 1;
                last_pos = new_path(n, o);
            end
            path(n_path, :) = [last_pos, deliveries(d).target];
            path_d(n_path) = d;
            path_m(n_path) = m;
            path_n(n_path) = nn;
            path_o(n_path) = size(new_path, 2) + 1;
            
            n_path = n_path + 1;
            nn = nn + 1;
        end
    end
end


[unique_path, ~, idx_unique] = unique(path, 'rows');

activities(1).dep = zeros(size(unique_path, 1));
% activities(1).temp = 1e+10 * (ones(size(unique_path, 1)) - eye(size(unique_path, 1)));

D_inc = 2;

for u = 1:size(unique_path, 1)
    idx_path = find(ismember(path, unique_path(u,:), 'rows'));
    tasks(u) = Task(u);
    tasks(u).pos = bases(unique_path(u, 1)).pos;
    tasks(u).target = bases(unique_path(u, 2)).pos;
    tasks(u).k = 1;
    tasks(u).reward = sum([deliveries(path_d(idx_path)).reward] ./ (path_m(idx_path) + 1));
    
%     min_occur = min(sum(path_n == path_n(idx_path)', 2));
%     multi_deliveries = length(unique(path_d(idx_path))) > 1;
%     for o = 1:length(idx_path)
% %         min_occur = sum(path_n == path_n(idx_path(o)), 2);
%         q = idx_unique((path_d == path_d(idx_path(o))) & (path_n == path_n(idx_path(o))));
%         q = q(q ~= u);
%         if min_occur > 1 && activities(1).dep(q, u) == 0
%             activities(1).dep(q, u) = 1;
%         elseif min_occur == 1
%             activities(1).dep(q, u) = D_inc;
%             activities(1).dep(u, q) = D_inc;
%             D_inc = D_inc + 1;
%         end
%         
%         q = idx_unique((path_d == path_d(idx_path(o))) & (path_n ~= path_n(idx_path(o))));
%         q = q(q ~= u);
% %         if min_occur == 1
%             q = q(~ismember(q, idx_unique(path_m == 0)));
% %         end
%         activities(1).dep(q, u) = -1;
%     end
%     
%     q = find(activities(1).dep(:, u) == 1);
%     if length(q) > 1
%         activities(1).dep(q, u) = D_inc;
%         D_inc = D_inc + 1;
%     end
end

activities(1).dep = [0	-1	-1	-1	-1	2	-1	0	0	0	0	0	0
-1	0	-1	-1	-1	-1	3	0	0	0	0	0	0
-1	-1	0	-1	-1	-1	-1	1	0	0	0	0	0
-1	-1	-1	0	-1	-1	-1	0	0	0	0	0	0
-1	-1	-1	-1	0	-1	-1	0	0	0	0	0	4
1	-1	-1	-1	-1	0	-1	-1	1	-1	-1	-1	-1
-1	1	-1	-1	-1	-1	0	-1	-1	1	-1	-1	-1
0	0	0	0	0	-1	-1	0	-1	-1	-1	-1	-1
0	0	0	0	0	2	-1	-1	0	-1	-1	-1	-1
0	0	0	0	0	-1	3	-1	-1	0	-1	-1	-1
0	0	0	1	0	-1	-1	-1	-1	-1	0	-1	-1
0	0	0	0	0	-1	-1	-1	-1	-1	-1	0	4
0	0	0	0	1	-1	-1	-1	-1	-1	-1	1	0];



%%

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
%         fprintf('==============================================================\n');
%         fprintf('===   AGENT %d   ==============================================\n', i);
%         fprintf('==============================================================\n');
%         fprintf('\tAgents z:\n');
%         disp_table(get_z(), tasksLabel, agentsLabel);
% 
%         fprintf('\tAgents y:\n');
%         disp_table(get_y(), tasksLabel, agentsLabel);
% 
%         fprintf('\tAgents zeta:\n');
%         disp_table(get_zeta(), tasksLabel, agentsLabel);
%         fprintf('\tAgents z:\n');
%         disp_table(get_z(), tasksLabel, agentsLabel);
        for m = 1:NUM_AGENTS
            if ~ADJ_MAT(i, m)
                continue
            end
            agents(i).conflictRes(t, m, agents(m).gi, agents(m).zi, agents(m).yi, agents(m).si, agents(m).zetai)
%             fprintf('--- Auction with Agent %d ----------------------\n', m);
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