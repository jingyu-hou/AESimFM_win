/*                                                                              */
/*      WeICME (Wedge Integrated Computational Materials Engineering)           */
/*                 - A 3-dimensional finite element program.                    */   
/*     Developed and maintained by Shenzhen Wedge Central                       */
/*    South Research Institute co., Ltd., Shenzhen, China                       */   
/*     Copy Right 2019-2023.                                                      */

void v_result( const double *A, const double *B, double *C )
/**********************************************************/
/*    Vektorbetrag: C =  Vektor(B)-Vektor(A) == Vector(AB)*/
/**********************************************************/
{
         C[0]=B[0]-A[0];
         C[1]=B[1]-A[1];
         C[2]=B[2]-A[2];
}

