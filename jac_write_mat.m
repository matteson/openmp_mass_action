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
        ind2 = regexp(tline,['Ith\(y,' num2str(jter) '\)']);
        if ~isempty(ind2)
            for kter = 1:length(ind2)
                temp = find(ind<ind2(kter),1,'last');
                ind3 = ind(temp);
                if ind3 == ind(end)
                    jac_cell{iter,jter} = [jac_cell{iter,jter} regexprep(tline((ind3-1):(end-2)),['*Ith\(y,' num2str(jter) '\)'],'')];
                else
                    jac_cell{iter,jter} = [jac_cell{iter,jter} regexprep(tline((ind3-1):(ind(temp+1)-2)),['*Ith\(y,' num2str(jter) '\)'],'')];
                end
            end
        end
    end
    tline = fgets(fid3);
    iter = iter + 1;
end

for iter = 1:length(m1.species)
    for jter = 1:length(m1.species)
        if strcmp(jac_cell{iter,jter}, [''])
            jac_cell{iter,jter} = '';
        else
            jac_cell{iter,jter} = [jac_cell{iter,jter}];
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

Ith = @(y,i) y(i);

for iter = 1:length(m1.parameters)
    str = [m1.parameters(iter).Name '=' num2str(m1.parameters(iter).Value) ';'];
    eval(str);
end

%%
% have SimData before this

test_col = zeros(150);

for lter = 1:81

pull = 1:3:100;
nrat = zeros(1,length(pull));

for kter = 1:length(pull)
    jac = zeros(150,150);
    y = SimData{lter,1}.Data(pull(kter),:);
    
    for iter = 1:150
        for jter = 1:150
            if strcmp(jac_cell{iter,jter},'')
                jac(iter,jter) = 0;
            else
                jac(iter,jter) = eval(jac_cell{iter,jter});
            end
        end
    end

    P = @(g) eye(150) - g*jac;
    test = P(.05).*sparc;
    
    % test_col = test_col + (abs(test)>0);
    nrat(kter) =  norm(test-P(.05))/norm(P(.05));
end
tmp(lter) = max(nrat);
figure();
plot(pull,nrat)

end

%%
clear inds
for iter = 1:150
    inds{iter} = find(sparc(iter,:));
end

solved = zeros(1,150);
for iter=1:150
    if all(iter == inds{iter})
        solved(iter) = 1;
    end
end

ind1 = find(solved);

str1 = ['int ind1[' num2str(length(ind1)) '] = {' num2str(ind1(1))];

for iter = 2:length(ind1)
    str1 = [str1 ',' num2str(ind1(iter))];
end

str1 = [str1 '};\n'];

for_str1 = [...
    'for(iter=0,iter<106,iter++){\n'...
    '     Ith(z,ind1[iter]) = Ith(r,ind1[iter])/P[ind1[iter]-1][ind1[iter]-1];\n'...
    '}\n'...
    ];
    
%%
solved2 = zeros(1,150);
for iter=1:150
    if all(ismember(inds{iter},union(find(solved),iter)))
        solved2(iter) = 1;
    end
end

tmp = solved2-solved;

ind2 = find(tmp);
ind_off = zeros(1,length(ind2));
for iter = 1:length(ind2)
    % Will generate an error for certain Jacobian structures
    ind_off(iter) = inds{ind2(iter)}(inds{ind2(iter)}~=ind2(iter));
end

str2 = ['int ind2[' num2str(length(ind2)) '] = {' num2str(ind2(1)-1)];

for iter = 2:length(ind2)
    str2 = [str2 ',' num2str(ind2(iter)-1)];
end

str2 = [str2 '};\n'];

str3 = ['int ind_off[' num2str(length(ind_off)) '] = {' num2str(ind_off(1)-1)];

for iter = 2:length(ind2)
    str3 = [str3 ',' num2str(ind_off(iter)-1)];
end

str3 = [str3 '};\n'];

for_str2 = [...
    'for(iter=0,iter<' num2str(length(ind2)) ',iter++){\n'...
    '     Ith(z,ind2[iter]) = (Ith(r,ind2[iter])-P[ind2[iter]-1][ind_off[iter]-1]*Ith(z,ind_off[iter]))/P[ind2[iter]-1][ind2[iter]-1];\n'...
    '}\n'...
    ];
%%
solved3 = zeros(1,150);
for iter=1:150
    if all(ismember(inds{iter},union(find(solved2),iter)))
        solved3(iter) = 1;
    end
end

tmp = solved3-solved2;
ind3 = find(tmp);
str4 = ['int ind3[' num2str(length(ind3)-2) '] = {' num2str(ind3(3)-1)];

for iter = 4:length(ind3)
    str4 = [str4 ',' num2str(ind3(iter)-1)];
end
str4 = [str4 '};\n'];

for iter = 3:length(ind3)
    % Will generate an error for certain Jacobian structures
    ind_off2(iter,:) = inds{ind3(iter)}(inds{ind3(iter)}~=ind3(iter));
end

str5 = ['int ind_off2[' num2str(length(ind_off2)-2) '][2] = {{' num2str(ind_off2(3,1)-1) ',' num2str(ind_off2(3,2)-1)];

for iter = 4:length(ind3)
    str5 = [str5 '},{' num2str(ind_off2(iter,1)-1) ',' num2str(ind_off2(iter,2)-1)];
end

str5 = [str5 '}};\n'];

for_str3 = [...
    'for(iter=0,iter<' num2str(length(ind3)-2) ',iter++){\n'...
    '     Ith(z,ind3[iter]) = '...
    '(Ith(r,ind3[iter])'...
    '-P[ind3[iter]-1][ind_off2[iter][0]-1]*Ith(z,ind_off2[iter][0])'...
    '-P[ind3[iter]-1][ind_off2[iter][1]-1]*Ith(z,ind_off2[iter][1]))'...
    '/P[ind3[iter]-1][ind3[iter]-1];\n'...
    '}\n'...
    ];

%%

ind_off3 = inds{ind3(1)}(inds{ind3(1)}~=ind3(1));

str6 = ['int ind_off3[' num2str(length(ind_off3)) '] = {' num2str(ind_off3(1)-1)];
for iter = 2:length(ind_off3)
    str6 = [str6 ',' num2str(ind_off3(iter)-1)];
end
str6 = [str6 '};\n'];

ind_off4 = inds{ind3(2)}(inds{ind3(2)}~=ind3(2));

str7 = ['int ind_off4[' num2str(length(ind_off4)) '] = {' num2str(ind_off4(1)-1)];
for iter = 2:length(ind_off4)
    str7 = [str7 ',' num2str(ind_off4(iter)-1)];
end
str7 = [str7 '};\n'];


str8 = ['int ind4[2] = {5,6};\n'];

for_str4 = [...
    'realtype rhs = 0;\n'...
    'iter=0;\n'...
    '     for(jter=0,jter<' num2str(length(ind_off3)) ',jter++){\n'...
    '          rhs += P[ind4[iter]-1][ind_off3[jter]-1]*Ith(z,ind_off3[jter]);\n'...
    '     }\n'...
    'Ith(z,ind4[iter]) = 1/P[ind4[iter]-1][ind4[iter]-1]*(Ith(r,ind4[iter])-rhs]);\n'...
    'rhs = 0;\n'...
    'iter=1;\n'...
    '     for(jter=0,jter<' num2str(length(ind_off3)) ',jter++){\n'...
    '          rhs += P[ind4[iter]-1][ind_off4[jter]-1]*Ith(z,ind_off4[jter]);\n'...
    '     }\n'...
    'Ith(z,ind4[iter]) = 1/P[ind4[iter]-1][ind4[iter]-1]*(Ith(r,ind4[iter])-rhs]);\n'...
    ];
%%

fid = fopen('krylov.txt','w');
    fprintf(fid,[str1 for_str1 str2 str3 for_str2 str4 str5 for_str3 str6 str7 str8 for_str4]);
fclose(fid);