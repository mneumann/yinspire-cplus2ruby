class Synapse < NeuralEntity

  # 
  # The fire weight of a Synapse.
  #
  property :weight, 'real', :marshal => true

  # 
  # The propagation delay of a Synapse.
  #
  property :delay, 'simtime', :marshal => true

  #
  # The pre and post Neurons of the Synapse.
  #
  property :pre_neuron, Neuron
  property :post_neuron, Neuron

  #  
  # Those two pointers are part of an internal linked-list that
  # starts at a Neuron and connects all pre-synapses of an Neuron
  # together. In the same way it connects all post-synapses of an
  # Neuron together.
  #
  property :next_pre_synapse, Synapse
  property :next_post_synapse, Synapse

  # 
  # Only propagate the stimulation if it doesn't originate from the
  # post Neuron.  Stimuli from a post Neuron are handled by a specific
  # Synapse class (e.g. Hebb).
  # 
  # We ignore the weight parameter that is passed by the Neuron.
  #
  method :stimulate, {:at => 'simtime'},{:weight => 'real'},{:source => NeuralEntity}, %{
    if (source != @post_neuron)
    {
      @post_neuron->stimulate(at + @delay, @weight, this);
    }
  }

  # 
  # Adding a pre synapse. Target must be a Neuron.
  #
  # O(1)
  #
  def connect(target)
    raise "target must be Neuron" unless target.kind_of?(Neuron)
    raise "Synapse already connected" if self.post_neuron || self.next_pre_synapse

    self.next_pre_synapse = target.first_pre_synapse
    target.first_pre_synapse = self
    self.post_neuron = target
  end

  #
  # O(n)
  #
  def disconnect(target)
    raise "target must be Neuron" unless target.kind_of?(Neuron)
    raise "Synapse not connected to this Neuron" if self.post_neuron != target

    #
    # Find the synapse in the linked list that precedes +self+.
    #
    prev = nil
    curr = target.first_pre_synapse

    while true
      break if curr == self
      break unless curr
      prev = curr
      curr = curr.next_pre_synapse
    end

    raise "Synapse not in pre synapse list" if curr != self

    #
    # Remove ourself (+self+) from linked list.
    #
    if prev
      prev.next_pre_synapse = self.next_pre_synapse
    else
      #
      # we are the last synapse in the pre synapse list.
      #
      raise "assert" unless target.first_pre_synapse == self
      target.first_pre_synapse = nil
    end

    self.post_neuron = nil
    self.next_pre_synapse = nil
  end

  def each_connection
    yield self.post_neuron
  end
end
