fid1 = fopen('het_rate.txt');
tline = fgets(fid1);
str = '';
iter = 1;
while ischar(tline)
    ind = regexp(tline,' = ');
    rate_cell{iter} = tline(1:(ind-1));
    Ith_cell{iter} = tline((ind+3):(end-2));
    
    tline = fgets(fid1);
    iter = iter + 1;
end

fclose(fid1);

%%
fid2 = fopen('het_f.txt');
tline = fgets(fid);
str = '';
while ischar(tline)
    str = [str ' ' tline];
    tline = fgets(fid2);
end

fclose(fid2);

%%
for iter = 1:length(rate_cell)
    str = regexprep(str,regexprep(regexprep(rate_cell{iter},'\[','\\['),'\]','\\]'),Ith_cell{iter});
end

%%
fid3 = fopen('rate_literal.txt','w');
    fprintf(fid3,str);
fclose(fid3);

%%
str = '';
for iter = 1:length(m1.species)
    for jter = 1:length(m1.species)
        jac_cell{iter,jter} = [''];
    end
end

fid3 = fopen('rate_literal.txt');
fid4 = fopen('het_jac.txt','w');
tline = fgets(fid3);
iter = 1;
while ischar(tline)
    ind = regexp(tline,'[+-]');
    for jter = 1:length(m1.species)
        ind2 = regexp(tline,['y_data\[' num2str(jter-1) '\]']);
        if ~isempty(ind2)
            for kter = 1:length(ind2)
                temp = find(ind<ind2(kter),1,'last');
                ind3 = ind(temp);
                if ind3 == ind(end)
                    jac_cell{iter,jter} = [jac_cell{iter,jter} regexprep(tline((ind3-1):(end-2)),['*y_data\[' num2str(jter-1) '\]'],'')];
                else
                    jac_cell{iter,jter} = [jac_cell{iter,jter} regexprep(tline((ind3-1):(ind(temp+1)-2)),['*y_data\[' num2str(jter-1) '\]'],'')];
                end
            end
        end
    end
    tline = fgets(fid3);
    iter = iter + 1;
end

kter=0;
for iter = 1:length(m1.species)
    for jter = 1:length(m1.species)
        if strcmp(jac_cell{iter,jter}, [''])
            jac_cell{iter,jter} = '';
        else
            jac_cell{iter,jter} = ['spJ[' num2str(kter) '] = ' jac_cell{iter,jter} '; \n'];
            kter=kter+1;
        end
    end
end

for iter = 1:length(m1.species)
    for jter = 1:length(m1.species)
        fprintf(fid4,jac_cell{iter,jter});
    end
end

fclose(fid3);
fclose(fid4);

%%

% fid5 = fopen('het_jac.txt');
% fid6 = fopen('het_jac_sparse.txt','w');
% 
% tline = fgets(fid5);
% while ischar(tline)
%     for iter = 1:150
%         tline = regexprep(tline,['Ith\(y,' num2str(iter) '\)'],['y_data[' num2str(iter-1) ']']);
%     end
%     sprintf(tline)
%     fprintf(fid6,tline);
%     tline = fgets(fid5);
% end
% 
% fclose(fid5);
% fclose(fid6);

%%

fid7 = fopen('het_jac.txt');
fid8 = fopen('het_jac_static.txt','w');
fid9 = fopen('het_jac_update.txt','w');

tline = fgets(fid7);
while ischar(tline)
    if isempty(regexp(tline,'y_data','ONCE'))
        fprintf(fid8,tline);
    else
        fprintf(fid9,tline);
    end
    tline = fgets(fid7);
end

fclose(fid7);
fclose(fid8);
fclose(fid9);

%%

fid5 = fopen('het_jac_static.txt');
fid6 = fopen('het_jac_static_corrected.txt','w');

% fprintf(fid6,[...
%     'static void staticJac(UserData* data)\n'...
% '{\n'...
% '	realtype *spJ = &(data->spJ[0]);\n'...
% '	memset(spJ, ''\\0'', sizeof(data->spJ));\n\n'...
% ]);

tline = fgets(fid5);
while ischar(tline)
        tline = regexprep(tline,['kf'],['data->kf']);
        tline = regexprep(tline,['kr'],['data->kr']);
        
    %sprintf(tline)
    fprintf(fid6,tline);
    tline = fgets(fid5);
end

fprintf(fid6,'}\n\n');

fclose(fid5);
fclose(fid6);

%%

fid5 = fopen('het_jac_update.txt');
fid6 = fopen('het_jac_update_corrected.txt','w');

    str1 = 'static void updateJac(UserData* data,N_Vector y)\n{\n';
   str2 = '';

iter = 1;
str1 = [str1 'realtype ' m1.parameters(iter).name];
str2 = [str2 m1.parameters(iter).name ' = data->' m1.parameters(iter).name ';\n'];
    
	
for iter = 2:length(m1.parameters)
    str1 = [str1 ', ' m1.parameters(iter).name ];
    str2 = [str2 m1.parameters(iter).name ' = data->' m1.parameters(iter).name ';\n'];
end

str1 = [str1 '; \n \n'];    

fprintf(fid6,str1);
fprintf(fid6,str2);

fprintf(fid6,'\nrealtype *y_data = NV_DATA_S(y);\n\nrealtype *spJ = &(data->spJ[0]);\n\n');

tline = fgets(fid5);
while ischar(tline)
%         tline = regexprep(tline,['kf'],['data->kf']);
%         tline = regexprep(tline,['kr'],['data->kr']);
%         
%     %sprintf(tline)
     fprintf(fid6,tline);
    tline = fgets(fid5);
end

fprintf(fid6,'\n}\n\n');

fclose(fid5);
fclose(fid6);