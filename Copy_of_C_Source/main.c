/*
 *  main.c
 *  cvode_test
 *
 *  Created by Andrew Matteson on 1/31/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include "mex.h"
#include "call_cvode.c"
#include <omp.h>
#include <stdio.h>

static int call_cvode(realtype param[], realtype init_array[],double RTOL,double atol_array[],realtype tstep_array[], realtype tout_array[],int NOUT,realtype y_out[][NEQ]);

void mexFunction(int nlhs,mxArray* plhs[], int nrhs, const mxArray* prhs[])
{	

	int iter,jter,kter; /* Looping indices */

	if (nrhs < 3) {
		mexErrMsgIdAndTxt("MATLAB:call_cvode:not_enough_args",
						  "You cannot call that without parameter array and timepts. >:-( ANGRYFACE!!!");

	}
	/* Unpack parameter array */
	
	int param_m = mxGetM(prhs[0]);
    int param_n = mxGetN(prhs[0]);

	if (param_m != NUMOUT | param_n != NUMPARAM) {
		mexErrMsgIdAndTxt("MATLAB:call_cvode:paramdimension",
						  "The input parameter set has incorrect dimensions.  It must be NUMOUT x NUMPARAM. >:-( ANGRYFACE!!!");
	}
	
    realtype *pPTR = mxGetPr(prhs[0]);
	realtype param[param_m][param_n];
	
	for (jter=0; jter<param_m; jter++) {
		for (kter=0; kter<param_n; kter++) {
			param[jter][kter] = pPTR[kter*param_m + jter];
		}
	}
	realtype param_scratch[param_n];
	
	/* Unpack initial array */
	
	int initn = mxGetN(prhs[1]);
	int initm = mxGetM(prhs[1]);

	realtype *initPTR = mxGetPr(prhs[1]);

	if (initm != NUMOUT | initn != NEQ) {
		mexErrMsgIdAndTxt("MATLAB:call_cvode:atol_size",
						  "The input initial value set has incorrect dimensions.  It must be NUMOUT x NEQ. >:-( ANGRYFACE!!!");
	}
	
	realtype init_array[initm][initn]; /* initial values */
	for (jter=0; jter<initm; jter++) {
		for (kter=0; kter<initn; kter++) {
			init_array[jter][kter] = initPTR[kter*initm + jter];
		}
	}
	
	realtype init_scratch[initn];
		
	/* Unpack time array */
	
	realtype *stepPTR = mxGetPr(prhs[2]);
	
	int numsteps = mxGetN(prhs[2]);
	realtype tstep_array[numsteps];
	for (iter=0; iter<numsteps; iter++) {
		tstep_array[iter] = stepPTR[iter];
	}
	
	realtype *outPTR = mxGetPr(prhs[3]);

	int time_n = mxGetN(prhs[3]);
	realtype tout_array[time_n];
	for (iter=0; iter<time_n; iter++) {
		tout_array[iter] = outPTR[iter];
	}
	
	int NOUT = time_n; /* (length of tstep_array) */
	

	/* Unpack optional tolerances, default if not declared */
	/* absolute tolerances */
	
	double atol_array[NEQ];
	if (nrhs>3) {
		realtype *atolPTR = mxGetPr(prhs[4]);
		int atoln = mxGetN(prhs[4]);
		if (atoln != NEQ) {
			mexErrMsgIdAndTxt("MATLAB:call_cvode:atol_size",
							  "length(atol_array) must be the same as the number of equations. >:-( ANGRYFACE!!!");
		}
		for (iter=0; iter<atoln; iter++) {
			atol_array[iter] = atolPTR[iter];
		}
	}
	else {
		for (iter=0; iter<NEQ; iter++) {
			atol_array[iter] = 1.0e-8;
		}
	}
		
	/* relative tolerances */
	
	double RTOL;
	if (nrhs>5) {
		realtype *rtolPTR = mxGetPr(prhs[5]);
		RTOL = rtolPTR[0];
	}
	else {
		RTOL = 1.0e-6;	
	}
		
	/* Load in number of execution threads */
	int numThreads;
	int cSize;
	if (nrhs>6) {
		realtype *ntPTR = mxGetPr(prhs[6]);
		numThreads = (int) ntPTR[0];
	}
	else {
		mexErrMsgIdAndTxt("MATLAB:call_cvode:profile",
						  "To profile by thread number you must supply all rhs arguments. >:-( ANGRYFACE!!!");
	}
	
	omp_set_num_threads(numThreads);

	/* Create output constructs*/
		
	realtype y_out[NOUT][NEQ][NUMOUT];
	realtype y_scratch[NOUT][NEQ];
	int err_test;
	int err_temp;
	err_test = 0;
	err_temp = 0;
	bool abort = false;
 
	#pragma omp parallel for schedule(dynamic,1) shared(y_out,param,init_array,RTOL, atol_array,tstep_array,tout_array,NOUT,abort) private(iter,param_scratch,init_scratch,y_scratch,jter,kter,err_temp) reduction(+:err_test)
	for (iter=0; iter<=NUMOUT-1; iter++) {
		
		for (jter = 0; jter<initn; jter++) {
			init_scratch[jter] = init_array[iter][jter];
		}
		
		for (jter = 0; jter<param_n; jter++) {
			param_scratch[jter] = param[iter][jter];

		}
		
		/* must handle errors */
	
if(err_test==0){
	err_temp = call_cvode(param_scratch,init_scratch,RTOL, atol_array,tstep_array,tout_array,NOUT,y_scratch);
	        err_test = err_test + err_temp;	
	
		
		for (jter = 0; jter<NOUT; jter++) {
			for (kter=0; kter<NEQ; kter++) {
				y_out[jter][kter][iter] = y_scratch[jter][kter];
			}
		}
	}
	 
}
/* Error testing */
if (err_test <0){
	mexErrMsgIdAndTxt("MATLAB:CVODE:general_fail","Sometimes the world just doesn't like you.");
}
	/* Construct Output */
	double *output;
	double *yPTR = &y_out[0][0][0];
	int dims[] = {NOUT, NEQ, NUMOUT};
	
	plhs[0] = mxCreateNumericArray(3, dims, mxDOUBLE_CLASS, mxREAL);
	output = mxGetPr(plhs[0]);
	
	/* Populate the output */
	for (iter=0; iter<NUMOUT; iter++) {
		for (jter=0; jter<NEQ; jter++) {
			for (kter=0; kter<NOUT; kter++) {
				output[iter*NEQ*NOUT + jter*NOUT + kter] = yPTR[iter + jter*NUMOUT + kter*NEQ*NUMOUT];
			}
		}
	}
}


