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
  property :last_spike_time, 'simtime', default: '%s = -INFINITY'
  
  #
  # Last fire time
  #
  property :last_fire_time, 'simtime', default: '%s = -INFINITY'

  #
  # Whether this neuron is a hebb neuron or not.  A hebb neuron also
  # stimulates it's pre synapses upon firing.
  #
  property :hebb, 'bool', default: '%s = false'


  def load(data)
    super
    self.abs_refr_duration = data['abs_refr_duration'] || 0.0
    self.last_spike_time = data['last_spike_time'] || -INFINITY
    self.last_fire_time = data['last_fire_time'] || -INFINITY
    self.hebb = data['hebb'] || false
  end

  def dump(into)
    super
    into['abs_refr_duration'] = self.abs_refr_duration
    into['last_spike_time'] = self.last_spike_time
    into['last_fire_time'] = self.last_fire_time
    into['hebb'] = self.hebb
  end

  method :each_connection, {iter: 'void (*%s)(NeuralEntity*,NeuralEntity*)'}, %{
    for (Synapse *syn = @first_post_synapse; syn != NULL;
        syn = syn->next_post_synapse)
    {
      iter(this, syn);
    }
  }, virtual: true, internal: true

  # 
  # Adding a post synapse. Target must be a Synapse.
  #
  # O(1)
  #
  method :connect, {target: NeuralEntity}, %{
    Synapse *syn = dynamic_cast<Synapse*>(target);

    if (syn->pre_neuron != NULL || syn->next_post_synapse != NULL)
      throw "Synapse already connected";

    syn->next_post_synapse = @first_post_synapse;
    @first_post_synapse = syn;
    syn->pre_neuron = this;
  }, virtual: true

  #
  # O(n)
  #
  method :disconnect, {target: NeuralEntity}, %{
    Synapse *syn = dynamic_cast<Synapse*>(target);

    if (syn->pre_neuron != this)
      throw "Synapse not connected to this Neuron";

    /*
     * Find the synapse in the linked list that precedes +syn+.
     */
    Synapse *prev = NULL;
    Synapse *curr = @first_post_synapse;

    while (true)
    {
      if (curr == NULL) break;
      if (curr == syn) break; 
      prev = curr;
      curr = curr->next_post_synapse;
    }

    if (curr != syn)
      throw "Synapse not in post synapse list";

    /*
     * Remove syn from linked list
     */
    if (prev == NULL)
    {
      /*
       * syn is the last synapse in the post synapse list.
       */
      assert(@first_post_synapse == syn);
      @first_post_synapse = NULL; 
    }
    else
    {
      prev->next_post_synapse = syn->next_post_synapse;
    }

    syn->pre_neuron = NULL;
    syn->next_post_synapse = NULL;
  }, virtual: true

  #
  # NOTE: The stimulation weight is 0.0 below as the synapse will add
  # it's weight to the preceding neurons.
  #
  method :fire_synapses, {at: 'simtime'}, %{
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
