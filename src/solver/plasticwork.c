# include <stdio.h>
# include <string.h>
# include <stdlib.h>
# include <pthread.h>
#include "solver.h"


#define NSTORAGE 20000000
#define MAX_CONNEC 60
#define MAX_NOD 20



int checkheatmaterial(char * input, int imat) {
  int i, j ;
  int ipos ;
  int count ;
  char input_trimmed[80] ;
  int result ;
  
  
  int start = (imat - 1) * 80 ;

  const int nmaterial = 5 ;
  const char* names_heatmaterial[5];
  names_heatmaterial[0]="ARRHENIUS" ;
  names_heatmaterial[1]="HANSEN";
  names_heatmaterial[2]="HANSEN_SPITTEL";
  names_heatmaterial[3]="HANSEN-SPITTEL";
  names_heatmaterial[4]="HANSEN SPITTEL";



  for ( i = 0; i < 80; i++ ) {
    input_trimmed[i] = ' ' ;
  }
 
  // trim input
  // find the first non blank position:
  /*
  for ( i = 0 + start; i < 80 + start; i++ ) {
    if (input[i] != ' ') break ;
  }
  ipos = i ;

  count = 0 ;
  for ( i = ipos; i < 80; i++ ) {
    input_trimmed[count] = input[i];
    count = count + 1 ;
  }
  */

  for(i = 0; i < nmaterial; i++ ) {

    result = 1 ; 
    for ( j = 0; j < strlen(names_heatmaterial[i]); j++ ) {
      if ( names_heatmaterial[i][j] != input[j+start] ) {
	result = 0 ;
	break ;
      }
    }
    

    if ( result == 1 ) {
      return result ;
    } 
    
  }
  
  return result ;
}
















double interpolate_mat ( double * mat_pages, int max_1st, int max_2nd,
			 int * ntemps, int imat, 
			 double temperature, int index ) {
  /*
    mat_pages(index,itemp,imat)
    mat_pages(0 ~ max_1st-1, 1 ~ max_2nd, * )
    index starts from 0
    itemp starts from 1
    imat starts from 1
  */

  
  double * temperature_array;
  double * val_array;

  int ind_head_mat, local_ind, global_ind_temp, global_ind_val ;
  int ntemp_points ;
  int j,ii ;
  double val ;
  double point0, point1, val0, val1 ;
  

  ntemp_points = ntemps[imat-1] ;




  temperature_array = malloc ( sizeof(double) * ntemp_points ) ;
  val_array = malloc ( sizeof(double) * ntemp_points ) ;
  
  ind_head_mat = ( imat - 1 ) * max_1st * max_2nd ;
  
  local_ind = 0 ;
  for ( j = 0; j < ntemp_points; j++ ) {

    global_ind_temp = ( imat - 1 ) * max_1st * max_2nd + max_1st * j ;
    global_ind_val  = ( imat - 1 ) * max_1st * max_2nd + max_1st * j + index ;

    temperature_array[j] = mat_pages[global_ind_temp];
    val_array[j] = mat_pages[global_ind_val];
      
  }

  
  //printf ( "temperature = %f", temperature ) ;

  /*
  if ( imat > 1 ) {
    for ( ii = 0; ii < 8; ii++ ) {
      printf ( "%f ", temperature_array[ii] );
    }
    printf ( "\n" );
    for ( ii = 0; ii < 8; ii++ ) {
      printf ( "%f ", val_array[ii] );
    }
    printf ( "\n" );
    printf ( "%f ", temperature ) ;
  }
  */

  
  if ( ntemp_points < 2 ) {
    val = val_array[0];
    goto deallocate_return ;
  }

  if ( temperature < temperature_array[0] ) {
    val = val_array[0];
    goto deallocate_return;
  } else if ( temperature > temperature_array[ntemp_points-1] ) {
    val = val_array[ntemp_points-1];
    goto deallocate_return;
  } else {

    for ( j = 0; j < ntemp_points-1; j++ ) {
      if  ( temperature >= temperature_array[j] && temperature <= temperature_array[j+1] ) {
	break;
      }
    }

  }

  //printf ( "j = %d", j ) ;
  point0 = temperature_array[j];
  point1 = temperature_array[j+1];
  val0 = val_array[j];
  val1 = val_array[j+1];
  val  = val0 + (val1 - val0)/(point1 - point0) * ( temperature - point0 ) ;

  

 deallocate_return:
  free ( temperature_array );
  free ( val_array ) ;

  return val ;

}






void plasticwork ( char * matname,
		   double * xstate,  int * nstate, 
		   double * stx, double * ener, 
		   double * pwork,
		   double * shcon, int *nshcon,
		   double * rhcon, int *nrhcon, double * t1, 
		   double * v, double * vold, 
		   double * vini,
		   int * mi, int * ne, 
		   char * lakon, 
		   int * kon, double * co, 
		   int * nk,
		   double *elcon, int * nelcon, 
		   int * ipkon, double* rdpcon, 
		   int* ielmat, int * ntmat, int * iout,
		   double * ttime, double* time ) {

  /*
    It is assumed here that only one material and one temperature point is used
    elastic strain is assumed to be small
  */

  /*
    elcon  :  elastic constants
    stx    :  stress at ip
    shcon  :  thermal constants ( specific heat )
    rhcon  :  density constants
    lakon  :  element label
    ipkon  :  kklocation in kon of the first node in the element connectivity
    kon    :  element connectivity
    ener   :  total energy density calculated from stress : strain
    list of element i)-1
  */


  #include "index.h"


  char char5[] = "     " ;
  char lakon3, lakon4, lakon5 ;
  int i, j, k, ie, ip, index, index1, ic, nope, nip;
  int indexe, konl[MAX_NOD], node_index, elnum ;
  int count, num_el, inode2, node_num, node_num1, node_num2 ;
  double energy_density, elastic_energy_density ;
  double stress[6] ;
  double strain[6], plstrain[6], plstrain0[6], del_plstrain[6] ;
  // note: the off-diagonal components of plastic strain are multiplied by the factor of 2
  double G, Youngs, Poisson ;
  double sph, density ;
  double * ptr_volume ;
  double volume, ivol ;
  double elplasticwork ;
  double totvolume, totdtemp ;
  FILE *pFile ;


  double largest_ptr_dtemp_node ;
  double largest_ptr_dtemp_el ;
  int ie_largest_ptr_dtemp_el ;
  int largest_ptr_node_el;

  int inode;
  int nlayer;
  int imat;
  double plratio;
  double temp;

  
  int debug_ints[5];
  char *debug_ints_anno[5] = {'\0'};
  double debug_dbles[5];
  char *debug_dbles_anno[5] = {'\0'};



  static int count_called  = 0 ;
  static double plwork_storage [ NSTORAGE ] ;
  //static double plstrain_storage [12000000] ; // store total plastic strain
  static double yield_stress_storage [ NSTORAGE ] ; // store yield stress
  static double eqp_storage[ NSTORAGE ]; // store equivalent plastic strain

  double plworkdensity ;
  double ystress, eqp, delta_eqp, ave_stress ;
  int flag ;


  //struct heatmaterialnames heatmat ;

  

  /*
  ptr_node_el : elements to which a node belong.
  nptr_node_el : length of ptr_node_el
  pwork : delta plastic work during one increment.
  plwork_storage : plastic work in last increment
  ptr_dtemp_node : nodal temperature increase.
  ptr_nope : number of nodes for each element.
  */


  /*
  if ( rdpcon[index_material_rdpcon] < 1.0 ) {
    return ;
  } 
  */


  if ( * iout <= 0 ) {
    return ;
  }



  nip = *mi ;
  nlayer = mi[2] ;

  if ( 0 == count_called ) {
    for ( i = 0; i < NSTORAGE; i++ ) {
      plwork_storage[i] = 0.0 ;
      yield_stress_storage[i] = 0.0 ;
      eqp_storage[i] = 0.0;
    }
    /*
    for ( i = 0; i < NSTORAGE; i++ ) {
      plstrain_storage[i] = 0.0 ;
    }
    */

  }



  //printf ( "%f, %f, %f, %f\n", Youngs, Poisson, sph, density ) ;
  //printf ( "here1\n" ) ;
  // default parameters:
  // WRONG

  /*
  for ( i = 0; i<80; i++ )
    printf("%c\n",matname[i] ) ; 

  printf("%d\n", *nshcon ) ;
  */


  /*
  Youngs  = elcon[1] ;
  printf ( "here1\n" ) ;
  Poisson = elcon[2] ;
  printf ( "here2\n" ) ;
  density = rhcon[1] ; 
  printf ( "here4\n" ) ;
  sph = shcon[1] ;
  printf ( "here5\n" ) ;
  */
  

  

  G = Youngs / ( 2.0 * ( 1.0 + Poisson ) ) ;

  /*
  count = 0 ;
  pFile = fopen ( "debug01.txt", "a" ) ;
  for ( int i = 0; i < *ne; i++ ) {
    for ( int j = 0; j < 9; j++ ) {
      fprintf ( pFile, "%d , \n", kon[count++] ) ;
    }
  }
  fclose(pFile) ;
  */



  // allocate space :
  ptr_volume = malloc(sizeof(double)) ;
  double * ptr_elvolumes = malloc((*ne) * sizeof(double) ) ; // volumes of each element
  int nptr_node_el = MAX_CONNEC * (*nk) ;

  /* ptr_node_el stores the element numbers sharing one node */
  int * ptr_node_el = malloc( nptr_node_el * sizeof(int) ) ; /* element numbers (at most
								19) for each node */
  int * ptr_nope  = malloc((*ne) * sizeof(int) ); /* number of nodes for each element */
  double *ptr_dtemp_el = malloc((*ne) * sizeof(double) ) ; // temperature incr of elements

  for ( i = 0; i < nptr_node_el; i++ ) ptr_node_el[i] = 0 ;
  /* ptr_node_el[0] number of elements
     ptr_node_el[1..19] element number ( 0 by default )
  */


  // determine ptr_node_el and ptr_nope
  for ( ie = 0; ie < * ne; ie++  ) {
  // reference : printoutelem.f
  index  = ie * 8 ; // lakon contains at most 8 characters for each element
    for ( i = 0; i < 5; i++ ) {
      char5[i] = lakon[index+i] ;
    }
    lakon3 = lakon[index+3] ;

    //printf("ie =%d, lakon3 = %c\n", ie, lakon3) ;
    lakon4 = lakon[index+4] ;
    if ( 0 == strcmp ( char5, "C3D8I" ) ) {
      nope = 11 ;
    } else if ( '2' == lakon3 ) {
      nope = 20 ;
    } else if ( '8' == lakon3 ) {
      nope = 8 ;
    } else if ( '1' == lakon3 && '0' == lakon4 ) {
      nope = 10 ;
    } else if ( '4' == lakon3 ) {
      nope = 4 ;
    } else if ( '1' == lakon3 && '5' == lakon4 ) {
      nope = 15 ;
    } else if ( '6' == lakon3 ) {
      nope = 6 ;
    } else {
      nope = 0 ;
    }
    ptr_nope[ie] = nope ;



    indexe = ipkon[ie] ;
    for ( j = 0; j < nope; j++ ) {
      konl[j] = kon[indexe+j] ; // node number
      node_index = ( konl[j] - 1 ) * MAX_CONNEC ;
      ptr_node_el[node_index] = ptr_node_el[node_index] + 1 ;
      ptr_node_el[node_index + ptr_node_el[node_index] ] = ie + 1; // element number
    }

  } // end of for ie

  /*
  largest_ptr_node_el = 0;
  printf ( "nptr_node_el = %d\n", nptr_node_el ) ;
  for ( i = 0; i < nptr_node_el; i++ ) {
    if ( largest_ptr_node_el < ptr_node_el[i] ) {
      largest_ptr_node_el = ptr_node_el[i];
    }
  }
  */

  //printf ( "here2\n" ) ;




  // obtain elemental temperature increase
  for ( ie = 0; ie < *ne; ie++ ) {

    // check if the element is a normal element
    if ( 0 == ptr_nope[ie] ) {
      continue ;
    }

    imat = ielmat[nlayer*ie] ;

    // check if the element is heat material:
    int checkresult = checkheatmaterial(matname, imat) ;
    //checkresult = 0 ;



    //rdpcon[index_nd12_rdpcon*(imat-1)+index_material_rdpcon] );
    if ( checkresult < 1 ) {
      plratio = 0.0 ;
    } else {
    if ( rdpcon[index_nd12_rdpcon*(imat-1) + 
		index_material_rdpcon] < 1.0 ) {
      plratio = 0.0;
      //ptr_dtemp_el[ie] = 0.0 ;
    } else { 
      plratio = rdpcon[index_nd12_rdpcon*(imat-1) 
		       + index_pwratio_rdpcon] ;
      //printf ( "rdpcon[ratio] = %f\n", 
      //rdpcon[index_nd12_rdpcon*(imat-1) + 9] );
      //printf ( "rdpcon[material] = %f\n", 
      //rdpcon[index_nd12_rdpcon*(imat-1)+index_material_rdpcon] );
      //printf ( "rdpcon[7] = %f\n", 
      //rdpcon[index_nd12_rdpcon*(imat-1) + 7] );
      //printf ( "ratio position = %d\n", 
      //index_nd12_rdpcon*(imat-1)+index_pwratio_rdpcon );
    }
    }


    FORTRAN ( calcvol2, (&ie, &nip, lakon, kon, co, ipkon, ptr_volume) ) ;
    // nip may be altered by calcvol

    volume = *ptr_volume ;
    ptr_elvolumes[ie] = volume ;

    elplasticwork = 0.0 ; // plastic work for an element
    if ( checkresult < 1 ) {
      ptr_dtemp_el[ie] = 0.0 ;

    } else {
    for ( ip = 0; ip < nip; ip++ ) {


      // extract temperature:
      
      index = nstate[0] * ( *mi ) * ie + nstate[0] * ip ;
      index = index + index_temp_xstate ;
      temp = xstate[index] ;
      

      sph = interpolate_mat(shcon, 4, *ntmat, 
			    nshcon, imat, 
			    temp, 1) ;


      density = interpolate_mat(rhcon, 2, *ntmat,
				nrhcon, imat,
				temp, 1 );

      debug_ints[0] = imat;
      debug_ints[1] = nshcon[imat-1];
      debug_ints[2] = *ntmat;
      debug_dbles[0] = temp;
      debug_dbles[1] = sph;
      debug_dbles[2] = density;
      debug_ints_anno[0] = "imat";
      debug_ints_anno[1] = "nshcon[imat-1]";
      debug_ints_anno[2] = "*ntmat";
      debug_dbles_anno[0] = "temperature";
      debug_dbles_anno[1] = "sph";
      debug_dbles_anno[2] = "density";
      
      
//    random_print ( 3, debug_ints, debug_ints_anno,
//		     3, debug_dbles, debug_dbles_anno, 1000 ) ;
      
	

      index1 = (*mi) * ie + ip ; // *mi is the number of max ip
      energy_density = ener[index1] ; // ener

      // extract stress for each ip:
      for ( ic = 0; ic < 6; ic ++ ) {
	index = 6 * (*mi) * ie + 6 * ip + ic ;
	stress[ic] = stx[index] ;
      } // end for ic


      // extract current yield stress for each ip:
      index = nstate[0] * ( *mi ) * ie + nstate[0] * ip ;
      index = index + 9 - 1 ;
      ystress = xstate[index] ;


      // extract current eqp for each ip:
      index = nstate[0] * ( *mi ) * ie + nstate[0] * ip ;
      eqp = xstate[index] ;


      





      // this is for test only:
      /*
      if ( eqp > 0.0 ) {
	ystress =  2.0e9 ;
      } else {
	ystress = 0.0 ;
      }
      */

      delta_eqp = eqp - eqp_storage[index1];
      ave_stress = 0.5 * 
	( ystress + yield_stress_storage[index1] ) ;

      plworkdensity = plratio * 
	ave_stress * delta_eqp ;

      if ( plworkdensity > 0.0 ) {
	pwork[index1] = plworkdensity;
	plwork_storage[index1] += pwork[index1] ;
      } else {
	pwork[index1]  = 0.0 ;
	// plwork_storage[index1] = plwork_storage[index1] ;
      }


      eqp_storage[index1] = eqp ;
      yield_stress_storage[index1] = ystress ;



      //  by using 0.5 * \sigma_ij \epsilon_ij
      /*
      index = nstate[0] * (*mi) * ie + nstate[0] * ip ;
      for ( ic = 0; ic < 6; ic++ ) {
	plstrain[ic] = xstate[index + ic + 1] ;
      }

      index = 6 * (*mi) * ie + 6 * ip ;
      for ( ic = 0; ic < 6; ic++ ) {
	plstrain0[ic] = plstrain_storage[index + ic] ;
      }

      for ( ic = 0; ic < 6; ic++ ) {
	del_plstrain[ic] = plstrain[ic] - plstrain0[ic] ;
      }

      plworkdensity = 0.0 ;
      for ( ic = 0; ic < 6; ic++ ) {
	plworkdensity += stress[ic]*del_plstrain[ic];
      }
      plworkdensity = plworkdensity * 0.5;


      if ( plworkdensity > 0.0 ) {
	pwork[index1] = plworkdensity ;
	plwork_storage[index1] += pwork[index1] ;
      } else {
	pwork[index1] = 0.0 ;
	// plwork_storage[index1] = plwork_storage[index1] ;
      }
      */




      //  by using ( total energy - elastic energy )
      /*
      strain[0] = 1.0/Youngs *
	( stress[0] - Poisson * ( stress[1] + stress[2] ) ) ;
      strain[1] = 1.0/Youngs *
	( stress[1] - Poisson * ( stress[0] + stress[2] ) ) ;
      strain[2] = 1.0/Youngs *
	( stress[2] - Poisson * ( stress[0] + stress[1] ) ) ;
      strain[3] = 0.5 / G * stress[3] ;
      strain[4] = 0.5 / G * stress[4] ;
      strain[5] = 0.5 / G * stress[5] ;

      elastic_energy_density = strain[0] * stress[0] + strain[1] * stress[1] +
	strain[2] * stress[2] + 2.0 * strain[3] * stress[3] +
	2.0 * strain[4] * stress[4] + 2.0 * strain[5] * stress[5] ;
      elastic_energy_density = 0.5 * elastic_energy_density ;
      */

      /*
      if ( energy_density - elastic_energy_density > plwork_storage[index1] ) {
	// additional plastic work is generated and accumulated.
	pwork[index1] = energy_density - elastic_energy_density  - plwork_storage[index1] ;
	plwork_storage[index1] = energy_density - elastic_energy_density ;
      } else {
	// no additional plastic work is generaged.
	pwork[index1] = 0.0 ;
	//plwork_storage[index] = plwork_storage[index] ;
	}
      */


      /*
      pwork [index1] = energy_density - elastic_energy_density  - plwork_storage[index1] ;
      if ( pwork[index1] < 0.0 ) pwork [index1] = 0.0 ;
      // delta plastic work must be nonnegative

      //if ( pwork[index1] > 1.0e-6 ) {
	//printf ( "ie = %d, ip = %d\n, pwork[index1] = %.10e\n", ie, ip, pwork[index1] );
      //}

      plwork_storage[index1] = energy_density - elastic_energy_density ;
      if ( plwork_storage[index1] < 0.0 ) plwork_storage [index1] = 0.0 ;
      // total plastic work must be nonnegative
      */

      /*
	      calculating the specific heat (needed for the capacity matrix)
      */


      ivol = volume / ((double)(nip)) ; // it is assumed that all ips have the same weight
      // it must be changed later
      elplasticwork = elplasticwork + pwork[index1] * ivol ;

      /*
      if ( ie == 683 && ip == 0 ) { // for statistics

      pFile = fopen ( "el_ip_plasticwork.txt", "a" ) ;

      fprintf ( pFile, "%E, %d, %d, %E, %E, %E \n", (*ttime) + (*time), ip+1, ie+1,
		pwork[index1], energy_density, volume ) ;

      fclose(pFile) ;


      } // end if ( ie == 0 && ip == 0 ) */


    } // end for ip
    
    ptr_dtemp_el[ie] = elplasticwork / ( volume * density ) / sph ;
    }


  } //  end for ie

  //exit(0);



  /* calculate nodal tempterature increment*/
  double * ptr_dtemp_node = malloc ( (*nk) * sizeof(double) ) ;

  for ( inode = 0; inode < *nk; inode++ ) {
    // something is wrong here

    node_index = inode * MAX_CONNEC ; /* at most 19 connectivity for each element */
    num_el = ptr_node_el[node_index] ;
    if ( num_el <= 0 ) {
      ptr_dtemp_node[inode] = 0.0 ;
    } else {

      //printf ( "inode = %d, num_el =%d \n", inode, num_el );


      totdtemp  = 0.0 ;
      totvolume = 0.0 ;
      for ( j = 0; j < num_el; j++ ) {
	index1 = node_index + j + 1 ;
	elnum = ptr_node_el[index1] ;
	totvolume = totvolume + ptr_elvolumes[elnum-1] ;
	//printf ( "ptr_dtemp_el[elnum-1] = %.5e, elnum = %d\n", ptr_dtemp_el[elnum-1], elnum ) ;
	//printf ( "ptr_elvolumes[elnum-1] = %.5e, elnum = %d\n", ptr_elvolumes[elnum-1], elnum ) ;

	totdtemp  = totdtemp  + ptr_dtemp_el[elnum-1] * ptr_elvolumes[elnum-1] ;
      }
      ptr_dtemp_node[inode] = totdtemp / totvolume ;
      //printf ( "ptr_dtemp_node[%d] = %.5e\n", inode, totdtemp/totvolume );
    }
  }

  /*
  largest_ptr_dtemp_node = 0.0;
  for ( i = 0 ; i < *nk; i++ ) {
    if (ptr_dtemp_node[i] > largest_ptr_dtemp_node) {
      largest_ptr_dtemp_node = ptr_dtemp_node[i] ;
    }
  }
  printf( "largest_ptr_dtemp_node = %.10e", largest_ptr_dtemp_node ) ;
  getchar();
  */



  //printf("here5\n");




  // update initial temperature:
  for ( ie = 0; ie < * ne; ie++ ) {
    index = ie * 8 ;
    lakon3 = lakon[index+3] ;

    //printf("lakon3 = %c, ptr_nope[%d] = %d\n", lakon3, ie, ptr_nope[ie] ) ;
    //printf("lakon6 = %c \n", lakon[index+6] ) ;
    //getchar();

    if ( 0 == ptr_nope[ie] ) {
      continue;
    }


    /*
    if ( lakon[index+6] != 'A' && lakon[index+6] != 'E' ) { // this is 3D element without extension
      if ( lakon3 == '8' ) { // eight node element
	indexe = ipkon[ie] ;
	for ( i = 0; i < 8; i++ ) {
	  node_num = kon[indexe+i] ;
	  ptr_dtemp_node[node_num] = 0.5 * (
					    ptr_dtemp_node)
	}
      }
    }
    */



    if ( '6' == lakon3 ) {

      if ( 'E' == lakon[index+6] || 'A'==lakon[index+6] ) {
	indexe = ipkon[ie] ;
	for ( i = 0; i < 3; i++ ) {
	  node_num = kon[indexe+i] + 1 ; // number of ghost node
	  // change the temperature on
	  ptr_dtemp_node[node_num-1] = ptr_dtemp_node[node_num] ;
	}
	for ( i = 0; i < 3; i++ ) {
	  node_num = kon [ indexe + 6 + i ]  ; // number of real node
	  node_num1 = kon [ indexe + i ] ; // number of extended node 1
	  node_num2 = kon [ indexe + 3 + i ] ; // number of extended node 2
	  ptr_dtemp_node [ node_num - 1 ] =  0.5 *
	    ( ptr_dtemp_node [ node_num1 - 1 ]
	      + ptr_dtemp_node [ node_num2 - 1 ] ) ;
	}
      } // it is extended C3D6 element

    } else if ( '8' == lakon3 ) {
      if ( 'E' == lakon[index+6] || 'A'==lakon[index+6] ) {
	indexe = ipkon[ie] ;
	for ( i = 0; i < 4; i++ ) {
	  node_num = kon[indexe+i] + 1 ; // number of ghost node
	  ptr_dtemp_node[node_num-1] = ptr_dtemp_node[node_num] ;
	}
	for ( i = 0; i < 4; i++ ) {
	  node_num = kon [ indexe + 8 + i ]  ; // number of real node
	  node_num1 = kon [ indexe + i ] ; // number of extended node 1
	  node_num2 = kon [ indexe + 4 + i ] ; // number of extended node 2
	  ptr_dtemp_node [ node_num - 1 ] =  0.5 *
	    ( ptr_dtemp_node [ node_num1 - 1 ]
	      + ptr_dtemp_node [ node_num2 - 1 ] ) ;
	} // end for i < 4

      } // it is extended C3D8 element
    }

  } // end ie


  //getchar();



  /*
    ptr_dtemp_node[0] = ptr_dtemp_node[4] ;
    ptr_dtemp_node[1] = ptr_dtemp_node[7] ;
    ptr_dtemp_node[2] = ptr_dtemp_node[10] ;
    ptr_dtemp_node[3] = ptr_dtemp_node[13] ;

    ptr_dtemp_node[5] = ptr_dtemp_node[4] ;
    ptr_dtemp_node[8] = ptr_dtemp_node[7] ;
    ptr_dtemp_node[11] = ptr_dtemp_node[10] ;
    ptr_dtemp_node[14] = ptr_dtemp_node[13] ;
  */


  for ( inode = 0; inode < *nk; inode++ ) { /* update nodal temperature
						 */
    //t1[inode] +=  ptr_dtemp_node[inode] ;
    v[inode*4] += ptr_dtemp_node[inode] ;
    vold[inode*4] = v[inode*4] ; // this is not important
  }


  /*
  pFile = fopen( "node_temperature.txt", "a" ) ;
  for ( int inode = 0; inode < *nk; inode++ ) {
    if ( inode == 165 ) {
      //fprintf ( pFile, "%d, %E, %E, %E, %E, %E \n", inode+1, (*ttime) + (*time), v[inode*4],
      //ptr_dtemp_node[inode], vold[inode*4], vini[inode*4] ) ;
    } //fprintf ( pFile, "\n" ) ;
  }
  fclose(pFile) ;
  */


  count_called += 1 ;


  free ( ptr_volume ) ;
  free ( ptr_dtemp_el ) ;
  free ( ptr_dtemp_node ) ;
  free ( ptr_elvolumes ) ;
  free ( ptr_node_el ) ;
  free ( ptr_nope ) ;

}
