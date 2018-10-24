function [timeg_vec, depthg_vec, varg_matrix] = glider_transect_contour(url_glider,var,fig,date_ini,date_end)

% Author: Maria Aristizabal on Oct 19 2018

% This funtion returns the gridded matrices needed to plot a glider transect with contour.
% The glider data is retrieved from the glider dac: 
% url = 'https://data.ioos.us/thredds/dodsC/deployments/';
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
% var_matrix: variable matrix


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

%% Mean profiles

pres_gridded = 0:0.5:max(max(presg));

var_gridded(length(pres_gridded),size(presg,2)) = nan;

for i=1:size(presg,2)
    [presu,oku] = unique(presg(:,i));
    varu = varg(oku,i);
    %ok = isfinite(varu);
    ok = isfinite(presu);
    if sum(ok) < 3
       var_gridded(:,i) = nan;
    else
       var_gridded(:,i) = interp1(presu(ok),varu(ok),pres_gridded);
    end
end

%% Outputs

[timeg_vec,ok] = sort(timeg);
depthg_vec = pres_gridded;
varg_matrix = var_gridded(:,ok);

%%

if strcmp(fig,'yes')

siz_text = 20;
siz_title =20;

var_name = ncreadatt(url_glider,var,'ioos_category');
var_units = ncreadatt(url_glider,var,'units');

cc_vec = floor(min(min(varg_matrix))):1:ceil(max(max(varg_matrix)));

figure
set(gcf,'position',[327 434 1301 521])
contourf(timeg_vec,-depthg_vec,varg_matrix,cc_vec,'.--k')
shading interp

set(gca,'fontsize',siz_text)
ylabel('Depth (m)')
title(['Along track ',var_name,' profile ',inst_name],'fontsize',siz_title)

cc = jet(length(cc_vec)-1);
colormap(cc)
c = colorbar;
c.Label.String = [var_name,' ','(',var_units,')'];
c.Label.FontSize = siz_text;
caxis([floor(min(min(varg_matrix))) ceil(max(max(varg_matrix)))])
set(c,'ytick',cc_vec)

tt_vec = unique(floor([timeg_vec(1),timeg_vec(1)+(timeg_vec(end)-timeg_vec(1))/10:(timeg_vec(end)-timeg_vec(1))/10:timeg_vec(end),timeg_vec(end)]));
xticks(tt_vec)
xticklabels(datestr(tt_vec,'mm/dd/yy'))
xlim([tt_vec(1) timeg_vec(end)])

ylim([-max(depthg_vec) 0])
yticks(floor(-max(depthg_vec):max(depthg_vec)/5:0))

set(gca,'TickDir','out') 
set(gca,'xgrid','on','ygrid','on','layer','top')

ax = gca;
ax.GridAlpha = 0.3;
end

end