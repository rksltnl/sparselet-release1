/* 
 * Hyun Oh Song (song@eecs.berkeley.edu)
 * sparselet filter tiling 
 */

#include <sys/types.h>
#include "mex.h"
#include <xmmintrin.h>

const int S = 3;

static inline void do_sum_sse(double *dst, const double *src, const double *src_end) {
  while (src != src_end) {
    _mm_storeu_pd(dst, _mm_add_pd(_mm_loadu_pd(dst), _mm_loadu_pd(src)));
    src += 2;
    dst += 2;
  }
}

static inline void do_sum(double *dst, const double *src_begin, size_t size) {
  if ((size % 2) == 0)
    return do_sum_sse(dst, src_begin, src_begin+size);

  size_t size2 = (size/2)*2;
  do_sum_sse(dst, src_begin, src_begin+size2);
  for (size_t i = size2; i < size; i++)
    dst[i] += src_begin[i];
}

void tile_sparselets(double* Q_ptr, double* P_ptr, int s_dimy, int s_dimx, int out_dimy, int out_dimx, int NUM_SUBFILTERS_Y, int NUM_SUBFILTERS_X){
  // Q_ptr points to head of ith filter response
  // P_ptr points to head of temp array for tiled filter response
  //   0 | 1
  //   --+--
  //   2 | 3
  
  for (int dy = 0; dy < NUM_SUBFILTERS_Y; dy++) {
    for (int dx = 0; dx < NUM_SUBFILTERS_X; dx++) {
      double *dst = P_ptr;
      
      for (int col = dx*S; col < dx*S + out_dimx; col++) {
        double *col_ptr = Q_ptr + col*s_dimy + dy*S;
        
        // SSE version
        do_sum(dst, col_ptr, out_dimy);
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
    if (mxGetClassID(prhs[0]) != mxDOUBLE_CLASS)
        mexErrMsgTxt("Invalid input");
    
    const int* Q_dims = mxGetDimensions( prhs[0]);
    double*    Q_ptr  = (double*)mxGetPr(prhs[0]);
    int s_dimy   = mxGetScalar(prhs[1]);
    int s_dimx   = mxGetScalar(prhs[2]);
    
    // load matrices of 2 by 54 of individual filter sizes, subfilter numbers
    const double* filter_sizes = (double*)mxGetPr(prhs[3]);
    const double* p_num_subfilters_per_filters = (double*)mxGetPr(prhs[4]);
    const int* f_dims = mxGetDimensions(prhs[4]);  
    const int  num_filters = f_dims[1];
    
    //mexPrintf("0]%f, 1]%f\n", p_num_subfilters_per_filters[0], p_num_subfilters_per_filters[1]);
    
    mxArray *cell_array_ptr = mxCreateCellArray(1, &num_filters);

    for (int i=0; i < num_filters; i++){
        const int out_dimy  = s_dimy + S - *(filter_sizes++);
        const int out_dimx  = s_dimx + S - *(filter_sizes++);
        const int P_dims[2] = {out_dimy, out_dimx};
        
        // Temp array to hold tiled filter response
        mxArray* mxP  = mxCreateNumericArray(2, P_dims, mxDOUBLE_CLASS, mxREAL);
        double* P_ptr_init = (double*)mxGetPr(mxP);
        double* P_ptr = P_ptr_init;       
        
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