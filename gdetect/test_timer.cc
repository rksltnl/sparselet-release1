#include "mex.h"
#include "timer.h"
#include <unistd.h>

/* Test how the timer works inside a loop
 * Q) Does it refresh or increment?
 * A) Increments. 
 * Time elapsed : 100.114
 * Time elapsed : 100.114
 */

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) { 
  
  Timer timer1;
  Timer timer2;
  
  timer1.start();
  for (int i=0; i<100; i++){
    timer2.start();
    usleep(1000000);  // sleep 1 seconds
    timer2.stop();
  }
  timer1.stop();
  
  timer1.printElapsed();
  timer2.printElapsed();
}
    