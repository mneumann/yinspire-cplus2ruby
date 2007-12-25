#ifndef __YINSPIRE__MEMORY_ALLOCATOR__
#define __YINSPIRE__MEMORY_ALLOCATOR__

#include <stdlib.h>

/*
 * Provides some basic utility functions for allocating and releasing
 * memory.
 */
class MemoryAllocator
{
  public:

    template<typename T> inline static T*
      alloc_n(size_t n)
      {
        T* ptr = (T*) calloc(n, sizeof(T));
        if (ptr == NULL)
        {
          throw "memory allocation failed";
        }
        return ptr;
      }

    template<typename T> inline static T*
      realloc_n(T* old_ptr, size_t n)
      {
        T* ptr = (T*) realloc(old_ptr, sizeof(T)*n);
        if (ptr == NULL)
        {
          throw "memory allocation failed";
        }
        return ptr;
      }

    template<typename T> inline static void
      free(T* ptr)
      {
        ::free(ptr);
      }

};

#endif
