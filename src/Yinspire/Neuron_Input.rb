#
# Input Neuron. Simply forwards stimuli.
#

require 'Yinspire/Neuron_InputOutput'

class Neuron_Input < Neuron_InputOutput

  method :fire, {:at => 'simtime'},{:weight => 'real'}, %{
    stimulate_synapses(at, weight);
  }

end
