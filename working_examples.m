
%% mean_glider_profile

% Inputs
url_glider = 'https://data.ioos.us/thredds/dodsC/deployments/rutgers/ru33-20180801T1323/ru33-20180801T1323.nc3.nc';
var = 'temperature';
date_ini = '01-Sep-2018 00:00:00';
date_end = '02-Sep-2018 00:00:00';
fig = 'yes';

[varg,presg,mean_profile,pres_gridded] = mean_glider_profile(url_glider,var,date_ini,date_end,fig);

%% glider_profile_model_comp

% Inputs
url_glider = 'https://data.ioos.us/thredds/dodsC/deployments/rutgers/ru33-20180801T1323/ru33-20180801T1323.nc3.nc';
model_name = 'GOFS 3.1';
url_model = 'http://tds.hycom.org/thredds/dodsC/GLBv0.08/expt_93.0/ts3z';
var = 'temperature';
date_ini = '01-Sep-2018 00:00:00';
date_end = '02-Sep-2018 00:00:00';
fig = 'yes';

[varg, presg, varg_mean, presg_gridded, target_varmod, depthmod_2d, varmod_mean, depthmod] = ...
    glider_profile_model_comp(url_glider,model_name,url_model,var,date_ini,date_end,fig);

%% glider_transect_fast_scatter

% Inputs
url_glider = 'https://data.ioos.us/thredds/dodsC/deployments/rutgers/ru33-20180801T1323/ru33-20180801T1323.nc3.nc';
var = 'temperature';
fig = 'yes';
date_ini = '01-Sep-2018 00:00:00';
date_end = '10-Sep-2018 00:00:00';

[timeg_vec, depthg_vec, varg_vec] = ...
    glider_transect_fast_scatter(url_glider,var,fig,date_ini,date_end);

%% glider_transect_contour

% Inputs
url_glider = 'https://data.ioos.us/thredds/dodsC/deployments/rutgers/ru33-20180801T1323/ru33-20180801T1323.nc3.nc';
var = 'temperature';
fig = 'yes';
date_ini = '01-Sep-2018 00:00:00';
date_end = '10-Sep-2018 00:00:00';

[timeg_vec, depthg_vec, varg_matrix] = ...
    glider_transect_contour(url_glider,var,fig,date_ini,date_end);

%% glider_transect_model_comp

% Inputs
url_glider = 'https://data.ioos.us/thredds/dodsC/deployments/rutgers/ru33-20180801T1323/ru33-20180801T1323.nc3.nc';
model_name = 'GOFS 3.1';
url_model = 'http://tds.hycom.org/thredds/dodsC/GLBv0.08/expt_93.0/ts3z';
var = 'temperature';
fig = 'yes';
date_ini = '01-Sep-2018 00:00:00';
date_end = '02-Sep-2018 00:00:00';

[timeg_vec, depthg_vec, varg_vec,timem,depthm,varm] = ...
    glider_transect_model_comp(url_glider,model_name,url_model,...
    var,fig,date_ini,date_end);

%%

