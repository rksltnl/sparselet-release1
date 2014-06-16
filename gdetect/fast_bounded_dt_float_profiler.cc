// AUTORIGHTS
// -------------------------------------------------------
// Copyright (C) 2013 Ross Girshick
// 
// Based on code from http://www.ics.uci.edu/~yyang8/
// research/pose/, which is in turn based on code from 
// http://cs.brown.edu/~pff/dt/.
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
#include <sys/types.h>
#include <algorithm>
#include "timer.h"

using namespace std;

// Generalized distance transforms based on Felzenszwalb and Huttenlocher's
// "Distance Transform of Sampled Functions." Theory of Computing, Vol. 8,
// No. 19, 2012.
//
// The cost function implemented here is a bounded quadratic:
//   d(x) = a*x^2 + b*x   if x \in [-range, range]
//   d(x) = inf           otherwise
//
// Some ideas for speeding up this code (i.e. precomputing division factors) 
// were taken from Charles Dubout's ffld code (http://www.idiap.ch/~cdubout/
// code/ffld.tar.gz).

static float eps = 0.00001;

static inline int square(int x) { return x*x; }

void dt1d(const float *src, float *dst, int *ptr, 
          int step, int n, float a, float b, float range,
          int *v, float *z, float *t) {
  int k     = 0;
  v[0]      = 0;
  z[0]      = -INFINITY;
  z[1]      = +INFINITY;
  
  float a_inv = 1/a;

  for (int q = 1; q <= n-1; q++) {
    // compute unbounded point of intersection
    float s = 0.5 * ((src[q*step] - src[v[k]*step]) * t[q - v[k]] 
                      + q + v[k] 
                      - b * a_inv);

    // bound point of intersection; +/- eps to handle boundary conditions
    s = min(v[k]+range+eps, max(q-range-eps, s));

    while (s <= z[k]) {
      // delete dominiated parabola
      k--;
      s = 0.5 * ((src[q*step] - src[v[k]*step]) * t[q - v[k]] 
                  + q + v[k] 
                  - b * a_inv);
      s = min(v[k]+range+eps, max(q-range-eps, s));
    }
    k++;
    v[k]   = q;
    z[k]   = s;
  }
  z[k+1] = INFINITY;

  k = 0;
  for (int q = 0; q <= n-1; q++) {
    while (z[k+1] < q)
      k++;
    dst[q*step] = a*square(q-v[k]) + b*(q-v[k]) + src[v[k]*step];
    ptr[q*step] = v[k];
  }
}

void dt1d(const float *src, float *dst, int *ptr, \
          int step, int n, float a, float b, float range,\
          int *v, float *z, float *t, Timer &timer6, Timer &timer7,\
          Timer &timer8, Timer &timer9, Timer &timer10) {
  int k     = 0;
  v[0]      = 0;
  z[0]      = -INFINITY;
  z[1]      = +INFINITY;
  
  float a_inv = 1/a;
  float ba_inv = b/a;

  timer6.start();
  for (int q = 1; q < n; q++) {
    
    timer8.start();
    // compute unbounded point of intersection
    int vk = v[k];
    float s = 0.5 * ((src[q*step] - src[vk*step]) * t[q - vk] 
                      + q + vk 
                      - ba_inv);
    timer8.stop();
    // bound point of intersection; +/- eps to handle boundary conditions
    timer9.start();
    s = min(v[k]+range+eps, max(q-range-eps, s));
    timer9.stop();

    timer10.start();
    while (s <= z[k]) {
      // delete dominiated parabola
      k--;
      s = 0.5 * ((src[q*step] - src[v[k]*step]) * t[q - v[k]] 
                  + q + v[k] 
                  - ba_inv);
      s = min(v[k]+range+eps, max(q-range-eps, s));
    }
    k++;
    v[k]   = q;
    z[k]   = s;
    timer10.stop();
  }
  timer6.stop();
  z[k+1] = INFINITY;

  timer7.start();
  k = 0;
  for (int q = 0; q < n; q++) {
    while (z[k+1] < q)
      k++;
    dst[q*step] = a*square(q-v[k]) + b*(q-v[k]) + src[v[k]*step];
    ptr[q*step] = v[k];
  }
  timer7.stop();
}

// matlab entry point
// [M, Ix, Iy] = fast_bounded_dt(vals, ax, bx, ay, by, range)
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) { 
  
  mexPrintf("Hello there1\n");
  
  Timer timer1;
  Timer timer2;
  Timer timer3;
  Timer timer4;
  Timer timer5;
  Timer timer6;
  Timer timer7;
  Timer timer8;
  Timer timer9;
  Timer timer10;
  
  if (nrhs != 6)
    mexErrMsgTxt("Wrong number of inputs"); 
  if (nlhs != 3)
    mexErrMsgTxt("Wrong number of outputs");
  if (mxGetClassID(prhs[0]) != mxSINGLE_CLASS)
    mexErrMsgTxt("Invalid input");

  enum {
    IN_VALS = 0,
    IN_AX,
    IN_BX,
    IN_AY,
    IN_BY,
    IN_RANGE
  };

  const int *dims = mxGetDimensions(prhs[IN_VALS]);
  const float *vals = (float *)mxGetPr(prhs[IN_VALS]);
  float ax = mxGetScalar(prhs[IN_AX]);
  float bx = mxGetScalar(prhs[IN_BX]);
  float ay = mxGetScalar(prhs[IN_AY]);
  float by = mxGetScalar(prhs[IN_BY]);
  float range = mxGetScalar(prhs[IN_RANGE]);
  
  mxArray  *mxM = mxCreateNumericArray(2, dims, mxSINGLE_CLASS, mxREAL);
  mxArray *mxIx = mxCreateNumericArray(2, dims,  mxINT32_CLASS, mxREAL);
  mxArray *mxIy = mxCreateNumericArray(2, dims,  mxINT32_CLASS, mxREAL);
  float   *M = (float *)mxGetPr(mxM);
  int32_t *Ix = (int32_t *)mxGetPr(mxIx);
  int32_t *Iy = (int32_t *)mxGetPr(mxIy);

  float   *tmpM = (float *)mxCalloc(dims[0]*dims[1], sizeof(float));
  int32_t *tmpIx = (int32_t *)mxCalloc(dims[0]*dims[1], sizeof(int32_t));
  int32_t *tmpIy = (int32_t *)mxCalloc(dims[0]*dims[1], sizeof(int32_t));

  // temporary storage used by 1d distance transforms
  int *v = new int[max(dims[0], dims[1])];
  float *z = new float[max(dims[0], dims[1]) + 1];
  float *t = new float[max(dims[0], dims[1])];
  
  // cache divisive factors used in 1d distance transforms
  timer1.start();
  t[0] = INFINITY;
  for (int y = 1; y < dims[0]; y++)
    t[y] = 1 / (-ay * y);
  timer1.stop();

  timer2.start();
  for (int x = 0; x < dims[1]; x++)
    dt1d(vals+x*dims[0], tmpM+x*dims[0], tmpIy+x*dims[0], 1, dims[0], 
         -ay, -by, range, v, z, t, timer6, timer7, timer8, timer9, timer10);
  timer2.stop();
  
  // cache divisive factors used in 1d distance transforms
  timer3.start();
  for (int x = 1; x < dims[1]; x++)
    t[x] = 1 / (-ax * x);
  timer3.stop();
  
  timer4.start();
  for (int y = 0; y < dims[0]; y++)
    dt1d(tmpM+y, M+y, tmpIx+y, dims[0], dims[1], 
         -ax, -bx, range, v, z, t);
  timer4.stop();
  
  // get argmaxes and adjust for matlab indexing from 1
  timer5.start();
  for (int x = 0; x < dims[1]; x++) {
    for (int y = 0; y < dims[0]; y++) {
      int p = x*dims[0]+y;
      Ix[p] = tmpIx[p]+1;
      Iy[p] = tmpIy[tmpIx[p]*dims[0]+y]+1;
    }
  }
  timer5.stop();
  
  timer1.printElapsed();
  timer2.printElapsed();
  timer3.printElapsed();
  timer4.printElapsed();
  timer5.printElapsed();
  
  timer6.printElapsed();
  timer7.printElapsed();
  
  timer8.printElapsed();
  timer9.printElapsed();
  timer10.printElapsed();
  
  delete [] v;
  delete [] z;
  delete [] t;

  mxFree(tmpM);
  mxFree(tmpIx);
  mxFree(tmpIy);
  plhs[0] = mxM;
  plhs[1] = mxIx;
  plhs[2] = mxIy;
}
