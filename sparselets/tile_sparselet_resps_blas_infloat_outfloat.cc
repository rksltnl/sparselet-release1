#include <sys/types.h>
#include "mex.h"

/* 
 * Hyun Oh Song (song@eecs.berkeley.edu)
 * Part filter tiling 
 */
 
const int S = 3;
const int NUM_SUB_FILTERS = 4;
const int NUM_SUBFILTERS_X = 2;
const int NUM_SUBFILTERS_Y = 2;

extern "C"{
  void saxpy_(int* n, float* alpha, float* x, \
           int* incX, float* y, int* incY);
};

inline void tile_sparselets(float* Q_ptr, float* P_ptr, int s_dimy, int s_dimx, int out_dimy, int out_dimx, int i){
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
        //mexPrintf("outdimy: %d\n", out_dimy);
        saxpy_(&out_dimy, &one, col_ptr, &inc, dst, &inc);
        dst     += out_dimy;
      }

      Q_ptr += (s_dimy * s_dimx); // Point Q_ptr to next sub-filter
    }
  }
}   
  

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) { 

    if (nrhs != 6)
        mexErrMsgTxt("Wrong number of inputs");
    if (nlhs != 1)
        mexErrMsgTxt("Wrong number of outputs");
    if (mxGetClassID(prhs[0]) != mxSINGLE_CLASS)
        mexErrMsgTxt("Invalid input");
    
    const mwSize* Q_dims = mxGetDimensions( prhs[0]);
    float*    Q_ptr  = (float*)mxGetPr(prhs[0]);
    int s_dimy   = (int)mxGetScalar(prhs[1]);
    int s_dimx   = (int)mxGetScalar(prhs[2]);
    int out_dimy = (int)mxGetScalar(prhs[3]);
    int out_dimx = (int)mxGetScalar(prhs[4]);
    int num_sub_filters_roots = (int)mxGetScalar(prhs[5]);
    
    // Cell array of tiled filter response
    mwSize num_filters = (mwSize)(Q_dims[1] - num_sub_filters_roots) / NUM_SUB_FILTERS;
    mxArray *cell_array_ptr = mxCreateCellArray(1, &num_filters);
    
    int numel_ith_filter = Q_dims[0] * NUM_SUB_FILTERS;
    
    // Offset the Q pointer to where part filter begins (after roots)
    Q_ptr += Q_dims[0] * num_sub_filters_roots;
    
    for (int i=0; i < num_filters; i++){
        // Temp array to hold tiled filter response
        mwSize P_dims[2] = {out_dimy, out_dimx};
        mxArray* mxP  = mxCreateNumericArray(2, P_dims, mxSINGLE_CLASS, mxREAL);
        float* P_ptr_init = (float*)mxGetPr(mxP);
        float* P_ptr = P_ptr_init;

        tile_sparselets(Q_ptr, P_ptr, s_dimy, s_dimx, out_dimy, out_dimx, i);
        P_ptr = P_ptr_init; // point back to origin
        mxSetCell(cell_array_ptr, i, mxP);
        Q_ptr += numel_ith_filter;
    }
    
    plhs[0] = cell_array_ptr;
}
