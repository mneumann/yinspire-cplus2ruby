class Synapse_Hebb < Synapse

  property :last_post_neuron_fire_time,    'simtime', :init => -Infinity, :marshal => true
  property :current_post_neuron_fire_time, 'simtime', :init => -Infinity, :marshal => true
  property :learning_rate,                 'real',    :init => 0.01,      :marshal => true
  property :decrease_rate,                 'real',    :init => 0.00005,   :marshal => true
  property :pre_synaptic_spikes,           'Array<simtime>'

  #
  # Default arguments for learning_window method
  #
  DEFAULT_LW_ARGS = "1, 1, 10, 8" 

  method :stimulate, {:at => 'simtime'},{:weight => 'real'},{:source => NeuralEntity}, %{
    if (source != @post_neuron)
    {
      @pre_synaptic_spikes.push(at);

      if (@last_post_neuron_fire_time > 0.0)
      {
        real delta_time = @last_post_neuron_fire_time - at;  
        real delta_weight = @learning_rate * learning_window(delta_time, #{DEFAULT_LW_ARGS});

        if (@pre_synaptic_spikes.size() > 1)
        {
          delta_time = @pre_synaptic_spikes[@pre_synaptic_spikes.size() - 2] - at;
        }

        delta_weight += @decrease_rate * delta_time;
        @weight += (1.0 - real_fabs(@weight)) * delta_weight;
      }

      @post_neuron->stimulate(at+@delay, @weight, this);
    }
    else
    {
      @last_post_neuron_fire_time = @current_post_neuron_fire_time; 
      @current_post_neuron_fire_time = at;

      real delta_weight = 0.0;

      for (int i=0; i < @pre_synaptic_spikes.size(); i++)
      {
        delta_weight += @learning_rate * learning_window(at - @pre_synaptic_spikes[i], #{DEFAULT_LW_ARGS});
      }

      @weight += (1.0 - real_fabs(@weight)) * delta_weight;
      @pre_synaptic_spikes.clear();
    }
  }

  static_method :learning_window, 
                {:delta_x => 'real'},
                {:pos_ramp => 'real'},{:neg_ramp => 'real'},
                {:pos_decay => 'real'},{:neg_decay => 'real'},
                {:returns => 'real'}, %{
    if (delta_x >= 0)
    {
      return (pos_ramp * delta_x * real_exp(-delta_x/pos_decay));
    }
    else
    {
      return (neg_ramp * delta_x * real_exp(delta_x/neg_decay));
    }
  }

end
