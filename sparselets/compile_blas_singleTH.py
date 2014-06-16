#!/usr/bin/env python

import sys
import subprocess
import os

if len(sys.argv) != 2:
	raise SystemExit("Need one filename")

fullfilename = sys.argv[1]
filename = fullfilename.split('.')[0]
mex_filename = filename + '_singleTH.' + "mexa64"
obj_filename = filename + '.' + "o"

matlab_path = "/Applications/MATLAB_R2011b.app"
mkl_path = "/Users/song/Documents/Workspace/intel64"

compile_string = "g++ -c  -I" + matlab_path + \
                 "/extern/include -I" + matlab_path + \
                 "/simulink/include -DMATLAB_MEX_FILE "+\
                 "-ansi -D_GNU_SOURCE -fPIC -fno-omit-frame-pointer "+\
                 "-pthread  -O3 -DNDEBUG -fopenmp " + "\"" + fullfilename + "\""
print '\n' + compile_string
subprocess.call(compile_string, shell=True)
print "Compilation successful\n"

# link_string = "g++ -O -pthread -shared -Wl,--version-script,"+\
# 			  matlab_path +"/extern/lib/maci64/mexFunction.map "+\
# 			  "-Wl,--no-undefined -o " + "\"" + mex_filename + \
# 			  "\" " + obj_filename + " -Wl,--start-group "+ mkl_path +\
# 			  "/libmkl_intel_lp64.a "+mkl_path+"/libmkl_sequential.a "+\
# 			  mkl_path+"/libmkl_core.a -Wl,--end-group -lpthread -Wl,"+\
# 			  "-rpath-link,"+matlab_path+"/bin/maci64 -L"+matlab_path+\
# 			  "/bin/maci64 -lmx -lmex -lmat -lm -lgomp"

# link_string = "g++ -O -pthread -shared -Wl,--version-script,"+\
# "/Applications/MATLAB_R2011b.app/extern/lib/maci64/mexFunction.map "+\
# "-Wl,--no-undefined -o " + "\"" + mex_filename + "\" " + \
# obj_filename + " -Wl,--start-group /Users/song/Documents/Workspace/intel64/libmkl_intel_lp64.a"+\
# " /Users/song/Documents/Workspace/intel64/libmkl_sequential.a /Users/song/Documents/Workspace/intel64/libmkl_core.a"+\
# " -Wl,--end-group -lpthread -Wl,-rpath-link,/Applications/MATLAB_R2011b.app/bin/maci64"+\
# " -L/Applications/MATLAB_R2011b.app/bin/maci64 -lmx -lmex -lmat -lm -lgomp"		

link_string = "g++ -O -pthread -shared -o " + "\"" + mex_filename + "\" " + \
obj_filename + " /Users/song/Documents/Workspace/intel64/libmkl_intel_lp64.a"+\
" /Users/song/Documents/Workspace/intel64/libmkl_sequential.a /Users/song/Documents/Workspace/intel64/libmkl_core.a"+\
" -lpthread"+\
" -L/Applications/MATLAB_R2011b.app/bin/maci64 -lmx -lmex -lmat -lm -lgomp"		  

print link_string
subprocess.call(link_string, shell=True)
print "Link successful"

env_string = "export MKL_NUM_THREADS=1"
subprocess.call(env_string, shell=True)
