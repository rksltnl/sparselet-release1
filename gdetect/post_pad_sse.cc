// AUTORIGHTS
// -------------------------------------------------------
// Copyright (C) 2011-2012 Ross Girshick
// 
// This file is part of the voc-releaseX code
// (http://people.cs.uchicago.edu/~rbg/latent/)
// and is available under the terms of an MIT-like license
// provided in COPYING. Please retain this notice and
// COPYING if you use this file (or a portion of it) in
// your project.
// -------------------------------------------------------

#include "mex.h"
#include <math.h>
#include <algorithm>
#include <xmmintrin.h>
#include <stdint.h>

// OS X aligns all memory at 16-byte boundaries (and doesn't provide
// memalign/posix_memalign).  On linux, we use memalign to allocated 
// 16-byte aligned memory.
#if !defined(__APPLE__)
#include <malloc.h>
#define malloc_aligned(a,b) memalign(a,b)
#else
#define malloc_aligned(a,b) malloc(b)
#endif

#define IS_ALIGNED(ptr) ((((uintptr_t)(ptr)) & 0xF) == 0)

using namespace std;

/* SSE version of std::copy */
static inline void do_copy_sse( double* start,  double* end, double* dst){    
    //if (!IS_ALIGNED(end))
    //    mexErrMsgTxt("end Memory not aligned");
    
    while (start != end){
        //if (!IS_ALIGNED(start))
        //    mexErrMsgTxt("start Memory not aligned");
        //if (!IS_ALIGNED(dst))
        //    mexErrMsgTxt("dst Memory not aligned");
        _mm_store_pd(dst, _mm_load_pd(start));
        dst += 2;
        start += 2;
    }
}   

static inline void do_copy( double* start,  double* end, size_t size, double* dst){
    if ((size%2)==0){
        return do_copy_sse(start, end, dst);
    }
    
    size_t size2 = (size/2)*2;
    do_copy_sse(start, start+size2, dst);

    for (size_t i = size2; i < size; i++)
        dst[i] = start[i];
}

/* SSE version of std::fill */
static inline void do_fill_sse(double* start, double* end, const double val, __m128d val_vec){
    while (start != end){
        _mm_store_pd(start, val_vec);
        start += 2;
    }
}

static inline void do_fill(double* start, double* end, size_t size, const double val, __m128d val_vec){
    
  if ((size %2) == 0)
      return do_fill_sse(start, end, val, val_vec);
  
  size_t size2 = (size/2)*2;
  do_fill_sse(start, start+size2, val, val_vec);
  for (size_t i = size2; i < size; i++)
      start[i] = val;
}

double* prepare(double* in, const int* dims){
  double* F = (double*)malloc_aligned(16, dims[0]*dims[1]*sizeof(double));
  // Sanity check that memory is aligned
  if (!IS_ALIGNED(F))
    mexErrMsgTxt("Memory not aligned");
  
  double* p = F;
  for (int x=0; x < dims[1]; x++){
      for (int y=0; y < dims[0]; y++){
          *(p++) = in[y + x*dims[0]];
      }
  }
  return F;
}

// matlab entry point
// B = post_pad(A, pady, padx, val)
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) { 
  const double pady = mxGetScalar(prhs[1]);
  const double padx = mxGetScalar(prhs[2]);
  const double val = mxGetScalar(prhs[3]);
  const mwSize *A_dims = mxGetDimensions(prhs[0]);
  const mwSize B_dims[] = { A_dims[0] + pady, A_dims[1] + padx };
  //mxArray *mx_B = mxCreateNumericArray(2, B_dims, mxDOUBLE_CLASS, mxREAL);
  double* B = (double*)malloc_aligned(16, B_dims[0]*B_dims[1]*sizeof(double));
  double* A = prepare((double *)mxGetPr(prhs[0]), A_dims);

  __m128d val_vec;
  val_vec = _mm_set_pd(val, val);
  bool isOddRows = false;
  // if odd number of rows, do top row separately, rest is done sse
  if (A_dims[0]%2 ==1){
    isOddRows = true;  
    for (int x = 0; x < A_dims[1]; x++){
        double* B_col = B + x*B_dims[0];
        double* A_col = A + x*A_dims[0];
        *B_col = *A_col;
    } 
  }
  
  // Fill each column
  for (int x = 0; x < A_dims[1]; x++) {
    double *B_col = B + x*B_dims[0];
    double *A_col = A + x*A_dims[0];
    
    if (x%2 ==1 && isOddRows){
        //mexPrintf("%d, Offset B,A\n", x);
        B_col++;
        A_col++;
    }
    
    //if (!IS_ALIGNED(B_col))
    //    mexErrMsgTxt("*B_col not aligned");
    
    //if (!IS_ALIGNED(A_col))
    //    mexErrMsgTxt("*A_col not aligned");
    
    do_copy(A_col, A_col+A_dims[0], A_dims[0], B_col);
    //copy(A_col, A_col+A_dims[0], B_col);

    if (pady > 0)
      //do_fill(B_col+A_dims[0], B_col+B_dims[0], B_dims[0]-A_dims[0], val, val_vec);
      fill(B_col+A_dims[0], B_col+B_dims[0], val);
  }

  //do_fill(B + A_dims[1]*B_dims[0], B+B_dims[0]*B_dims[1], B_dims[0]*B_dims[1] - A_dims[1]*B_dims[0], val, val_vec);
  fill(B + A_dims[1]*B_dims[0], B+B_dims[0]*B_dims[1], val);

  mxArray* mx_C = mxCreateNumericArray(2, B_dims, mxDOUBLE_CLASS, mxREAL);
  double*  C = (double*)mxGetPr(mx_C);
  memcpy(C, B, B_dims[0]*B_dims[1]*sizeof(double));
  //for (int i=0; i < B_dims[0]*B_dims[1]; i++){
  //   *(C++) = *(B++);
  //}

  plhs[0] = mx_C;

  free(B);
  free(A);
}
