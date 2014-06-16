#include <sys/types.h>
#include "mex.h"

const int S = 3;
const int NUM_SUB_FILTERS = 4;
/* 
 * Hyun Oh Song (song@eecs.berkeley.edu)
 * Part filter tiling 
 */

void tile_sparselets(double* Q_ptr, double* P_ptr, int s_dimy, int s_dimx, int out_dimy, int out_dimx, int i){
    // Q_ptr points to head of ith filter response
    // P_ptr points to head of temp array for tiled filter response
    //   0 | 1
    //   --+--
    //   2 | 3
    
    int col=0, row=0, P_idx=0; 
    int stop_idx = out_dimx * out_dimy;
    // Copy P0
    while (P_idx < stop_idx){
        if (row == out_dimy){
            row = 0;
            col += s_dimy;
        }
        P_ptr[P_idx++] = Q_ptr[col+row];
        row++;
    }
    Q_ptr += (s_dimy * s_dimx); // Point Q_ptr to next sub-filter
    
    // Copy P1
    col=S*s_dimy; row=0; P_idx=0;
    while (P_idx < stop_idx){
        if (row == out_dimy){
            row = 0;
            col += s_dimy;
        }
        P_ptr[P_idx++] += Q_ptr[col+row];
        row++;
    }
    Q_ptr += (s_dimy * s_dimx);
    
    // Copy P2
    col=0; row=S; P_idx=0;
    while (P_idx < stop_idx){
        if (row == (S + out_dimy)){
            row = S;
            col += s_dimy;
        }
        P_ptr[P_idx++] += Q_ptr[col+row];
        row++;
    }
    Q_ptr += (s_dimy * s_dimx);
    
    // Copy P3
    col=S*s_dimy; row=S; P_idx=0;
    while (P_idx < stop_idx){
        if (row == (S + out_dimy)){
            row = S;
            col += s_dimy;
        }
        P_ptr[P_idx++] += Q_ptr[col+row];
        row++;
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
    
    // Temp array to hold tiled filter response
    int P_dims[2] = {out_dimy, out_dimx};
    mxArray* mxP  = mxCreateNumericArray(2, P_dims, mxDOUBLE_CLASS, mxREAL);

    // Cell array of tiled filter response
    const int num_filters = (Q_dims[1] - num_sub_filters_roots) / NUM_SUB_FILTERS;
    mxArray *cell_array_ptr = mxCreateCellArray(1, &num_filters);
    
    int numel_ith_filter = Q_dims[0] * NUM_SUB_FILTERS;
    double* P_ptr_init = (double*)mxGetPr(mxP);
    double* P_ptr = P_ptr_init;
    
    // Offset the Q pointer to where part filter begins (after roots)
    Q_ptr += Q_dims[0] * num_sub_filters_roots;
    
    for (int i=0; i < num_filters; i++){
        tile_sparselets(Q_ptr, P_ptr, s_dimy, s_dimx, out_dimy, out_dimx, i);
        P_ptr = P_ptr_init; // point back to origin
        mxSetCell(cell_array_ptr, i, mxDuplicateArray(mxP));
        if (i != (num_filters-1))
            Q_ptr += numel_ith_filter;
    }
    
    plhs[0] = cell_array_ptr;
}
