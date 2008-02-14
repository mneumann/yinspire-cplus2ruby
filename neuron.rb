#
# The base class of all neurons.
#
class Neuron < NeuralEntity

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
  # Duration of the absolute refraction period.
  #
  property :abs_refr_duration, 'simtime', :marshal => true

  #
  # Last spike time
  #
  property :last_spike_time, 'simtime', :init => -Infinity, :marshal => true
  
  #
  # Last fire time
  #
  property :last_fire_time, 'simtime', :init => -Infinity, :marshal => true

  #
  # Whether this neuron is a hebb neuron or not.  A hebb neuron also
  # stimulates it's pre synapses upon firing.
  #
  property :hebb, 'bool', :init => false, :marshal => true

  #
  # O(1)
  #
  def connect(target)
    add_post_synapse(target)
  end

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

  protected

  #
  # NOTE: The stimulation weight is 0.0 below as the synapse will add
  # it's weight to the preceding neurons.
  #
  method :fire_synapses, {:at => 'simtime'}, %{
    if (@hebb) 
    {
      for (Synapse *syn = @first_pre_synapse; syn != NULL;
          syn = syn->next_pre_synapse)
      {
        syn->stimulate(at, 0.0, this);
      }
    }
    for (Synapse *syn = @first_post_synapse; syn != NULL;
        syn = syn->next_post_synapse)
    {
      syn->stimulate(at, 0.0, this);
    }
  }

end
