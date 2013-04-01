species = m1.species;
reactions = m1.reactions;
for i=1:length(species)
    spe_cell{i} = species(i).Name;
end

for iter = 1:length(species)
    ydot_cell{iter} = ['ydot_data[' num2str(iter-1) '] = '];
end

for iter = 1:length(reactions)
    param = reactions(iter).kineticLaw.getparameters;
    F_R = reactions(iter).Reversible + 1;
    
    for jter = 1:F_R
        if jter == 1
            for kter = 1:length(reactions(iter).Reactants)
                ind = find(strcmp(reactions(iter).Reactants(kter).Name,spe_cell));
                ydot_cell{ind} = [ydot_cell{ind} ' - rates[' num2str(iter-1) '][0]'];
            end
            for kter = 1:length(reactions(iter).Products)
                ind = find(strcmp(reactions(iter).Products(kter).Name,spe_cell));
                ydot_cell{ind} = [ydot_cell{ind} ' + rates[' num2str(iter-1) '][0]'];
            end
        elseif jter == 2
            for kter = 1:length(reactions(iter).Reactants)
                ind = find(strcmp(reactions(iter).Reactants(kter).Name,spe_cell));
                ydot_cell{ind} = [ydot_cell{ind} ' + rates[' num2str(iter-1) '][1]'];
            end
            for kter = 1:length(reactions(iter).Products)
                ind = find(strcmp(reactions(iter).Products(kter).Name,spe_cell));
                ydot_cell{ind} = [ydot_cell{ind} ' - rates[' num2str(iter-1) '][1]'];
            end
        end
    end
end

for iter = 1:length(species)
    ydot_cell{iter} = [ydot_cell{iter} ';'];
end

for iter = 1:length(species)
    if m1.species(iter).ConstantAmount == 1
        ydot_cell{iter} = ['ydot_data[' num2str(iter-1) '] = 0;'];
    end
end

fid = fopen('het_f.txt', 'w');

for iter = 1:length(species)
    fprintf(fid,[ydot_cell{iter} '\n']);
end
    

fclose(fid);
    
    
    