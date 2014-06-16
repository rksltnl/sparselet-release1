#include "mex.h"
#include "string.h"
//#include "timer.h"
#include "mkl_spblas.h"

/*
 *  C = alpha * A * B + beta * C
 *  B and C are dense matrices, A is m-by-k sparse matrix in csc format
 *  B is k-by-n matrix
 * 
 *  Take as input preparsed sparse matrix of val, ja, ia
 *
 *  Input, A_val, ja, ia, A_dims=[m(#rows in A), k(#cols in A)], B
 */

// extern "C"{
//   void mkl_scscmm(char* chn, ptrdiff_t* m, ptrdiff_t* n, ptrdiff_t* k, \
//        float* alpha, char* matdescra, float* val, int* indx, \
//        int* pntrb, int* pntre, \
//        float* b, ptrdiff_t* ldb, float* beta, float* c, ptrdiff_t* ldc);
// };

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{  
  //Timer time1;
  //Timer time2;
  char *chn = "T";
  char* matdescra = "G00C";
  float one = 1.0, zero = 0.0;
  
  float* A_val    = (float*)mxGetPr(prhs[0]);
  int* ja  = (int*)mxGetPr(prhs[1]);
  int* ia  = (int*)mxGetPr(prhs[2]);
  double* A_dims = mxGetPr(prhs[3]);
  float* B      = (float*)mxGetPr(prhs[4]);
  
  int m = (int)A_dims[0];
  int k = (int)A_dims[1];
  int n = (int)mxGetM(prhs[4]);
  //mexPrintf("m=%d, k=%d, n=%d\n", m, k, n);
  
  // create output matrix C
  plhs[0] = mxCreateNumericMatrix(k, n, mxSINGLE_CLASS, mxREAL);
  //plhs[0] = mxCreateDoubleMatrix(k,n,mxREAL);
  float* C_out = (float*)mxGetPr(plhs[0]);
  //float* C_sur = (float*)malloc(sizeof(float) * k*n);
  //float* C_sur = (float*)mxMalloc(k*n* sizeof(float));
  
//  time1.start();
  //mkl_scscmm_(chn, &m, &n, &k, &one, matdescra, A_val, ja, &ia[0], &ia[1], \
  //        B, &n, &zero, C_sur, &n);
    mkl_scscmm(chn, &m, &n, &k, &one, matdescra, A_val, ja, &ia[0], &ia[1], \
          B, &n, &zero, C_out, &n);
//  time1.stop();
  
//  time2.start();
//   float* p_C_sur = C_sur;
//   for (int rowid=0; rowid<k; rowid++){
//     for (int colid=0; colid<n; colid++){
//       C_out[rowid + colid*k] = *(p_C_sur++);
//     }
//   }
//   time2.stop();
  
//   time1.printElapsed();
//   time2.printElapsed();
  
  //free(C_sur);
  //mxFree(C_sur);
}
