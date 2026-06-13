/* Windows compatibility shim for CalculiX MinGW build */
#ifndef WIN_COMPAT_H
#define WIN_COMPAT_H

/* mkdir: POSIX has 2 args (path, mode), Windows/MinGW _mkdir has 1 arg (path) */
#ifdef mkdir
#undef mkdir
#endif
#define mkdir(path, mode) _mkdir(path)

#endif /* WIN_COMPAT_H */
