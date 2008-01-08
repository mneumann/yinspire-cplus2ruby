#include "algo/pairing_heap.h"
#include "chunked_freelist_allocator.h"

namespace BenchPairingHeap
{
  template<class ET>
  struct T
  {
    typedef PairingHeap<ET> PQ;

    struct ACC
    {
      ChunkedFreelistAllocator<ET> *freelist;

      ACC()
      {
        @freelist = new ChunkedFreelistAllocator<ET>(100000);
      }

      ~ACC()
      {
        delete @freelist;
      }

      inline void hold(PQ *pq, double increment)
      {
        ET *e = pq->top();
        e->priority += increment;
        pq->pop();
        pq->push(e);
      }

      inline void push(PQ *pq, double priority)
      {
        ET *e = @freelist->allocate();
        e->priority = priority;
        pq->push(e);
      }

      inline void pop(PQ *pq)
      {
        @freelist->free(pq->top());
        pq->pop();
      }

      inline double pop_return_priority(PQ *pq)
      {
        ET *e = pq->top();
        double res = e->priority; 
        pq->pop();
        @freelist->free(e);
        return res;
      }

      static const char* algorithm_name()
      {
        return "PairingHeap";
      }
    };
  };
};
