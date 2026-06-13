/*                                                                              */
/*      WeICME (Wedge Integrated Computational Materials Engineering)           */
/*                 - A 3-dimensional finite element program.                    */   
/*     Developed and maintained by Shenzhen Wedge Central                       */
/*    South Research Institute co., Ltd., Shenzhen, China                       */   
/*     Copy Right 2019-2023.                                                      */

#include <stdlib.h>
#include <math.h>
#include <stdio.h>
#include <string.h>
#include "solver.h"

ITG strcmp2(const char *s1, const char *s2, ITG length)
{

/* comparison of the first "length" characters unless s1
   and/or s2 has less characters */

  ITG a,b,i;

  i=0;
  do {
    a=*s1++;
    b=*s2++;

    if(b=='\0'){
      a='\0';
      b='\0';
      break;
    }
    if(a=='\0'){
      a='\0';
      b='\0';
      break;
    }
    i++;
  }while((a==b)&&(i<length));
  return(a-b);
}
	  
