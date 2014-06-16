#include <sys/types.h>
#include "mex.h"
#include <xmmintrin.h>

const int S = 3;
const int NUM_SUB_FILTERS = 4;
/* 
 * Hyun Oh Song (song@eecs.berkeley.edu)
 * Part filter tiling 
 */

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

void tile_sparselets(double* Q_ptr, double* P_ptr, int s_dimy, int s_dimx, int out_dimy, int out_dimx, int i){
  // Q_ptr points to head of ith filter response
  // P_ptr points to head of temp array for tiled filter response
  //   0 | 1
  //   --+--
  //   2 | 3
  
  const int NUM_SUBFILTERS_X = 2;
  const int NUM_SUBFILTERS_Y = 2;

  for (int dy = 0; dy < NUM_SUBFILTERS_Y; dy++) {
    for (int dx = 0; dx < NUM_SUBFILTERS_X; dx++) {
      double *dst = P_ptr;
      
      for (int col = dx*S; col < dx*S + out_dimx; col++) {
        double *col_ptr = Q_ptr + col*s_dimy + dy*S;
        
#if 1
        // SSE version
        do_sum(dst, col_ptr, out_dimy);
        dst += out_dimy;
#else
        // Non-SSE version
        double *col_end = col_ptr + out_dimy;
        while (col_ptr != col_end)
          *(dst++) += *(col_ptr++);
#endif
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
    if (mxGetClassID(prhs[0]) != mxDOUBLE_CLASS)
        mexErrMsgTxt("Invalid input");
    
    const int* Q_dims = mxGetDimensions( prhs[0]);
    double*    Q_ptr  = (double*)mxGetPr(prhs[0]);
    int s_dimy   = mxGetScalar(prhs[1]);
    int s_dimx   = mxGetScalar(prhs[2]);
    int out_dimy = mxGetScalar(prhs[3]);
    int out_dimx = mxGetScalar(prhs[4]);
    int num_sub_filters_roots = mxGetScalar(prhs[5]);
    
    // Cell array of tiled filter response
    const int num_filters = (Q_dims[1] - num_sub_filters_roots) / NUM_SUB_FILTERS;
    mxArray *cell_array_ptr = mxCreateCellArray(1, &num_filters);
    
    int numel_ith_filter = Q_dims[0] * NUM_SUB_FILTERS;
    
    // Offset the Q pointer to where part filter begins (after roots)
    Q_ptr += Q_dims[0] * num_sub_filters_roots;

    // Temp array to hold tiled filter response
    const int P_dims[2] = {out_dimy, out_dimx};
    mxArray* mxP  = mxCreateNumericArray(2, P_dims, mxDOUBLE_CLASS, mxREAL);
    double* P_ptr_init = (double*)mxGetPr(mxP);
    double* P_ptr = P_ptr_init;    
    
    for (int i=0; i < num_filters; i++){

        tile_sparselets(Q_ptr, P_ptr, s_dimy, s_dimx, out_dimy, out_dimx, i);
        P_ptr = P_ptr_init; // point back to origin
        mxSetCell(cell_array_ptr, i, mxDuplicateArray(mxP));
        Q_ptr += numel_ith_filter;
    }
    
    plhs[0] = cell_array_ptr;
}
