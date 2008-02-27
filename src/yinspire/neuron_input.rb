#
# Input Neuron. Simply forwards stimuli.
#

require 'yinspire/neuron_input_output'

class Neuron_Input < Neuron_Input_Output

  method :fire, {:at => 'simtime'},{:weight => 'real'}, %{
    fire_synapses(at, weight);
  }

end
