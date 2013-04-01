kter=1;
for iter = 1:length(m1.species)
    for jter = 1:length(m1.species)
        if jac_sparc(iter,jter) == 1
            dict{1} = ['J\[' num2str(iter-1) '\]\[' num2str(jter-1) '\]'];
            dict{2} = sp_indx(jac_sparc,iter-1,jter-1);
            dict{3} = ['spJ[' num2str(dict{2}) ']'];
            
            dict_log{kter} = dict;
            kter=kter+1;
        end
    end
end

%%
fid = fopen('jtv.txt');

str = '';
tline = fgets(fid);
while(ischar(tline))
    str = [str tline];
    tline = fgets(fid);
end
fclose(fid);

for iter = 1:length(dict_log)
    str = regexprep(str,dict_log{iter}{1},dict_log{iter}{3});
end

fid = fopen('jtv_sparse.txt','w');
    fprintf(fid,str);
fclose(fid);