README for sparselet code
=========

### Introduction



### Citing sparselets

If you find sparselet detection code useful in your research, please cite:

	@inproceedings{Song-TPAMI2014,
		title = "Generalized Sparselet Models for Real-Time Multiclass Object Recognition",
		booktitle = "IEEE Transactions on Pattern Analysis and Machine Intelligence",
		year = "2014",
		author = "Hyun Oh Song and Ross Girshick and Stefan Zickler and Christopher Geyer and Pedro Felzenszwalb and Trevor Darrell",
	}

	@inproceedings{Song-ICML2013,
		title = "Discriminatively Activated Sparselets",
		booktitle = "International Conference on Machine Learning (ICML)",
		year = "2013", 
		author = "Ross Girshick and Hyun Oh Song and Trevor Darrell",
	}

	@inproceedings {Song-ECCV2012,
		title = "Sparselet Models for Efficient Multiclass Object Detection",
		booktitle = "European Conference on Computer Vision (ECCV)",
		year = "2012",
		author = "Hyun Oh Song and Stefan Zickler and Tim Althoff and Ross Girshick and Mario Fritz and Christopher Geyer and Pedro Felzenszwalb and Trevor Darrell",
	}

### License

Sparselet is released under the Simplified BSD License (refer to the
LICENSE file for details).

### System Requirements
* OS X or Linux
* MATLAB
* Intel® C++ Composer XE for OS X (for OS X) or Intel® C++ Studio XE for Linux (for Linux)
  This is currently freely available under the non-commercial license for students.
  (https://software.intel.com/en-us/intel-education-offerings#pid-2460-93)
* SPAMS toolbox (http://spams-devel.gforge.inria.fr/downloads.html)  

### Install instructions

1. Download and install Intel® C++ Composer XE from the link above.
2. Unpack the sparselet code.
3. Download and install SPAMS toolbox in the same directory level as in the sparselet code.
4. On a terminal run $python sparselets/compile_blas_singleTH_MAC.py (for OS X) or $python sparselets/compile_blas_singleTH.py (for Linux)
5. Start matlab.
6. Run the 'compile' function to compile the helper functions.
   (you may need to edit compile.m to use a different convolution 
    routine depending on your system)
7. Use 'demo_detection' code for a demo usage of the sparselet code for multiclass object detection.


