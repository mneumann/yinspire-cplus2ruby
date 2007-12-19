#
# Formerly known as KernelbasedLIF
#
class Neuron_SRM_01 < Neuron

  property :tau_m, 'real'
  property :tau_ref, 'real'
  property :ref_weight, 'real'
  property :mem_pot, 'real'
  property :const_threshold, 'real'

  method :stimulate, {at: 'stime', weight: 'real', source: NeuralEntity}, %{
    if (at >= @last_fire_time + @abs_refr_duration)
    {
      super::stimulate(at, weight, source);
    }
  }, virtual: true

  method :process, {at: 'stime'}, %{
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
      fire(at);
    }
  }, virtual: true

  method :fire, {at: 'stime'}, %{
    //@simulator->record_fire_event(at, this);
    @mem_pot = 0.0;
    @last_fire_time = at;
    fire_synapses(at);
  }
end
