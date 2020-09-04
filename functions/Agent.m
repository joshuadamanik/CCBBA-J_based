classdef Agent
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        id
        pos
        Lt
        zi
        vi
        ci
        yi
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
        
        function val = excl(obj, j)
            global tasks
            q = tasks(j).q();
            activity = tasks(j).activity();
            deps = activity.deps();
            val = 1;
            for u = 1:size(deps, 2)
                j_u = activity.elements(u).id;
                if ~( length(obj.ci) >= j && length(obj.yi) >= j_u && obj.ci(j) > obj.yi(j_u) ) && ( deps(u, q) == -1 )
                    val = 0;
                    break;
                end
            end
        end
        
        function val = canBid(obj, j)
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
                if ( length(obj.wanyi) >= j && obj.wanyi(j) > 0 && nsat > 0 ) || ...
                   ( length(obj.wsoloi) < j || obj.wsoloi(j) > 0 ) || ( nsat == Nreq )
                    val = 1; % TODO: Change this value to canBid_i(k_q) variable from paper at page 1645
                else
                    val = 0;
                end
            end
            
            
            val = val && obj.excl(j);
        end
        
        function buildBundle(obj)
            
        end
    end
end
