/* Detect a discrepancy from the linux futex headers and the actual kernel running in a VM.
 *
 * c.f. http://stackoverflow.com/a/9301512/2938
 */

#include <sys/syscall.h>
#include <unistd.h>
#include <sys/time.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
typedef uint32_t u32; /* required on older kernel headers to fix a bug in futex.h Delete this line if it causes problems. */
#include <linux/futex.h>

int main(int argc, char *argv[])
{
#if defined(FUTEX_WAIT) && defined(FUTEX_WAKE) 
        uint32_t i = 1;
        int res = 0;
        res = syscall(__NR_futex, (void *) &i, FUTEX_WAKE, 1,
                        (void*)0,(void*)0, 0);
        if (res != 0)
        {
                printf("FUTEX_WAKE HAD ERR %i: %s\n", errno, strerror(errno));
        } else {
                printf("FUTEX_WAKE SUCCESS\n");
        }

        res = syscall(__NR_futex, (void *) &i, FUTEX_WAIT, 0,
                        (void*)0,(void*)0, 0);
        if (res != 0)
        {
                printf("FUTEX_WAIT HAD ERR %i: %s\n", errno, strerror(errno));
        } else {
                printf("FUTEX_WAIT SUCCESS\n");
        }
#else
        printf("FUTEX_WAKE and FUTEX_WAIT are not defined.\n");
#endif

#if defined(FUTEX_WAIT_PRIVATE) && defined(FUTEX_WAKE_PRIVATE) 
        uint32_t j = 1;
        int res_priv = 0;
        res_priv = syscall(__NR_futex, (void *) &j, FUTEX_WAKE_PRIVATE, 1,
                        (void*)0,(void*)0, 0);
        if (res_priv != 0)
        {
                printf("FUTEX_WAKE_PRIVATE HAD ERR %i: %s\n", errno, strerror(errno));
        } else {
                printf("FUTEX_WAKE_PRIVATE SUCCESS\n");
        }

        res_priv = syscall(__NR_futex, (void *) &j, FUTEX_WAIT_PRIVATE, 0,
                        (void*)0,(void*)0, 0);
        if (res_priv != 0)
        {
                printf("FUTEX_WAIT_PRIVATE HAD ERR %i: %s\n", errno, strerror(errno));
        } else {
                printf("FUTEX_WAIT_PRIVATE SUCCESS\n");
        }
#else
        printf("FUTEX_WAKE_PRIVATE and FUTEX_WAIT_PRIVATE are not defined.\n");
#endif


        return 0;
}
