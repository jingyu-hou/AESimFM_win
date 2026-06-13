# include <stdlib.h>
# include <stdio.h>


void readxstateini ( double *xstate, int nlen, int n1, int n2, int n3 ) {
  FILE * fptr ;
  int index ;
  int k, j, i ;

  if ((fptr = fopen("inistate.inp","r")) == NULL){
    printf("Error! opening file");

    // Program exits if the file pointer returns NULL.
    exit(1);
  }

  for ( k = 0; k < n3; k++ ) {
    for ( j = 0; j < n2; j++ ) {
      for ( i = 0; i < n1; i++ ) {
	if ( i == 0 ) {
	  index = ( k ) * n1 * n2 + ( j ) * n1 + i ;
	  fscanf(fptr,"%lf", &xstate[index]);
	}
      }
    }
  }

  //printf("Value of n=%f", num);
  fclose(fptr); 

  if ( (fptr = fopen("stbl.inp","r") ) == NULL ) {
    printf("Error! opening file");
    exit(1) ;
  }

  
  for ( k = 0; k < n3; k++ ) {
    for ( j = 0; j < n2; j++ ) {
      for ( i = 0; i < n1; i++ ) {
	if ( i > 6 && i < 13 ) {
	  index = ( k ) * n1 * n2 + ( j ) * n1 + i ;
	  fscanf(fptr,"%lf", &xstate[index]);
	}
      }
    }
  }


}
