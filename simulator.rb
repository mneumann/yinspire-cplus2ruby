class Simulator
  helper_header %{
    #include "binary_heap.h"
  }

  #
  # The current simulation time.
  #
  property :schedule_current_time, 'stime'

  #
  # The time step used for stepped scheduling.
  #
  property :schedule_step, 'stime', default: '%s = INFINITY'

  #
  # The time of the next step.
  #
  property :schedule_next_step, 'stime', default: '%s = INFINITY'

  #
  # The tolerance (time difference) up to which local stimuli are
  # accumulated.
  #
  property :stimuli_tolerance, 'stime'

  #
  # Priority queue used to schedule the entities.
  #
  property :schedule_pq, 'IndexedBinaryHeap<NeuralEntity*, NeuralEntity>', internal: true

  #
  # If stepped scheduling is used, this points to the first entiy in the
  # stepped schedule list.
  #
  property :schedule_stepping_list_root, NeuralEntity

  #
  # Start the simulation.
  #
  method :run, {stop_at: 'stime'}, %{
    while (true)
    {
      stime next_stop = MIN(stop_at, @schedule_next_step);

      /* 
       * Calculate all events from the priority queue until the next time
       * step is reached.
       */
      while (!@schedule_pq.empty())
      {
        NeuralEntity *top = @schedule_pq.top();
        if (top->schedule_at >= next_stop)
          break;
        @schedule_current_time = top->schedule_at; 
        @schedule_pq.pop();
        top->process(top->schedule_at);
      }

      if (@schedule_current_time >= stop_at)
        break;

      if (@schedule_stepping_list_root == NULL && @schedule_pq.empty())
        break;

      /* 
       * Calculate the entities that require stepped processing.
       */ 
      @schedule_current_time = @schedule_next_step; 

      if (@schedule_stepping_list_root != NULL)
      {
        // FIXME: collect all entities in an array. then process them.
      }

      @schedule_next_step += @schedule_step;
    }
  }
  
  # 
  # If an entity has changed it's scheduling time, it has to call this
  # method to reflect the change within the priority queue.
  #
  method :schedule_update, {entity: NeuralEntity}, %{
    @schedule_pq.push_or_update(entity);
  }
end
