require 'Yinspire/Stimulus'

#
# Module contains code to store local stimuli in a priority queue. Used
# by several Neuron models.
#
module Stimuli; cplus2ruby

  #
  # Each NeuralEntity has it's own local stimuli priority queue.
  # Neurons make use of this whereas Synapses do not.
  #
  # Nevertheless we put this into the base class for simplicity reasons
  # and as it's quite low overhead (12 bytes).
  #
  property :stimuli_pq, 'BinaryHeap<Stimulus, MemoryAllocator<Stimulus> >'

  #
  # Returns a Ruby array in the form [at1, weight1, at2, weight2] 
  # for +stimuli_pq+.
  #
  method :stimuli_pq_to_a, {:returns => Object}, %{
    VALUE ary = rb_ary_new(); 
    @stimuli_pq.each(Stimulus::dump_to_a, &ary);
    return ary;
  }

  # 
  # Add a Stimuli to the local priority queue.
  #
  method :stimuli_add, {:at => 'simtime'},{:weight => 'real'}, %{
    Stimulus s; s.at = at; s.weight = weight;

    if (@simulator->stimuli_tolerance >= 0.0)
    {
      Stimulus *parent = @stimuli_pq.find_parent(s);

      if (parent != NULL && (s.at - parent->at) <= @simulator->stimuli_tolerance)
      {
        parent->weight += s.weight;
        return;
      }
    }
    
    @stimuli_pq.push(s);
    schedule(@stimuli_pq.top().at);
  }

  # 
  # Consume all Stimuli until +till+ and return the sum of the weights.
  #
  method :stimuli_sum, {:till => 'simtime'},{:returns => 'real'}, %{
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
  method :stimuli_sum_inf, {:till => 'simtime'},{:is_inf => 'bool&'},{:returns => 'real'}, %{
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

end
