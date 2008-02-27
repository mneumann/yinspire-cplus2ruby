class Synapse < NeuralEntity

  include SynapseStructureMixin

  # 
  # The fire weight of a Synapse.
  #
  property :weight, 'real', :marshal => true

  # 
  # The propagation delay of a Synapse.
  #
  property :delay, 'simtime', :marshal => true

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
end
