/*
 * An implicit Binary Heap.
 *
 * Copyright (c) 2007, 2008 by Michael Neumann (mneumann@ntecs.de)
 *
 * NOTE: We start counting from 1 in the elements array!
 *
 * Template parameters:
 *
 *   E:        Element type
 *   Alloc:    Allocator
 *   Acc:      Accessor struct. Defines ordering relation (less).
 *   MIN_CAPA: minimum number of elements
 *
 * Example:
 *
 *   struct Acc
 *   {
 *     static inline bool less(const int& a, const int& b)
 *     {
 *       return a < b;
 *     }
 *   };
 *
 *   BinaryHeap<int, MemoryAllocator, Acc> heap;
 *   heap.push(4);
 *   heap.pop();
 *   ...
 *
 */

#ifndef __YINSPIRE__BINARY_HEAP__
#define __YINSPIRE__BINARY_HEAP__

#include <assert.h>

/*
 * This is used to be able to keep track of
 * an elements index in the IndexedBinaryHeap subclass.
 * Unused in this class.
 */
template <typename E>
struct BinaryHeapDummyIndexer
{
  static inline void index_changed(E& e, unsigned int i) 
  {
    /* DUMMY */
  }
};

template <typename E, class Alloc, class Acc=E, class Idx=BinaryHeapDummyIndexer<E>, unsigned int MIN_CAPA=1024>
class BinaryHeap
{
    typedef unsigned int I; // index type

  public:

      BinaryHeap()
      {
        @capacity = 0;
        @size_ = 0;
        @elements = NULL; // we do lazy allocation!
      }

      ~BinaryHeap()
      {
        if (@elements != NULL)
        {
          Alloc::free(@elements+1);
        }
        @elements = NULL;
      }

    inline E&
      top() const
      {
        assert(@size > 0);
        return @elements[1];  
      }

    void
      pop()
      {
        remove(1);
      }

    inline void
      remove(I i)
      {
        assert(i <= @size_);

        // 
        // Element i is removed from the heap and as such becomes
        // a "bubble" (free element). Move the bubble until
        // the bubble becomes a leaf element. 
        //
        Idx::index_changed(@elements[i], 0);  // detach from heap
        I bubble = move_bubble_down(i);

        //
        // Now take the last element and insert it at the position of
        // the bubble. In case the bubble is already the last element we
        // are done.
        //
        if (bubble != @size_)
        {
          insert_and_bubble_up(bubble, @elements[@size_]);
        }
        --@size_;
      }

    void
      push(const E& element)
      {
        if (@size_ >= @capacity) resize(2*@capacity);
        insert_and_bubble_up(++@size_, element);
      }

    inline I
      size() const
      {
        return @size_;
      }

    inline bool
      empty() const
      {
        return (@size_ == 0);
      }
    
    /*
     * Returns NULL or a pointer to the parent of +element+.
     */
    E*
      find_parent(const E& element)
      {
        I i;

        //
        // Find the position of the first element that is less than +element+.
        // 
        for (i = @size_; i != 0 && Acc::less(element, @elements[i]); i /= 2);

        return (i == 0 ? NULL : &@elements[i]); 
      }

    /*
     * Iterate over all elements (non-destructive)
     */
    void
      each(void (*yield)(const E&, void*), void *data)
      {
        for (I i=1; i <= @size_; i++)
        {
          yield(@elements[i], data);
        }
      }
 
  protected:

    /*
     * Insert +element+ into the heap beginning from
     * +i+ and searching upwards to the root for the 
     * right position (heap ordered) to insert.
     *
     * Element at index +i+ MUST be empty, i.e. unused!
     */
    inline void
      insert_and_bubble_up(I i, const E& element)
      {
        for (;i >= 2 && Acc::less(element, @elements[i/2]); i /= 2)
        {
          store_element(i, @elements[i/2]);
        }

        // finally store it into the determined hole
        store_element(i, element);
      }

    /*
     * Move the bubble (empty element) at +i+ down in direction
     * to the leaves. When the bubble reaches a leaf, stop and
     * return the index of the leaf element which is now empty.
     */
    inline I 
      move_bubble_down(I i)
      {
        const I sz = @size_;
        I right_child = i * 2 + 1;

        while (right_child <= sz) 
        {
          if (Acc::less(@elements[right_child-1], @elements[right_child]))
          {
            --right_child; // minimum child is left child
          }

          store_element(i, @elements[right_child]);
          i = right_child;
          right_child = i * 2 + 1;
        }

        //
        // Edge case (comparison with the last element)
        //
        if (right_child-1 == sz)
        {
          store_element(i, @elements[right_child-1]);
          i = right_child-1;
        }

        return i;
      }

    /*
     * The 0'th element is never used (accessed), so 
     * we allocate only "capacity" elements (instead of capacity+1)
     * and move the pointer one element before the begin of the 
     * allocated memory. 
     */
    void
      resize(I new_capacity)
      {
        E *new_elements;

        if (new_capacity < MIN_CAPA) @capacity = MIN_CAPA;  
        else @capacity = new_capacity;

        //
        // We do lazy allocation!
        //
        if (@elements != NULL)
        {
          new_elements = Alloc::realloc_n(@elements+1, @capacity);
        }
        else
        {
          new_elements = Alloc::alloc_n(@capacity);
        }

        assert(new_elements != NULL);
        assert(@capacity >= @size);

        //
        // move pointer so that we "introduce" a zero'th 
        // element.
        //
        @elements = new_elements-1;
      }

    /*
     * FIXME: cannot overwrite method in a subclass 
     * The only purpose of this method is that we overwrite it in the
     * subclass IndexedBinaryHeap to keep track of an elements index.
     */
    inline void
      store_element(I i, const E& element)
      {
        @elements[i] = element;
        Idx::index_changed(@elements[i], i); 
      }

  protected:

    I  size_;
    E *elements;
    I  capacity;
};

#endif
