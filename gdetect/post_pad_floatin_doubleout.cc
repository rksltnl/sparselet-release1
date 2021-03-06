#include "mex.h"
#include <algorithm>

using namespace std;

// matlab entry point
// B = post_pad(A, pady, padx, val)
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) { 
  const double pady = mxGetScalar(prhs[1]);
  const double padx = mxGetScalar(prhs[2]);
  const double val  = mxGetScalar(prhs[3]);
  const mwSize *A_dims = mxGetDimensions(prhs[0]);
  const mwSize B_dims[] = { A_dims[0] + pady, A_dims[1] + padx };
  mxArray *mx_B = mxCreateNumericArray(2, B_dims, mxDOUBLE_CLASS, mxREAL);
  double *B = (double *)mxGetPr(mx_B);
  const float *A = (float *)mxGetPr(prhs[0]);

  // Fill each column
  for (int x = 0; x < A_dims[1]; x++) {
    double *B_col = B + x*B_dims[0];
    const float *A_col = A + x*A_dims[0];
    copy(A_col, A_col+A_dims[0], B_col);

    if (pady > 0)
      fill(B_col+A_dims[0], B_col+B_dims[0], val);
  }

  fill(B + A_dims[1]*B_dims[0], B+B_dims[0]*B_dims[1], val);

  plhs[0] = mx_B;
}
