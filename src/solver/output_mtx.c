# include <stdlib.h>
# include <stdio.h>
# include <sys/types.h>
# include <sys/stat.h>
# include <unistd.h>


void output_mtx ( double *ad, double *au, double * adb, double *aub, double *rhs,
		  int * neq, int * nzs, int * icol, int * irow, int * symmetryflag,
		  int solstatus, int inc, int iit ) {
  FILE * fptr ;
  char str1[10];
  char str2[10];
  char str3[20];
  int const nperline = 15;
  int i, j ;

  // make ./mat direcotry if not exists:
  struct stat st={0};
  if ( stat("./mat", &st) == -1 ) {
    _mkdir ( "./mat" ) ;
  }


  sprintf ( str1, "%05d", inc ) ;
  sprintf ( str2, "%03d", iit ) ;
  

  sprintf ( str3,"./mat/mt_%s_%s.txt", str1, str2 ) ;



  if ( solstatus == 0 ) {


    if ( (fptr = fopen(str3,"a") ) == NULL) {
      printf("Error! opening file") ;
      exit(1) ;
    }

    fprintf ( fptr, "Square\n" ) ;
    fprintf ( fptr, "symmetric\n" ) ;
    fprintf ( fptr, "calc\n" ) ;
    fprintf ( fptr, "%d\n", neq[1] ) ;
    fprintf ( fptr, "%d\n", nzs[1] ) ;

    fprintf ( fptr, "icol:\n" ) ;
    for ( i = 0 ; i<neq[1]; i++ ) {
      if ( i == neq[1]-1 ) {
	fprintf ( fptr, "%d\n", icol[i] ) ;
      } else {
	if ( (i + 1)%nperline == 0 ) {
	  fprintf ( fptr, "%d\n", icol[i] ) ;
	} else {
	  fprintf ( fptr, "%d, ", icol[i] ) ;
	}
      }
    }
    fprintf ( fptr, "end\n" ) ;

    fprintf ( fptr, "irow:\n" ) ;
    for ( i = 0 ; i<nzs[1]; i++ ) {
      if ( i == nzs[1]-1 ) {
	fprintf ( fptr, "%d\n", irow[i] ) ;
      } else {
	if ( (i + 1)%nperline == 0 ) {
	  fprintf ( fptr, "%d\n", irow[i] ) ;
	} else {
	  fprintf ( fptr, "%d, ", irow[i] ) ;
	}
      }
    }
    fprintf ( fptr, "end\n" ) ;
    fprintf ( fptr, "\n" ) ;

    fprintf ( fptr, "mass matrix:\n" ) ;
    fprintf ( fptr, "diagonal elements:\n" ) ;
    for ( i = 0; i<neq[1]; i++ ) {
      if ( i == neq[1]-1 ) {
	fprintf ( fptr, "%11.4E\n", adb[i] ) ;
      } else {
	if ( (i + 1)%nperline == 0 ) {
	  fprintf ( fptr, "%11.4E\n", adb[i] ) ;
	} else {
	  fprintf ( fptr, "%11.4E, ", adb[i] ) ;
	}
      }
    }
    fprintf ( fptr, "end\n" ) ;
 
    fprintf ( fptr, "off-diagonal elements:\n" ) ;
    for ( i = 0; i<nzs[1]; i++ ) {
      if ( i == nzs[1]-1 ) {
	fprintf ( fptr, "%11.4E\n", au[i] ) ;
      } else {
	if ( (i + 1)%nperline == 0 ) {
	  fprintf ( fptr, "%11.4E\n", au[i] ) ;
	} else {
	  fprintf ( fptr, "%11.4E, ", au[i] ) ;
	}
      }
    }
    fprintf ( fptr, "end\n" ) ;
    fprintf ( fptr, "\n" ) ;

    fprintf ( fptr, "stiffness matrix:\n" ) ;
    fprintf ( fptr, "diagonal elements:\n" ) ;
    for ( i = 0; i<neq[1]; i++ ) {
      if ( i == neq[1]-1 ) {
	fprintf ( fptr, "%11.4E\n", ad[i] ) ;
      } else {
	if ( (i + 1)%nperline == 0 ) {
	  fprintf ( fptr, "%11.4E\n", ad[i] ) ;
	} else {
	  fprintf ( fptr, "%11.4E, ", ad[i] ) ;
	}
      }
    }
    fprintf ( fptr, "end\n" ) ;
 
    fprintf ( fptr, "off-diagonal elements:\n" ) ;
    for ( i = 0; i<nzs[1]; i++ ) {
      if ( i == nzs[1]-1 ) {
	fprintf ( fptr, "%11.4E\n", au[i] ) ;
      } else {
	if ( (i + 1)%nperline == 0 ) {
	  fprintf ( fptr, "%11.4E\n", au[i] ) ;
	} else {
	  fprintf ( fptr, "%11.4E, ", au[i] ) ;
	}
      }
    }
    fprintf ( fptr, "end\n" ) ;
    fprintf ( fptr, "\n" ) ;
  

  
    fprintf ( fptr, "right hand side:\n" ) ;
    for ( i = 0; i<neq[1]; i++ ) {
      if ( i == neq[1]-1 ) {
	fprintf ( fptr, "%11.4E\n", rhs[i] ) ;
      } else {
	if ( (i + 1)%nperline == 0 ) {
	  fprintf ( fptr, "%11.4E\n", rhs[i] ) ;
	} else {
	  fprintf ( fptr, "%11.4E, ", rhs[i] ) ;
	}
      }
    }
    fprintf ( fptr, "end\n" ) ;

    fclose(fptr);

  } else if ( solstatus > 0 ) {
    if ( (fptr = fopen(str3,"a") ) == NULL) {
      printf("Error! opening file") ;
      exit(1) ;
    }
    
    fprintf ( fptr, "solution:\n" ) ;
    for ( i = 0; i<neq[1]; i++ ) {
      if ( i == neq[1]-1 ) {
	fprintf ( fptr, "%11.4E\n", rhs[i] ) ;
      } else {
	if ( (i + 1)%nperline == 0 ) {
	  fprintf ( fptr, "%11.4E\n", rhs[i] ) ;
	} else {
	  fprintf ( fptr, "%11.4E, ", rhs[i] ) ;
	}
      }
    }
    fprintf ( fptr, "end\n" ) ;

    fclose(fptr);

  } // end if solstatus

}
