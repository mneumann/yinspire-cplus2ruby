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
class Benchmark
{
  public:

    Benchmark(PQ *pq, Distribution *distribution)
    {
      @pq = pq;
      @distribution = distribution; 
    }

    /*
     * In the updown benchmark the xxx_cycles mean complete up/down
     * cycles. 
     */
    double
      updown(int max_queue_size, int warmup_cycles, int empty_updown_cycles, int updown_cycles)
      {
        clock_t t1, t2;

        run_updown(max_queue_size, warmup_cycles); // warmup

        t1 = clock();
        run_empty_updown(max_queue_size, empty_updown_cycles);
        t2 = clock();
        double empty_updown_time = ((double)(t2 - t1)) / empty_updown_cycles;

        t1 = clock();
        run_updown(max_queue_size, updown_cycles);
        t2 = clock();
        double updown_time = ((double)(t2 - t1)) / updown_cycles;

        return (updown_time - empty_updown_time) / CLOCKS_PER_SEC;
      }

    double
      classic_hold(int queue_size, int warmup_cycles, int empty_hold_cycles, int hold_cycles)
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

  protected:

    void
      run_updown(unsigned int max_queue_size, unsigned int cycles)
      {
        unsigned int i, j;

        for (i=0; i<cycles; i++)
        {
          for (j=0; j<max_queue_size; j++)
          {
            @acc.push(@pq, distribution->next());
          }
          for (j=0; j<max_queue_size; j++)
          {
            @acc.pop(@pq);
          }
        }
      }

    void
      run_empty_updown(unsigned int max_queue_size, unsigned int cycles)
      {
        unsigned int i, j;

        for (i=0; i<cycles; i++)
        {
          // To avoid dead code elemination...
          for (j=0; j<2*max_queue_size; j++)
          {
            if (j&1 == 0)
            {
              distribution->next();
            }
          }
        }
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
            @acc.push(@pq, rnd_real.next());
          }

          if (!@pq->empty() && rnd_bool.next() < delete_prob)
          {
            @acc.pop(@pq);
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

    /*
     * Perform a hold operation
     */
    inline void
      hold()
      {
        @acc.hold(@pq, distribution->next()); 
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
    ACC acc;

};
