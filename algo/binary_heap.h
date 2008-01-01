/*
 * An implicit Binary Heap.
 *
 * Copyright (c) 2007, 2008 by Michael Neumann (mneumann@ntecs.de)
 *
 * Template parameters:
 *
 *   E: Element type
 *   MA: Memory Allocator
 *   ACC: Accessor 
 *
 * Example:
 *
 *   struct acc {
 *     inline static bool bh_cmp_gt(int& i1, int& i2) {
 *       return (i1 > i2);
 *     }
 *   }
 *
 *   BinaryHeap<int, MemoryAllocator, acc> heap;
 *   heap.push(4);
 *   heap.pop();
 *   ...
 *
 */

#ifndef __YINSPIRE__BINARY_HEAP__
#define __YINSPIRE__BINARY_HEAP__

template <class E, class MA, class ACC = E, unsigned int MIN_CAPA=1023>
class BinaryHeap
{
    typedef unsigned int I; // index type

  public:

      BinaryHeap()
      {
        @capacity = 0;
        @size = 0;
        @elements = NULL; // we do lazy allocation!
      }

      ~BinaryHeap()
      {
        MA::free(@elements);
        @elements = NULL;
      }

    void
      push(const E& element)
      {
        @size += 1;
        if (@size > @capacity)
        {
          resize();
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

    inline E&
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
      try_pop(E& element)
      {
        if (empty()) return false;
        element = top();
        pop();
        return true;
      }

    inline I
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
        for (I i=1; i <= @size; i++)
        {
          detach_index(i);
        }
        @size = 0;
      }

    template <typename DATA> bool
      accumulate(E& element, bool (*accumulator)(E&,const E&,DATA), DATA data)
      {

        /*
         * Find the position of the first element that is not greater than
         * +element+.
         */ 
        I index = @size; 
        while (index > 0 && ACC::bh_cmp_gt(element_at(index), element))
        {
          index /= 2;
        }

        /*
         * index now points to the element that is greater than
         * +element+ (or the non-existing element in case of @size==0).
         * 
         * assert(index == 0 || ACC::bh_cmp_gt(element_at(index), element)); 
         */

        if (index == 0 || !accumulator(@elements[index], element, data))
        {
          return false;
        }
        return true;
      }

    /*
     * Iterate over all elements (non-destructive)
     */
    template <typename DATA> void
      each(void (*yield)(E&, DATA), DATA data)
      {
        for (I i=1; i <= @size; i++)
        {
          yield(@elements[i], data);
        }
      }

  protected:

    inline void
      swap_elements(I i1, I i2)
      {
        @elements[0] = @elements[i1];
        @elements[i1] = @elements[i2];
        @elements[i2] = @elements[0];

        update_index(i1);
        update_index(i2);
      }

    inline E&
      element_at(I index) const
      {
        return @elements[index];
      }

    inline void
      propagate_down(I index)
      {
        I i2;

        while (index*2+1 <= @size)
        {
          i2 = index*2 + (cmp_gt(index*2, index*2+1) ? 1 : 0);

          if (cmp_gt(index, i2))
          {
            swap_elements(index, i2);
            index = i2;
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
      propagate_up(I index)
      {
        while (index > 1 && cmp_gt(index/2, index))
        {
          swap_elements(index/2, index);
          index /= 2;
        }
      }

    inline void
      resize()
      {
        resize(2*@capacity+1);
      }

    void
      resize(I new_capacity)
      {
        if (new_capacity < MIN_CAPA) new_capacity = MIN_CAPA;  // minimum capacity!
        @capacity = new_capacity; 

        /* 
         * We do lazy allocation!
         */
        if (@elements != NULL)
        {
          @elements = MA::realloc_n(@elements, @capacity+1);
        }
        else
        {
          @elements = MA::alloc_n(@capacity+1);
        }
      }

    inline bool
      cmp_gt(I i1, I i2) const
      {
        return (ACC::bh_cmp_gt(element_at(i1), element_at(i2)));
      }

    inline void
      update_index(I index)
      {
        /* DUMMY */
      }

    inline void
      detach_index(I index)
      {
        /* DUMMY */
      }

  protected:

    I  size;
    E* elements;
    I  capacity;
};

#endif
