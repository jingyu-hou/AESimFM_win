#include<stdio.h>
#include <sys/time.h>
#include <stdio.h>



void itinerate_print ( int nint, int * ints, char ** anno_ints,
		       int ndoubles, double * dbles, char ** anno_dbles ) {

  int ii;
  int is_print;
  int elapsed_time;
  int const_itinerate_time = 15;

  struct timeval tv;

  static int icall = 0;
  static int set_time = 0;
  static int initime = 0;

  
  if ( icall == 0 ) {

    gettimeofday(&tv, NULL);
    initime = tv.tv_sec;

    set_time = const_itinerate_time ;

    is_print = 1 ;

    icall = 1 ;
  } else {
    gettimeofday(&tv, NULL);

    elapsed_time = tv.tv_sec - initime ;

    if ( elapsed_time > set_time ) {
      is_print = 1;
      set_time += const_itinerate_time;
    } else {
      is_print = 0;
    }

  }
    

  elapsed_time = tv.tv_sec - initime ;

  if ( is_print == 1 ) {

    //printf ( "itinerate printing at time = %d\n", elapsed_time ) ;

    for ( ii = 0; ii < nint; ii++ ) {
      //printf ( "%s = %d\n", anno_ints[ii], ints[ii] ) ;
    }

    for ( ii = 0; ii < ndoubles; ii++ ) {
      //printf ( "%s = %f\n", anno_dbles[ii], dbles[ii] ) ;
    }
    //printf ( "end of itinerate printing\n" ) ;
  }


}



