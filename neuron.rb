#
# The base class of all neurons.
#
class Neuron < NeuralEntity

  #
  # Pointers to the first pre/post Synapse.
  #
  property :first_pre_synapse, Synapse
  property :first_post_synapse, Synapse

  #
  # Duration of the absolute refraction period.
  #
  property :abs_refr_duration, 'simtime'

  #
  # Last spike time
  #
  property :last_spike_time, 'simtime', :init => -Infinity
  
  #
  # Last fire time
  #
  property :last_fire_time, 'simtime', :init => -Infinity

  #
  # Whether this neuron is a hebb neuron or not.  A hebb neuron also
  # stimulates it's pre synapses upon firing.
  #
  property :hebb, 'bool', :init => false


  def load(data)
    super
    self.abs_refr_duration = data['abs_refr_duration'] || 0.0
    self.last_spike_time = data['last_spike_time'] || -Infinity
    self.last_fire_time = data['last_fire_time'] || -Infinity
    self.hebb = data['hebb'] || false
  end

  def dump(into)
    super
    into['abs_refr_duration'] = self.abs_refr_duration
    into['last_spike_time'] = self.last_spike_time
    into['last_fire_time'] = self.last_fire_time
    into['hebb'] = self.hebb
  end

  # 
  # Adding a post synapse. Target must be a Synapse.
  #
  # O(1)
  #
  def connect(target)
    raise "target must be Synapse" unless target.kind_of?(Synapse)
    raise "Synapse already connected" if target.pre_neuron || target.next_post_synapse

    target.next_post_synapse = self.first_post_synapse
    self.first_post_synapse = target
    target.pre_neuron = self
  end

  #
  # O(n)
  #
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
    else
      #
      # target is the last synapse in the post synapse list.
      #
      raise "assert" unless self.first_post_synapse == target
      self.first_post_synapse = nil
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
