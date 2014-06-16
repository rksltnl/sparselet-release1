#include "mex.h"
#include <algorithm>

using namespace std;

// matlab entry point
// B = post_pad(A, pady, padx, val)
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) { 
  const float pady = (float)mxGetScalar(prhs[1]);
  const float padx = (float)mxGetScalar(prhs[2]);
  const float val = (float)mxGetScalar(prhs[3]);
  const mwSize *A_dims = mxGetDimensions(prhs[0]);
  const mwSize B_dims[] = { A_dims[0] + pady, A_dims[1] + padx };
  mxArray *mx_B = mxCreateNumericArray(2, B_dims, mxSINGLE_CLASS, mxREAL);
  float *B = (float *)mxGetPr(mx_B);
  const float *A = (float *)mxGetPr(prhs[0]);

  // Fill each column
  for (int x = 0; x < A_dims[1]; x++) {
    float *B_col = B + x*B_dims[0];
    const float *A_col = A + x*A_dims[0];
    copy(A_col, A_col+A_dims[0], B_col);

    if (pady > 0)
      fill(B_col+A_dims[0], B_col+B_dims[0], val);
  }

  fill(B + A_dims[1]*B_dims[0], B+B_dims[0]*B_dims[1], val);

  plhs[0] = mx_B;
}
