CC=gcc
IFLAGS=-I/home/alm475/sundialsgcc/include/ -I/share/apps/matlab/R2011a/extern/include -I/share/apps/matlab/R2011a/simulink/include
CFLAGS1=-DMATLAB_MEX_FILE   -DMX_COMPAT_32  -DNDEBUG -D_GNU_SOURCE -ansi  -fexceptions -fPIC -fno-omit-frame-pointer -pthread 
CFLAGS2=-fopenmp -O3 -ffast-math
LFLAGS1 =-L/home/alm475/sundialsgcc/lib/ -lsundials_cvode -lsundials_nvecserial -Wl,-rpath-link,/share/apps/matlab/R2011a/bin/glnxa64 -L/share/apps/matlab/R2011a/bin/glnxa64 -lmx -lmex -lmat -lm -lstdc++
LFLAGS2 =-pthread -shared -Wl,--version-script,/share/apps/matlab/R2011a/extern/lib/glnxa64/mexFunction.map -Wl,--no-undefined

all: fast_sim clean

fast_sim:  C_Source/main.c
	$(CC) -c  $(IFLAGS) $(CFLAGS1) $(CFLAGS2)  "C_Source/main.c"
	$(CC)   $(LFLAGS1) $(LFLAGS2) $(CFLAGS2) -o  "fastsim.mexa64"  main.o

clean:
	rm -f *.o
