#!/usr/bin/env python

import sys
import subprocess
import os

matlab_rootpath = "/Applications/MATLAB_R2011b.app"
mexfilename = "sparselets/matrix_sparse_ATB_csc_parsed_float.cc"
mexfilename_stripped = mexfilename.replace('/', ' ').replace('.', ' ').split()
mexfilename_stripped = mexfilename_stripped[-2]
output_path = "bin/" + mexfilename_stripped

compile_string = "icc -m64 -fast -O3 -unroll-aggressive -opt-prefetch " +\
                  "-I/opt/intel/mkl/include -I" + matlab_rootpath + "/extern/include " + \
                  mexfilename + " " + \
                  "-L" + matlab_rootpath + "/bin/maci64 -lmx -lmex -lmat -undefined dynamic_lookup "+\
                  "/opt/intel/mkl/lib/libmkl_intel_lp64.a /opt/intel/mkl/lib/libmkl_sequential.a /opt/intel/mkl/lib/libmkl_core.a "+\
                  "-lpthread -lm -o " + output_path + ".mexmaci64"

print '\n' + compile_string
subprocess.call(compile_string, shell=True)
print "Compilation successful\n"