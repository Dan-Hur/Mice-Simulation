classdef Environment < handle
   % a class that creates an environment object
   
   properties (Constant)
       RADIUS = 50
       CENTER = [0, 0]
       BOUNDARY = 5
       x_axis = [1, 0]
   end
   
   methods
            
       function coll_dir = check_wall_collision(env, rat)
            % Function CHECK_WALL_COLLISION() checks for collision of a rat
            % with the arena wall
            %
            % Inputs:
            %     env - Environment object
            %     rat - object of class Rat.
            %
            % Output:
            %     coll_dir - scalar (angle) that indicates the direction of
            %     the wall relative to the rats location. The angle
            %     is confined to [0 360). If the rat didn't collide
            %     with the wall: coll_dir = -1;
            %
            % Usage:
            % >> env.check_wall_collision(rat);
            
            if env.did_rat_col(rat) == 1
                coll_dir = Environment.calc_angle(env.x_axis, rat.location);
            else
                coll_dir = -1;
            end
            
       end
       
       function coll = did_rat_col(env, rat)
           % this function checks if the rat collided with the boundary
           %
           % Input:
           %     env - Environment object
           %     rat - Rat object
           %
           % Output:
           %     coll - boolean answer: 1 if collided, 0 if not
           
           rat_vec = sqrt((rat.location(1) ^ 2) + (rat.location(2) ^ 2));
           coll = (rat_vec > (env.RADIUS - (env.BOUNDARY + rat.hitbox))); 
       end
       
       function h_env_ax = plot_env(env, h_ax)
           % function plot_env() creates a new figure with the round
           % arena plotted on top.
           % The arena represented by a white circle, the area
           % off-bounds is painted in black.
           %
           % Input:
           %     h_fig (Optional) - a handle to a figure
           % Output:
           %     h_env_ax - handle to axes with the arena.
           %
           % Usage:
           % h_ax = env.plot_env();
           
           % here I create the arena matrix
           [X, Y] = ndgrid(-env.RADIUS:0.1:env.RADIUS, -env.RADIUS:0.1:env.RADIUS);
           arena = double((X.^2 + Y.^2) < (env.RADIUS ^ 2));
           eight_bit_arena = uint8(arena.* 255);
           
           %here I create the figure and axes, and the plot
           
           if nargin == 2 % the handle to the figure is decided based on if a handle was given.
               h_env_ax = h_ax;
           else
               h_env_fig = figure('name', 'Arena');
               h_env_ax = axes(h_env_fig);
           end
           
           h_env_img = imshow(eight_bit_arena, 'Parent', h_env_ax);
           
           % next i place it correctly on the axes
           h_env_img.XData =  [-env.RADIUS, env.RADIUS];
           h_env_img.YData =  [-env.RADIUS, env.RADIUS];
           h_env_ax.XLim = [-env.RADIUS, env.RADIUS];
           h_env_ax.YLim = [-env.RADIUS, env.RADIUS];
           
       end
       
       function loc = create_valid_loc(env)
           % this fuction will create a random coordinate between BOUNDARY
           % and the edge of the arena
           %
           % Input:
           %     env - an Environment object
           % Output:
           %     loc - a random valid coordinate vector [x, y]
           
           r = randi([env.BOUNDARY, env.RADIUS]);
           deg = randi([0, 360]);
           
           x = r * cosd(deg);
           y = r * sind(deg);
           
           loc = [x, y];
       end
       
       function loc_mat = rand_start(env, n)
           % this fuction will generate a matrix of locations, in the form
           % of n * 2, the rows being an [x, y] coordinate.
           % each location mus be in a valid location in respect to the
           % arena and the other locations
           %
           % Input:
           %     env - an Environment object
           %     n  - number of locations to be created
           % Output:
           %     loc_mat a matrix of valid random location
           
           loc_mat = zeros(n, 2);
           
           for i = 1:n
               loc = env.create_valid_loc();        % generates a random location in the correct range
               
               while ismember(loc, loc_mat, 'rows') % make sure the generated location wasn't generated before
                   loc = env.create_valid_loc();
               end
               
               loc_mat(i, 1:2) = loc;               % inserts the location to the matrix

           end
       end

   end
   
   methods (Static)
       
       function deg = calc_angle(v1, v2)
           % Function calc_angle() calculates the angle that has to be added to
           % v1 in order to rotate it to the direction of v2. Example: [1 0]
           % has to be rotated 45 deg clockwise to point towards [1 1]
           % (according to the inverted Y axis, as produced by MATLAB imaging functions)
           %
           % Inputs: 
           %    v1 - 1x2 matrix with [x, y] values of the first vector.
           %    v2 - 1x2 matrix with [x, y] values of the second vector.
           %
           % Output:
           %    deg - The angle from v1 to v2. Format: scalar, range [0 360)
           %
           % Usage:
           %    >> ang = calc_angle([1, 0], [1, 1]); % Returns [45]

            [ang1, ~] = cart2pol(v1(1), v1(2));
            [ang2, ~] = cart2pol(v2(1), v2(2));
            deg = wrapTo360(rad2deg(ang2 - ang1));
       end
       
       function show_tracks()
           % this function will ask the user for a txt file, and use it to
           % plot the trajectory of a user specified (by index) rat 
           %
           % Inputs & Outputs:
           %     none
           
           [f_name, f_path] = uigetfile('.txt', 'Select data file'); % gets a file
           
           if isequal(f_name, 0) || isequal(f_path, 0) % checks if a file was chosen
               disp('no file was chosen');
               return
           else
               full_file = fullfile(f_path, f_name);
           end
           
           user_indx = inputdlg('Rat number?', '',  1, {'1'}); % gets a rat index from the user
           if isempty(user_indx) || isempty(user_indx{1})
              disp('no number was inserted');
              return
           else
               rat_idx = str2double(user_indx);
           end
           
           x_col_idx = 3 + ((rat_idx-1) * 4); % the col of x locations, starts at 3 with jumps of 4 between rats
           y_col_idx = 4 + ((rat_idx-1) * 4); % the col of y locations, starts at 4 with jumps of 4 between rats
           
           % the next try block will catch an error resulting from bad rat
           % indexing (if the user inserts '0' or an index higher than the
           % number of rats in the simulation). in addition this will catch
           % errors regarding bad file formating
           try
               data_mat = readmatrix(full_file, 'NumHeaderLines',1); % loads matrix data
               x_col = data_mat(:, x_col_idx);
               y_col = data_mat(:, y_col_idx);
           catch err
               disp('Bad rat index given, or incorrec file format');
               return
           end
           
           % next - plotting
           h_fig = figure('Name', 'Figure 2');
           title_str = sprintf('Rat No. %1$s - Trajectory', user_indx{1});
           h_ax = axes(h_fig, 'Title', title_str);
           color_ls = linspace(1, 10, length(x_col));
           plot(h_ax, x_col, -y_col);
           hold(h_ax, 'on');
           scatter(h_ax, x_col, -y_col, 25, color_ls, 'filled');
           h_ax.XTick = (-50:10:50); % sets ticks to be in jumps of 10
           h_ax.XLim = [-50, 50];
           h_ax.YLim = [-50, 50];
           h_ax.XLabel.String = 'X';
           h_ax.YLabel.String = 'Y';
           
       end
   end
end