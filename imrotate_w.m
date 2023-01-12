function rot_im = imrotate_w(im, d)
	% Function IMROTATE_W() rotates an image by d degrees counter-clockwise
	%
	% Inputs:
    %     im - A grayscale image.
	%	  d  - degrees, counter-clockwise
	%
	% Outputs:
	%     rot_im - rotated image.
    %
    % Usage:
    %     >> im_rot = imrotate_w(im, 30); % Rotates the image by 30 deg.
	
	if((nargin ~= 2) || ndims(im) == 3)	% Abort execution if number of inputs is not 2 or the image is RGB
		disp('Wrong number of parameters, or their contents. Exiting...');
		return;
	end
	
	max_val = max(im(:));  				% Find the value of the brightest image
	rot_im = max_val - imrotate(max_val - im, d);  % invert the colors, rotate, and invert colors again.
end