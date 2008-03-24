#
# Extends class NeuralEntity for methods related to 
# scheduling.
#
class NeuralEntity

  #
  # The index of this entity in the entity priority queue managed by the
  # Simulator. If +schedule_index+ is zero then the entity is currently
  # not present in the priority queue and as such the entity is not
  # scheduled at a specific time.
  #
  property :schedule_index, 'uint'

  #
  # If the entity has events in the future, this is the timestamp of the
  # next event.
  #
  property :schedule_at, 'simtime', :init => Infinity

  #
  # If stepped scheduling is used, these two properties reference the
  # previous/next entity in the stepped-scheduling list.
  #
  property :schedule_stepping_list_prev, NeuralEntity
  property :schedule_stepping_list_next, NeuralEntity

  # 
  # To be able to modify the stepped scheduling list
  # (schedule_stepping_list_prev/next) during stepped schedule
  # processing, we build up an internal linked list that we use to
  # traverse all entities that require stepped schedule processing. 
  # 
  # This is cheaper than using an externalized linked list, as we would
  # have to allocate memory which we overcome with this approach.
  # 
  # This is only used by the simulator!
  #
  property :schedule_stepping_list_internal_next, NeuralEntity

  #
  # Schedule the entity at a specific time. Only schedule if the new
  # schedule time is before the current schedule time.
  #
  method :schedule, {:at => 'simtime'}, %{
    // FIXME: make sure that @schedule_at is 
    // reset when entity is removed from pq!
    if (at < @schedule_at)
    {
      @schedule_at = at;
      @simulator->schedule_update(this);
    }
  }, :inline => true

  # 
  # Returns +true+ if stepped scheduling is enabled, +false+ otherwise.
  #
  method :schedule_stepping_enabled, {:returns => 'bool'}, %{
    return (@schedule_stepping_list_prev != NULL && 
            @schedule_stepping_list_next != NULL);
  }

  #
  # Enables stepped scheduling.
  #
  method :schedule_enable_stepping, {}, %{
    if (!schedule_stepping_enabled())
    {
      NeuralEntity*& root = @simulator->schedule_stepping_list_root; 
      if (root != NULL)
      {
        @schedule_stepping_list_prev = root;
        @schedule_stepping_list_next = root->schedule_stepping_list_next;
        root->schedule_stepping_list_next = this; 
        @schedule_stepping_list_next->schedule_stepping_list_prev = this; 
      }
      else
      {
        root = this; 
        @schedule_stepping_list_prev = this;
        @schedule_stepping_list_next = this;
      }
    }
  }

  #
  # Disables stepped scheduling.
  #
  method :schedule_disable_stepping, {}, %{
    if (schedule_stepping_enabled())
    {
      if (@schedule_stepping_list_prev != @schedule_stepping_list_next)
      {
        @schedule_stepping_list_prev->schedule_stepping_list_next = @schedule_stepping_list_next; 
        @schedule_stepping_list_next->schedule_stepping_list_prev = @schedule_stepping_list_prev;  
      }
      else
      {
        /*
         * We are the last entity in the stepping list.
         */
        @simulator->schedule_stepping_list_root = NULL;
        @schedule_stepping_list_prev = NULL;
        @schedule_stepping_list_next = NULL;
      }
    }
  }

  #
  # Accessor function for BinaryHeap
  #
  static_method :less, {:a => NeuralEntity},{:b => NeuralEntity},{:returns => 'bool'}, %{
    return (a->schedule_at < b->schedule_at);
  }, :inline => true

  #
  # Accessor function for BinaryHeap
  #
  static_method :index, {:a => NeuralEntity},{:returns => 'uint&'}, %{
    return a->schedule_index;
  }, :inline => true

end
