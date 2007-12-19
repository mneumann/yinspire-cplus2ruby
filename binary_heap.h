/*
 * Two Binary Heap implementations.
 *
 * Copyright (c) 2007 by Michael Neumann (mneumann@ntecs.de)
 *
 */

#ifndef __YINSPIRE__BINARY_HEAP__
#define __YINSPIRE__BINARY_HEAP__

/*
 * DEPENDENCIES: uint must be defined as unsigned integer
 */

#include "memory_allocator.h"

/*
 * An implicit Binary Heap.
 *
 * Example:
 *
 *   struct acc {
 *     inline static bool bh_cmp_gt(int& i1, int& i2) {
 *       return (i1 > i2);
 *     }
 *   }
 *
 *   BinaryHeap<int, acc> heap;
 *   heap.push(4);
 *   heap.pop();
 *   ...
 *
 */

template <class T, class ACC = T>
class BinaryHeap
{
  public:

      BinaryHeap()
      {
        @capacity = 0;
        @size = 0;
        @elements = NULL; // we do lazy allocation!
      }

      ~BinaryHeap()
      {
        MemoryAllocator::free<T>(@elements);
        @elements = NULL;
      }

    void
      push(const T& element)
      {
        @size += 1;
        if (@size > @capacity)
        {
          resize(2*@capacity + 1);
        }
        @elements[@size] = element;
        update_index(@size);
        propagate_up(@size);
      }

    void
      pop()
      {
        detach_index(1);
        @elements[1] = @elements[@size];
        @size -= 1;
        if (@size > 0)
        {
          update_index(1);
          propagate_down(1);
        }
      }

    inline T&
      top() const
      {
        return @elements[1];  
      }

    bool
      try_pop()
      {
        if (empty()) return false;
        pop();
        return true;
      }

    bool
      try_pop(T& element)
      {
        if (empty()) return false;
        element = top();
        pop();
        return true;
      }

    inline uint
      get_size() const
      {
        return @size;
      }

    inline bool
      empty() const
      {
        return (@size == 0);
      }

    /*
     * Remove all elements from the pq.
     */
    void
      clear()
      {
        for (uint i=1; i <= @size; i++)
        {
          detach_index(i);
        }
        @size = 0;
      }

    template <typename DATA> void
      push_accumulate(T& element, bool (*accumulate)(T&,T&,DATA), DATA data)
      {

        /*
         * Find the position of the element that is not greater than
         * +element+.
         */ 
        uint index = @size; 
        while (index > 1 && ACC::bh_cmp_gt(element_at(index/2), element))
        {
          index /= 2;
        }

        /*
         * index now points to the element that is greater than
         * +element+ (or the non-existing element in case of @size==0).
         * 
         * assert(index == 0 || ACC::bh_cmp_gt(element_at(index), element)); 
         */

        if (index == 0 || !accumulate(@elements[index], element, data))
        {
          push(element);
        }
      }

    /*
     * Iterate over all elements (non-destructive)
     */
    template <typename DATA> void
      each(void (*yield)(T&, DATA), DATA data)
      {
        for (uint i=1; i <= @size; i++)
        {
          yield(@elements[i], data);
        }
      }

  protected:

    inline void
      swap_elements(uint i1, uint i2)
      {
        T tmp = @elements[i1];
        @elements[i1] = @elements[i2];
        @elements[i2] = tmp;

        update_index(i1);
        update_index(i2);
      }

    inline T&
      element_at(uint index)
      {
        return @elements[index];
      }

    inline void
      propagate_down(uint index)
      {
        uint min;

        while (index*2+1 <= @size)
        {
          min = cmp_gt(index*2, index*2+1) ? 1 : 0; 
          if (cmp_gt(index, index*2+min))
          {
            swap_elements(index, index*2+min);
            index = index*2+min;
          }
          else
          {
            break;
          }
        }

        /*
         * edge case
         */ 
        if (index*2 == @size && cmp_gt(index, index*2))
        {
          swap_elements(index, index*2);
        }
      }

    inline void
      propagate_up(uint index)
      {
        while (index > 1 && cmp_gt(index/2, index))
        {
          swap_elements(index/2, index);
          index /= 2;
        }
      }

    inline void
      resize(uint new_capacity)
      {
        if (new_capacity < 7) new_capacity = 7;  // minimum capacity!
        @capacity = new_capacity; 

        /* 
         * We do lazy allocation!
         */
        if (@elements != NULL)
        {
          @elements = MemoryAllocator::realloc_n<T>(@elements, @capacity+1);
        }
        else
        {
          @elements = MemoryAllocator::alloc_n<T>(@capacity+1);
        }
      }

    inline bool
      cmp_gt(uint i1, uint i2)
      {
        return (ACC::bh_cmp_gt(element_at(i1), element_at(i2)));
      }

    inline void
      update_index(uint index)
      {
        /* DUMMY */
      }

    inline void
      detach_index(uint index)
      {
        /* DUMMY */
      }

  protected:

    uint capacity;
    uint size;
    T*   elements;

};

/*
 * An Indexed Binary Heap
 *
 * The Indexed Binary Heap keeps track of the indices of it's elements
 * stored in the heap. 
 *
 * The requirement was to modify an elements priority. In a regular
 * implicit binary heap this is an inefficient operation, as 
 * the element has to be found prior to modifying it's priority. 
 * And finding an element is O(n) in an implicit binary heap. By keeping
 * track of the elements index and storing this value inside the
 * element, the complexity of modifying an elements priority is
 * O(log n) in the worst-case! 
 *
 * NOTE: Index 0 of the elements array is unused.  It's the index that
 * should be used to denote that an element is NOT actually present in
 * the binary heap.
 *
 * Example:
 *
 *   struct acc {
 *     inline static uint& bh_index(T& e) {
 *       return e.schedule_index;
 *     }
 *     inline static bool bh_cmp_gt(T& e1, T& e2) {
 *       return (e1.schedule_at > e2.schedule_at);
 *     }
 *   }
 *
 *   IndexedBinaryHeap<T, acc> heap;
 *   ...
 *
 */

template <class T, class ACC = T> 
class IndexedBinaryHeap : public BinaryHeap<T,ACC>
{
    typedef BinaryHeap<T,ACC> super; 

  public:

    void
      update(T& element)
      {
        uint index = ACC::bh_index(element); 
        super::propagate_up(index);
        super::propagate_down(index);
      }

    void 
      push_or_update(T& element)
      {
        if (ACC::bh_index(element) == 0)
        {
          BinaryHeap<T,ACC>::push(element);
        }
        else
        {
          update(element);
        }
      }

  protected:

    inline void
      update_index(uint i)
      {
        ACC::bh_index(BinaryHeap<T,ACC>::element_at(i)) = i;
      }

    inline void
      detach_index(uint i)
      {
        ACC::bh_index(BinaryHeap<T,ACC>::element_at(i)) = 0;
      }

};

#endif
