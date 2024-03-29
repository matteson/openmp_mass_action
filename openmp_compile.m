clear all
clc

%%
path(path,'M_files')

%%
m1 = sbioloadproject('models/Merged_1.sbproj');
m1 = m1.m1;

num_kf = length(m1.reactions); %I think this requires all reactions to have forward component
num_kr = length(sbioselect(m1,'Type','reaction','Where','Reversible','==',1));

% number of instances, want to adjust this so it's auto detected at some
% point
numout = 81;

%%
rate_write

rate_compile

jac_write

jac_write_sparse

het_parampass
%%

fid = fopen('odefun_draft.txt','w');

fid_copy = fopen('het_userdata.txt');

tline = fgets(fid_copy);
while(ischar(tline))
    fprintf(fid,tline);
    tline = fgets(fid_copy);
end

fclose(fid_copy);

fid_copy = fopen('het_jac_static_corrected.txt');

fprintf(fid,[...
    'static void staticJac(UserData* data)\n'...
    '{\n'...
    '	realtype *spJ = &(data->spJ[0]);\n'...
    '	memset(spJ, ''\\\\0'', sizeof(data->spJ));\n\n'...
    ]);

tline = fgets(fid_copy);
while(ischar(tline))
    fprintf(fid,tline);
    tline = fgets(fid_copy);
end

fclose(fid_copy);

fid_copy = fopen('het_jac_update_corrected.txt');

tline = fgets(fid_copy);
while(ischar(tline))
    fprintf(fid,tline);
    tline = fgets(fid_copy);
end

fclose(fid_copy);

fid_copy = fopen('het_parampass.txt');

tline = fgets(fid_copy);
while(ischar(tline))
    fprintf(fid,tline);
    tline = fgets(fid_copy);
end

fclose(fid_copy);

fclose(fid); %necessary?
%%
fid = fopen('odefun_draft.txt','a'); %necessary?

str1 = ['static void setRates(realtype kf_rates[' num2str(num_kf) '], realtype kr_rates[' num2str(num_kr) '], N_Vector y, UserData* data) \n{ \nrealtype '];
str2 = ''; %fill this later

iter = 1;
str1 = [str1 m1.parameters(iter).name];
str2 = [str2 m1.parameters(iter).name ' = data->' m1.parameters(iter).name ';\n'];

for iter = 2:length(m1.parameters)
    str1 = [str1 ', ' m1.parameters(iter).name ];
    str2 = [str2 m1.parameters(iter).name ' = data->' m1.parameters(iter).name ';\n'];
end

str1 = [str1 '; \n \n'];

fprintf(fid,str1);
fprintf(fid,str2);

fprintf(fid,'\n\nrealtype *y_data = NV_DATA_S(y); \n\n');

fid_r = fopen('het_rate.txt');

l = fgetl(fid_r);
while(ischar(l))
    fprintf(fid,[l '\n']);
    l = fgetl(fid_r);
end

fclose(fid_r);

fprintf(fid,'\n}\n\n');

fprintf(fid,'static int f(realtype t, N_Vector y, N_Vector ydot, void *user_data)\n{\n');
fprintf(fid,'	UserData* data;\n');
fprintf(fid,'	data = (UserData*) user_data;\n\n');

fprintf(fid,['	realtype kf_rates[' num2str(num_kf) '], kr_rates[' num2str(num_kr) '];\n']);
fprintf(fid,'	realtype *ydot_data = NV_DATA_S(ydot);\n\n');

fprintf(fid,'	setRates(kf_rates, kr_rates, y, data);\n\n');

fid_f = fopen('het_f.txt');

l = fgetl(fid_f);
while(ischar(l))
    fprintf(fid,[l '\n']);
    l = fgetl(fid_f);
end
fclose(fid_f);

fprintf(fid,'\nreturn(0);\n}');

fclose(fid);

%%

het_write_somthing

jtv_matrix_form

jtv_to_spjtv

%%

fid = fopen('odefun_adapted.txt','a');

fprintf(fid,...
    [...
    '\n\nstatic int jtv(N_Vector v, N_Vector Jv, realtype t,\n' ...
    '               N_Vector y, N_Vector fy,\n' ...
    '               void *user_data, N_Vector tmp)\n' ...
    '{	\n' ...
    '	UserData* data;\n' ...
    '	data = (UserData*) user_data;\n' ...
    '		\n' ...
    '	updateJac(data,y);\n' ...
    '			\n' ...
    '	realtype *Jv_data =  NV_DATA_S(Jv);\n' ...
    '	realtype *v_data  =  NV_DATA_S(v);\n' ...
    '	realtype *spJ = &(data->spJ[0]);\n\n' ...
    ]...
    );

fid_jtv = fopen('jtv_sparse.txt');

tline = fgets(fid_jtv);

while(ischar(tline))
    
    fprintf(fid,tline);
    tline = fgets(fid_jtv);
    
end

fprintf(fid,'\nreturn(0);\n\n}\n\n');

fclose(fid);
fclose(fid_jtv);

%% PRECOND

het_precond_diag


fid = fopen('odefun_adapted.txt','a');


fprintf(fid,...
    [...
    'static int Precond(realtype tn, N_Vector y, N_Vector fy,\n'...
    '                   booleantype jok, booleantype *jcurPtr, realtype gamma,\n'...
    '                   void *user_data, N_Vector vtemp1, N_Vector vtemp2,\n'...
    '                   N_Vector vtemp3)\n'...
    '{	\n'...
    '	\n'...
    '	UserData* data;\n'...
    '	data = (UserData*) user_data;\n'...
    '	\n'...
    '	updateJac(data,y);\n'...
    '	*jcurPtr = TRUE;\n'...
    ]);

fid_psolve = fopen('het_precond_spdiag.txt');
tline = fgets(fid_psolve);

while(ischar(tline))
    fprintf(fid,tline);
    tline = fgets(fid_psolve);
end

fprintf(fid,...
    [...
    'realtype *spJ = &(data->spJ[0]);\n'...
    '	\n'...
    '	N_VConst(0,data->J_diag);\n'...
    '	realtype *diag_data = NV_DATA_S(data->J_diag);\n'...
    '\n'...
    '	int iter;\n'...
    '\n'...
    '	for (iter = 0; iter<' num2str(num2str(length(sp_diag_ind))) ';iter++) {\n'... %this line not general, need to get "98" from appropriate place
    '		diag_data[valid_ind[iter]] = spJ[sp_diag_ind[iter]];\n'...
    '	}\n'...
    '	\n'...
    '	N_VConst(1, vtemp1); /* used to ref wtemp*/\n'...
    '	N_VLinearSum(1,vtemp1,-gamma,data->J_diag,data->J_diag);\n'...
    '	N_VInv(data->J_diag, data->J_diag);\n'...
    '\n'...
    '	return(0);\n'...
    '	\n'...
    '}\n\n'...
    ]);

%% PSOLVE

fid = fopen('odefun_adapted.txt','a');

fprintf(fid,...
    [...
    'static int PSolve(realtype tn, N_Vector y, N_Vector fu,\n'...
    '                  N_Vector r, N_Vector z,\n'...
    '                 realtype gamma, realtype delta,\n'...
    '                  int lr, void * user_data, N_Vector vtemp)\n'...
    '{	\n'...
    '	UserData* data;\n'...
    '	data = (UserData*) user_data;\n'...
    '	\n'...
    '	N_VProd(r, data->J_diag, z);\n'...
    '	\n'...
    '	return(0);\n'...
    '}\n\n'...
    ]);

fprintf(fid,...
    [...
'static void ehfun(int err_code, const char *module, const char *function, char *msg, void *eh_data){\n'...
'        if (err_code == -1) {\n'...
'                err_code = 0;\n'...
'        }\n'...
'}\n\n'...
]);

%% File cleanup and organization

cleanup = true;

if cleanup
    copyfile('odefun_adapted.txt','odefun.c');
    delete(...
        'het_f.txt',...
        'het_jac.txt',...
        'het_jac_static.txt',...
        'het_jac_static_corrected.txt',...
        'het_jac_update.txt',...
        'het_jac_update_corrected.txt',...
        'het_parampass.txt',...
        'het_precond_spdiag.txt',...
        'het_rate.txt',...
        'het_userdata.txt',...
        'jac_store.txt',...
        'jtv.txt',...
        'jtv_sparse.txt',...
        'kf_rates_collapse.txt',...
        'kr_rates_collapse.txt',...
        'odefun_adapted.txt',...
        'odefun_draft.txt',...
        'rate_literal.txt'...
        );
end

% %% Prep the main.c profiler
% 
% % param list
% str = num2str(m1.parameter(1).Value);
% for iter = 2:length(m1.parameters)
%     str = [str ',' num2str(m1.parameters(iter).Value)];
% end
% 
% str = ['{' str '}'];
% 
% param_str = ['realtype param[' num2str(numout) '][' num2str(length(m1.parameters)) '] = { \n'];
% 
% for iter = 1:(numout-1)
%     param_str = [param_str str ',\n'];
% end
% 
% param_str = [param_str str '\n};\n'];
% 
% 
% % init list
% str = num2str(m1.species(1).InitialAmount);
% for iter = 2:length(m1.species)
%     str = [str ',' num2str(m1.species(iter).InitialAmount)];
% end
% 
% str = ['{' str '}'];
% 
% init_str = ['realtype init_array[' num2str(numout) '][' num2str(length(m1.species)) '] = { \n'];
% 
% for iter = 1:(numout-1)
%     init_str = [init_str str ',\n'];
% end
% 
% init_str = [init_str str '\n};\n'];
% 
% %
% atol_str = ['realtype atol_array[' num2str(length(m1.species)) '] = {1e-8'];
% 
% for iter = 2:length(m1.species)
%     atol_str = [atol_str ',1e-8'];
% end
% atol_str = [atol_str '};\n'];
% 
% %% Write the main.c profiler
% 
% fid = fopen('main.c','w');
% 
% fprintf(fid,...
%     [...
%     '/*\n'...
%     ' *  main.c\n'...
%     ' *  cvode_test\n'...
%     ' *\n'...
%     ' *  Created by Andrew Matteson on 1/31/11.\n'...
%     ' *  Copyright 2011 __MyCompanyName__. All rights reserved.\n'...
%     ' *\n'...
%     ' */\n'...
%     '\n'...
%     '#include "call_cvode.c"\n'...
%     '#include <omp.h>\n'...
%     '\n'...
%     '\n'...
%     'static int call_cvode(realtype param[], realtype init_array[],realtype RTOL,realtype atol_array[],realtype time_array[], int NOUT,realtype y_out[][NEQ]);\n'...
%     '\n'...
%     'int main(int argc, const char * argv[])\n'...
%     '{	\n'...
%     '\n'...
%     '	int iter,jter;/*,kter; /* Looping indices */\n'...
%     '\n'...
%     ]);
% fprintf(fid,...
%     [...
%     param_str...
%     '	realtype param_scratch[' num2str(length(m1.parameters)) '];\n'...
%     '	\n'...
%     ]);
% fprintf(fid,...
%     [...
%     init_str...
%     ]);
% fprintf(fid,...
%     [...
%     '    \n'...
%     '	realtype init_scratch[' num2str(length(m1.species)) '];\n'...
%     '	realtype time_array[121] = {0,60,120,180,240,300,360,420,480,540,600,660,720,780,840,900,960,1020,1080,1140,1200,1260,1320,1380,1440,1500,1560,1620,1680,1740,1800,1860,1920,1980,2040,2100,2160,2220,2280,2340,2400,2460,2520,2580,2640,2700,2760,2820,2880,2940,3000,3060,3120,3180,3240,3300,3360,3420,3480,3540,3600,3660,3720,3780,3840,3900,3960,4020,4080,4140,4200,4260,4320,4380,4440,4500,4560,4620,4680,4740,4800,4860,4920,4980,5040,5100,5160,5220,5280,5340,5400,5460,5520,5580,5640,5700,5760,5820,5880,5940,6000,6060,6120,6180,6240,6300,6360,6420,6480,6540,6600,6660,6720,6780,6840,6900,6960,7020,7080,7140,7200};\n'...
%     '	int NOUT = 121;\n'...
%     atol_str...
%     ]);
% fprintf(fid,...
%     [...
%     '	realtype RTOL =  1.0e-6;\n'...
%     '	\n'...
%     '	/*omp_set_num_threads(1);*/\n'...
%     '\n'...
%     '	/* Create output constructs*/\n'...
%     '		\n'...
%     '	realtype y_out[NOUT][NEQ][NUMOUT];\n'...
%     '	realtype y_scratch[NOUT][NEQ];\n'...
%     '	int err_test;\n'...
%     '	\n'...
%     '	/*#pragma omp parallel for shared(y_out,param,init_array,RTOL, atol_array,time_array,NOUT) private(iter,param_scratch,init_scratch,y_scratch,jter,kter,err_test)*/\n'...
%     '	for (iter=0; iter<=NUMOUT-1; iter++) {\n'...
%     '		\n'...
%     '		for (jter = 0; jter<' num2str(length(m1.species)) '; jter++) {\n'...
%     '			init_scratch[jter] = init_array[iter][jter];\n'...
%     '		}\n'...
%     '		\n'...
%     '		for (jter = 0; jter<' num2str(length(m1.parameters)) '; jter++) {\n'...
%     '			param_scratch[jter] = param[iter][jter];\n'...
%     '		}\n'...
%     '		\n'...
%     ]);
% fprintf(fid,...
%     [...
%     '		/* must handle errors */\n'...
%     '		\n'...
%     '		err_test = call_cvode(param_scratch,init_scratch,RTOL,atol_array,time_array,NOUT,y_scratch);\n'...
%     '		\n'...
%     '		printf("Finished iter: %%i\\n",iter);\n'...
%     '		\n'...
%     '		/*for (kter=0; kter<NEQ; kter++) {\n'...
%     '			for (jter = 0; jter<NOUT; jter++) {\n'...
%     '				y_out[jter][kter][iter] = y_scratch[jter][kter];\n'...
%     '			}\n'...
%     '		}\n'...
%     '		*/\n'...
%     '	}\n'...
%     '	\n'...
%     '	/* Construct Output */\n'...
%     '	/*double *output;*/\n'...
%     '	/*double *yPTR = &y_out[0][0][0];*/\n'...
%     '	/*int dims[] = {NOUT, NEQ, NUMOUT};*/\n'...
%     '	\n'...
%     '	\n'...
%     ]);
% fprintf(fid,...
%     [...
%     '	/* Populate the output */\n'...
%     '	/*\n'...
%     '	for (iter=0; iter<NUMOUT; iter++) {\n'...
%     '		for (jter=0; jter<NEQ; jter++) {\n'...
%     '			for (kter=0; kter<NOUT; kter++) {\n'...
%     '				output[iter*NEQ*NOUT + jter*NOUT + kter] = yPTR[iter + jter*NUMOUT + kter*NEQ*NUMOUT];\n'...
%     '			}\n'...
%     '		}\n'...
%     '	}\n'...
%     '	 */\n'...
%     '}\n'...
%     ]);