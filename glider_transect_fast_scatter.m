
function [timeg_vec, depthg_vec, varg_vec] = glider_transect_fast_scatter(url_glider,var,fig,date_ini,date_end)

% Author: Maria Aristizabal on Oct 19 2018

% This funtion returns the vectors needed to plot a glider transect with the function
% fast_scatter created by John Kerfoot. The glider data is retrieved from
% the glider dac: 'https://data.ioos.us/thredds/dodsC/deployments/';
%
% Inputs:
% url_glider: url address or directory on local computer where the netcdf 
%             file with the glider data resides. Example:
%             'https://data.ioos.us/thredds/dodsC/deployments/rutgers/ng288-20180801T0000/ng288-20180801T0000.nc3.nc'
% var: variable to plot. Ex: 'temperature', 'salinity'. Make sure
%       to use the same name as defined in the netcdf file
% fig: if the value is 'yes' a plot of the glider transect is produced. 
%      'no' the plot is not produced.

% Optional inputs
%
% date_ini: initial date the user wish to visualize the data. Example: '01-Oct-2018 00:00:00'. 
%            If empty, then the default option is the beginning of the record
% date_end: final date the user wish to visualize the data. Example: 12-Oct-2018 00:00:00'.
%          If empty, then the default option is the end of the record
% 

% Outputs:
% time_vec: time vector
% depth_vec: depth vector
% var_vec: variable vactor


%% Glider Extract

inst_id = ncreadatt(url_glider,'/','id');
inst = strsplit(inst_id,'-');
inst_name = inst{1};

time = double(ncread(url_glider,'time'));
time = datenum(1970,01,01,0,0,time);

if ~exist('date_ini','var')
   tti = time(1);
else
   tti = datenum(date_ini); 
end

if ~exist('date_end','var')
   tte = time(end);
else
   tte = datenum(date_end); 
end

variable = double(ncread(url_glider,var));
pressure = double(ncread(url_glider,'pressure'));

% Finding subset of data for time period of interest
ok_time_glider = find(time >= tti & time < tte);

varg = variable(:,ok_time_glider);
presg = pressure(:,ok_time_glider);
timeg = time(ok_time_glider);

%% Outputs

time_mat = repmat(timeg,1,size(varg,1))';
time_vec = reshape(time_mat,1,size(time_mat,1)*size(time_mat,2));
timeg_vec = time_vec';

depth_vec = reshape(presg,1,size(presg,1)*size(presg,2));
depthg_vec = depth_vec';

var_vec = reshape(varg,1,size(varg,1)*size(varg,2));
varg_vec = var_vec';

%%

if strcmp(fig,'yes')

siz_title = 20;
siz_text = 20;
marker.MarkerSize = 16;  

var_name = ncreadatt(url_glider,var,'ioos_category');
var_units = ncreadatt(url_glider,var,'units');
    
figure
set(gcf,'position',[327 434 1301 521])
fast_scatter(timeg_vec,-depthg_vec,varg_vec,'colorbar','vert','marker',marker);

set(gca,'fontsize',siz_text)
ylabel('Depth (m)')
title(['Along track ',var_name,' profile ',inst_name],'fontsize',siz_title)

c = colorbar;
colormap('jet')
c.Label.String = [var_name,' ','(',var_units,')'];
c.Label.FontSize = siz_text;
caxis([floor(min(varg_vec)) ceil(max(varg_vec))])
cc_vec = unique(round(floor(min(varg_vec)):(max(varg_vec)-min(varg_vec))/5:ceil(max(varg_vec))));
set(c,'ytick',cc_vec)

tt_vec = unique(floor([timeg_vec(1),timeg_vec(1)+(timeg_vec(end)-timeg_vec(1))/10:(timeg_vec(end)-timeg_vec(1))/10:timeg_vec(end),timeg_vec(end)]));
xticks(tt_vec)
xticklabels(datestr(tt_vec,'mm/dd/yy'))
xlim([tt_vec(1) time_vec(end)])

ylim([-max(depthg_vec) 0])
yticks(floor(-max(depthg_vec):max(depthg_vec)/5:0))

set(gca,'TickDir','out') 
set(gca,'xgrid','on','ygrid','on','layer','top')

ax = gca;
ax.GridAlpha = 0.3;

end

end
