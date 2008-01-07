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
      inline void hold(PQ *pq, double increment)
      {
        ET e = pq->top();
        e.priority += increment;
        pq->pop();
        pq->push(e);
      }

      inline void push(PQ *pq, double priority)
      {
        ET e;
        e.priority = priority;
        pq->push(e);
      }

      inline void pop(PQ *pq)
      {
        pq->pop();
      }

      static const char* algorithm_name()
      {
        return "BinaryHeap";
      }
    };
  };
};
