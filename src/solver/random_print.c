#include<stdio.h>
#include <sys/time.h>
#include <stdio.h>


void random_print (int nint, int * ints, char ** anno_ints,
		   int ndoubles, double * dbles, char ** anno_dbles,
		   int number ) {
  
  
  static int icall = 0;
  int is_print = 0 ;
  int r, ii ;

  
  if ( icall == 0 ) {
    srand(time(NULL)); // Initialization, should only be called once.
    icall = 1;
  }

  r = rand()%number + 1; // Returns a pseudo-random integer between 1 and number.

  
  if ( r == 1 ) {
    is_print = 1 ;
  } else {
    is_print = 0 ;
  }

  if ( is_print == 1 ) {

    printf ( "random printing\n" ) ;
    for ( ii = 0; ii < nint; ii++ ) {
      printf ( "%s = %d\n", anno_ints[ii], ints[ii] ) ;
    }

    for ( ii = 0; ii < ndoubles; ii++ ) {
      printf ( "%s = %f\n", anno_dbles[ii], dbles[ii] ) ;
    }
    printf ( "end of random printing\n" ) ;
  }

}

