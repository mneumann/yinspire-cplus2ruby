/*
 * An Indexed Binary Heap
 *
 * Copyright (c) 2007, 2008 by Michael Neumann (mneumann@ntecs.de)
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
 *   IndexedBinaryHeap<E, MemoryAllocator, acc> heap;
 *   ...
 *
 */

#ifndef __YINSPIRE__INDEXED_BINARY_HEAP__
#define __YINSPIRE__INDEXED_BINARY_HEAP__

#include "binary_heap.h"

template <class E, class MA, class ACC = E, unsigned int MIN_CAPA=1023> 
class IndexedBinaryHeap : public BinaryHeap<E, MA, ACC, MIN_CAPA>
{
    typedef unsigned int I; // index type
    typedef BinaryHeap<E, MA, ACC, MIN_CAPA> super; 

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

    /*
     * Remove this element from the heap.
     */
    void
      remove(E& element)
      {
        // FIXME
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
