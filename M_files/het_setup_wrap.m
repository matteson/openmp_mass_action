clear all

m1 = sbioloadproject('het_template.sbproj');
m1 = m1.m1;


%%
param_vec = zeros(1,length(m1.parameters));
init_vec = zeros(1,length(m1.species));

for iter = 1:length(m1.parameters)
    param_vec(iter) = m1.parameters(iter).value;
end

for iter = 1:length(m1.species)
    init_vec(iter) = m1.species(iter).InitialAmount;
end

param = repmat(param_vec,81,1);
init = repmat(init_vec,81,1);
%%
EGF_dose = 2e16*[9e-9 3e-9 1e-9 3.3e-10 1.1e-10 3.7e-11 1.2e-11 4.1e-12 0];
HGF_dose = 2e16*[9e-9 3e-9 1e-9 3.3e-10 1.1e-10 3.7e-11 1.2e-11 4.1e-12 0];

for iter = 1:9
    for jter = 1:9
        tmp = (iter-1)*9 + jter;
        init(tmp,2) = HGF_dose(iter);
        init(tmp,3) = EGF_dose(jter);
    end
end

%%
T = 0:60:7200;

%%
abstol = 1e-8*ones(1,150);
rtol = 1e-6;

%%
param_str = ['realtype param[81][67] = { \n' ];

for iter = 2:81
    param_str = [param_str '     {' num2str(param(iter,1)) ];
    for jter = 2:67
        param_str = [param_str ',' num2str(param(iter,jter))];
    end
    param_str = [param_str '}\n'];
end
param_str = [param_str '};\n'];
param_str = [param_str 'realtype param_scratch[67];\n'];

init_str = ['realtype init_array[81][150] = { ' ];
for iter = 2:81
    init_str = [init_str '     {' num2str(init(iter,1)) ];
    for jter = 2:150
        init_str = [init_str ',' num2str(init(iter,jter))];
    end
    init_str = [init_str '}\n'];
end
init_str = [init_str '};\n'];
init_str = [init_str 'realtype init_scratch[150];\n'];

lin = 0:60:7200;
time_str = ['realtype time_array[' num2str(length(lin)) '] = {' num2str(0)];
for iter = 2:length(lin)
    time_str = [time_str ',' num2str(lin(iter))];
end
time_str = [time_str '};\n'];
time_str = [time_str 'int NOUT = ' num2str(length(lin)) ';\n'];

atol_str = ['realtype atol_array[' num2str(150) '] = {1e-8'];
for iter = 2:150
    atol_str = [atol_str ',1e-8' ];
end
atol_str = [atol_str '};\n'];
atol_str = [atol_str 'RTOL =  1.0e-6;\n'];

fid = fopen('main_wrap.txt','w');

fprintf(fid,param_str);
fprintf(fid,init_str);
fprintf(fid,time_str);
fprintf(fid,atol_str);

fclose(fid);
