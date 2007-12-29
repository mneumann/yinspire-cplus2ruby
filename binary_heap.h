/*
 * Two Binary Heap implementations.
 *
 * Copyright (c) 2007 by Michael Neumann (mneumann@ntecs.de)
 *
 */

#ifndef __YINSPIRE__BINARY_HEAP__
#define __YINSPIRE__BINARY_HEAP__

#include <iostream>

/*
 * An implicit Binary Heap.
 *
 *   E: Element type
 *   I: Index type name
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
 *   BinaryHeap<int, MemoryAllocator, unsigned int, acc> heap;
 *   heap.push(4);
 *   heap.pop();
 *   ...
 *
 */

template <class E, class MA, typename I = unsigned int, class ACC = E>
class BinaryHeap
{
  public:

      BinaryHeap()
      {
        @capacity = 0;
        //@real_capacity = 
        @size = 0;
        @elements = NULL; // we do lazy allocation!
        @resize_factor = 0;
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
        // bit shifted capacity.
     
        //I new_capacity = @capacity+1;

        //@capacity *=
        resize(2*@capacity+1);
        //@resize_factor *= 2;
      }

    void
      resize(I new_capacity)
      {
        if (new_capacity < 1023) new_capacity = 1023;  // minimum capacity!
        @capacity = new_capacity; 

        //std::cout << "rf: " << @resize_factor << "  ";
        //std::cout << "nc: " << new_capacity << std::endl; 

        //resize_factor++;

        /* 
         * We do lazy allocation!
         */
        if (@elements != NULL)
        {
          E *new_elements = MA::alloc_n(@capacity+1);
          memcpy(new_elements, elements, sizeof(E)*@size-1);
          MA::free(@elements);
          @elements = new_elements;
          //@elements = MA::realloc_n(@elements, @capacity+1);
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

    I  real_capacity;
    I  capacity;
    I  size;
    E* elements;
    short resize_factor;

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
 *     inline static unsigned int& bh_index(E& e) {
 *       return e.schedule_index;
 *     }
 *     inline static bool bh_cmp_gt(E& e1, E& e2) {
 *       return (e1.schedule_at > e2.schedule_at);
 *     }
 *   }
 *
 *   IndexedBinaryHeap<E, MemoryAllocator, unsigned int, acc> heap;
 *   ...
 *
 */

template <class E, class MA, typename I = unsigned int, class ACC = E> 
class IndexedBinaryHeap : public BinaryHeap<E, MA, I, ACC>
{
    typedef BinaryHeap<E, MA, I, ACC> super; 

  public:

    void
      update(E& element)
      {
        I index = ACC::bh_index(element); 
        super::propagate_up(index);
        super::propagate_down(index);
      }

    inline void 
      push_or_update(E& element)
      {
        if (ACC::bh_index(element) == 0)
        {
          super::push(element);
        }
        else
        {
          update(element);
        }
      }

  protected:

    inline void
      update_index(I i)
      {
        ACC::bh_index(super::element_at(i)) = i;
      }

    inline void
      detach_index(I i)
      {
        ACC::bh_index(super::element_at(i)) = 0;
      }

};

#endif
