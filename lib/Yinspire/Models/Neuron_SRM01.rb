require 'Yinspire/Models/Neuron_Base'

#
# Formerly known as KernelbasedLIF
#
class Neuron_SRM01 < Neuron_Base

  property :tau_m,           'real', :marshal => true
  property :tau_ref,         'real', :marshal => true
  property :ref_weight,      'real', :marshal => true
  property :mem_pot,         'real', :marshal => true
  property :const_threshold, 'real', :marshal => true

  method :stimulate, {:at => 'simtime'},{:weight => 'real'},{:source => NeuralEntity}, %{
    if (at >= @last_fire_time + @abs_refr_duration)
    {
      @simulator->event_counter++;
      super::stimulate(at, weight, source);
    }
  }

  method :process, {:at => 'simtime'}, %{
    real weight = stimuli_sum(at);
    const real delta = at - @last_fire_time - @abs_refr_duration;

    if (delta < 0.0) return;

    /*
     * Calculate new membrane potential
     */

    @mem_pot = weight + @mem_pot * real_exp( -(at - @last_spike_time)/@tau_m );
    @last_spike_time = at;

    /*
     * Calculate dynamic threshold
     */
    const real dynamic_threshold = @ref_weight * real_exp(-delta/@tau_ref);

    if (@mem_pot >= @const_threshold + dynamic_threshold)
    {
      /* Fire */
      @mem_pot = 0.0;
      @last_fire_time = at;
      @simulator->record_fire(at, 0.0, this);
      stimulate_synapses(at, 0.0);
    }
  }

end
