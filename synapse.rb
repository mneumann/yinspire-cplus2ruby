class Synapse < NeuralEntity

  # 
  # The fire weight of a Synapse.
  #
  property :weight, 'real'

  # 
  # The propagation delay of a Synapse.
  #
  property :delay, 'simtime'

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
  method :stimulate, {at: 'simtime', weight: 'real', source: NeuralEntity}, %{
    if (source != @post_neuron)
    {
      @post_neuron->stimulate(at + @delay, @weight, this);
    }
  }, virtual: true

  # 
  # Adding a pre synapse. Target must be a Neuron.
  #
  # O(1)
  #
  method :connect, {target: NeuralEntity}, %{
    Neuron *neuron = dynamic_cast<Neuron*>(target);

    if (@post_neuron != NULL || @next_pre_synapse != NULL)
      throw "Synapse already connected";

    @next_pre_synapse = neuron->first_pre_synapse;
    neuron->first_pre_synapse = this;
    @post_neuron = neuron;
  }, virtual: true

  #
  # O(n)
  #
  method :disconnect, {target: NeuralEntity}, %{
    Neuron *neuron = dynamic_cast<Neuron*>(target);

    if (@post_neuron != neuron)
      throw "Synapse not connected to this Neuron";

    /*
     * Find the synapse in the linked list that precedes +this+.
     */
    Synapse *prev = NULL;
    Synapse *curr = neuron->first_pre_synapse;

    while (true)
    {
      if (curr == NULL) break;
      if (curr == this) break; 
      prev = curr;
      curr = curr->next_pre_synapse;
    }

    if (curr != this)
      throw "Synapse not in pre synapse list";

    /*
     * Remove ourself (this) from linked list
     */
    if (prev == NULL)
    {
      /*
       * we are the last synapse in the pre synapse list.
       */
      assert(neuron->first_pre_synapse == this);
      neuron->first_pre_synapse = NULL; 
    }
    else
    {
      prev->next_pre_synapse = @next_pre_synapse;
    }

    @post_neuron = NULL;
    @next_pre_synapse = NULL;
  }, virtual: true

  method :each_connection, {iter: 'void (*%s)(NeuralEntity*,NeuralEntity*)'}, %{
    iter(this, @post_neuron);
  }, virtual: true, internal: true

  def load(data)
    super
    self.weight = data['weight'] || 0.0
    self.delay = data['delay'] || 0.0
  end

  def dump(into)
    super
    into['weight'] = self.weight
    into['delay'] = self.delay
  end
end
