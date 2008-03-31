require 'Yinspire/Models/Neuron_Base'

#
# Formerly known as SpecialEKernel
#
class Neuron_SRM02 < Neuron_Base

  property :tau_m,           'real', :marshal => true
  property :tau_ref,         'real', :marshal => true
  property :reset,           'real', :marshal => true
  property :u_reset,         'real', :marshal => true
  property :mem_pot,         'real', :marshal => true
  property :const_threshold, 'real', :marshal => true

  method :stimulate, {:at => 'simtime'},{:weight => 'real'},{:source => NeuralEntity}, %{
    @simulator->event_counter++;
    super::stimulate(at, weight, source);
  }

  method :process, {:at => 'simtime'}, %{
    real weight = stimuli_sum(at);

    /*
     * Calculate new membrane potential
     */

    @mem_pot = weight + @mem_pot * real_exp( -(at - @last_spike_time)/@tau_m );
    @last_spike_time = at;

    if (at < @last_fire_time + @abs_refr_duration)
      return;

    /*
     * Calculate dynamic reset
     */
    const real delta = at - @last_fire_time - @abs_refr_duration;
    const real dynamic_reset = @reset * real_exp(-delta/@tau_ref);

    if (@mem_pot >= @const_threshold + dynamic_reset)
    {
      /* Fire */

      if (@abs_refr_duration > 0.0)
      {
        schedule(at + @abs_refr_duration);
      }

      if (isinf(@mem_pot))
      {
        @mem_pot = 0.0;
        @reset = @u_reset;
      }
      else
      {
        @reset = dynamic_reset + @u_reset;
      }
      @last_fire_time = at;

      @simulator->record_fire(at, 0.0, this);
      stimulate_synapses(at, 0.0);
    }
  }

end
