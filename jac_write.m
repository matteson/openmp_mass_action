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
tline = fgets(fid2);
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
        jac_cell{iter,jter} = ['J[' num2str(iter-1) '][' num2str(jter-1) '] ='];
        jac_func{iter,jter} = [''];
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
                    jac_func{iter,jter} = [jac_func{iter,jter} regexprep(tline((ind3-1):(end-2)),['*y_data\[' num2str(jter-1) '\]'],'')];
                    jac_func{iter,jter} = regexprep(regexprep(jac_func{iter,jter},'\[','('),'\]',')');
                else
                    jac_cell{iter,jter} = [jac_cell{iter,jter} regexprep(tline((ind3-1):(ind(temp+1)-2)),['*y_data\[' num2str(jter-1) '\]'],'')];
                    jac_func{iter,jter} = [jac_func{iter,jter} regexprep(tline((ind3-1):(end-2)),['*y_data\[' num2str(jter-1) '\]'],'')];
                    jac_func{iter,jter} = regexprep(regexprep(jac_func{iter,jter},'\[','('),'\]',')');
                end
            end
        end
    end
    tline = fgets(fid3);
    iter = iter + 1;
end

for iter = 1:length(m1.species)
    for jter = 1:length(m1.species)
        if strcmp(jac_cell{iter,jter}, ['J[' num2str(iter-1) '][' num2str(jter-1) '] ='])
            jac_cell{iter,jter} = '';
            jac_func{iter,jter} = '0';
        else
            jac_cell{iter,jter} = [jac_cell{iter,jter} '; \n'];
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