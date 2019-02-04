

function [varg,presg,mean_profile,pres_gridded] = mean_glider_profile(url_glider,var,date_ini,date_end,fig)

% Author: Maria Aristizabal on Oct 25 2018

% This funtion returns all the glider profiels and their average for a time window.  
% The glider data is retrieved from
% the glider dac: 'https://data.ioos.us/thredds/dodsC/deployments/'
% There are three choices of models: GOFS 3.1, GOFS 3.0 or COPERNICUS

%
% Inputs:
% url_glider: url address or directory on local computer where the netcdf 
%             file with the glider data resides. Example:
%             'https://data.ioos.us/thredds/dodsC/deployments/rutgers/ng288-20180801T0000/ng288-20180801T0000.nc3.nc'
% url_model: url address or directory on local computer where the netcdf 
%            file with the model output resides. Example for GOFS 3.1:
%            'http://tds.hycom.org/thredds/dodsC/GLBv0.08/expt_93.0/ts3z' 
% var: variable to plot. Ex: 'temperature', 'salinity'. Make sure
%       to use the same name as defined in the netcdf file
%
% date_ini: initial date the user wish to visualize the data. Example: '01-Oct-2018 00:00:00'. 
% date_end: final date the user wish to visualize the data. Example: 02-Oct-2018 00:00:00'.
% fig: if the value is 'yes' a plot of the variable profile is produced. 
%      'no' the plot is not produced.
% 

% Outputs:
% varg: all the glider profiles within the user defined time window
% presg: depth vector fot all profiles
% meand_profile: mean of all glider profiles
% pres_gridded: gridded depth vector


%% Glider Extract

inst_id = ncreadatt(url_glider,'/','id');
inst = strsplit(inst_id,'-');
inst_name = inst{1};

time = double(ncread(url_glider,'time'));
time = datenum(1970,01,01,0,0,time);

tti = datenum(date_ini); 
tte = datenum(date_end); 

variable = double(ncread(url_glider,var));
pressure = double(ncread(url_glider,'pressure'));
latitude = double(ncread(url_glider,'latitude'));
longitude = double(ncread(url_glider,'longitude'));

% Finding subset of data for time period of interest
ok_time_glider = find(time >= tti & time < tte);

varg = variable(:,ok_time_glider);
presg = pressure(:,ok_time_glider);
timeg = time(ok_time_glider);
latg = latitude(ok_time_glider);
long = longitude(ok_time_glider);

% Mean lat and lon
latm = mean(latg);
lonm = mean(long);

%% Mean profiles

pres_gridded = 0:0.5:max(max(presg));

var_gridded(length(pres_gridded),size(presg,2)) = nan;

for i=1:size(presg,2)
    [presu,oku] = unique(presg(:,i));
    varu = varg(oku,i);
    okd = isfinite(presu);
    presf = presu(okd);
    varf = varu(okd);
    ok = isfinite(varf);
    if sum(ok) < 3
       var_gridded(:,i) = nan;
    else
       var_gridded(:,i) = interp1(presf(ok),varf(ok),pres_gridded);
    end
end

mean_profile= nanmean(var_gridded,2);

%% Figure

if strcmp(fig,'yes')

siz_text = 20;
siz_title = 24;
mar_siz = 12;
lgd_siz =18;

var_name = ncreadatt(url_glider,var,'ioos_category');
var_units = ncreadatt(url_glider,var,'units');

figure
set(gcf,'position',[648 171 593 784])

plot(varg,-presg,'.-g','markersize',mar_siz)
hold on
h1 = plot(varg(:,1),-presg(:,1),'.-g','markersize',mar_siz);
hold on
h2 = plot(mean_profile,-pres_gridded,'.-k','markersize',mar_siz,'linewidth',4);

lgd = legend([h1 h2],{[inst_name,' ',datestr(timeg(1)),'-',datestr(timeg(end))],...
    'Mean glider profile'},'Location','SouthEast');
set(lgd,'fontsize',lgd_siz)

set(gca,'fontsize',siz_text)
ylabel('Depth (m)')
title({[var_name,' profile ',inst_name],...
    ['Mean [lat , lon] = ','[',num2str(round(latm,2)),' , ',num2str(round(lonm,2)),']']},...
    'fontsize',siz_title)
xlabel([var_name,' (',var_units,')'])

set(gca,'TickDir','out') 
set(gca,'xgrid','on','ygrid','on','layer','top')

ax = gca;
ax.GridAlpha = 0.4;

end