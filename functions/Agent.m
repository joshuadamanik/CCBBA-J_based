classdef Agent < handle
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here
    % TODO: TIMEOUT of vi, okq, wsolo, wany
    
    properties
        id
        pos
        Lt
        zi
        zetai
        vi
        bi
        pi
        yi
        si
        wsoloi
        wanyi
    end
    
    methods
        function obj = Agent(id)
            %UNTITLED3 Construct an instance of this class
            %   Detailed explanation goes here
            obj.id = id;
            obj.zi = [];
            obj.vi = [];
            obj.wsoloi = [];
            obj.wanyi = [];
        end
        
        function val = nsat(obj, j)
            global tasks
            q = tasks(j).q();
            activity = tasks(j).activity();
            deps = activity.deps();
            val = 0;
            for u = 1:size(deps, 2)
                j_u = activity.elements(u).id;
                if length(obj.zi) >= j_u && obj.zi(j_u) > 0 && (deps(u, q) == 1)
                    val = val + 1;
                end
            end
        end
        
        function val = mutex1(obj, j, cij)
            global tasks
            q = tasks(j).q();
            activity = tasks(j).activity();
            deps = activity.deps();
            val = 1;
            for u = 1:size(deps, 2)
                j_u = activity.elements(u).id;
                if ~( length(obj.yi) < j_u || cij > obj.yi(j_u) ) && ( deps(u, q) == -1 )
                    val = 0;
                    break;
                end
            end
        end
        
        function val = mutex2(obj, j)
            global tasks
            q = tasks(j).q();
            activity = tasks(j).activity();
            deps = activity.deps();
            val = 1;
            for u = 1:size(deps, 2)
                j_u = activity.elements(u).id;
                if ~( length(obj.yi) < j_u || ( length(obj.yi) >= j && obj.yi(j) > obj.yi(j_u) ) ) && ( deps(u, q) == -1 )
                    val = 0;
                    break;
                end
            end
        end
        
        function val = canBid(obj, j, cij)
            global tasks
            OPTI_STRAT = 1;
            PESS_STRAT = 0;
            
            q = tasks(j).q();
            Nreq = tasks(j).activity().Nreq(q);
            strat = tasks(j).activity().strats(q);
            
            nsat = obj.nsat(j);
            
            if strat == PESS_STRAT
                if nsat == Nreq
                    val = 1;
                else
                    val = 0;
                end
            else
                if ( ( length(obj.wanyi) < j || obj.wanyi(j) < 3 ) && nsat > 0 ) || ...
                   ( length(obj.wsoloi) < j || obj.wsoloi(j) < 3 ) || ( nsat == Nreq )
                    val = 1; % TODO: Change this value to canBid_i(k_q) variable from paper at page 1645
                else
                    val = 0;
                end
            end
            
            val = val && obj.mutex1(j, cij);
        end
        
        function buildBundle(obj)
            global tasks
            
            assert(length(obj.bi) == length(obj.pi), 'Length of bi and pi is not equal');
            
            tasks_id = [tasks.id];
            
            while length(obj.bi) < obj.Lt
                
                avail_tasks = tasks_id(~ismember(tasks_id, obj.bi));

                new_pi = zeros(length(avail_tasks), length(obj.bi) + 1);
                new_ci = zeros(length(avail_tasks), 1);

                for j = 1:length(avail_tasks)

                    curr_cij = obj.calcReward();

                    new_pij = zeros(length(obj.bi) + 1);
                    new_cij = zeros(length(obj.bi) + 1, 1);

                    for n = 1:length(obj.bi) + 1
                        new_pij(n,:) = [obj.pi(1:n-1), avail_tasks(j), obj.pi(n:end)];
                        new_cij(n) = obj.calcReward(new_pij(n,:)) - curr_cij;
                    end

                    [~, n_max] = max(new_cij);
                    new_pi(j,:) = new_pij(n_max,:);
                    new_ci(j) = new_cij(n_max);
                    new_ci(j) = new_ci(j) * obj.canBid(avail_tasks(j), new_ci(j)) * ( length(obj.yi) < avail_tasks(j) || new_ci(j) > obj.yi(avail_tasks(j)) );
                end

                [ci_max, j_max] = max(new_ci);
                
                if ci_max == 0
                    break
                end
                
                obj.bi = [obj.bi, avail_tasks(j_max)];
                obj.pi = new_pi(j_max, :);
                obj.zetai(obj.pi) = obj.calcTime();
                obj.yi(avail_tasks(j_max)) = new_ci(j_max);
                obj.zi(avail_tasks(j_max)) = obj.id;
            end
        end
        
        function reward = calcReward(obj, path)
            global tasks
            if ~exist('path', 'var')
                path = obj.pi;
            end
            
            time = obj.calcTime(path);
            reward = 0;
            for j = 1:length(path)
                reward = reward + exp(-0.01*time(j)) * tasks(path(j)).reward;
            end
        end
        
        function time = calcTime(obj, path)
            global tasks
            SPEED = 15; % m/s
            DIST_PER_SQUARE = 10;
            
            if ~exist('path', 'var')
                path = obj.pi;
            end
            dist = 0;
            time = zeros(1, length(path));
            last_pos = obj.pos;
            for j = 1:length(path)
                dist = dist + DIST_PER_SQUARE * (norm(tasks(path(j)).pos - last_pos) + norm(tasks(path(j)).target - tasks(path(j)).pos));
                time(j) = dist / SPEED;
                last_pos = tasks(path(j)).target;
            end
        end
        
        function conflictRes(obj, t, m, zm, ym, sm)
            obj.si(m) = t;
            
            for j = 1:length(zm)
                if zm(j) == 0
                    if length(obj.zi) < j || obj.zi(j) == 0
                        % LEAVE
                    elseif obj.zi(j) == obj.id
                        % LEAVE
                    elseif obj.zi(j) == m
                        % UPDATE
                        obj.updateRes(j, ym(j), zm(j));
                    else
                        n = obj.zi(j);
                        if length(obj.si) < n || ( length(sm) >= n && sm(n) > obj.si(n) )
                            % UPDATE
                            obj.updateRes(j, ym(j), zm(j));
                        end
                    end
                elseif zm(j) == m
                    if length(obj.zi) < j || obj.zi(j) == 0
                        % UPDATE
                        obj.updateRes(j, ym(j), zm(j));
                    elseif obj.zi(j) == obj.id
                        if ym(j) > obj.yi(j)
                            % UPDATE & RELEASE
                            obj.updateRes(j, ym(j), zm(j));
                            obj.releaseBundle(j);
                        end
                    elseif obj.zi(j) == m
                        % UPDATE
                        obj.updateRes(j, ym(j), zm(j));
                    else
                        n = obj.zi(j);
                        if length(obj.si) < n || ( length(sm) >= n && sm(n) > obj.si(n) ) || ...
                           ym(j) > obj.yi(j)
                            % UPDATE
                            obj.updateRes(j, ym(j), zm(j));
                        end
                    end
                elseif zm(j) == obj.id
                    if length(obj.zi) < j || obj.zi(j) == 0
                        % LEAVE
                    elseif obj.zi(j) == obj.id
                        % LEAVE
                    elseif obj.zi(j) == m
                        % RESET
                        obj.resetRes(j);
                    else
                        n = obj.zi(j);
                        if length(obj.si) < n || ( length(sm) >= n && sm(n) > obj.si(n) )
                            % UPDATE
                            obj.updateRes(j, ym(j), zm(j));
                        end
                    end
                else
                    n = zm(j);
                    if length(obj.zi) < j || obj.zi(j) == 0
                        if length(obj.si) < n || ( length(sm) >= n && sm(n) > obj.si(n) )
                            % UPDATE
                            obj.updateRes(j, ym(j), zm(j));
                        end
                    elseif obj.zi(j) == obj.id
                        if ( length(obj.si) < n || ( length(sm) >= n && sm(n) > obj.si(n) ) ) && ...
                           ym(j) > obj.yi(j)
                            % UPDATE & RELEASE
                            obj.updateRes(j, ym(j), zm(j));
                            obj.releaseBundle(j);
                        end
                    elseif obj.zi(j) == m
                        if length(obj.si) < n || ( length(sm) >= n && sm(n) > obj.si(n) )
                            % UPDATE
                            obj.updateRes(j, ym(j), zm(j));
                        else
                            % RESET
                            obj.resetRes(j);
                        end
                    elseif obj.zi(j) == n
                        if length(obj.si) < n || ( length(sm) >= n && sm(n) > obj.si(n) )
                            % UPDATE
                            obj.updateRes(j, ym(j), zm(j));
                        end
                    else
                        o = obj.zi(j);
                        if ( length(obj.si) < n || ( length(sm) >= n && sm(n) > obj.si(n) ) ) && ...
                           ( length(obj.si) < o || ( length(sm) >= o && sm(o) > obj.si(o) ) ) 
                            % UPDATE
                            obj.updateRes(j, ym(j), zm(j));
                        elseif ( length(obj.si) < n || ( length(sm) >= n && sm(n) > obj.si(n) ) ) && ...
                               ym(j) > obj.yi(j)
                            % UPDATE
                            obj.updateRes(j, ym(j), zm(j));
                        elseif ( length(sm) < n || ( length(obj.si) >= n && obj.si(n) > sm(n) ) ) && ...
                               ( length(obj.si) < o || ( length(sm) >= o && sm(o) > obj.si(o) ) ) 
                            % RESET
                            obj.resetRes(j);
                        end
                    end
                end
            end
            
            j = 1;
            while true
                if j > length(obj.bi)
                    break
                end
                if ~obj.mutex2(obj.bi(j))
                    resetRes(obj, obj.bi(j))
                    obj.releaseBundle(obj.bi(j))
                end
                j = j + 1;
            end
        end
        
        function updateRes(obj, j, ymj, zmj)
            obj.yi(j) = ymj;
            obj.zi(j) = zmj;
        end
        
        function resetRes(obj, j)
            obj.yi(j) = 0;
            obj.zi(j) = 0;
        end
        
        function releaseBundle(obj, j)
            for j_b = 1:length(obj.bi)
                if obj.bi(j_b) == j
                    obj.bi(j_b) = [];
                    break;
                end
            end
            for j_p = 1:length(obj.pi)
                if obj.pi(j_p) == j
                    obj.pi(j_p) = [];
                    break;
                end
            end
        end
    end
end

