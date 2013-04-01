

%%
spe_list = m1.species;
for i=1:length(spe_list)
    spe_cell{i} = spe_list(i).Name;
end

reactions = m1.reactions;

kter = 0;
lter = 0;

%need to define dict_log_f and _r before as empty, must handle cases of
%non-reversible or non_forward

dict_log_f = {};
dict_log_r = {};

for iter = 1:length(reactions)
    param = reactions(iter).kineticLaw.getparameters;
    F_R = reactions(iter).Reversible + 1;
    for jter = 1:F_R
        str = param(jter).Name;
        if jter == 1
            dict{1} = ['rates\[' num2str(iter-1) '\]\[' num2str(jter-1) '\]'];
            dict{2} = ['kf_rates[' num2str(kter) ']'];
            kter = kter+1;
            dict_log_f{kter} = dict;
        elseif jter == 2
            dict{1} = ['rates\[' num2str(iter-1) '\]\[' num2str(jter-1) '\]'];
            dict{2} = ['kr_rates[' num2str(lter) ']'];
            lter = lter + 1;
            dict_log_r{lter} = dict;
        end
    end
end

dict_log(1:length(dict_log_f)) = dict_log_f;
dict_log((length(dict_log_f)+1):(length(dict_log_r)+length(dict_log_f))) = dict_log_r;

%%

fid = fopen('odefun_draft.txt');

str = '';
tline = fgets(fid);
while(ischar(tline))
    str = [str tline];
    tline = fgets(fid);
end
fclose(fid);

for iter = 1:length(dict_log)
    str = regexprep(str,dict_log{iter}{1},dict_log{iter}{2});
end

fid = fopen('odefun_adapted.txt','w');
    fprintf(fid,str);
fclose(fid);

%%

fid = fopen('odefun_adapted.txt');

str1 = '';
str2 = '';
tline = fgets(fid);
while(ischar(tline))
    if isempty(regexp(tline,'kf_rates', 'once'))
        str1 = [str1 tline];
        tline = fgets(fid);
    else
        str2 = [str2 tline];
        tline = fgets(fid);
    end
end
fclose(fid);

fid = fopen('kr_rates_collapse.txt','w');
    fprintf(fid,str1);
fclose(fid);
fid = fopen('kf_rates_collapse.txt','w');
    fprintf(fid,str2);
fclose(fid);