#include "mex.h"

/*
 * Take MATLAB's double sparse matrix and return
 *  float value and ja, ia indices (csc format)
 */

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  double* A = mxGetPr(prhs[0]);
  int n = mxGetN(prhs[0]);
  
  mwIndex* ir = mxGetIr(prhs[0]); // nnz length, row indicies
  mwIndex* jc = mxGetJc(prhs[0]); // n+1 length, funky indicies
  int     nnz = jc[n]; 
  
  // Copy double A into float (length equal to nnz)
  plhs[0] = mxCreateNumericMatrix(nnz, 1, mxSINGLE_CLASS, mxREAL);
  float* p_A_float = (float*)mxGetPr(plhs[0]);
  for (int i=0; i<nnz; i++){
    p_A_float[i] = A[i];
  }
  
  // Copy ja
  plhs[1] = mxCreateNumericMatrix(nnz, 1, mxINT32_CLASS, mxREAL);
  int* ja = (int*)mxGetPr(plhs[1]);
  for (int i=0; i < nnz; i++)
    ja[i] = (int)ir[i];
  
  // Copy ia
  plhs[2] = mxCreateNumericMatrix(n+1, 1, mxINT32_CLASS, mxREAL);
  int* ia = (int*)mxGetPr(plhs[2]);
  for (int i=0; i < n+1; i++)
    ia[i] = (int)jc[i];
}
