function [varg, presg, varg_mean, presg_gridded, target_varmod, depthmod_2d, varmod_mean, depthmod] = ...
          glider_profile_model_comp(url_glider,model_name,url_model,var,date_ini,date_end,fig)

% Author: Maria Aristizabal on Oct 25 2018

% This funtion returns all the glider profiles and their average for the user
% defined time window.  
% It also returns the same profile and their average from a model output. 
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
% varg: glider profiles
% presg: glider depths
% varg_mean: mean glider profile
% presg_gridded: gridded depth vector
% target_varmod: profiles from model output
% depthmod_2d: depth matrix for model output
% varmod_mean: mean model profile
% depthmod: depth vector from model output

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

%% Read Model output

%ncdisp(url_model);

depth = 'depth';
time = 'time';

if strcmp(model_name,'GOFS 3.1') || strcmp(model_name,'GOFS 3.0')
    lat = 'lat';
    lon = 'lon';
    if strcmp(var,'temperature')
       varm = 'water_temp';
    end
    if strcmp(var,'salinity')
       varm = 'salinity';
    end
end

if strcmp(model_name,'COPERNICUS')
    lat = 'latitude';
    lon = 'longitude';
    if strcmp(var,'temparature')
       varm = 'thetao';
    end
    if strcmp(var,'salinity')
       varm = 'so';
    end
end
    
latmod = ncread(url_model,lat);
lonmod = ncread(url_model,lon);
depthmod = ncread(url_model,depth);
tim = ncread(url_model,time); % hours since 2000-01-01 00:00:00
timemod = tim/24 + datenum(2000,01,01,0,0,0);

oktimemod = find(timemod >= tti & timemod < tte);
target_timemod = timemod(oktimemod);

% Conversion from glider longitude and latitude to GOFS 3.0 and
% GOFS 3.1 convention
target_lon(1:length(long)) = nan;

if strcmp(model_name,'GOFS 3.1') || strcmp(model_name,'GOFS 3.0')
   for i=1:length(timeg)
       if long(i) < 0 
          target_lon(i) = 360 + long(i);
       else
          target_lon(i) = long(i);
       end
   end
end

if strcmp(model_name,'COPERNICUS') 
   target_lon = long;
end

target_lat = latg;

sublonmod = interp1(timeg,target_lon,timemod(oktimemod),'spline');
%sublonmod = sublonmod(isfinite(sublonmod));
sublatmod = interp1(timeg,target_lat,timemod(oktimemod),'spline');
%sublatmod = sublatmod(isfinite(sublatmod));

oklonmod = round(interp1(lonmod,1:length(lonmod),sublonmod));
oklatmod = round(interp1(latmod,1:length(latmod),sublatmod));

target_varmod(length(depthmod),length(oklonmod))=nan;
for i=1:length(oklonmod)
    disp(length(oklonmod))
    disp([model_name,' i=',num2str(i)])
    target_varmod(:,i) = squeeze(double(ncread(url_model,varm,[oklonmod(i) oklatmod(i) 1 oktimemod(i)],[1 1 inf 1])));
end

%% Mean profiles

% Model
depthmod_2d = repmat(depthmod,[1,length(oklonmod)]);
varmod_mean = mean(target_varmod,2);

% Glider
presg_gridded = 0:0.5:max(max(presg));

varg_gridded(length(presg_gridded),size(presg,2)) = nan;
for i=1:size(presg,2)
    [presu,oku] = unique(presg(:,i));
    varu = varg(oku,i);
    %ok = isfinite(varu);
    ok = isfinite(presu);
    if sum(ok) < 3
       varg_gridded(:,i) = nan;
    else
       varg_gridded(:,i) = interp1(presu(ok),varu(ok),presg_gridded);
    end
end

varg_mean= nanmean(varg_gridded,2);

%% Figure

if strcmp(fig,'yes')

siz_text = 20;
siz_title = 24;
mar_siz = 18;
lgd_siz =18;

var_name = ncreadatt(url_glider,var,'ioos_category');
var_units = ncreadatt(url_glider,var,'units');

figure
set(gcf,'position',[648 171 593 784])

plot(varg,-presg,'.-g','markersize',mar_siz)
hold on
plot(target_varmod,-depthmod_2d,'.-','markersize',mar_siz,'color',[0 0.7 1])
h1 = plot(varg_mean,-presg_gridded,'.-k','markersize',mar_siz,'linewidth',4);
h2 = plot(varmod_mean,-depthmod,'.-b','markersize',mar_siz,'linewidth',4);

lgd = legend([h1 h2],{[inst_name,' ',datestr(timeg(1),'dd-mmm-yyyy HH:MM'),' - ',datestr(timeg(end),'dd-mmm-yyyy HH:MM')],...
             [model_name,' ', datestr(target_timemod(1),'dd-mmm-yyyy HH:MM'),' - ',datestr(target_timemod(end),'dd-mmm-yyyy HH:MM')]},...
             'Location','SouthEast');
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
