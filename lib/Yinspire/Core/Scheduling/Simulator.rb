require 'Yinspire/Core/NeuralEntity'

#
# Extends class Simulator for methods related to 
# scheduling.
#
class Simulator

  #
  # The current simulation time.
  #
  property :schedule_current_time, 'simtime'

  #
  # The time step used for stepped scheduling.
  #
  property :schedule_step, 'simtime', :init => Infinity

  #
  # The time of the next step.
  #
  property :schedule_next_step, 'simtime', :init => Infinity

  #
  # Priority queue used to schedule the entities.
  #
  property :schedule_pq, 'IndexedBinaryHeap<NeuralEntity*, MemoryAllocator<NeuralEntity*>, NeuralEntity>',
    :mark => 'mark_schedule_pq()'

  method :mark_schedule_pq, {}, %{
    @schedule_pq.each(Simulator::mark_schedule_pq_iter, NULL);
  }
 
  static_method :mark_schedule_pq_iter, {:s => 'NeuralEntity* const&'}, {:ptr => 'void*'}, %{
    if (s) rb_gc_mark(s->__obj__);
  }

  #
  # If stepped scheduling is used, this points to the first entiy in the
  # stepped schedule list.
  #
  property :schedule_stepping_list_root, NeuralEntity

  #
  # Run the simulation.
  #
  method :schedule_run, {:stop_at => 'simtime'}, %{
    while (true)
    {
      simtime next_stop = MIN(stop_at, @schedule_next_step);

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
  method :schedule_update, {:entity => NeuralEntity}, %{
    @schedule_pq.update(entity);
  }, :inline => true

end
