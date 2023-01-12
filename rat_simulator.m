% ================================= Opening / Closing function =====================================
function varargout = rat_simulator(varargin)
    % RAT_SIMULATOR MATLAB code for rat_simulator.fig
    %      RAT_SIMULATOR, by itself, creates a new RAT_SIMULATOR or raises the existing
    %      singleton*.
    %
    %      H = RAT_SIMULATOR returns the handle to a new RAT_SIMULATOR or the handle to
    %      the existing singleton*.
    %
    %      RAT_SIMULATOR('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in RAT_SIMULATOR.M with the given input arguments.
    %
    %      RAT_SIMULATOR('Property','Value',...) creates a new RAT_SIMULATOR or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before rat_simulator_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to rat_simulator_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES

    % Edit the above text to modify the response to help rat_simulator

    % Last Modified by GUIDE v2.5 06-Dec-2020 19:34:41

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @rat_simulator_OpeningFcn, ...
                       'gui_OutputFcn',  @rat_simulator_OutputFcn, ...
                       'gui_LayoutFcn',  [] , ...
                       'gui_Callback',   []);
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end

    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end
    % End initialization code - DO NOT EDIT
end

function rat_simulator_OpeningFcn(hObject, eventdata, handles, varargin)
    
    handles.output = hObject; % was given initially
    global db; % a global database
    
    % debugging string
    handles.debug_str = "=========== debug function ===========" + newline() + ...
    "======================================";
    
    % ================================= for button configuration ===================================
    handles.green_color = [0.392, 0.831, 0.075];
    handles.red_color = [1, 0, 0];
    handles.start_wh_str = 'Start (while-loop)';
    handles.stop_wh_str = 'Stop (while-loop)';
    handles.start_tmr_str = 'Start (timer)';
    handles.stop_tmr_str = 'Stop (timer)';
    
    % ====================================== for timing ============================================
    handles.h_timer = timer('ExecutionMode', 'fixedSpacing', 'Period', 0.001, 'TimerFcn',...
        {@timer_Callback, hObject});
    
    % ================================= for circle plotting ========================================
    
    handles.angles = linspace(0, 2*pi, 100);
    handles.circle_x = 5 * sin(handles.angles);
    handles.circle_y = 5 * cos(handles.angles);
    
    % ============================== plotting and configuration ====================================
    handles.pause_len = 0.03;                                   % the amount of time the simulation will pause in s when the foot shock happens
    handles.default_fig_color = [0.94, 0.94, 0.94];             % default gray color for the figure
    handles.env = Environment();
    init_parameters(handles, hObject)                           % initializes rat array, footshock counter, and iter counter
    handles = guidata(hObject);
    handles.fs_counter_text.String = db.fs_counter;
    handles.array_length = length(handles.rat_array);           % records the array length for the simulation loop
    handles.h_env_ax = handles.env.plot_env(handles.h_sim_ax);  % plots the arena and sets axes to it
    handles.ax_title = title(handles.h_env_ax, ...
        append("iteration number: ", string(db.iter_num)));     % creates a title based on the iteration number
    plot_rats(handles.rat_array, handles.h_env_ax);             % plots rats
    plot_col_circles(handles.h_env_ax, handles.rat_array);      % plots invisible circles for collisions
    
    % ========================================= listeners ==========================================
    
    handles.l_inter_rat = init_rat_col_listeners(handles.rat_array, handles.h_env_ax, hObject,...
        [1, 0, 0], 'inter_rat_col');
    
    handles.l_wall = init_rat_col_listeners(handles.rat_array, handles.h_env_ax, hObject,...
        [0, 1, 0], 'wall_col');
    
    % ================================== file managment ============================================
    
    db.h_txt = fopen('sim_log.txt', 'w');             % creates a txt file 
    write_title_row(db.h_txt, handles.array_length);  % adds the title row
    plot_frame = getframe(handles.h_env_ax);
    im_frame = frame2im(plot_frame);
    imwrite(im_frame, 'sim_frames.tif');
    db.im_array = {};
    guidata(hObject, handles); 
    
    
end

function varargout = rat_simulator_OutputFcn(hObject, eventdata, handles) 

    varargout{1} = handles.output;

end

function h_sim_fig_CloseRequestFcn(hObject, eventdata, handles)
    global db
    stop(handles.h_timer);
    delete(handles.h_timer);
    save_ans = questdlg('Overwrite existing meta-data file?', 'Overwrite?', 'Yes', 'No', 'Yes');
    if length(save_ans) == 3
        generate_m_file(handles);
    end
    save_images(db.im_array);
    fclose(db.h_txt);
    clear db;
    delete(hObject);
    
end
% ======================================== Callbacks ===============================================

function foot_shc_button_Callback(hObject, eventdata, handles)

    global db;
    
    handles.h_sim_fig.Color = 'red'; % visual cue that the rats were shocked
    pause(handles.pause_len);
    
    for rat = handles.rat_array
        rat.foot_shock
    end
    
    handles.h_sim_fig.Color = handles.default_fig_color; % returns default color
    db.fs_counter = db.fs_counter + 1;
    handles.fs_counter_text.String = db.fs_counter;
    guidata(hObject, handles);
end

function start_wh_button_Callback(hObject, eventdata, handles)
    % this function will run an infinite simulation with an option to stop
    % when pressing again using a while loop
    
    persistent is_wh_playing;
    
    if is_wh_playing
        is_wh_playing = 0;
        hObject.ForegroundColor = handles.green_color;
        hObject.String = handles.start_wh_str;
        handles.strat_tmr_button.Enable = 'on';
        return
    end
    
    is_wh_playing = 1;
    hObject.ForegroundColor = handles.red_color;
    hObject.String = handles.stop_wh_str;
    handles.strat_tmr_button.Enable = 'off'; 
    
    while is_wh_playing
        single_sim_loop(handles, hObject);
    end
end

function strat_tmr_button_Callback(hObject, eventdata, handles)
    % this function will run an infinite simulation with an option to stop
    % when pressing again using a timer

    if length(handles.h_timer.Running) == 2 % this allows to check if the timer is 'on'
        stop(handles.h_timer)
        handles.start_wh_button.Enable = 'on';
        hObject.ForegroundColor = handles.green_color;
        hObject.String = handles.start_tmr_str;  
        return
    end
    
    handles.start_wh_button.Enable = 'off';
    hObject.ForegroundColor = handles.red_color;
    hObject.String = handles.stop_tmr_str;
    start(handles.h_timer)
    
end

function timer_Callback(h_tim, eventdata, hObject)
    %runs the simulation loop when activated by the timer
    
    handles = guidata(hObject);
    single_sim_loop(handles, hObject);
end

function rat_col_Callback(rat, eventdata, h_ax, hObject, color)
    % marks a rat with a circle after collision with other objects
    %
    % Inputs:
    %    rat- a rat object
    %    h_ax - axes to plot the cicrcle on
    %    hObject - a graphical object
    %    color - the color of the circle marking
    %
    % Outputs:
    %    none
    
    handles = guidata(hObject);
    location = rat.location;
    
    if length(eventdata.EventName) == 13 % shows a red circle in the rats location if the rat collided with another rat
        rat.h_r_circle.XData = (location(1) + handles.circle_x); % sets x vector
        rat.h_r_circle.YData = (location(2) - handles.circle_y); % sets y vector
        rat.h_r_circle.Visible = 'on';                           % makes the circle visible
        drawnow();                                               % draws graphics
        rat.h_r_circle.Visible = 'off';                          % makes the circle invisible
        
    elseif length(eventdata.EventName) == 8 % shows a green circle in the rats location if the rat collided with another rat
        rat.h_g_circle.XData = (location(1) + handles.circle_x);
        rat.h_g_circle.YData = (location(2) - handles.circle_y);
        rat.h_g_circle.Visible = 'on';
        drawnow();
        rat.h_g_circle.Visible = 'off';  
    end
        
end

% ===================================== debug function =============================================

function debug_button_Callback(hObject, eventdata, handles)
    disp(handles.debug_str)
end

% ==================================== helper functions ============================================

function loc_of_others = create_loc_of_others(rat_index, rat_array)
    % a function that takes an array of Rat objectand creates a new
    % array without one of the rats (given as input)
    %
    % Input:
    %    rat_index - an index for a rat object to exclude from the rest of the rats
    %    rat_array - an array of rat objects for which the location is
    %    returned
    %
    % Output:
    %    loc_of_others - an array (matrix) of rat locations (individual rows)
    
    mat_rows = length(rat_array);                                                % the number of rows based on the amount of other rats
    loc_of_all_rats = reshape([rat_array.location], [2, mat_rows])';             % a prepared matrix of all locations in the given array
    loc_of_others = loc_of_all_rats([1:(rat_index - 1), (rat_index + 1):end], :); % removes the given index from the array
    
end

function rat_array = create_rat_array(env, r_n, or_n, yr_n)
    % a function that creates an array of rats 'on demand'
    %
    % Input:
    %    env - an Environment object
    %    r_n - number of Rat objects
    %    or_n - number of Old_rat objects
    %    yr_n - number of Yong_rat objects
    %
    % Output:
    %    rat_array - an array of rats
    
    all_rats_n = r_n + or_n + yr_n;
    rat_array = Rat.empty();
    locations = env.rand_start(all_rats_n); % locations for the rats
    loc_idx = 0;                            % an index for the rat's location, extracted from 'locations';
    
    for i = 1:r_n % creates normal Rat objects
        loc_idx = loc_idx + 1;
        rat_array(end+1) = Rat(locations(loc_idx, :));
    end
    
    for i = 1:or_n % creates Old rat objects
        loc_idx = loc_idx + 1;
        rat_array(end+1) = Old_rat(locations(loc_idx, :));
    end
    
    for i = 1:yr_n % creates Young rat objects
        loc_idx = loc_idx + 1;
        rat_array(end+1) = Young_rat(locations(loc_idx, :));
    end
end

function plot_rats(rat_array, h_axes)
    % a function that plots rats on given axes, based on a given array
    %
    % Inputs:
    %    rat_array - an array of rat objects
    %    h_axes - an axes object on which the rats will be plotted
    %
    % Output:
    %    none
    
    for rat = rat_array
        hold (h_axes , 'on');
        rat.plot_rat(h_axes);
    end
end

function single_sim_loop(handles, hObject)
    % a function that runs one iteration of the simulation for all rats in
    % an array
    %
    % Input:
    %    handles - handles object
    %
    % Output:
    %    none
    
    global db;
    
    db.iter_num = db.iter_num + 1; % updates the iteration number
    handles.ax_title.String = append("iteration number: ", string(db.iter_num)); % changes title based on iteration progress
    fprintf(db.h_txt, '%1$d\t', db.iter_num); % adds iteration number to txt file
    
    for i = 1:handles.array_length % updates rats
        locs_of_others = create_loc_of_others(i, handles.rat_array);
        handles.rat_array(i).update_rat(handles.env, locs_of_others);
        handles.rat_array(i).plot_rat(handles.h_env_ax);
        fprintf(db.h_txt, '%1$s\t', handles.rat_array(i).get_data_str()); % inserts data to txt file
    end
    
    fprintf(db.h_txt, '\n'); % moves to the next line in txt
    create_im_array(handles.h_env_ax)
    drawnow();
end

function lis_array = init_rat_col_listeners(rat_array, h_ax, hObject, color, event_name)
    % creates an array of listeners for an array of objects.
    %
    % Input:
    %    rat_array - an array of (rat) objects
    %    h_ax - axes to plot the circle on
    %    hObject - a graphical object
    %    color - color of the circle drawn around the mouse
    %    event_name - the name of the event to which to listen
    %
    % Output
    %    lis_array- an array of listeners
    
    array_len = length(rat_array);
    lis_array = cell([1, array_len]);
    for i = 1:array_len
        h_l = addlistener(rat_array(i), event_name, ...
            @(rat, event)rat_col_Callback(rat, event, h_ax, hObject, color));
        lis_array{1, i} = h_l; 
    end

end

function plot_col_circles(h_ax, rat_array)
    % this function will plot a circle for each rat in the array on a given
    % axis
    %
    % Inputs:
    %    h_ax - a handle for axes on which to plot circles
    %    rat_array - an array of Rat objects
    %
    % Outputs:
    %    none
    
    for rat = rat_array
        rat.set_coll_circles(h_ax);
    end
    
end

function init_parameters(handles, hObject)
    % this function will initialize the simulation parameters either from
    % scratch or from a saved file - depending on the users choice
    %
    % Inputs:
    %    handles - handles struct
    %    hObject - a handle to a graphical object
    %
    % Outputs:
    %    none
    global db;
    
    ret_exist = exist('GUI_meta_data.mat', 'file');
    
    if ret_exist % checks if the file exists, if it does, shows question window
        user_ans = questdlg('Load previous experiment?', 'Load old?', 'Yes', 'No', 'Yes');
    end
    
    if ret_exist == 0 || isempty(user_ans) || length(user_ans) == 2 % checks if the user could or did not wand to load existing data
        db.iter_num = 0;                                       % records the number of iterations
        db.fs_counter = 0;                                     % records the number of foot shocks given
        handles.rat_array = create_rat_array(handles.env, 2, 2, 1); % creates an array of rat objects
        
    elseif length(user_ans) == 3                                    % checks if the user did wand to load existing data
        h_mfile = matfile('GUI_meta_data.mat');
        db.iter_num = h_mfile.iter_num;
        db.fs_counter = h_mfile.fs_counter;
        handles.rat_array = h_mfile.rat_array;
    end
    guidata(hObject, handles); % saves the handles
end

function generate_m_file(handles)
    % this function will create a new .m file with simulation parameters
    % depending on the users choice
    %
    % Inputs:
    %    handles - handles struct
    %
    % Outputs:
    %    none
    global db;
    
    rat_array = handles.rat_array;
    iter_num = db.iter_num;
    fs_counter = db.fs_counter;
    for rat = rat_array % set the rat plotting to 0 so they can be plotted again
        rat.was_plotted = 0;
    end
    save('GUI_meta_data.mat', '-v7.3', 'rat_array', 'iter_num', 'fs_counter');
    
end

function write_title_row(h_txt, array_len)
    % this function will create a title row to a textual file, formated as
    % iter num, speed, x location, y location, direction
    %
    % Inputs:
    %    array_len - length of rat array for which to create the title
    %    h_txt - a handle to an open txt file
    %
    % Outputs:
    %    none
    
    fprintf(h_txt, 'iter\t');
    
    for i = 1:array_len
        fprintf(h_txt, 's%1$d\t\tloc%1$d\tdir%1$d\t', i);
    end
    fprintf(h_txt,'\n');
end

function create_im_array(h_ax)
    % this function will create an array of images out of framed axes
    % and insert them to the global variable db 
    %
    % Inputs:
    %    h_ax - a handle to the axes
    %
    % Outputs:
    %    none
    
    global db; 
    plot_frame = getframe(h_ax);     % saves plot frame
    im_frame = frame2im(plot_frame); % creates image from frame
    db.im_array{end+1} = im_frame;   % adds the image to the array

end

function save_images(im_array)
    % this function will save images from an array to the disk
    %
    % Input:
    %    im_array - arrat of .tif images
    %
    % Outputs:
    %    none
    arr_len = length(im_array);            % made for onlt one calculation, not that it matters...
    h_wb = waitbar(0, 'Saving images...'); % a waitbar for clarity
    
    for i = 1:arr_len
        imwrite(im_array{i}, 'sim_frames.tif', 'writemode', 'append'); % appends image to a tif file
        waitbar(i/arr_len, h_wb);
    end
    
    delete(h_wb)
end