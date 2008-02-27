module NeuronStructureMixin
  include Cplus2Ruby

  #
  # Pointers to the first/last pre/post Synapse.
  #
  # The pointers to the last Synapse are required
  # to append a new synapse at the end to keep
  # the order intact.
  #
  property :first_pre_synapse, Synapse
  property :first_post_synapse, Synapse
  property :last_pre_synapse, Synapse
  property :last_post_synapse, Synapse

  #
  # O(n)
  #
  # FIXME
  def disconnect(target)
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

  def each_connection
    syn = self.first_post_synapse
    while syn
      yield syn
      syn = syn.next_post_synapse
    end
  end

  #
  # O(1)
  #
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

  #
  # O(1)
  #
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

  alias connect add_post_synapse

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
  end

  protected

  #
  # Find the synapse in the linked list that precedes +syn+, starting
  # at synapse +first+ and using the +next_method+ chaing (e.g.
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

end

module SynapseStructureMixin
  include Cplus2Ruby

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
  property :prev_pre_synapse, Synapse
  property :prev_post_synapse, Synapse

  # 
  # Adding a pre synapse. Target must be a Neuron.
  #
  # O(1)
  #
  def connect(target)
    target.add_pre_synapse(self)
  end

  #
  # O(n)
  # FIXME
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
