/*
 * A Calendar Queue implementation.
 *
 * Copyright (c) 2007, 2008 by Michael Neumann (mneumann@ntecs.de)
 *
 * Template parameters:
 *
 *   E: Element type
 *   ACC: Accessor
 *     priority -> real
 *     next -> E*&
 *   real: precision type
 * 
 */

#ifndef __YINSPIRE__CALENDAR_QUEUE__
#define __YINSPIRE__CALENDAR_QUEUE__

#include <assert.h>

template <typename E, class ACC = E, typename real=float>
class CalendarQueue
{
    typedef unsigned int I; // index type

  public:

    CalendarQueue(real initial_bucket_width=1.0)
    {
      @size_ = 0;
      @buckets = NULL;
      @num_buckets = 0;
      @bucket_width = initial_bucket_width;
      @current_year = 0;
      @current_day = 0;
      resize(1, initial_bucket_width);
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

    void
      push(E *element)
      {
        const real priority = ACC::priority(element); 

        assert(priority >= 0.0);

        ++@size_;

        if (@size_ > 2*@num_buckets)
        {
          // double number of buckets
          resize(2*@num_buckets, @bucket_width/2.0);
        }

        // map priority to a bucket
        I bucket = ((I)(priority / @bucket_width)) % @num_buckets;

        // and sort element into that bucket
        insert_sorted(bucket, element);

        //
        // in case that the newly inserted element is smaller than the
        // currently smallest value we have to change the year and day.
        //
        if (priority < (@current_year * @num_buckets + @current_day)*@bucket_width)
        {
          @current_year = (I)(priority / @bucket_width) / @num_buckets;
          @current_day = bucket;
        }
      }

    E*
      pop()
      {
        assert(@size_ > 0);

        --@size_;

        if (@size_ < @num_buckets/2 && @num_buckets > 1)
        {
          // half the number of buckets
          //resize(@num_buckets/2, @bucket_width*2.0);
        }

        real priority;
        real max_value_this_year = (@current_year+1)*@bucket_width*@num_buckets;
        E *top;

        for (; @current_day < @num_buckets; @current_day++)
        {
          top = @buckets[@current_day];
          if (top != NULL)
          {
            real priority = ACC::priority(top);

            // FIXME: < or <= ???
            if (priority < max_value_this_year)
            {
              // remove top element
              @buckets[@current_day] = ACC::next(top); 

              return top;
            }
          }
        }

        // we couldn't find an element within the current year.
        // -> find the smallest element and jump to it's year.

        real min_priority = INFINITY;
        int min_index = -1;

        for (I i = 0; i < @num_buckets; i++)
        {
          top = @buckets[i];
          if (top != NULL && ACC::priority(top) < min_priority)
          {
            min_priority = ACC::priority(top);
            min_index = i;
          }
        }

        assert(min_index >= 0);

        @current_year = ((I)(min_priority / @bucket_width)) / @num_buckets;
        @current_day = ((I)(min_priority / @bucket_width))  % @num_buckets;

        top = @buckets[min_index];
        @buckets[min_index] = ACC::next(top); 

        return top;
      }

  protected:

    void
      insert_sorted(I bucket, E *element)
      {
        E *curr = @buckets[bucket];
        E *prev = NULL; 
        const real priority = ACC::priority(element);

        //
        // Find the first element that is >= +element+.
        // Insert +element+ *before* that element.
        //
        while (true)
        {
          if (curr == NULL) break;
          if (ACC::priority(curr) >= priority) break;
          prev = curr;
          curr = ACC::next(curr);
        }

        if (prev == NULL)
        {
          ACC::next(element) = curr;
          @buckets[bucket] = element;
        }
        else
        {
          ACC::next(element) = ACC::next(prev); 
          ACC::next(prev) = element;
        }
      }

    /* 
     * TODO: the growing-case can be improved by
     * always merging two consecutive buckets
     * into a new one.
     * 
     * TODO: enqueue should be faster if done with decreasing priorities, instead
     * of increasing ones ( O(1) vs. O(n/2) ).
     *
     * TODO: during insert above, determine the smallest element. this avoids
     * rescanning the whole buckets at least twice (the first time to notice
     * that we couldn't find an item within this year, and the second time to
     * find the smallest element).
     */
    void
      resize(I new_num_buckets, real new_bucket_width)
      {
        E **old_buckets = @buckets;
        @buckets = new E*[new_num_buckets];

        // initialize @buckets to NULL
        for (I i = 0; i < new_num_buckets; i++) @buckets[i] = NULL;

        if (old_buckets != NULL)
        {
          for (I i = 0; i < @num_buckets; i++)
          {
            for (E *curr = old_buckets[i]; curr != NULL; curr = ACC::next(curr))
            {
              real priority = ACC::priority(curr);  
              I bucket = (I)(priority / new_bucket_width) % new_num_buckets;
              insert_sorted(bucket, curr);
            }
          }

          delete[] old_buckets;
        }

        @num_buckets = new_num_buckets;
        @bucket_width = new_bucket_width;
        @current_year = 0;
        @current_day = 0;
      }

  private:

    I size_;
    I num_buckets;
    real bucket_width;
    E** buckets;

    I current_year;
    I current_day;
};

#endif
