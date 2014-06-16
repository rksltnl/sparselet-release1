#!/usr/bin/env python

import sys
import subprocess
import os

if len(sys.argv) != 2:
	raise SystemExit("Need one filename")

fullfilename = sys.argv[1]
filename = fullfilename.split('.')[0]
mex_filename = filename + '.' + "mexa64"
obj_filename = filename + '.' + "o"

compile_string = "g++ -c  -I/u/vis/song/.MATH/R2011b/extern/include -I/u/vis/song/.MATH/R2011b/simulink/include -DMATLAB_MEX_FILE -ansi -D_GNU_SOURCE -fPIC -fno-omit-frame-pointer -pthread  -O3 -DNDEBUG -fopenmp " + "\"" + fullfilename + "\""
print '\n' + compile_string
subprocess.call(compile_string, shell=True)
print "Compilation successful\n"

link_string = "g++ -O -pthread -shared -Wl,--version-script,/u/vis/song/.MATH/R2011b/extern/lib/glnxa64/mexFunction.map -Wl,--no-undefined -o " + "\"" + mex_filename + "\" " + obj_filename + " -Wl,--start-group /u/vis/x1/song/intel64/libmkl_intel_lp64.a /u/vis/x1/song/intel64/libmkl_intel_thread.a /u/vis/x1/song/intel64/libmkl_core.a -Wl,--end-group -lpthread -Wl,-rpath-link,/u/vis/song/.MATH/R2011b/bin/glnxa64 -L/u/vis/song/.MATH/R2011b/bin/glnxa64 -lmx -lmex -lmat -lm -L/usr/local/lib/mkl-10.3.2/compiler/lib/intel64 -liomp5"
print link_string
subprocess.call(link_string, shell=True)
print "Link successful"

env_string = "export MKL_NUM_THREADS=24"
subprocess.call(env_string, shell=True)
