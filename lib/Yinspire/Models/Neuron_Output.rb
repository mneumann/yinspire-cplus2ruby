require 'Yinspire/Models/Neuron_InputOutput'

#
# Output Neuron. Used to record fire events.
#
class Neuron_Output < Neuron_InputOutput

  stub_method :fire, {:at => 'simtime'},{:weight => 'real'}

  #
  # Overwrite
  #
  def fire(at, weight) end
 
end
