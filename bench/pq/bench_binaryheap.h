#include "algo/binary_heap.h"
#include "memory_allocator.h"

namespace BenchBinaryHeap
{
  template<class ET>
  struct T
  {
    typedef BinaryHeap<ET, MemoryAllocator<ET> > PQ;

    struct ACC
    {
      static inline unsigned int get_size(PQ *pq)
      {
        return pq->size();
      }

      static inline void hold(PQ *pq, double increment)
      {
        ET e = pq->top();
        e.priority += increment;
        pq->pop();
        pq->push(e);
      }

      static inline void push(PQ *pq, double priority)
      {
        ET e;
        e.priority = priority;
        pq->push(e);
      }

      static const char* algorithm_name()
      {
        return "BinaryHeap";
      }
    };
  };
};
