#include <assert.h>
#include "distribution.h"
#include <time.h> // clock()

/*
 *
 * ACC: 
 *
 *   hold(PQ* pq, double priority_increment);
 *   push(PQ* pq, double priority_value);
 *
 */
template <class PQ, class ACC>
class ClassicHold
{

  public:

    ClassicHold(PQ *pq, Distribution *distribution)
    {
      @pq = pq;
      @distribution = distribution; 
    }

    /*
     * Setup the priority queue with a size of +queue_size+.
     */ 
    void
      setup(unsigned int queue_size, double insert_prob=0.75, double delete_prob=0.5)
      {
        RandomDistribution rnd_bool;
        RandomDistribution rnd_real;

        assert(insert_prob > delete_prob);

        while (@pq->size() < queue_size)
        {
          if (rnd_bool.next() < insert_prob)
          {
            ACC::push(@pq, rnd_real.next());
          }

          if (!@pq->empty() && rnd_bool.next() < delete_prob)
          {
            @pq->pop();
          }
        }
      }

  /*
   * To reach the steady state, +repeats+ number of hold operations are
   * performed.
   *
   * A common number of repeat cycles is "30*queue_size".
   */
  void
    warmup(int repeats) 
    {
      for (; repeats > 0; repeats--)
      {
        hold();
      }
    }

  void
    perform_empty_holds(int repeats)
    {
      for (; repeats > 0; repeats--)
      {
        empty_hold();
      }
    }

  void
    perform_holds(int repeats)
    {
      for (; repeats > 0; repeats--)
      {
        hold();
      }
    }

  double measure(int queue_size, int warmup_cycles, int empty_hold_cycles,
      int hold_cycles)
  {
    clock_t t1, t2;

    setup(queue_size);
    warmup(warmup_cycles);

    t1 = clock();
    perform_empty_holds(empty_hold_cycles);
    t2 = clock();
    double empty_hold_time = ((double)(t2 - t1)) / empty_hold_cycles;

    t1 = clock();
    perform_holds(hold_cycles);
    t2 = clock();
    double hold_time = ((double)(t2 - t1)) / hold_cycles;

    return (hold_time - empty_hold_time) / CLOCKS_PER_SEC;
  }

  /*
   * Perform a hold operation
   */
  inline void
    hold()
    {
      ACC::hold(@pq, distribution->next()); 
    }

  /*
   * Perform an empty hold operation for measuring the overhead of
   * random number generation etc (all except priority queue
   * operations).
   */ 
  inline void
    empty_hold()
    {
      distribution->next();
    }

  private:

    PQ *pq;
    Distribution *distribution;

};
