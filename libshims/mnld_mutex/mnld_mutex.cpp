#include <dlfcn.h>
#include <errno.h>
#include <pthread.h>
#include <stdint.h>

extern "C" int pthread_mutex_destroy(pthread_mutex_t* mutex) {
    // Bionic P+ writes 0xffff after a successful destroy and aborts if an old
    // vendor process destroys it again.  Oreo treated this undefined operation
    // as harmless, which is what MTK's mnld expects during GPS shutdown.
    if (mutex != nullptr && *reinterpret_cast<volatile uint16_t*>(mutex) == 0xffff) {
        return 0;
    }

    using Destroy = int (*)(pthread_mutex_t*);
    static Destroy real_destroy =
            reinterpret_cast<Destroy>(dlsym(RTLD_NEXT, "pthread_mutex_destroy"));
    return real_destroy != nullptr ? real_destroy(mutex) : EINVAL;
}
