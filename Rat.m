classdef Rat < handle & matlab.mixin.Heterogeneous
    % a class that creates a 'rat' object
    
    properties
        
        location = [0, 0];   
        direction;
        speed;
        h_im;
        h_q;
        was_plotted = 0;    % check if the specific rat was plotted for better plot manipulation
        ACCEL_STD = 0.2;
        MAX_SPEED = 2;
        DIR_STD = 15;
        RESCALE_FACT = 1/50;
        QUIVER_SCALING_FACTOR = 10;
        ARROW_C = 'r';
        FOOT_SHOCK_SPD = 2  % a speed to be added to the rat after a foot shock
        
        hitbox = 2
        coll_spd = 1; % the rat will slow down to this speed when it collides
        
        % circle plot handles for use in collision
        h_r_circle; 
        h_g_circle;
        
    end
    
    properties (Constant)
        
        image = imread('rat_single.tif');
        animation_cycle_unit = 2;
        
    end
    
    events
        inter_rat_col
        wall_col
    end
    
    methods
        
        function rat = Rat(loc)
            % constructor function for rat objects 
            %
            % Input (optional):
            %   loc - the rat's location, formated as [x, y]
            %
            % Output:
            %   rat - Rat object
            
            if nargin == 1
                rat.location = loc;
            end
            
            rat.speed = unifrnd(0, rat.MAX_SPEED);
            rat.direction = unifrnd(0, 360);

        end
        
        function im = get_image(rat)
            % a function that loads and roates the rat image  
            %
            % Inputs:
            %     rat - Rat object.
            % Outputs:
            %     im - a handle to the rotated image (matrix)
            %
            % i substract the direction from 360 since the rotation of imrotate is counter clockwise,
            % as opposed to the direction of rotation in rat.direction (if
            % i understtod correctly from your explaination).
            
            ccw_deg = 360 - rat.direction; % converting the rat's cw degrees to the imrotate ccw degrees
                
            if (ccw_deg >= 0) && (ccw_deg <= 90) % first quadrant
                im = imrotate_w(rat.image, ccw_deg); 

            elseif (ccw_deg > 90) && (ccw_deg <= 270) % second and third quadrants
                im = imrotate_w(flipud(rat.image), ccw_deg);
                
            elseif (ccw_deg > 270) && (ccw_deg <= 360) % fourth quadrant
                im = imrotate_w(rat.image, ccw_deg);
            end
        end
        
        function arrow = create_arrow(rat, ax)
            %this function creates a custom arrow based on the rat
            %properties
            %
            % Inputs:
            %     rat - Rat object.
            %     ax - an axes handle (optional)
            % Outputs:
            %     arrow - a vector that will be shown in the beginning of
            %     the axes
            
            SCALING_FACTOR = rat.QUIVER_SCALING_FACTOR; % needed for the arrow to be seen well
            
            X = rat.location(1); % the middle of the given pictures x axis
            Y = rat.location(2); % the middle of the given pictures y axis
            U = SCALING_FACTOR * rat.speed * cosd(rat.direction); % x component
            V = SCALING_FACTOR * rat.speed * sind(rat.direction); % y component
            % adding axes if given
            if nargin == 2
                arrow = quiver(ax, X, Y, U, V, rat.ARROW_C, 'LineWidth', 1);
            else
                arrow = quiver(X, Y, U, V, rat.RROW_C, 'LineWidth', 1);
            end
        end
        
        function h_im = plot_rat(rat, h_ax)
            % a function that plots the rat based on an image matrix (rat.image) with a
            % corresponding arrow
            %
            % Inputs:
            %
            %     rat - Rat object.
            %     h_ax (optional) - axis handle
            %
            % Outputs:
            %
            %     h_im - a handle to the plotted image
            
            % the next line gets rescaled image boundarys for the given
            % image
            img = rat.get_image();
            [lower_x_bound, upper_x_bound, lower_y_bound , upper_y_bound] = rat.get_rat_bounds(img);
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%% next block is for changing plotted rat's position %%%%%%%%%%%%%%%%%%%%

            if (nargin > 1) && (rat.was_plotted == 1) % checks if a rat was plotted on axes
                rat.plot_change(img);                 % changes the plotted rat's location on the axes
                h_im = rat.h_im;                      % returns h_im since the function needs to return it
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%% next block is for ploting a rat on given axes %%%%%%%%%%%%%%%%%%%%%

            elseif nargin > 1 % checking if hadle was given
                h_im = imshow(img, 'Parent' ,h_ax);
                
                % next placing and scaling the rat on the axes
                h_im.XData = ([lower_x_bound, upper_x_bound]); % placing the rat in the correct location on the x axis and scaling
                h_im.YData = ([lower_y_bound, upper_y_bound]); % placing the rat in the correct location on the y axis and scaling
                
                hold(h_ax, 'on');
                h_quiv = rat.create_arrow(h_ax); % creates the arrow on top of the image
                rat.h_im = h_im;                 % transfers the image handle to the rat object
                rat.h_q = h_quiv;                % transfers the quiver handle to the rat object
                rat.was_plotted = 1;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%% next block is for ploting a rat on it's own axis %%%%%%%%%%%%%%%%%%%
            else
                h_rat_fig = figure('name', 'rat image');
                h_rat_ax = axes(h_rat_fig);
                h_im = imshow(img, 'Parent', h_rat_ax);  
                
                % next placing and scaling the rat on the axes
                h_im.XData = ([lower_x_bound, upper_x_bound]);  % placing the rat in the correct location on the x axis and scaling
                h_im.YData = ([lower_y_bound, upper_y_bound]);  % placing the rat in the correct location on the y axis and scaling
                h_rat_ax.XLim = ([lower_x_bound, upper_x_bound]); % scaling the x axis
                h_rat_ax.YLim = ([lower_y_bound, upper_y_bound]); % scaling the y axis
                
                hold(h_rat_ax, 'on');
                h_quiv = rat.create_arrow(h_rat_ax); % creates the arrow on top of the image
                rat.h_im = h_im;                     % transfers the image handle to the rat object
                rat.h_q = h_quiv;                    % transfers the quiver handle to the rat object
                rat.was_plotted = 1;
            end
        end
        
        function loc_change(rat)
            % updates the rats location based on 2 times speed in the rats
            % current direction
            %
            % Inputs:
            %     rat - Rat object
            % Outputs:
            %     none
            
            CYCLE_UNIT = rat.animation_cycle_unit; % units of speed moved per cycle
            
            loc_delta_X = (rat.speed * CYCLE_UNIT) * cosd(rat.direction); % x component change
            loc_delta_Y = (rat.speed * CYCLE_UNIT) * sind(rat.direction); % y component change
            
            new_x = rat.location(1) + loc_delta_X;
            new_y = rat.location(2) + loc_delta_Y;
            
            rat.location = [new_x, new_y];
        end
        
        function update_rat(rat, env, loc_of_others)
           % this function updates the rat's direction, speed and then location
           %
           % Inputs:
           %     rat - Rat object.
           %     env - an Environment object.
           %     loc_of_others - location matrix of other rats
           % Outputs:
           %     none
           
           delta_d = rat.dir_change(); % the change in the direction
           delta_s = rat.spd_change(); % the change in the speed
           
           new_dir = rat.direction + delta_d;
           new_spd = rat.speed + delta_s;
           
           % next i check that the direction is not over 360 and if speed
           % is out of range
           correct_dir = Rat.correct_deg(new_dir);
           correct_spd = rat.correct_speed(new_spd);
           
           %next, check wall collision, and change direction accordingly
           wall_coll_dir = env.check_wall_collision(rat);
           rat_coll = check_rat_coll(rat, loc_of_others);
           
           if wall_coll_dir ~= -1 % checks if the rat collided, and changes it's direction
               correct_dir = wrapTo360(wall_coll_dir + normrnd(180, 20)); % changes the rat's direction
               correct_spd = rat.coll_spd;                                % slows down mouse when collided (I think it's more realistic, it's not really necessary)
               notify(rat, 'wall_col');
           end
           
           if rat_coll == 1 % checks if the rat collided with other rats
               correct_dir = wrapTo360(correct_dir + normrnd(90, rat.DIR_STD)); % changes the rat's direction
               correct_spd = rat.coll_spd;                                      % slows down mouse when collided
               notify(rat, 'inter_rat_col');
           end
           
           % next i update the direction, speed and the location of the rat
           rat.direction = correct_dir;
           rat.speed = correct_spd;
           rat.loc_change();
           
        end
        
        function [lower_x_bound, upper_x_bound, ...
                lower_y_bound, upper_y_bound] = get_rat_bounds(rat, img)
            % this function returns the given images picture boundarys based on the given rat's location.
            % this will allow to place the img in the location of the rat,
            % with the corrects scaling, by returning the correct XData and
            % YData boundarys
            %
            % Inputs:
            %     rat - a Rat object, to be used for location on axes and
            %     scaling
            %     img - an image to be scaled and placed correctly based on
            %     the given rat
            %
            % Outputs:
            %     lower_x_bound - lowest x value of the scaled picture
            %     upper_x_bound - highest x value of the scaled picture
            %     lower_y_bound - lowest y value of the scaled picture
            %     upper_y_bound - highest y value of the scaled picture

            
            img_x = length(img(1, :)) ; % the images x length
            img_y = length(img(:, 1)) ; % the images y length
            lower_x_bound = rat.location(1) - (img_x .* rat.RESCALE_FACT / 2); % lower boundary for ploting the rat on the x axis
            upper_x_bound = rat.location(1) + (img_x .* rat.RESCALE_FACT / 2); % upper boundary for ploting the rat on the x axis
            lower_y_bound = rat.location(2) - (img_y .* rat.RESCALE_FACT / 2); % lower boundary for ploting the rat on the y axis
            upper_y_bound = rat.location(2) + (img_y .* rat.RESCALE_FACT / 2); % upper boundary for ploting the rat on the y axis
        end
        
        function plot_change(rat, img)
            % this function will change plotted rat's location and rotation
            %
            % Inputs:
            %     rat - a Rat object, to be used for placing on the figure,
            %     using it's handles
            %     img - an image matrix for plotting the rat anew
            %
            % Outputs:
            %     None
            
            SCALING_FACTOR = 10; % should be the same as in create_arrow() function
            
            [lower_x_bound, upper_x_bound, lower_y_bound , upper_y_bound] = rat.get_rat_bounds(img);
            rat.h_im.CData = img;                              % for raotating the rat if the given image is rotated
            rat.h_im.XData = ([lower_x_bound, upper_x_bound]); % placing the rat in the correct location on the x axis and scaling
            rat.h_im.YData = ([lower_y_bound, upper_y_bound]); % placing the rat in the correct location on the y axis and scaling
            rat.h_q.XData = rat.location(1);                   % changing quiver x position
            rat.h_q.YData = rat.location(2);                   % changing quiver y position
            rat.h_q.UData = SCALING_FACTOR * rat.speed * cosd(rat.direction); % changing quiver x component
            rat.h_q.VData = SCALING_FACTOR * rat.speed * sind(rat.direction); % changing quiver y component
            
        end
       
        function loc_of_others = get_loc_of_others(rat)
            % this function will return a matrix of the locations of other
            % rats
            %
            % Input:
            %    rat - Rat object
            %
            % Output:
            %    loc_of_others - a matrix of the location of other rats
            
            mat_rows = length(rat.list_of_others); % the number of rows based on the amount of other rats
            loc_of_others = zeros(mat_rows, 2);    % a prepared matrix
            
            for i = 1:mat_rows % goes over indices  %AK: Extract fields of object array by >> fields = [obj_arr.field];
                loc_of_others(i, :) = rat.list_of_others(i).location; % inserts locations to the matrix
            end
        end
        
        function ret = check_rat_coll(rat, loc_of_others)
            % this function checks for a rat if it collided with other rats
            %
            % Inputs:
            %    rat - Rat object
            %    loc_of_others - location matrix of other rats
            %
            % Output
            %    ret - a retuned value based on collision - if the rat
            %    collided return 1, else return 0
            
            mat_rows = length(loc_of_others);
            ret = 0;
            rat_x_front = rat.location(1) + rat.hitbox;
            rat_x_back = rat.location(1) - rat.hitbox;
            rat_y_front = rat.location(2) + rat.hitbox;
            rat_y_back = rat.location(2) - rat.hitbox;
            
            for i = 1:mat_rows
                % the next condition basically checks if the rat's hitbox
                % collides with the hitbox of others
                if (((rat_x_front) > loc_of_others(i, 1) - rat.hitbox) &&...      % front to back x collision
                        ((rat_x_back) < loc_of_others(i, 1) + rat.hitbox)) && ... % back to front x collision                  
                        (((rat_y_front) > loc_of_others(i, 2) - rat.hitbox) &&... % front to back y collision
                        ((rat_y_back) < loc_of_others(i, 2) + rat.hitbox))        % back to front y collision
                    
                    ret = 1;
                end

            end
        end
        
        function foot_shock(rat)
            % this function simulates a foot shock for the rat by
            % increasing it's speed
            %
            % Input:
            %    rat- a Rat object
            %
            % Output:
            %    None
            
            rat.speed = rat.speed + rat.FOOT_SHOCK_SPD;
        end
        
        function delta_d = dir_change(rat)
            % a function that calculated the direction change for the rat
            % object based on a normal distribution, with a probability of
            % 0.1
            %
            % Input:
            %     none
            % Output:
            %     delta_d  = the change in direction based on a normal
            %     distribution
            
            DEG_PROB = 0.1; % the probability to change direction
            D_MEAN = 0;
            D_STDEV = rat.DIR_STD;
            
            if Rat.p_ber(DEG_PROB) == 1 
                delta_d = normrnd(D_MEAN, D_STDEV);
            else
                delta_d = 0;
            end
        end
        
        function cor_spd = correct_speed(rat, spd)
            % corrects the rats speed to be according to wanted max and not
            % lower than 0
            %
            % Input:
            %     spd - the speed to be checked
            % Output:
            %     cor_spd = the corrected speed
            
            MAX_SPD = rat.MAX_SPEED;
            MIN_SPEED = 0;
            
            if spd <= MAX_SPD && spd >= MIN_SPEED
                cor_spd = spd;
            
            elseif spd > MAX_SPD
                cor_spd = MAX_SPD;
            
            elseif spd < MIN_SPEED
                cor_spd = MIN_SPEED;
            end     
        end
        
        function delta_s = spd_change(rat)
            % this function will calculate a speed change for the mouse,
            % based on a normal distribution with a probability of 0.4
            %
            % Input:
            %     none
            % Output:
            %     delta_d  = the change in direction based on a normal
            %     distribution
            
            SPEED_PROB = 0.4; % the probability to change speed
            S_MEAN = 0;
            S_STDEV = rat.ACCEL_STD;
            
            if Rat.p_ber(SPEED_PROB) == 1
                delta_s = normrnd(S_MEAN, S_STDEV);
            else
                delta_s = 0;
            end
        end
        
        function data_str = get_data_str(rat)
            % this function will return a string with the rat's data,
            % formated as - speed, x location, y location, direction.
            %
            % Inputs:
            %    rat - Rat object
            %
            % Outputs:
            %    data_str - a formated string with the rat's parameters
            
            data_str = sprintf('%1$.1f\t%2$.1f\t%3$.1f\t%4$.1f',...
                rat.speed, rat.location(1), rat.location(2), rat.direction);
        end
        
        function set_coll_circles(rat, h_ax)
           % this function will create handles to circles plotted for use in collision, 
           % and set them to the class variables
           %
           % Inputs:
           %     rat- a Rat object
           %     h_ax - handle to axes on which the circles will be plotted
           %
           % Outputs:
           %     none
           
           angles = linspace(0, 2*pi, 100);
           circle_x = 5 * sin(angles);
           circle_y = 5 * cos(angles);
           line_width = 5;
           
           rat.h_r_circle = scatter(h_ax, (0 + circle_x), (0 - circle_y), ...
               line_width, 'filled', 'MarkerFaceColor', 'r');
           rat.h_r_circle.Visible = 'off';
           
           hold(h_ax, 'on');
           
           rat.h_g_circle = scatter(h_ax, (0 + circle_x), (0 - circle_y), ...
               line_width, 'filled', 'MarkerFaceColor', 'g');
           rat.h_g_circle.Visible = 'off';
           
        end
    end
    
    methods (Static)
        function val = p_ber(p_head)
            % returns a result of a coinflip
            % p_head is the chance to get heads
            %
            % Input:
            %     p_head - probability between 0 and 1
            % Output:
            %     val = result of bernoulli experiment with the given
            %     probability
            
            val = binornd(1, p_head);  %AK: OK, other way is >> val = rand() < p_head;
        end
        
        function deg = correct_deg(in_deg)   %AK: Checkout >> new_deg = wrapTo360(old_deg);  :) %% should i swap to it?
            % this function will calculate the correct degree, meaning that
            % if a degree bigger than 360 is given, it will be converted to
            % a corresponding degree under 360.
            
            % Input:
            %     in_deg - the degree to be checked
            % Output:
            %     deg - the corrected degree
            
            if in_deg > 360 % i did this so the rat can change directions continously, rather than
                            % limiting the rotation to 360
                deg = (in_deg - 360);
                
            elseif in_deg < 0 % to not have negative degrees, i convert them to the equivalent 
                              % degree in the correct quadrant
                deg = 360 + in_deg;
            else
                deg = in_deg;
            end
        end

    end  
end
