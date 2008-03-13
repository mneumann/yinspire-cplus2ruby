require 'Yinspire/Models/Neuron_InputOutput'

#
# Input Neuron. Simply forwards stimuli.
#
class Neuron_Input < Neuron_InputOutput

  method :fire, {:at => 'simtime'},{:weight => 'real'}, %{
    stimulate_synapses(at, weight);
  }

end
