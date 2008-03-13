require 'yinspire/stimuli'

class Neuron_Base < Neuron

  include Stimuli
  
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

  method :stimulate_synapses, {:at => 'simtime'}, {:weight => 'real'}, %{
    if (@hebb) stimulate_pre_synapses(at, weight);
    stimulate_post_synapses(at, weight);
  }

  method :stimulate, {:at => 'simtime'},{:weight => 'real'},{:source => NeuralEntity}, %{
    stimuli_add(at, weight);
  }

end
