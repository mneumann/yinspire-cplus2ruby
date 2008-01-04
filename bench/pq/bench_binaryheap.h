#include "algo/binary_heap.h"
#include "memory_allocator.h"

namespace BenchBinaryHeap
{
  struct ET_FLOAT 
  {
    float priority;

    static inline bool greater_than(ET_FLOAT &a, ET_FLOAT &b) { return a.priority > b.priority; }
    static const char* element_type() { return "float"; }
  };

  struct ET_DOUBLE 
  {
    double priority;

    static inline bool greater_than(ET_DOUBLE &a, ET_DOUBLE &b) { return a.priority > b.priority; }
    static const char* element_type() { return "double"; }
  };

  struct ET_STIMULI
  {
    float priority;
    float weight;

    static inline bool greater_than(ET_STIMULI &a, ET_STIMULI &b) { return a.priority > b.priority; }
    static const char* element_type() { return "Stimuli/float"; }
  };

  template<class ET>
  struct T
  {
    typedef BinaryHeap<ET, MemoryAllocator<ET> > PQ;

    struct ACC
    {
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
