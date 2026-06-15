#ifndef HDF5_WRITER_H
#define HDF5_WRITER_H

#include "solver.h"

#ifdef OUTPUT_HDF5

#include <hdf5.h>

#define H5_FORMAT_NAME    "AESimFM-H5"
#define H5_FORMAT_VERSION "0.1"

int h5_init(const char *jobnamec, const char *solver_version,
            int nk, int ne, int nmat, int nstate_);

int h5_write_mesh(double *co, ITG nk, ITG *kon, ITG *ipkon, char *lakon, ITG ne,
                  ITG nkon, char *set, ITG nset, ITG *istartset, ITG *iendset,
                  ITG *ialset, char *matname, ITG nmat, ITG *ielmat, ITG mi0);

int h5_write_increment(ITG istep, ITG iinc, double ttime, double dt,
                       int converged, int iterations, int cutbacks,
                       double *v, double *sti, double *xstate, double *t1,
                       ITG nk, ITG ne, ITG nstate_, ITG mi0, ITG ithermal);

int h5_close(void);

const char* h5_get_filename(void);

/* Called from frd.c after each increment's FRD data is written */
void frd_h5_write_state(double *co, ITG *nk, double *v, double *stn, double *t1,
                        double *xstaten, ITG *nstate_, ITG *istep, ITG *iinc,
                        double *time, ITG *ithermal, ITG *mi);

int h5_write_sdv_metadata(ITG nstate_);

/* Called from signal handler — safe to call from crash context */
void h5_close_on_crash(void);

#else

/* Stubs when HDF5 not enabled */
#define h5_init(j,v,nk,ne,nm,ns)           0
#define h5_write_mesh(c,nk,k,ik,l,ne,nkon,s,ns,ss,es,as,mn,nm,im,mi0) 0
#define h5_write_increment(is,ii,t,dt,cv,it,cu,v,st,xs,t1,nk,ne,ns,mi0,th) 0
#define h5_close()                          0
#define h5_get_filename()                   NULL
#define frd_h5_write_state(co,nk,v,stn,t1,xs,ns,is,ii,t,th,mi) ((void)0)
#define h5_write_sdv_metadata(ns)           0
#define h5_close_on_crash()                 ((void)0)

#endif /* OUTPUT_HDF5 */

#endif /* HDF5_WRITER_H */
