#
# Base class of all Synapses. Defines the structure that is special for
# a Synapse, i.e. that a Synapse has a pre and a post-Neuron.  Also
# each Synapse has a +weight+ and a +delay+.
#
class Synapse < NeuralEntity

  property :pre_neuron, Neuron
  property :post_neuron, Neuron
  
  #  
  # Those pointers are part of an internal linked-list that
  # starts at a Neuron and connects all pre-synapses of an Neuron
  # together. In the same way it connects all post-synapses of an
  # Neuron together.
  #
  property :next_pre_synapse, Synapse
  property :next_post_synapse, Synapse
  property :prev_pre_synapse, Synapse
  property :prev_post_synapse, Synapse

  # 
  # The fire weight of a Synapse.
  #
  property :weight, 'real', :marshal => true

  # 
  # The propagation delay of a Synapse.
  #
  property :delay, 'simtime', :marshal => true

  # 
  # Adding a pre synapse. Target must be a Neuron.
  #
  def connect(target)
    target.add_pre_synapse(self)
  end

  def disconnect(target)
    target.delete_pre_synapse(self)
  end

  def each_connection
    yield self.post_neuron
  end

  # 
  # Only propagate the stimulation if it doesn't originate from the
  # post Neuron.  Stimuli from a post Neuron are handled by a specific
  # Synapse class (e.g. Hebb).
  # 
  # NOTE: We ignore the weight parameter that is passed by the Neuron.
  #
  method :stimulate, {:at => 'simtime'},{:weight => 'real'},{:source => NeuralEntity}, %{
    if (source != @post_neuron)
    {
      @post_neuron->stimulate(at + @delay, @weight, this);
    }
  }

end
