#include "algo/calendar_queue.h"
#include "chunked_freelist_allocator.h"

namespace BenchCalendarQueue
{
  template<class ET>
  struct T
  {
    typedef CalendarQueue<ET> PQ;

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
        ET *e = pq->pop();
        e->_priority += increment;
        pq->push(e);
      }

      inline void push(PQ *pq, double priority)
      {
        ET *e = @freelist->allocate();
        e->_priority = priority;
        pq->push(e);
      }

      inline void pop(PQ *pq)
      {
        @freelist->free(pq->pop());
      }

      inline double pop_return_priority(PQ *pq)
      {
        ET *e = pq->pop();
        double res = e->_priority; 
        @freelist->free(e);
        return res;
      }

      static const char* algorithm_name()
      {
        return "CalendarQueue";
      }
    };
  };
};
