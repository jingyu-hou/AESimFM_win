      
C     output characters
 300  FORMAT ( A )

C     variable =  3.500E3
 800  FORMAT ( A, " = ", ES13.3E3 )


C     nvariable = 6
 805  FORMAT ( A, " = ", I5 )


C     ---------------------------------------------------------
C        ---------------- KINC =    5 ----------------------
C     ---------------------------------------------------------
 815  FORMAT 
     &     ( 7x, "----------------------------------
     &-----------------------",/,
     &     7x, "------------------- ", A4, " = ", 
     &     I5, " ------------------------",/,
     &     7x,"------------------
     &---------------------------------------")



C     output characters and two float values
 820  FORMAT ( A, " ", 2ES13.3E3 )

C     Not solution at 5(KINC) 3(IITER)
 821  FORMAT ( A, " ", I5, A, " ", I3, A )



C     |  XXXXX  |  XXXXX  |  XXXXX  |  
C     |-2.31E-02| 4.95E-05|-5.25E+15| 
 853  FORMAT ( "|",2X,A5,2X,"|",2X,A5,2X,"|",2X,A5,2X,"|",/
     &     "|",ES9.2E2,"|", ES9.2E2,"|", ES9.2E2,"|")

C     |  XXXXX  |  XXXXX  |  XXXXX  | XXXXX | XXXXX | 
C     |-2.31E-02| 4.95E-05|-5.25E+15|  
 855  FORMAT ( "|",2X,A5,2X,"|",2X,A5,2X,"|",2X,A5,2X,"|",
     &     2X,A5,2X,"|",2X,A5,2X,"|",/
     &     "|",ES9.2E2,"|", ES9.2E2,"|", ES9.2E2,"|",ES9.2E2,"|",
     &     ES9.2E2,"|")




C     |  XXXXX  |  XXXXX  |  XXXXX  |  XXXXX  |  XXXXX  |  XXXXX  |  XXXXX  |  XXXXX  |
C     |-2.31E-02| 4.95E-05|-5.25E+15| 
 858  FORMAT ( "|",2X,A5,2X,"|",2X,A5,2X,"|",2X,A5,2X,"|",2X,A5,2X,"|",
     &     2X,A5,2X,"|", 2X,A5,2X,"|",2X,A5,2X,"|",2X,A5,2X,"|",/
     &     "|",ES9.2E2,"|",ES9.2E2,"|",ES9.2E2,"|",ES9.2E2,"|",
     &     ES9.2E2,"|", ES9.2E2,"|", ES9.2E2,"|", ES9.2E2,"|")


C     output 3 by 3 matrix
 900  FORMAT ( A,/,3ES13.3E3,/,3ES13.3E3,/,3ES13.3E3 )

