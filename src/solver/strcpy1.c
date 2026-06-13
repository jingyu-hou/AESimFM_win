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

ITG strcpy1(char *s1, const char *s2, ITG length)
{
  ITG b,i,blank=0;

  for(i=0;i<length;i++) {
      if(blank==0){
	  b=*s2;
	  if(b=='\0')blank=1;
      }
      if(blank==0) {*s1=*s2;s2++;}
      else *s1=' ';
      s1++;
  }
  return 0;
}
	  




