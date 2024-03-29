openmp_mass_action
==================

This project is a MATLAB to C translator for MATLAB SimBiology mass-action models.  For models that need to be
repeatedly simulated with different parameters or initial conditions it can run in parallel using OpenMP.  It employs
the SUNDIALS CVODE Solver (https://computation.llnl.gov/casc/sundials/main.html) to solve the ODE system generated
from the SimBiology reactions.

Given many conditions to simulate (parameters or initial conditions) and sufficient threads the code generated by this
project can outperform MATLAB's compiled sbiosimulate command in absolute time for certain classes of models (especially
those in Andrew's dissertation).  Certain operations in solving the ODEs including Jacobian operations and preconditioning
the Jacobian solver have been optimized to have a small memory footpritn (generally in the L2 cache for most model/processor
combos).

There are many things that are not good about the code generation/compilation process.  I'm sorry about all of them,
and hope someone will eventually make the whole process a beautiful one line command.  I can't do more work on this 
project for contractual reasons, but hope someone can benefit from it.  Contact me if you'd like to take over 
maintenance.

Note on condition of code:
This code should be considered research quality (that's a polite way of saying just shy of an alpha release).  Errors
caused by improper use may error silently.  Accuracy has been rigorously assesed for the models in the Andrew's thesis,
but untested edge cases could potentially have unexpected results.

The code was developed as part of the doctoral dissertation of Andrew Matteson at New York University.
This software is licensed under the General Public License v2
Copyright Andrew Matteson and New York University 2013

Examples:

To generate code for a model (in our example Merged_1.sbproj) we put the model in the file "Models" and edit the
file openmp_compile.m to point to this 

The line to edit is:
m1 = sbioloadproject('models/Merged_1.sbproj');

Save the file and run
openmp_compile.m

This will run a while and create several temporary text file in the directory.  Eventually odefun.c will be made
and the script ends.  Copy odefun.c into the folder C_Source (yeah, I know, my bad, please see above excuses).

We can use make to compile the resulting code.  You will need to edit the makefile to point towards your installation
of sundials and MATLAB.

[alm475@login-0-0 ~]$ cd model_adapt/

[alm475@login-0-0 model_adapt]$ make

gcc -c  -I/home/alm475/sundialsgcc/include/ -I/share/apps/matlab/R2011a/extern/include -I/share/apps/matlab/R2011a/simulink/include -DMATLAB_MEX_FILE   -DMX_COMPAT_32  -DNDEBUG -D_GNU_SOURCE -ansi  -fexceptions -fPIC -fno-omit-frame-pointer -pthread  -fopenmp -O3 -ffast-math  "C_Source/main.c"
gcc   -L/home/alm475/sundialsgcc/lib/ -lsundials_cvode -lsundials_nvecserial -Wl,-rpath-link,/share/apps/matlab/R2011a/bin/glnxa64 -L/share/apps/matlab/R2011a/bin/glnxa64 -lmx -lmex -lmat -lm -lstdc++ -pthread -shared -Wl,--version-script,/share/apps/matlab/R2011a/extern/lib/glnxa64/mexFunction.map -Wl,--no-undefined -fopenmp -O3 -ffast-math -o  "fastsim.mexa64"  main.o
rm -f *.o

[alm475@login-0-0 model_adapt]$ ls

Copy_of_C_Source  fastsim.mexa64  M_files  openmp_compile.m
C_Source    makefile	  models

Now for a use example......

