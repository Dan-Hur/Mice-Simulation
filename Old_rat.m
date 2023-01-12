classdef Old_rat < Rat
    % a class that creates an 'old rat' object
    
    methods
        
        function rat = Old_rat(loc)  
            % a constructor function for Old_rat objects. which uses the
            % Rat class constructor as well
            %
            % Input:
            %    loc - the location of the rat
            
            rat@Rat(loc);
            rat.ACCEL_STD = 0.1;
            rat.MAX_SPEED = 1.5;
            rat.RESCALE_FACT = 1/35;
            rat.QUIVER_SCALING_FACTOR = 10;
            rat.ARROW_C = 'k';
            rat.coll_spd = 0.5;
        end
        
    end
end