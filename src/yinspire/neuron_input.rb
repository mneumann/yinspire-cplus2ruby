#
# Input Neuron. Simply forwards stimuli.
#
class Neuron_Input < Neuron

  # 
  # Forwards each stimuli separately, i.e. it does NOT 
  # add stimuli with the same timestamp together.
  #
  method :process, {:at => 'simtime'}, %{
    printf("Neuron_Input#process(%f)\\n", at);
    while (!@stimuli_pq.empty() && @stimuli_pq.top().at <= at)
    {
      fire_synapses(@stimuli_pq.top().at, @stimuli_pq.top().weight);
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
