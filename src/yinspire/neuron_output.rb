#
# Output Neuron. Used to record fire events.
#

require 'yinspire/neuron_input_output'

class Neuron_Output < Neuron_Input_Output

  method :fire, {:at => 'simtime'},{:weight => 'real'}, %{
    printf("Neuron %s fired at %f with %f\\n", RSTRING(@id)->ptr, at, weight);
  }

end
