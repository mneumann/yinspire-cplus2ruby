require 'Yinspire/Models/Neuron_InputOutput'

#
# Output Neuron. Used to record fire events.
#
class Neuron_Output < Neuron_InputOutput

  method :fire, {:at => 'simtime'},{:weight => 'real'}, %{
    printf("Neuron %s fired at %f with %f\\n", RSTRING(@id)->ptr, at, weight);
  }

end
