#include "mex.h"
#include <math.h>
#include <xmmintrin.h>
#include <stdint.h>


// matlab entry point
// Q = fast_sparse_mult(R, AlphaM, BetaM);
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) { 
  enum {
    IN_R = 0,
    IN_ALPHA,
    IN_BETA
  };

  const mxArray *mx_R = prhs[IN_R];
  const mxArray *mx_A = prhs[IN_ALPHA];
  const mxArray *mx_B = prhs[IN_BETA];

  const mwSize *R_dims = mxGetDimensions(mx_R);
  const mwSize *A_dims = mxGetDimensions(mx_A);

  const float *R    = (float *)mxGetPr(mx_R);
  const float *A    = (float *)mxGetPr(mx_A);
  const uint64_t *B = (uint64_t *)mxGetPr(mx_B);

  const mwSize Q_dims[] = { R_dims[1], A_dims[1] };
  mxArray *mx_Q = mxCreateNumericArray(2, Q_dims, mxDOUBLE_CLASS, mxREAL);
  double *Q = mxGetPr(mx_Q);

  const int R_rows = R_dims[0];
  const int A_rows = A_dims[0];
  const int Q_rows = Q_dims[0];

  for (int i = 0; i < R_dims[1]; i++) {
    const float *R_col = R + i*R_rows;

    for (int j = 0; j < A_dims[1]; j++) {
      const float *A_col = A + j*A_rows;
      const uint64_t *B_col = B + j*A_rows;

      float r = 0;
      for (int k = 0; k < A_dims[0]; k++) {
        r += R_col[B_col[k]] * A_col[k];
      }
      *(Q + i + Q_rows*j) = r;
    }
  }

  plhs[0] = mx_Q;
}
