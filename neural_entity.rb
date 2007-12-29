#
# NeuralEntity is the base class of all entities in a neural net, i.e.
# Neurons and Synapses.
#
class NeuralEntity
  # 
  # The data structure used for storing a fire impluse or any other form
  # of stimulation.
  #
  helper_header %{
    struct Stimulus
    {
      simtime at;
      real  weight;

      inline static bool
        bh_cmp_gt(Stimulus &a, Stimulus &b)
        {
          return (a.at > b.at); 
        }
    };
  }

  #
  # Each NeuralEntity has an +id+ associated which uniquely identifies
  # itself within a Simulator instance. This +id+ is usually assigned by the
  # Simulator (during loading or constructing a neural net) and SHOULD
  # NOT be changed afterwards (because it's used as a key in a Hash).
  #
  property :id

  #
  # Each NeuralEntity has a reference back to the Simulator. This is
  # used for example to update it's scheduling or to report a fire
  # event.
  #
  # Like +id+, this is assigned by the Simulator.
  #
  property :simulator, Simulator

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
  property :schedule_at, 'simtime', init: Infinity

  #
  # Each NeuralEntity has it's own local stimuli priority queue.
  # Neurons make use of this whereas Synapses do not.
  #
  # Nevertheless we put this into the base class for simplicity reasons
  # and as it's quite low overhead (12 bytes).
  #
  property :stimuli_pq, 'BinaryHeap<Stimulus, MemoryAllocator<Stimulus> >'
    
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
  # Helper code for method +stimuli_pq_to_a+.
  #
  helper_code %{
    static void
    dump_stimuli(Stimulus& s, VALUE ary)
    {
      rb_ary_push(ary, rb_float_new(s.at));
      rb_ary_push(ary, rb_float_new(s.weight));
    }
  }

  #
  # Returns a Ruby array in the form [at1, weight1, at2, weight2] 
  # for +stimuli_pq+.
  #
  method :stimuli_pq_to_a, {returns: Object}, %{
    VALUE ary = rb_ary_new(); 
    @stimuli_pq.each<VALUE>(dump_stimuli, ary);
    return ary;
  }

  # 
  # Dump the internal state of a NeuralEntity and return it. Internal
  # state does not contain the net connections which have to be dumped
  # separatly by the Simulator using +each_connection+.
  #
  def dump(into)
  end

  #
  # Load the internal state of a NeuralEntity from +data+. Note that
  # this does not neccessarily reset the internal state prior of
  # loading, which means that you have to take care that the
  # NeuralEntity is not put in an inconsistent state!
  #
  def load(data)
  end

  #
  # Connect +self+ with +target+.
  #
  def connect(target)
    raise "abstract method"
  end

  #
  # Disconnect +self+ from all connections.
  #
  def disconnect(target)
    raise "abstract method"
  end
  
  #
  # Disconnect +self+ from all connections.
  #
  def disconnect_all
    each_connection {|conn| disconnect(conn) }
  end

  #
  # Iterates over each connection. To be overwritten by subclasses!
  #
  def each_connection
    raise "abstract method"
  end

  #
  # Stimulate an entity +at+ a specific time with a specific +weight+
  # and from a specific +source+.
  #
  # Default behaviour is to add the stimuli to the local priority queue.
  #
  # Overwrite!
  #
  method :stimulate, {at: 'simtime', weight: 'real', source: NeuralEntity}, %{
    stimuli_add(at, weight);
  }, virtual: true

  #
  # This method is called when a NeuralEntity reaches it's scheduling
  # time.
  #
  # Overwrite if you need this behaviour!
  #
  method :process, {at: 'simtime'}, nil, virtual: true

  #
  # This method is called in each time-step, if and only if a
  # NeuralEntity had enabled stepped scheduling.
  #
  # Overwrite if you need this behaviour!
  #
  method :process_stepped, {at: 'simtime', step: 'simtime'}, nil, virtual: true

  protected

  #
  # Schedule the entity at a specific time.
  #
  method :schedule, {at: 'simtime'}, %{
    // FIXME: make sure that @schedule_at is 
    // reset when entity is removed from pq!
    if (@schedule_at != at)
    {
      @schedule_at = at;
      @simulator->schedule_update(this);
    }
  }

  # 
  # Returns +true+ if stepped scheduling is enabled, +false+ otherwise.
  #
  method :schedule_stepping_enabled, {returns: 'bool'}, %{
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
  # Accumulation function
  #
  helper_code %{
    static bool
    stimuli_accum(Stimulus &parent, const Stimulus &element, real tolerance)
    {
      if ((element.at - parent.at) > tolerance) return false;

      if (isinf(element.weight))
      {
         /* 
          * We only accumulate two infinitive values!
          */
         return (isinf(parent.weight) ? true : false);
      }

      parent.weight += element.weight;
      return true;
    }
  }

  # 
  # Add a Stimuli to the local priority queue.
  #
  method :stimuli_add, {at: 'simtime', weight: 'real'}, %{
    Stimulus s; s.at = at; s.weight = weight;
    if (@simulator->stimuli_tolerance >= 0.0)
    {
      if (@stimuli_pq.accumulate<real>(s, stimuli_accum, @simulator->stimuli_tolerance))
      {
        return;
      }
    }
    @stimuli_pq.push(s);
    schedule(@stimuli_pq.top().at);
  }

  # 
  # Consume all Stimuli until +till+ and return the sum of the weights.
  #
  method :stimuli_sum, {till: 'simtime', returns: 'real'}, %{
    real weight = 0.0;

    while (!@stimuli_pq.empty() && @stimuli_pq.top().at <= till)
    {
      weight += @stimuli_pq.top().weight;
      @stimuli_pq.pop();
    }

    /*
     * NOTE: we don't have to remove the entity from the schedule if the
     * pq is empty.
     */
    if (!@stimuli_pq.empty())
    {
      schedule(@stimuli_pq.top().at);
    }

    return weight;
  }

  #
  # Consume all Stimuli until +till+ and return the sum of the weights.
  # This treats infinitive values specially and instead of summing them,
  # it sets +is_inf+ to +true+.
  #
  method :stimuli_sum_inf, {till: 'simtime', is_inf: 'bool&', returns: 'real'}, %{
    real weight = 0.0;
    is_inf = false;

    while (!@stimuli_pq.empty() && @stimuli_pq.top().at <= till)
    {
      if (isinf(@stimuli_pq.top().weight))
      {
        is_inf = true;
      }
      else
      {
        weight += @stimuli_pq.top().weight;
      }
      @stimuli_pq.pop();
    }

    if (!@stimuli_pq.empty())
    {
      schedule(@stimuli_pq.top().at);
    }

    return weight;
  }

  #
  # Accessor function for BinaryHeap
  #
  method :bh_cmp_gt, {a: NeuralEntity, b: NeuralEntity, returns: 'bool'}, %{
    return (a->schedule_at > b->schedule_at);
  }, static: true, inline: true
  
  #
  # Accessor function for BinaryHeap
  #
  method :bh_index, {a: NeuralEntity, returns: 'uint&'}, %{
    return a->schedule_index;
  }, static: true, inline: true

end
