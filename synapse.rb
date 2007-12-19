class Synapse

  # 
  # The fire weight of a Synapse.
  #
  property :weight, 'real'

  # 
  # The propagation delay of a Synapse.
  #
  property :delay, 'stime'

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
  method :stimulate, {at: 'stime', weight: 'real', source: NeuralEntity}, %{
    if (source != @post_neuron)
    {
      @post_neuron->stimulate(at + @delay, @weight, this);
    }
  }, virtual: true

end
