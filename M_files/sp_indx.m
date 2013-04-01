function out = sp_indx(sparc,i,j)

if sparc(i+1,j+1) == 0
    error();
end

out = sum(sum(sparc(1:i,:),2)) + sum(sparc((i+1),1:(j+1))) - 1;