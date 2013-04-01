
str = ['static int flag = 1;\n'];
str = [str 'static realtype ' m1.parameters(1).name ];

for iter = 2:length(m1.parameters)
    str = [str ', ' m1.parameters(iter).name];
end

str = [str ';\n'];

str = [str ...
    'if (flag){\n'...
    '     flag = 0;\n'];

for iter = 1:length(m1.parameters)
    str = [str  '     ' m1.parameters(iter).name ' = data->' m1.parameters(iter).name ';\n'];
end

str = [str '}'];