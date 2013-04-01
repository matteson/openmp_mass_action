fid = fopen('het_precond_spdiag.txt','w');

kter = 1;
for i = 1:length(m1.species)
   if jac_sparc(i,i)
       valid_ind(kter) = i-1;
       sp_diag_ind(kter) = sp_indx(jac_sparc,i-1,i-1);
       kter = kter+1;
   end
end

str = ['static const int valid_ind[' num2str(length(valid_ind)) '] = {' num2str(valid_ind(1))];

for iter = 2:length(valid_ind)
   str = [str ',' num2str(valid_ind(iter))];
end

str = [str '};\n'];

fprintf(fid,str);

str = ['static const int sp_diag_ind[' num2str(length(sp_diag_ind)) '] = {' num2str(sp_diag_ind(1))];

for iter = 2:length(sp_diag_ind)
   str = [str ',' num2str(sp_diag_ind(iter))];
end

str = [str '};\n'];

fprintf(fid,str);
