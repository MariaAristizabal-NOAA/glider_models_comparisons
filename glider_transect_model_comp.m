function [timeg_vec, depthg_vec, varg_matrix,timem,depthm,varm] = glider_transect_model_comp(url_glider,model_name,url_model,var,fig,date_ini,date_end)

% Author: Maria Aristizabal on Oct 23 2018

% This funtion returns the gridded matrices needed to plot a glider transect 
% with contour and also returns the same transect from a model output. 
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
% timeg_vec: glider time vector
% depthg_vec: glider depth vector
% varg_vec: glider variable vector
% timem: model time vector
% depthm: model depth vector
% varm: model variable matrix


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
latitude = double(ncread(url_glider,'latitude'));
longitude = double(ncread(url_glider,'longitude'));

% Finding subset of data for time period of interest
ok_time_glider = find(time >= tti & time < tte);

varg = variable(:,ok_time_glider);
presg = pressure(:,ok_time_glider);
timeg = time(ok_time_glider);
latg = latitude(ok_time_glider);
long = longitude(ok_time_glider);

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

% Conversion from glider longitude and latitude to GOFS 3.1 and
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

sublonmod = interp1(timeg,target_lon,timemod(oktimemod));
sublonmod = sublonmod(isfinite(sublonmod));
sublatmod = interp1(timeg,target_lat,timemod(oktimemod));
sublatmod = sublatmod(isfinite(sublatmod));

oklonmod = round(interp1(lonmod,1:length(lonmod),sublonmod));
oklatmod = round(interp1(latmod,1:length(latmod),sublatmod));

target_varmod(length(depthmod),length(oklonmod))=nan;
for i=1:length(oklonmod)
    disp(length(oklonmod))
    disp([model_name,' i=',num2str(i)])
    target_varmod(:,i) = squeeze(double(ncread(url_model,varm,[oklonmod(i) oklatmod(i) 1 oktimemod(i)],[1 1 inf 1])));
end

%% Outputs

[timeg_vec,ok] = sort(timeg);
depthg_vec = pres_gridded;
varg_matrix = var_gridded(:,ok);

timem = timemod(oktimemod);
depthm = depthmod;
varm = target_varmod;

%%

if strcmp(fig,'yes')

siz_text = 20;
siz_title =20;

var_name = ncreadatt(url_glider,var,'ioos_category');
var_units = ncreadatt(url_glider,var,'units');

cc_vec = floor(min(min(varg_matrix))):1:ceil(max(max(varg_matrix)));
    
figure
set(gcf,'position',[327 434 1301 521*2])

subplot(211)
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

%%
subplot(212)
contourf(timem,-depthm,varm,cc_vec,'.--k')
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

%%




set(gca,'fontsize',siz_text)
ylabel('Depth (m)')
title(model_name,'fontsize',siz_title)

c = colorbar;
colormap('jet')
c.Label.String = [var_name,' ','(',var_units,')'];
c.Label.FontSize = siz_text;
caxis([floor(min(varg_vec)) ceil(max(varg_vec))])
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
