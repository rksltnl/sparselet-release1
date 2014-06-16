/* 
 * Hyun Oh Song (song@eecs.berkeley.edu)
 * sparselet filter tiling 
 */

#include <sys/types.h>
#include "mex.h"

const int S = 3;
extern "C"{
  void saxpy_(int* n, float* alpha, float* x, \
           int* incX, float* y, int* incY);
};

void tile_sparselets(float* Q_ptr, float* P_ptr, int s_dimy, int s_dimx, int out_dimy, int out_dimx, int NUM_SUBFILTERS_Y, int NUM_SUBFILTERS_X){
  // Q_ptr points to head of ith filter response
  // P_ptr points to head of temp array for tiled filter response
  //   0 | 1
  //   --+--
  //   2 | 3
  
  float one = 1.0; 
  int inc = 1;
  
  for (int dy = 0; dy < NUM_SUBFILTERS_Y; dy++) {
    for (int dx = 0; dx < NUM_SUBFILTERS_X; dx++) {
      float *dst = P_ptr;
      
      for (int col = dx*S; col < dx*S + out_dimx; col++) {
        float *col_ptr = Q_ptr + col*s_dimy + dy*S;
        
        // HOS: mkl blas level 1, daxpy(n, a, x, incx, y, incy)
        saxpy_(&out_dimy, &one, col_ptr, &inc, dst, &inc);
        dst += out_dimy;
      }

      Q_ptr += (s_dimy * s_dimx); // Point Q_ptr to next sub-filter
    }
  }
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) { 

    if (nrhs != 5)
        mexErrMsgTxt("Wrong number of inputs");
    if (nlhs != 1)
        mexErrMsgTxt("Wrong number of outputs");
    if (mxGetClassID(prhs[0]) != mxSINGLE_CLASS)
        mexErrMsgTxt("Invalid input");
    
    const mwSize* Q_dims = mxGetDimensions( prhs[0]);
    float*    Q_ptr  = (float*)mxGetPr(prhs[0]);
    int s_dimy   = mxGetScalar(prhs[1]);
    int s_dimx   = mxGetScalar(prhs[2]);
    
    // load matrices of 2 by 54 of individual filter sizes, subfilter numbers
    const float* filter_sizes = (float*)mxGetPr(prhs[3]);
    const float* p_num_subfilters_per_filters = (float*)mxGetPr(prhs[4]);
    const mwSize* f_dims = mxGetDimensions(prhs[4]);  
    const mwSize  num_filters = (mwSize)f_dims[1];
    
    //mexPrintf("0]%f, 1]%f\n", p_num_subfilters_per_filters[0], p_num_subfilters_per_filters[1]);
    
    mxArray *cell_array_ptr = mxCreateCellArray(1, &num_filters);

    for (int i=0; i < num_filters; i++){
        const int out_dimy  = s_dimy + S - *(filter_sizes++);
        const int out_dimx  = s_dimx + S - *(filter_sizes++);
        const mwSize P_dims[2] = {out_dimy, out_dimx};
        
        // Temp array to hold tiled filter response
        mxArray* mxP  = mxCreateNumericArray(2, P_dims, mxSINGLE_CLASS, mxREAL);
        float* P_ptr_init = (float*)mxGetPr(mxP);
        float* P_ptr = P_ptr_init;       
        
        int numy = *(p_num_subfilters_per_filters++);
        int numx = *(p_num_subfilters_per_filters++);

        tile_sparselets(Q_ptr, P_ptr, s_dimy, s_dimx, out_dimy, out_dimx, numy, numx);
        P_ptr = P_ptr_init; // point back to origin
        mxSetCell(cell_array_ptr, i, mxP);
        
        // Point to next filter
        Q_ptr += Q_dims[0]*numy*numx;        
    }
    
    plhs[0] = cell_array_ptr;    
}