#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "hdf5_writer.h"

#ifdef OUTPUT_HDF5

#include <hdf5.h>

/* Module state */
static hid_t  h5_file = -1;
static char   h5_filename[700] = "";
static ITG    h5_ne_stored = 0;
static ITG    h5_last_step = -1, h5_last_inc = -1;
static ITG    h5_initialized = 0, h5_mesh_written = 0;

/* Forward */
static int  h5_write_nset(const char *set, ITG nset, ITG *istartset,
                           ITG *iendset, ITG *ialset);
static void h5_write_str_attr(hid_t loc, const char *name, const char *value);

/* ---------- helpers ---------- */

static void h5_write_str_attr(hid_t loc, const char *name, const char *value)
{
  hid_t s    = H5Screate(H5S_SCALAR);
  hid_t atype = H5Tcopy(H5T_C_S1);
  H5Tset_size(atype, strlen(value) + 1);
  hid_t attr = H5Acreate2(loc, name, atype, s, H5P_DEFAULT, H5P_DEFAULT);
  H5Awrite(attr, atype, value);
  H5Aclose(attr);
  H5Tclose(atype);
  H5Sclose(s);
}

static int h5_write_nset(const char *set, ITG nset, ITG *istartset,
                          ITG *iendset, ITG *ialset)
{
  hid_t g, dset, ds;
  hsize_t dims[2];
  ITG i;
  char sname[82];

  g = H5Gcreate2(h5_file, "/mesh/sets", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);

  for (i = 0; i < nset; i++) {
    ITG nmemb = iendset[i] - istartset[i] + 1;
    if (nmemb <= 0) continue;

    strncpy(sname, set + (hsize_t)i * 81, 80);
    sname[80] = '\0';
    { int sl = (int)strlen(sname);
      while (sl > 0 && sname[sl-1] == ' ') sname[--sl] = '\0';
    }

    dims[0] = (hsize_t)nmemb;
    ds = H5Screate_simple(1, dims, NULL);
    dset = H5Dcreate2(g, sname, H5T_NATIVE_INT, ds, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
    H5Dwrite(dset, H5T_NATIVE_INT, H5S_ALL, H5S_ALL, H5P_DEFAULT, ialset + istartset[i] - 1);
    H5Dclose(dset);
    H5Sclose(ds);
  }

  H5Gclose(g);
  return 0;
}

/* ---------- public API ---------- */

int h5_init(const char *jobnamec, const char *solver_version,
            int nk, int ne, int nmat, int nstate_)
{
  hid_t  g;
  time_t now;
  char   timestr[64];

  (void)nk; (void)ne; (void)nmat; (void)nstate_;

  snprintf(h5_filename, sizeof(h5_filename), "%s.h5", jobnamec);

  h5_file = H5Fcreate(h5_filename, H5F_ACC_TRUNC, H5P_DEFAULT, H5P_DEFAULT);
  if (h5_file < 0) return 1;

  h5_write_str_attr(h5_file, "format_name",    H5_FORMAT_NAME);
  h5_write_str_attr(h5_file, "format_version", H5_FORMAT_VERSION);
  h5_write_str_attr(h5_file, "solver_version", solver_version);
  h5_write_str_attr(h5_file, "source_job",     jobnamec);
  time(&now); strftime(timestr, sizeof(timestr), "%Y-%m-%dT%H:%M:%SZ", gmtime(&now));
  h5_write_str_attr(h5_file, "created_utc",    timestr);

  g = H5Gcreate2(h5_file, "/mesh", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
  H5Gclose(g);
  g = H5Gcreate2(h5_file, "/steps", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
  H5Gclose(g);
  g = H5Gcreate2(h5_file, "/state", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
  H5Gclose(g);

  h5_initialized = 1;
  return 0;
}

int h5_write_mesh(double *co, ITG nk, ITG *kon, ITG *ipkon, char *lakon, ITG ne,
                  ITG nkon, char *set, ITG nset, ITG *istartset, ITG *iendset,
                  ITG *ialset, char *matname, ITG nmat, ITG *ielmat, ITG mi0)
{
  hid_t g, dset, ds;
  hsize_t dims[2];
  ITG i, j;

  (void)lakon; (void)matname; (void)nmat; (void)mi0;

  if (!h5_initialized) return 1;

  /* /mesh/nodes */
  g = H5Gcreate2(h5_file, "/mesh/nodes", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);

  { ITG *ids = (ITG*)malloc(nk * sizeof(ITG));
    for (i = 0; i < nk; i++) ids[i] = i + 1;
    dims[0] = (hsize_t)nk;
    ds = H5Screate_simple(1, dims, NULL);
    dset = H5Dcreate2(h5_file, "/mesh/nodes/ids", H5T_NATIVE_INT, ds,
                      H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
    H5Dwrite(dset, H5T_NATIVE_INT, H5S_ALL, H5S_ALL, H5P_DEFAULT, ids);
    H5Dclose(dset); H5Sclose(ds);
    free(ids);
  }

  dims[0] = (hsize_t)nk; dims[1] = 3;
  ds = H5Screate_simple(2, dims, NULL);
  dset = H5Dcreate2(h5_file, "/mesh/nodes/coordinates", H5T_NATIVE_DOUBLE, ds,
                    H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
  H5Dwrite(dset, H5T_NATIVE_DOUBLE, H5S_ALL, H5S_ALL, H5P_DEFAULT, co);
  H5Dclose(dset); H5Sclose(ds);
  H5Gclose(g);

  /* /mesh/elements */
  g = H5Gcreate2(h5_file, "/mesh/elements", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);

  { ITG *eids = (ITG*)malloc(ne * sizeof(ITG));
    for (i = 0; i < ne; i++) eids[i] = i + 1;
    dims[0] = (hsize_t)ne;
    ds = H5Screate_simple(1, dims, NULL);
    dset = H5Dcreate2(h5_file, "/mesh/elements/ids", H5T_NATIVE_INT, ds,
                      H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
    H5Dwrite(dset, H5T_NATIVE_INT, H5S_ALL, H5S_ALL, H5P_DEFAULT, eids);
    H5Dclose(dset); H5Sclose(ds);
    free(eids);
  }

  /* connectivity: find max nodes-per-element, pad.
     ipkon is 1-based (Fortran convention); kon[1..nkon] are active. */
  { ITG max_nc = 4;
    for (i = 0; i < ne; i++) {
      ITG start = ipkon[i];
      ITG end   = (i + 1 < ne) ? ipkon[i + 1] : nkon + 1;
      ITG nc    = end - start;
      if (nc > max_nc) max_nc = nc;
    }
    if (max_nc < 4) max_nc = 4;
    if (max_nc > 27) max_nc = 27;
    dims[0] = (hsize_t)ne; dims[1] = (hsize_t)max_nc;
    ds = H5Screate_simple(2, dims, NULL);
    dset = H5Dcreate2(h5_file, "/mesh/elements/connectivity", H5T_NATIVE_INT, ds,
                      H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
    { ITG *conn = (ITG*)calloc((size_t)ne * (size_t)max_nc, sizeof(ITG));
      for (i = 0; i < ne; i++) {
        ITG start = ipkon[i];
        ITG end   = (i + 1 < ne) ? ipkon[i + 1] : nkon + 1;
        ITG nc    = end - start;
        for (j = 0; j < nc && j < max_nc; j++)
          conn[i * max_nc + j] = kon[start + j];
      }
      H5Dwrite(dset, H5T_NATIVE_INT, H5S_ALL, H5S_ALL, H5P_DEFAULT, conn);
      free(conn);
    }
    H5Dclose(dset); H5Sclose(ds);
  }

  /* material assignment */
  dims[0] = (hsize_t)ne;
  ds = H5Screate_simple(1, dims, NULL);
  dset = H5Dcreate2(h5_file, "/mesh/elements/material", H5T_NATIVE_INT, ds,
                    H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
  H5Dwrite(dset, H5T_NATIVE_INT, H5S_ALL, H5S_ALL, H5P_DEFAULT, ielmat);
  H5Dclose(dset); H5Sclose(ds);
  H5Gclose(g);

  /* /mesh/sets */
  if (nset > 0) {
    h5_write_nset(set, nset, istartset, iendset, ialset);
  }

  h5_ne_stored   = ne;
  h5_mesh_written = 1;
  return 0;
}

int h5_write_increment(ITG istep, ITG iinc, double ttime, double dt,
                       int converged, int iterations, int cutbacks,
                       double *v, double *sti, double *xstate, double *t1,
                       ITG nk, ITG ne, ITG nstate_, ITG mi0, ITG ithermal)
{
  char grp[96];
  hid_t g, ds, dset;
  hsize_t dims[2];
  ITG ip_count;

  if (!h5_initialized || !h5_mesh_written) return 1;

  /* prevent duplicate (step,inc) writes — frd() may be called multiple times */
  if (istep == h5_last_step && iinc == h5_last_inc) return 0;
  h5_last_step = istep;
  h5_last_inc  = iinc;

  ip_count = (mi0 > 0) ? mi0 : 1;

  snprintf(grp, sizeof(grp), "/steps/step_%04d", (int)istep);
  if (H5Lexists(h5_file, grp, H5P_DEFAULT) <= 0) {
    g = H5Gcreate2(h5_file, grp, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
    H5Gclose(g);
  }

  snprintf(grp, sizeof(grp), "/steps/step_%04d/inc_%06d", (int)istep, (int)iinc);
  g = H5Gcreate2(h5_file, grp, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);

  /* increment attributes */
  { hid_t s = H5Screate(H5S_SCALAR);
    hid_t at = H5Acreate2(g, "time", H5T_NATIVE_DOUBLE, s, H5P_DEFAULT, H5P_DEFAULT);
    H5Awrite(at, H5T_NATIVE_DOUBLE, &ttime); H5Aclose(at);
    at = H5Acreate2(g, "converged", H5T_NATIVE_INT, s, H5P_DEFAULT, H5P_DEFAULT);
    H5Awrite(at, H5T_NATIVE_INT, &converged); H5Aclose(at);
    H5Sclose(s);
  }

  /* /node */
  { hid_t ng = H5Gcreate2(g, "node", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
    /* U: displacement (mt*nk) — mt = DOFs per node, at least 3 for structural */
    { ITG nd = 3;
      dims[0] = (hsize_t)nk; dims[1] = (hsize_t)nd;
      ds = H5Screate_simple(2, dims, NULL);
      dset = H5Dcreate2(ng, "U", H5T_NATIVE_DOUBLE, ds, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
      H5Dwrite(dset, H5T_NATIVE_DOUBLE, H5S_ALL, H5S_ALL, H5P_DEFAULT, v);
      H5Dclose(dset); H5Sclose(ds);
    }
    if (ithermal) {
      dims[0] = (hsize_t)nk;
      ds = H5Screate_simple(1, dims, NULL);
      dset = H5Dcreate2(ng, "TEMP", H5T_NATIVE_DOUBLE, ds, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
      H5Dwrite(dset, H5T_NATIVE_DOUBLE, H5S_ALL, H5S_ALL, H5P_DEFAULT, t1);
      H5Dclose(dset); H5Sclose(ds);
    }
    H5Gclose(ng);
  }

  /* /integration_point */
  { hid_t ig = H5Gcreate2(g, "integration_point", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
    /* S: stress 6 components per integration point */
    dims[0] = (hsize_t)ne; dims[1] = (hsize_t)(6 * ip_count);
    ds = H5Screate_simple(2, dims, NULL);
    dset = H5Dcreate2(ig, "S", H5T_NATIVE_DOUBLE, ds, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
    H5Dwrite(dset, H5T_NATIVE_DOUBLE, H5S_ALL, H5S_ALL, H5P_DEFAULT, sti);
    H5Dclose(dset); H5Sclose(ds);

    if (nstate_ > 0) {
      dims[0] = (hsize_t)ne; dims[1] = (hsize_t)(nstate_ * ip_count);
      ds = H5Screate_simple(2, dims, NULL);
      dset = H5Dcreate2(ig, "SDV", H5T_NATIVE_DOUBLE, ds, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
      H5Dwrite(dset, H5T_NATIVE_DOUBLE, H5S_ALL, H5S_ALL, H5P_DEFAULT, xstate);
      H5Dclose(dset); H5Sclose(ds);
    }
    H5Gclose(ig);
  }

  H5Gclose(g);
  return 0;
}

int h5_close(void)
{
  if (h5_file >= 0) {
    H5Fflush(h5_file, H5F_SCOPE_GLOBAL);
    H5Fclose(h5_file);
    h5_file = -1;
  }
  h5_initialized = 0;
  return 0;
}

const char* h5_get_filename(void)
{
  return (h5_file >= 0) ? h5_filename : NULL;
}

/* ---------- Called from frd.c after increment data is committed ---------- */

void frd_h5_write_state(double *co, ITG *nk, double *v, double *stn, double *t1,
                        double *xstaten, ITG *nstate_, ITG *istep, ITG *iinc,
                        double *time, ITG *ithermal, ITG *mi)
{
  if (!h5_initialized) return;

  ITG ne = h5_ne_stored;
  if (ne <= 0) return;

  h5_write_increment(*istep, *iinc, *time, 0.0,
                     /* converged= */1, /* iterations= */1, /* cutbacks= */0,
                     v, stn, xstaten, t1,
                     *nk, ne, *nstate_, mi[0], *ithermal);
}

/* h5_close_on_crash: called from signal handler to flush HDF5 state.
   No allocations, no complex calls — must be signal-safe. */
void h5_close_on_crash(void)
{
  if (h5_file >= 0) {
    H5Fclose(h5_file);
    h5_file = -1;
  }
}

/* ---------- SDV metadata ---------- */

#define SDV_MAX_LABEL 53

typedef struct { const char *name; const char *ns; const char *desc; } sdv_entry_t;

static const sdv_entry_t _sdv_forging[SDV_MAX_LABEL] = {
  /*  1 */ {"EQPLAS",              "forging/recrystallization", "Equivalent plastic strain"},
  /*  2 */ {"EPLAS(1)",            "forging/recrystallization", "Plastic strain 11"},
  /*  3 */ {"EPLAS(2)",            "forging/recrystallization", "Plastic strain 22"},
  /*  4 */ {"EPLAS(3)",            "forging/recrystallization", "Plastic strain 33"},
  /*  5 */ {"EPLAS(4)",            "forging/recrystallization", "Plastic strain 12"},
  /*  6 */ {"EPLAS(5)",            "forging/recrystallization", "Plastic strain 13"},
  /*  7 */ {"EPLAS(6)",            "forging/recrystallization", "Plastic strain 23"},
  /*  8 */ {"EQPLASRT",            "forging/recrystallization", "Equivalent plastic strain rate"},
  /*  9 */ {"SYIELD",              "forging/recrystallization", "Yield stress"},
  /* 10 */ {"PLASTIC_DISSIPATION", "forging/recrystallization", "Plastic dissipation"},
  /* 11 */ {"X_DRX",               "forging/recrystallization", "Dynamic recrystallization fraction"},
  /* 12 */ {"D_DRX",               "forging/recrystallization", "DRX grain size"},
  /* 13 */ {"D_AVE",               "forging/recrystallization", "Average grain size"},
  /* 14 */ {"T_AVE",               "forging/recrystallization", "DRX average temperature"},
  /* 15 */ {"RATE_AVE",            "forging/recrystallization", "DRX average strain rate"},
  /* 16 */ {"DAMAGE",              "forging/recrystallization", "Damage value"},
  /* 17 */ {"DAMAGE_INIT_STRAIN",  "forging/recrystallization", "Damage initiation strain"},
  /* 18 */ {"UNUSED",              "forging/recrystallization", "Reserved/unused"},
  /* 19 */ {"MEAN_STRESS_BEFORE",  "forging/recrystallization", "Mean stress before averaging"},
  /* 20 */ {"MEAN_STRESS_AFTER",   "forging/recrystallization", "Mean stress after averaging"},
  /* 21 */ {"TEMP_CURRENT",        "forging/recrystallization", "Current temperature"},
  /* 22 */ {"MRX_SIGN",            "forging/recrystallization", "MRX activation flag"},
  /* 23 */ {"SRX_SIGN",            "forging/recrystallization", "SRX activation flag"},
  /* 24 */ {"X_MRX",               "forging/recrystallization", "MRX recrystallization fraction"},
  /* 25 */ {"X_SRX",               "forging/recrystallization", "SRX recrystallization fraction"},
  /* 26 */ {"D_MRX",               "forging/recrystallization", "MRX grain size"},
  /* 27 */ {"D_SRX",               "forging/recrystallization", "SRX grain size"},
  /* 28 */ {"D_MIX",               "forging/recrystallization", "Mixed average grain size"},
  /* 29 */ {"EQV_RE",              "forging/recrystallization", "Current recovery equivalent plastic strain"},
  /* 30 */ {"EQV_RE0",             "forging/recrystallization", "Recovery equivalent plastic strain at unload start"},
  /* 31 */ {"EQUER_MEAN",          "forging/recrystallization", "Mean equivalent strain rate during deformation"},
  /* 32 */ {"EQV05_DRX",           "forging/recrystallization", "Strain at 50% DRX completion"},
  /* 33 */ {"T05_MRX",             "forging/recrystallization", "Time to 50% MRX"},
  /* 34 */ {"T05_SRX",             "forging/recrystallization", "Time to 50% SRX"},
  /* 35 */ {"T_GROWTH0_MRX",       "forging/recrystallization", "MRX grain growth start time"},
  /* 36 */ {"D_GROWTH0_MRX",       "forging/recrystallization", "MRX grain growth start size"},
  /* 37 */ {"T_GROWTH0_SRX",       "forging/recrystallization", "SRX grain growth start time"},
  /* 38 */ {"D_GROWTH0_SRX",       "forging/recrystallization", "SRX grain growth start size"},
  /* 39 */ {"UNDEFORM_SIGN",       "forging/recrystallization", "Undeformed state flag"},
  /* 40 */ {"T_DEFORM",            "forging/recrystallization", "Accumulated deformation time"},
  /* 41 */ {"D0_K90",              "forging/recrystallization", "K90 initial grain size"},
  /* 42 */ {"N3_MRX_GG",           "forging/recrystallization", "MRX grain growth completion flag"},
  /* 43 */ {"N4_SRX_GG",           "forging/recrystallization", "SRX grain growth completion flag"},
  /* 44 */ {"CREEP_EQ",            "creep_softening",           "Accumulated equivalent creep strain"},
  /* 45 */ {"CREEP_RATE",          "creep_softening",           "Current equivalent creep strain rate"},
  /* 46 */ {"CREEP_DINC",          "creep_softening",           "Current increment creep strain"},
  /* 47 */ {"CREEP_QTILD",         "creep_softening",           "Equivalent stress before creep correction"},
  /* 48 */ {"CREEP_PRESSURE",      "creep_softening",           "Hydrostatic pressure for creep"},
  /* 49 */ {"SOFTENING_FACTOR",    "creep_softening",           "Aging softening/relaxation factor"},
  /* 50 */ {"RELAXED_STRESS_EQ",   "creep_softening",           "Relaxed equivalent stress"},
  /* 51 */ {"CREEP_ACTIVE_FLAG",   "creep_softening",           "Creep/softening activation flag"},
  /* 52 */ {"CREEP_TEMP_K",        "creep_softening",           "Creep model temperature"},
  /* 53 */ {"CREEP_TIME_HOLD",     "creep_softening",           "Accumulated hold/relaxation time"},
};

int h5_write_sdv_metadata(ITG nstate_)
{
  hid_t g, sg, ds, dset;
  hsize_t dims;
  ITG i, n;
  char *buf;

  if (!h5_initialized || h5_file < 0) return 1;

  n = (nstate_ > 0 && nstate_ <= SDV_MAX_LABEL) ? nstate_ : SDV_MAX_LABEL;

  g = H5Gopen2(h5_file, "/state", H5P_DEFAULT);
  if (g < 0) return 1;

  /* create /state/sdv group */
  sg = H5Gcreate2(g, "sdv", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);

  dims = (hsize_t)n;
  ds = H5Screate_simple(1, &dims, NULL);

  /* names: fixed-length strings, write as single contiguous buffer */
  { hid_t atype = H5Tcopy(H5T_C_S1);
    H5Tset_size(atype, 32);
    dset = H5Dcreate2(sg, "names", atype, ds, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
    buf = (char*)calloc((size_t)n, 32);
    for (i = 0; i < n; i++) strncpy(buf + (size_t)i * 32, _sdv_forging[i].name, 31);
    H5Dwrite(dset, atype, H5S_ALL, H5S_ALL, H5P_DEFAULT, buf);
    free(buf);
    H5Dclose(dset);
    H5Tclose(atype);
  }

  /* namespaces */
  { hid_t atype = H5Tcopy(H5T_C_S1);
    H5Tset_size(atype, 48);
    dset = H5Dcreate2(sg, "namespaces", atype, ds, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
    buf = (char*)calloc((size_t)n, 48);
    for (i = 0; i < n; i++) strncpy(buf + (size_t)i * 48, _sdv_forging[i].ns, 47);
    H5Dwrite(dset, atype, H5S_ALL, H5S_ALL, H5P_DEFAULT, buf);
    free(buf);
    H5Dclose(dset);
    H5Tclose(atype);
  }

  /* descriptions */
  { hid_t atype = H5Tcopy(H5T_C_S1);
    H5Tset_size(atype, 72);
    dset = H5Dcreate2(sg, "descriptions", atype, ds, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
    buf = (char*)calloc((size_t)n, 72);
    for (i = 0; i < n; i++) strncpy(buf + (size_t)i * 72, _sdv_forging[i].desc, 71);
    H5Dwrite(dset, atype, H5S_ALL, H5S_ALL, H5P_DEFAULT, buf);
    free(buf);
    H5Dclose(dset);
    H5Tclose(atype);
  }

  H5Sclose(ds);
  H5Gclose(sg);
  H5Gclose(g);

  return 0;
}

#endif /* OUTPUT_HDF5 */
