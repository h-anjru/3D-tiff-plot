% USER INPUT: TIFF names
elev_tiff = '';
color_tiff = '';

% To plot a subset of the area, modify plot bounds below.

% read each TIFF raster (elevation and reference)
[elev, elev_ref] = readgeoraster(elev_tiff);
[color, color_ref] = readgeoraster(color_tiff);

% search limits of each to determine new limits
x_min = max([elev_ref.XWorldLimits(1) color_ref.XWorldLimits(1)]);
x_max = min([elev_ref.XWorldLimits(2) color_ref.XWorldLimits(2)]);

y_min = max([elev_ref.YWorldLimits(1) color_ref.YWorldLimits(1)]);
y_max = min([elev_ref.YWorldLimits(2) color_ref.YWorldLimits(2)]);

% round values to level of precision of pixels
x_pix = color_ref.CellExtentInWorldX;
y_pix = color_ref.CellExtentInWorldY;

% round min up and max down to stay within bounds
x_min = ceil(x_min / x_pix) * x_pix;
x_max = floor(x_max / x_pix) * x_pix;

y_min = ceil(y_min / y_pix) * y_pix;
y_max = floor(y_max / y_pix) * y_pix;

% create XY mesh for plotting (each XY is center of a pixel)
[X, Y] = meshgrid(x_min:x_pix:x_max, y_min:y_pix:y_max);

% change nodata from -999 to NaN for smoother mapping
elev = changem(elev, NaN, -999);
color = changem(color, 0, -999);

% interpolate each TIFF to align to new grid
elev_interp = mapinterp(elev, elev_ref, X, Y, 'linear');
color_interp = mapinterp(color, color_ref, X, Y, 'linear');

% Each XY point is the center of a pixel. The faces of the surface that is
% to be plotted will not be the pixels of the TIFF, but interpolated faces
% between the center points of each pixel.
%
% The coloring of the surface will also be handled in this manner. Each XYZ
% point will have an associated color from the DOD, but the colors will be
% plotted not on the points but on the interpolated faces.

% USER INPUT: modify plot bounds
plot_northing = [y_min y_max];
plot_easting = [269500 269650];

% convert (N,E) to (row,col)
plot_col = round((plot_easting - x_min) / x_pix) + 1;
plot_row = sort(round((y_max - plot_northing) / y_pix) + 1);

% plot subset of surface
s = surf( ...
    X(plot_row(1):plot_row(2), plot_col(1):plot_col(2)), ...
    Y(plot_row(1):plot_row(2), plot_col(1):plot_col(2)), ...
    elev_interp(plot_row(1):plot_row(2), plot_col(1):plot_col(2)), ...
    color_interp(plot_row(1):plot_row(2), plot_col(1):plot_col(2)) ...
    );

% surface properties
s.FaceColor = 'interp';     % faces span between pixels
s.EdgeAlpha = 0.0;          % set to 0 for plotting large surfaces

% set light angle (azimuth, elevation) for shading
lightangle(135, 30);

% axis and plot properties
ax = gca;

xlabel('Easting [m]');
ylabel('Northing [m]');
zlabel('Elevation [m]');

% proper display of coordinates
ax.XAxis.TickLabelFormat = '%6.0f';
ax.XAxis.Exponent = 0;
ax.YAxis.TickLabelFormat = '%6.0f';
ax.YAxis.Exponent = 0;

axis equal;

% TODO: A custom colormap? try command "colormapeditor"
colormap(jet)

bar = colorbar;
bar.Label.String = 'Change in elevation [m]';  % change label to attribute
bar.FontSize = 12;
