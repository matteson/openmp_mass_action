jac_sparc = zeros(length(m1.species));

for iter = 1:length(m1.species)
    for jter = 1:length(m1.species)
        if strcmp(jac_cell{iter,jter}, '')
            jac_sparc(iter,jter) = 0;
        else
            jac_sparc(iter,jter) = 1;
        end
    end
end
%%

fid = fopen('jtv.txt','w');

for iter = 1:length(m1.species)
    
    if m1.species(iter).ConstantAmount % set derivative to zero in case of constant species
        str = ['Jv_data[' num2str(iter-1) '] = 0;\n'];
        fprintf(fid,str);
    else
        str = ['Jv_data[' num2str(iter-1) '] = '];
        
        for jter = find(jac_sparc(iter,:))
            str = [ str '+ J[' num2str(iter-1) '][' num2str(jter-1) ']*v_data[' num2str(jter-1) '] '];
        end
        
        str = [str ';\n'];
        fprintf(fid,str);
    end
end

fclose(fid);

%%

fid = fopen('jac_store.txt','w');

for iter = 1:length(m1.species)
    for jter = find(jac_sparc(iter,:))
        str = ['data->J[' num2str(iter) '][' num2str(jter) '] = J[' num2str(iter) '][' num2str(jter) '];\n'];
        fprintf(fid,str);
    end
end

fclose(fid);