require 'Yinspire/Neuron_Base'

#
# Common base class for input and output neurons. They behave almost
# the same except for what action is performed once a neuron fires.
#
class Neuron_InputOutput < Neuron_Base

  virtual :fire
  method :fire, {:at => 'simtime'},{:weight => 'real'}, nil 

  # 
  # Process each stimuli separately, i.e. it does NOT 
  # add stimuli with the same timestamp together.
  #
  method :process, {:at => 'simtime'}, %{
    while (!@stimuli_pq.empty() && @stimuli_pq.top().at <= at)
    {
      fire(@stimuli_pq.top().at, @stimuli_pq.top().weight);
      @stimuli_pq.pop();
    }

    /*
     * NOTE: we don't have to remove the entity from the schedule if the
     * pq is empty.
     */
    if (!@stimuli_pq.empty())
    {
      schedule(@stimuli_pq.top().at);
    }
  }

end
