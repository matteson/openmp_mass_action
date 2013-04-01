fid = fopen('sp_ind_psolve.txt','w');
%%

%int ind2[34] =
ind2 = [9,20,21,22,23,24,26,27,28,31,34,39,42,45,46,47,48,57,58,59,60,69,70,73,74,77,78,83,88,90,93,95,98,100];
%int ind_off[34] =
ind_off = [11,18,19,15,17,38,41,44,49,50,51,30,33,36,51,50,49,87,97,89,99,71,72,53,53,92,94,85,63,89,80,94,64,99];

for iter = 1:34
    sp_ind_off(iter) = sp_indx(jac_sparc,ind2(iter), ind_off(iter));
end

str = ['int sp_ind_off[34] = {' num2str(sp_ind_off(1))];

for iter = 2:34
    str = [str ',' num2str(sp_ind_off(iter))];
end

str = [str '};\n'];

fprintf(fid,str);


%%

	% int ind3[8] = 
    ind3 = [37,40,43,75,76,86,91,96];
	%int ind_off2[8][2] = 
    ind_off2 = [[28,48];[31,47];[34,46];[53,73];[53,74];[59,90];[78,95];[60,100]];

for iter = 1:numel(ind3)
    for jter = 1:2
        sp_ind_off2(iter,jter) = sp_indx(jac_sparc,ind3(iter), ind_off2(iter,jter));
    end
end

str = ['int sp_ind_off2[8][2] = {{' num2str(sp_ind_off2(1,1)) ',' num2str(sp_ind_off2(1,2)) '}'];

for iter = 2:numel(ind3)
   str = [str ',{' num2str(sp_ind_off2(iter,1)) ',' num2str(sp_ind_off2(iter,2)) '}'];
end

str = [str '};\n'];

fprintf(fid,str);

%%
%int ind_off3[26] =
ind_off3 = [15,17,18,19,28,30,31,33,34,36,49,50,51,59,60,63,64,71,72,73,74,78,80,89,94,99];
%int ind_off4[20] =
ind_off4 = [11,38,41,44,46,47,48,49,50,51,85,87,89,90,92,94,95,97,99,100];
%int ind4[2] =
ind4 = [5,6];

for iter = 1:numel(ind_off3)
    sp_ind_off3(iter) = sp_indx(jac_sparc,ind4(1), ind_off3(iter));
end

str = ['int sp_ind_off3[26] = {' num2str(sp_ind_off3(1)) ];

for iter = 2:numel(ind_off3)
   str = [str ',' num2str(sp_ind_off3(iter)) ];
end

str = [str '};\n'];

fprintf(fid,str);


for iter = 1:numel(ind_off4)
    sp_ind_off4(iter) = sp_indx(jac_sparc,ind4(2), ind_off4(iter));
end

str = ['int sp_ind_off4[20] = {' num2str(sp_ind_off4(1)) ];

for iter = 2:numel(ind_off4)
   str = [str ',' num2str(sp_ind_off4(iter)) ];
end

str = [str '};\n'];

fprintf(fid,str);


