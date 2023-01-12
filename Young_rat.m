classdef Young_rat < Rat
    % a class that creates a 'young rat' object
    
    methods
        
        function rat = Young_rat(loc)
            % a constructor function for Young_rat objects. which uses the
            % Rat class constructor as well
            %
            % Input:
            %    loc - the location of the rat
            
            rat@Rat(loc);  
            rat.ACCEL_STD = 0.5;
            rat.MAX_SPEED = 4;
            rat.RESCALE_FACT = 1/65;
            rat.QUIVER_SCALING_FACTOR = 10;
            rat.ARROW_C = 'y';
        end
        
    end
end