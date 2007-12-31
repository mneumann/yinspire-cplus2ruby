#ifndef __YINSPIRE__TYPES__
#define __YINSPIRE__TYPES__

typedef unsigned int uint;
typedef float real; 
typedef float simtime;

#define real_exp expf
#define real_fabs fabsf

#ifndef NULL
#define NULL 0L
#endif

#define MIN(a,b) ((a) < (b) ? (a) : (b))
#define MAX(a,b) ((a) > (b) ? (a) : (b))

#endif
