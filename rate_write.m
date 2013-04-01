
spe_list = m1.species;
for i=1:length(spe_list)
    spe_cell{i} = spe_list(i).Name;
end

fid = fopen('het_rate.txt', 'w');
reactions = m1.reactions;

for iter = 1:length(reactions)
    param = reactions(iter).kineticLaw.getparameters;
    F_R = reactions(iter).Reversible + 1;
    for jter = 1:F_R
        str = param(jter).Name;
        if jter == 1
            for kter = 1:length(reactions(iter).Reactants)
                ind = find(strcmp(reactions(iter).Reactants(kter).Name,spe_cell));
                str = [str '*y_data[' num2str(ind-1) ']'];
            end
        elseif jter == 2
            for kter = 1:length(reactions(iter).Products)
                ind = find(strcmp(reactions(iter).Products(kter).Name ,spe_cell));
                str = [str '*y_data[' num2str(ind-1) ']'];
            end
        end
        tofile = ['rates[' num2str(iter-1) '][' num2str(jter-1) '] = ' str ';\n'];
        fprintf(fid,tofile);
    end
end

fclose(fid);