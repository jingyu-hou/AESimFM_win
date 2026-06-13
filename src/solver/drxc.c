#include<math.h>



int istate_to_index ( int istate, int ip, int ie, // istate starts from 1
  int nstate, int nip, int ne  )  {

  int index ;

  index = nstate *  nip * ie + nstate * ip ;
	index = index + istate - 1 ;

  return index;

}



void drxc ( double *xstate, int *nstate, 
	    double *gsloc, int *mi, int *ne,
	    double *time, double *ttime, 
	    double *dtime, int * iinc, int * istep, 
	    int * iout ) {

  # include "index.h"

  /* This function calculates drx @ ips */

  double a1,n1,m1,q1,c1,a2,n2,a5,h5,n5,m5,q5,c5,
    beta_d,k_d,a10,
    a8,h8,n8,m8,q8,c8,d0 ;
  int nip, ie, ip, index, index0 ;
  double epsilon_eff, epsilon_rate ;
  double t ; // current temperature
  double t_av ; // historical averaged temperature
  double r_av ; // historical averaged strain rate
  double t_ave ; // new historical averaged temperature
  double rate_ave ; // new historical averaged strain rate
  double epsilon_p, epsilon_c, epsilon05 ;
  double x_drx, d_drx ;
  double d_ave ;

  double r = 8.314 ;

  static int num_called = 0 ;
  static double eqp_storage[92000000];
  static double static_drx[92000000];
  static double called_time = 0.0 ;

  double epsilon_nminus1, Delta_epsilonn ;


  enum sdv {
    eqps = 1,
    eplas1,
    eplas2,
    eplas3,
    eplas4,
    eplas5,
    eplas6,
    strainrate,
    ystress,
    pldissi,
    drxfrac, // 11
    drxgs,
    avegs,
    avetemp,
    avestrainrate,
    damage,
    damini,
    sdv18,
    meanstress_averagine,
    meanstress_averagi,
    temperature_nowadays,
    dplstrain,
    sdv23,
    sdv24,
    sdv25
  };





  // needs to be reconsidered
  a1=0.004659 ;
  n1=0.0 ;
  m1=0.1238  ;
  q1=49520.0 ;
  c1=0.0 ;
  a2=0.83  ;
  n2=0.0 ;
  d0=50.0 ;
  a5=5.043e-9 ;
  h5=0.0 ;
  n5=-1.42 ;
  m5=-0.408 ;
  q5=196000.0 ;
  c5=0.0 ;
  a10=0.8 ;
  beta_d=0.693 ;
  k_d=1.0 ;
  a8=485.0e8 ;
  h8=0.0 ;
  n8=-0.41 ;
  m8=-0.028 ;
  q8=-24.0e4 ;
  c8=0.0 ;


  /*
  a1    =  gsloc[0];
  n1    =  gsloc[1];
  m1    =  gsloc[2];
  q1    =  gsloc[3];
  c1    =  gsloc[4];
  a2    =  gsloc[5];
  n2    =  gsloc[6];
  d0    =  gsloc[7];
  a5    =  gsloc[8];
  h5    =  gsloc[9];
  n5    =  gsloc[10];
  m5    =  gsloc[11];
  q5    =  gsloc[12];
  c5    =  gsloc[13];
  a10   =  gsloc[14];
  beta_d=  gsloc[15];
  k_d   =  gsloc[16];
  a8    =  gsloc[17];
  h8    =  gsloc[18];
  n8    =  gsloc[19];
  m8    =  gsloc[20];
  q8    =  gsloc[21];
  c8    =  gsloc[22];

  printf ( "a1 = %f\n", a1 );
  printf ( "n1 = %f\n", n1 );
  printf ( "m1 = %f\n", m1 ) ;
  printf ( "c8 = %f\n", c8 ) ;
  exit ( 0 );
  */




  if ( * iout <= 0 ) {
    return ;
  }


  // debug:
  /*
  if ( *istep == 2 ) {
    printf ( "nstate[0]=%d", *nstate ) ;
    printf ( "*mi = %d", *mi ) ;
    exit(0);
  }
  */




  //printf ( "nstate[0] = %d\n", *nstate ) ;
  //printf ( "ne = %d\n", *ne ) ;


  nip = *mi ;


  if ( num_called == 0 ) {

    //printf ( " 1 nstate[0] = %d\n", *nstate ) ;
    //printf ( " *ne = %d\n", *ne ) ;

    for ( ie = 0; ie < *ne; ie++ ) {
      for ( ip = 0; ip < nip; ip++ ) {
	//index0 = nstate[0] * ( *mi ) * ie + nstate[0] * ip ;

	//index = nstate[0] * ( *mi ) * ie + nstate[0] * ip ;
	//index = index + 21 - 1 ;

	//printf ( " ie = %d, nip = %d, nstate[0] = %d\n", ie, *mi, *nstate ) ;

        index = istate_to_index(temperature_nowadays,ip,ie,
                                nstate[0], (*mi), (*ne) );
	//t = xstate[index] ; // in celcius degree
	t = xstate[index] ; // in celcius degree




	//index = nstate[0] * ( *mi ) * ie + nstate[0] * ip ;
	//index = index + 8 - 1 ;

        index = istate_to_index(strainrate,ip,ie,
                                nstate[0], (*mi), (*ne) );
	epsilon_rate = xstate[index] ;

	t_ave = t ;
	rate_ave = epsilon_rate ;
	x_drx = 0.0 ;
	d_drx = 0.0 ;

	// save variables:
	//index = nstate[0] * ( *mi ) * ie + nstate[0] * ip ;
	//index = index + 11 - 1 ;
        index = istate_to_index(drxfrac,ip,ie,
                                nstate[0], (*mi), (*ne) );
	xstate[index] = x_drx ;
	static_drx[index] = x_drx ;

	//index = index0 + 12 - 1 ;
        index = istate_to_index(drxgs,ip,ie,
                                nstate[0], (*mi), (*ne) );
	xstate[index] = d_drx ;
	static_drx[index] = d_drx ;

	//index = nstate[0] * ( *mi ) * ie + nstate[0] * ip ;
	//index = index + 16 - 1 ;
        index = istate_to_index ( avetemp, ip, ie,
                                  nstate[0], (*mi), (*ne) );
	xstate[index] = t_ave ;
	static_drx[index] = t_ave ;

	//index = nstate[0] * ( *mi ) * ie + nstate[0] * ip ;
	//index = index + 17 - 1 ;
        index = istate_to_index ( avestrainrate, ip, ie,
                                  nstate[0], (*mi), (*ne) );
	xstate[index] = rate_ave ;
	static_drx[index] = rate_ave ;
      }
    }


    /* record eqp */
    for ( ie = 0; ie < *ne; ie++ ) {
      for ( ip = 0; ip < nip; ip++ ) {
	//index = nstate[0] * ( *mi ) * ie + nstate[0] * ip ;
	index = istate_to_index ( eqps, ip, ie,
                                   nstate[0], (*mi), (*ne) );
	 eqp_storage[index] = xstate[index] ;
      }
    }

    /* record time called */
    called_time = *time + *ttime ;

    num_called = num_called + 1 ;
    return ;

  } // called for the first time


  //printf ( " 2 nstate[0] = %d\n", *nstate ) ;



  for ( ie = 0; ie < *ne; ie++ ) {

    for ( ip = 0; ip < nip; ip++ ) {

      //index0 = nstate[0] * ( *mi ) * ie + nstate[0] * ip ;

      // extract current eqp for each ip:
      //index = nstate[0] * ( *mi ) * ie + nstate[0] * ip ;
      index = istate_to_index ( eqps, ip, ie,
                                nstate[0], (*mi), (*ne) );
      epsilon_eff = xstate[index] ;

      // make sure monotonicity of eqplas
      if ( epsilon_eff < eqp_storage[index] ) {
	epsilon_eff = eqp_storage[index] ;
      }


      // calculate current eqp_rate for each ip:
      //index = nstate[0] * ( *mi ) * ie + nstate[0] * ip ;
      index = istate_to_index ( eqps, ip, ie,
                                nstate[0], (*mi), (*ne) ) ;
      //index = index + 8 - 1 ;
      //epsilon_rate = xstate[index] ;
      epsilon_rate = ( xstate[index] - eqp_storage[index] ) / ( *ttime + *time - called_time ) ;
      if ( epsilon_rate < 0.0 ) {
	       epsilon_rate = 0.0 ;
      }


      // extract current temperature for each ip
      //index = nstate[0] * ( *mi ) * ie + nstate[0] * ip ;
      //index = index + 21 - 1 ;
      index = istate_to_index ( temperature_nowadays, ip, ie,
                                nstate[0], (*mi), (*ne) ) ;
      t = xstate[index] + 273.0 ;

      // extract average temperature for each ip
      //index = nstate[0] * ( *mi ) * ie + nstate[0] * ip ;
      //index = index + 16 - 1 ;
      index = istate_to_index ( avetemp, ip,ie,
                                nstate[0], (*mi), (*ne) ) ;
      //t_av = xstate[index] ;
      t_av = static_drx[index] ;

      // extract average strain rate for each ip
      //index = nstate[0] * ( *mi ) * ie + nstate[0] * ip ;
      //index = index + 17 - 1 ;
      index = istate_to_index ( avestrainrate, ip,ie,
                                nstate[0], (*mi), (*ne) ) ;
      //r_av = xstate[index] ;
      r_av = static_drx[index] ;

      // extract average x_drx:
      //index = nstate[0] * ( *mi ) * ie + nstate[0] * ip ;
      //index = index + 11 - 1 ;
      index = istate_to_index ( drxfrac, ip,ie,
                                nstate[0], (*mi), (*ne) ) ;
      //x_drx = xstate[index] ;
      x_drx = static_drx[index] ;


      // extract average d_drx:
      //index = nstate[0] * ( *mi ) * ie + nstate[0] * ip ;
      //index = index + 12 - 1 ;
      index = istate_to_index ( drxgs, ip,ie,
                                nstate[0], (*mi), (*ne) ) ;
      d_drx = static_drx[index] ;

      t_ave = t_av + 273.0 ;
      rate_ave = r_av ;


      //index = nstate[0] * ( *mi ) * ie + nstate[0] * ip ;
      index = istate_to_index ( eqps, ip,ie,
                                nstate[0], (*mi), (*ne) ) ;
      epsilon_nminus1 = eqp_storage[index] ;
      Delta_epsilonn = xstate[index] - eqp_storage[index] ;
      if ( Delta_epsilonn < 0.0 ) {
	       Delta_epsilonn = 0.0 ;
      }

      /*
      t_ave = ( t_ave * ( epsilon_eff - epsilon_rate * (*dtime) ) +
      t * epsilon_rate*(*dtime) ) / epsilon_eff ;*/

      if ( epsilon_eff > 1.0e-10 ) {
	t_ave = ( t_ave * ( epsilon_nminus1 ) +
		  t * Delta_epsilonn ) / epsilon_eff ;
      } else {
	t_ave = t_ave ;
      }

      /*
      rate_ave = ( rate_ave * ( epsilon_eff - epsilon_rate * (*dtime) ) +
		   pow ( epsilon_rate, 2.0 ) * (*dtime) ) / epsilon_eff ;
      */


      if ( epsilon_eff > 1.0e-10 ) {
	rate_ave = ( rate_ave * (epsilon_nminus1) +
		     epsilon_rate * Delta_epsilonn ) / epsilon_eff ;
      } else {
	rate_ave = rate_ave ;
      }

      /*
      printf ( "epsilon_nminums1 = %f, epsilon_rate = %f, Delta_epsilonn = %f, epsilon_eff = %f\n, total_time=%f, called_time=%f",
	       epsilon_nminus1, epsilon_rate, Delta_epsilonn, epsilon_eff, *ttime, called_time) ;
      exit(0);
      */

      epsilon_p = a1 * pow(d0,n1) * pow(rate_ave,m1) * exp(q1/r/t_ave) + c1 ;
      epsilon_c = a2 * epsilon_p ;
      epsilon05 = a5 * pow(d0,h5) * pow(epsilon_eff,n5) * pow(rate_ave,m5) *
	                exp(q5/r/t_ave) + c5 ;

      x_drx = 1.0 - exp(-beta_d * pow( (epsilon_eff-a10*epsilon_p) / epsilon05, k_d) ) ;
      if (x_drx < 0.0) {
        x_drx = 0.0 ;
      } else if ( x_drx > 1.0 ) {
	x_drx = 1.0 ;
      }
      


      d_drx = a8 * pow(d0,h8) * pow(epsilon_eff,n8) * pow(rate_ave,m8) * exp(q8/8.314/t_ave) + c8 ;
      if (x_drx == 0.0) {
        d_drx = 0.0 ;
      }
      if ( d_drx > d0 ) {
	       d_drx = d0 ;
      }

      // average grain size
      d_ave = d0 * (1.0 - x_drx ) + d_drx * x_drx ;




      // save variables:
      //index = nstate[0] * ( *mi ) * ie + nstate[0] * ip ;
      //index = index + 11 - 1 ;
      index = istate_to_index ( drxfrac, ip,ie,
                                nstate[0], (*mi), (*ne) ) ;
      xstate[index] = x_drx ;
      static_drx[index] = x_drx ;


      //index = nstate[0] * ( *mi ) * ie + nstate[0] * ip ;
      //index = index + 12 - 1 ;
      index = istate_to_index ( drxgs, ip, ie,
                                nstate[0], (*mi), (*ne) ) ;
      xstate[index] = d_drx ;
      static_drx[index] = d_drx ;


      //index = index0 + 13 - 1 ;
      index = istate_to_index ( avegs, ip, ie,
                                nstate[0], (*mi), (*ne) ) ;
      xstate[index] = d_ave ;
      static_drx[index] = d_ave ;


      //index = index0 + 16 - 1 ;
      index = istate_to_index ( avetemp, ip, ie,
                                nstate[0], (*mi), (*ne) ) ;
      xstate[index] = t_ave - 273.0 ;
      static_drx[index] = xstate[index];

      //index = nstate[0] * ( *mi ) * ie + nstate[0] * ip ;
      //index = index + 17 - 1 ;
      index = istate_to_index ( avestrainrate, ip, ie,
                                nstate[0], (*mi), (*ne) ) ;
      xstate[index] = rate_ave ;
      static_drx[index] = rate_ave ;

      //index = nstate[0] * ( *mi ) * ie + nstate[0] * ip ;
      //index = index + 22 - 1 ;
      index = istate_to_index ( dplstrain, ip, ie,
                                nstate[0], (*mi), (*ne) ) ;
      xstate[index] = Delta_epsilonn ;


    } // end of for ip

  } // end of for ie

  /* record eqp */
  for ( ie = 0; ie < *ne; ie++ ) {
    for ( ip = 0; ip < nip; ip++ ) {
      //index = nstate[0] * ( *mi ) * ie + nstate[0] * ip ;
      index = istate_to_index ( eqps, ip, ie,
                                nstate[0], (*mi), (*ne) ) ;
      eqp_storage[index] = xstate[index] ;
    }
  }

  /* record time called */
  called_time = *ttime + *time ;

  num_called = num_called + 1 ;


}
