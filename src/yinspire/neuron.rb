#
# Base class of all Neurons. Defines the structure that is special for a
# Neuron, i.e. that a Neuron has pre- and post-Synapses.
#
class Neuron < NeuralEntity

  property :first_pre_synapse, Synapse
  property :first_post_synapse, Synapse
  property :last_pre_synapse, Synapse
  property :last_post_synapse, Synapse

  def add_pre_synapse(syn)
    raise ArgumentError, "Synapse expected" unless syn.kind_of?(Synapse)
    raise "Synapse already connected" if syn.post_neuron || syn.next_pre_synapse

    if last = self.last_pre_synapse
      assert(last.next_pre_synapse == nil) # missing method: neuron instead of synapse
      last.next_pre_synapse = syn
      self.last_pre_synapse = syn # advance tail pointer
    else
      assert(self.first_pre_synapse == nil)
      self.first_pre_synapse = self.last_pre_synapse = syn
    end

    syn.post_neuron = self
  end

  def add_post_synapse(syn)
    raise ArgumentError, "Synapse expected" unless syn.kind_of?(Synapse)
    raise "Synapse already connected" if syn.pre_neuron || syn.next_post_synapse

    if last = self.last_post_synapse
      assert(last.next_post_synapse == nil)
      last.next_post_synapse = syn
      self.last_post_synapse = syn # advance tail pointer
    else
      assert(self.first_post_synapse == nil)
      self.first_post_synapse = self.last_post_synapse = syn
    end

    syn.pre_neuron = self
  end

  def delete_pre_synapse(syn)
    raise ArgumentError, "Synapse expected" unless syn.kind_of?(Synapse)
    raise "Synapse not connected to this Neuron" if syn.post_neuron != self

    prev = find_preceding_synapse(syn, first_pre_synapse(), :next_pre_syapse)

    #
    # Remove +target+ from linked list.
    #
    if prev
      prev.next_pre_synapse = target.next_post_synapse
      self.last_post_synapse = prev if self.last_post_synapse == target 
    else
      #
      # target is the only synapse in the post synapse list.
      #
      assert self.first_post_synapse == target
      assert self.last_post_synapse == target
      self.first_post_synapse = nil
      self.last_post_synapse = nil
    end

    target.pre_neuron = nil
    target.next_post_synapse = nil
  end

  def delete_post_synapse(syn)
    # FIXME
    raise "target must be Synapse" unless target.kind_of?(Synapse)
    raise "Synapse not connected to this Neuron" if target.pre_neuron != self 

    #
    # Find the synapse in the linked list that precedes +target+.
    #
    prev = nil
    curr = self.first_post_synapse

    while true
      break if curr == target
      break unless curr
      prev = curr
      curr = curr.next_post_synapse
    end

    raise "Synapse not in post synapse list" if curr != target

    #
    # Remove +target+ from linked list.
    #
    if prev
      prev.next_post_synapse = target.next_post_synapse
      self.last_post_synapse = prev if self.last_post_synapse == target 
    else
      #
      # target is the only synapse in the post synapse list.
      #
      assert self.first_post_synapse == target
      assert self.last_post_synapse == target
      self.first_post_synapse = nil
      self.last_post_synapse = nil
    end

    target.pre_neuron = nil
    target.next_post_synapse = nil
  end

  alias connect add_post_synapse
  alias disconnect delete_post_synapse
  
  #
  # Iterates over each outgoing connection (post synapses).
  # 
  def each_connection
    syn = self.first_post_synapse
    while syn
      yield syn
      syn = syn.next_post_synapse
    end
  end

  protected

  #
  # Find the synapse in the linked list that precedes +syn+, starting
  # at synapse +first+ and using the +next_method+ chain (e.g.
  # :next_pre_synapse or :next_post_synapse).
  #
  def find_preceding_synapse(syn, first, next_method)
    prev, curr = nil, first

    while true
      break if curr == syn
      break unless curr
      prev = curr
      curr = curr.send(next_method)
    end

    raise "Synapse not in pre synapse list" if curr != syn
    return prev
  end

  method :stimulate_pre_synapses, {:at => 'simtime'}, {:weight => 'real'}, %{
    for (Synapse *syn = @first_pre_synapse; syn != NULL; syn = syn->next_pre_synapse)
    {
      syn->stimulate(at, weight, this);
    }
  }

  method :stimulate_post_synapses, {:at => 'simtime'}, {:weight => 'real'}, %{
    for (Synapse *syn = @first_post_synapse; syn != NULL; syn = syn->next_post_synapse)
    {
      syn->stimulate(at, weight, this);
    }
  }

end
