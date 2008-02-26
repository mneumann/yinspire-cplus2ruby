/*
 * A chunked freelist Allocator
 *
 * Copyright (c) 2007, 2008 by Michael Neumann (mneumann@ntecs.de)
 *
 * Memory is allocated in chunks of size +chunk_size+. Chunks are never
 * freed except when the destructor is called.
 */

#ifndef __YINSPIRE__CHUNKED_FREELIST_ALLOCATOR__
#define __YINSPIRE__CHUNKED_FREELIST_ALLOCATOR__

#include <assert.h>

template <class T, class ACC = T>
class ChunkedFreelistAllocator
{

    template <class TT>
    struct Chunk
    {
      Chunk<TT> *next_chunk;
      TT *array; 
    };

  public:

    ChunkedFreelistAllocator(unsigned int chunksize)
    {
      @freelist = NULL;
      @chunklist = NULL;
      @chunksize = chunksize;
    }

    T*
      allocate()
      {

        // alloc new chunk if no more free elements are available
        if (@freelist == NULL) alloc_chunk();

        assert(@freelist != NULL);

        T* e = @freelist; 
        @freelist = ACC::next(e);
        ACC::next(e) = NULL;

        return e;
      }

    void
      free(T* e)
      {
        //assert(ACC::next(e) == NULL);
        ACC::next(e) = @freelist;
        @freelist = e;
      }

    void
      free_list(T* first, T* last)
      {
        assert(last != NULL);
        //assert(ACC::next(first) == NULL);
        ACC::next(last) = @freelist; 
        @freelist = first;
      }

  protected:

    void
      alloc_chunk()
      {
        Chunk<T> *new_chunk = new Chunk<T>;
        new_chunk->next_chunk = @chunklist;
        @chunklist = new_chunk;

        new_chunk->array = new T[@chunksize]; 

        // put all elements of new chunk on freelist
        for (unsigned int i=0; i<@chunksize-1; i++)
        {
          ACC::next(&new_chunk->array[i]) = &new_chunk->array[i+1];
        }

        ACC::next(&new_chunk->array[@chunksize-1]) = @freelist;
        @freelist = &new_chunk->array[0];
      }

  private:

    T *freelist;
    Chunk<T> *chunklist;
    unsigned int chunksize;
};

#endif
