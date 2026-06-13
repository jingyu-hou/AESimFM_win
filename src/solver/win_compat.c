/* Windows compatibility stubs for POSIX functions used in solver.c */
#include <time.h>
#include <stdlib.h>
#include <string.h>

/* ctime_r: POSIX thread-safe ctime. On Windows/MinGW, ctime is already thread-safe. */
char *ctime_r(const time_t *timep, char *buf) {
    char *result = ctime(timep);
    if (result && buf) {
        strcpy(buf, result);
        return buf;
    }
    return NULL;
}

/* setenv: POSIX setenv. On Windows, use _putenv_s or _putenv. */
int setenv(const char *name, const char *value, int overwrite) {
    if (!overwrite && getenv(name))
        return 0;
    /* Build "NAME=VALUE" string */
    size_t nlen = strlen(name);
    size_t vlen = strlen(value);
    char *envstr = (char *)malloc(nlen + vlen + 2);
    if (!envstr) return -1;
    strcpy(envstr, name);
    envstr[nlen] = '=';
    strcpy(envstr + nlen + 1, value);
    int rc = _putenv(envstr);
    free(envstr);
    return rc;
}
