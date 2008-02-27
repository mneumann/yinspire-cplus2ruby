#
# The base class of all neurons.
#
class Neuron < NeuralEntity

  include NeuronStructureMixin
  
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

  protected

  #
  # NOTE: The stimulation weight is 0.0 (see below) as the synapse will
  # add it's weight to the preceding neurons.
  #
  method :fire_synapses, {:at => 'simtime'}, {:weight => 'real'}, %{
    if (@hebb) 
    {
      for (Synapse *syn = @first_pre_synapse; syn != NULL;
          syn = syn->next_pre_synapse)
      {
        syn->stimulate(at, weight, this);
      }
    }
    for (Synapse *syn = @first_post_synapse; syn != NULL;
        syn = syn->next_post_synapse)
    {
      syn->stimulate(at, weight, this);
    }
  }

end
