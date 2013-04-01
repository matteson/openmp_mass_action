/* -----------------------------------------------------------------
 * Adapted from CVODE example originally by:
 *
 * Programmer(s): Scott D. Cohen, Alan C. Hindmarsh and
 *                Radu Serban @ LLNL
 * -----------------------------------------------------------------
*/

#include "odefun.c"

static void parampass(UserData *data, realtype param[]);
static int  check_flag(void *flagvalue, char *funcname, int opt);

/*
 *-------------------------------
 * Main Program
 *-------------------------------
 */

static int call_cvode(realtype param[], realtype init_array[],realtype RTOL,realtype atol_array[],realtype tstep_array[], realtype tout_array[],int NOUT,realtype y_out[][NEQ])
{
	realtype T0 = tstep_array[0];
	realtype reltol, t, tstep, tout;
	N_Vector y, abstol;
	void *cvode_mem;
	int flag, istep, iout;
		
	y = abstol = NULL;
	cvode_mem = NULL;
	
	/* Encapsulate param into data structure */
		
	UserData* data;
	data = NULL;
	data = (UserData*) malloc(sizeof *data);  /* Allocate data memory */
	if(check_flag((void *)data, "malloc", 2)) return(1);
		
	parampass(data,param);
	
	staticJac(data);
	
	data->J_diag = N_VNew_Serial(NEQ);

	/* Create serial vector of length NEQ for I.C. and abstol */
	y = N_VNew_Serial(NEQ);
	if (check_flag((void *)y, "N_VNew_Serial", 0)) return(1);
	abstol = N_VNew_Serial(NEQ); 
	if (check_flag((void *)abstol, "N_VNew_Serial", 0)) return(1);
	
	/* Initialize y */
	int n; /* looping index */
	realtype *y_data = NV_DATA_S(y);	
	for (n = 0; n < NEQ; n = n + 1)
	{
		y_data[n] = init_array[n];
	}

	for (n = 0; n<NEQ; n++) {
		y_out[0][n] = y_data[n]; /* set initial conditions into mem */
	}
		
	/* Set the scalar relative tolerance */
	reltol = RTOL;
	
	/* Set the vector absolute tolerance */
	realtype *abstol_data = NV_DATA_S(abstol);
	for (n = 0; n < NEQ;n = n + 1 ) {
		abstol_data[n] = atol_array[n];
	}
	
	/* Call CVodeCreate to create the solver memory and specify the 
	 * Backward Differentiation Formula and the use of a Newton iteration */
	cvode_mem = CVodeCreate(CV_BDF, CV_NEWTON);
	if (check_flag((void *)cvode_mem, "CVodeCreate", 0)) return(1);
	
	/* Call CVodeInit to initialize the integrator memory and specify the
	 * user's right hand side function in y'=f(t,y), the inital time T0, and
	 * the initial dependent variable vector y. */
	
	flag = CVodeInit(cvode_mem, f, T0, y);
	if (check_flag(&flag, "CVodeInit", 1)) return(1);
	
	/* Call CVodeSVtolerances to specify the scalar relative tolerance
	 * and vector absolute tolerances */
	flag = CVodeSVtolerances(cvode_mem, reltol, abstol);
	if (check_flag(&flag, "CVodeSVtolerances", 1)) return(1);
	
	/* Set the pointer to user-defined data */
	flag = CVodeSetUserData(cvode_mem, data);
	if(check_flag(&flag, "CVodeSetUserData", 1)) return(1);
	
	/* Call CVSpgmr to specify the linear solver CVSPGMR 
	 * with left preconditioning and the maximum Krylov dimension maxl */
	flag = CVSpgmr(cvode_mem, PREC_LEFT, 0);
	if(check_flag(&flag, "CVSpgmr", 1)) return(1);
	
	/* set the JAcobian-times-vector function */
	flag = CVSpilsSetJacTimesVecFn(cvode_mem, jtv);
	if(check_flag(&flag, "CVSpilsSetJacTimesVecFn", 1)) return(1);
	
	/* Set modified Gram-Schmidt orthogonalization */
	flag = CVSpilsSetGSType(cvode_mem, MODIFIED_GS);
	if(check_flag(&flag, "CVSpilsSetGSType", 1)) return(1);
	
	/* Set the preconditioner solve and setup functions */
	flag = CVSpilsSetPreconditioner(cvode_mem, Precond, PSolve);
	if(check_flag(&flag, "CVSpilsSetPreconditioner", 1)) return(1);
	
	flag = CVodeSetErrHandlerFn(cvode_mem, ehfun, NULL);

	
	flag = CVodeSetMaxNumSteps(cvode_mem,15000);

	
	/* In loop, call CVode and test for error. */
	iout  = 1;  tout  = tout_array[1];
	istep = 1;  tstep = tstep_array[1]; /* We take tstep_array[1] since initial time is given in vector array */
	n = 2;
			
	int ii;
	
	while(1) {

		flag = CVode(cvode_mem, tstep, y, &t, CV_NORMAL);
		if (check_flag(&flag, "CVode", 1)) break;
		/*printf("tstep: %f\n",tstep);*/

		if (tstep == tout) {
			/*printf("tout: %f with iout: %i with istep: %i\n",tout,iout,istep);*/

		for (ii = 0; ii<NEQ; ii++) {
			y_out[iout][ii] = y_data[ii]; /*danger here, screw up indexes and will write y_out into t_array or segfault */
		}
			iout++;
			tout = tout_array[iout];
		}
		
		
		if (flag == CV_SUCCESS) {
			/*printf("tout: %f with iout: %i with istep: %i\n",tout,iout,istep);*/
			istep++;			
		}
		
		if (iout == NOUT) break; /* Want to reconstruct this so it checks the length of tstep_array */
		tstep = tstep_array[istep];

	}
	
	
	/* Free y and abstol vectors */
	N_VDestroy_Serial(y);
	N_VDestroy_Serial(abstol);
	N_VDestroy_Serial(data->J_diag);
	
	free(data);
	
	/* Free integrator memory */
	CVodeFree(&cvode_mem);

	return(flag);
}

/*
 *-------------------------------
 * Private helper functions
 *-------------------------------
 */

static int check_flag(void *flagvalue, char *funcname, int opt)
{
	int *errflag;
	
	/* Check if SUNDIALS function returned NULL pointer - no memory allocated */
	if (opt == 0 && flagvalue == NULL) {
	/*	fprintf(stderr, "\nSUNDIALS_ERROR: %s() failed - returned NULL pointer\n\n",
				funcname); */
		return(1); }
	
	/* Check if flag < 0 */
	else if (opt == 1) {
		errflag = (int *) flagvalue;
		if (*errflag < 0) {
		/*	fprintf(stderr, "\nSUNDIALS_ERROR: %s() failed with flag = %d\n\n",
					funcname, *errflag);*/
		/* possibily move mex error handling into here for more control */
			return(1); }}
	
	/* Check if function returned NULL pointer - no memory allocated */
	else if (opt == 2 && flagvalue == NULL) {
	/*	fprintf(stderr, "\nMEMORY_ERROR: %s() failed - returned NULL pointer\n\n",
				funcname);
	*/	return(1); }
	
	return(0);
}


