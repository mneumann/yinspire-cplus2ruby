#include "neuron_srm_01.h"
#include "simulator.h"
#include <math.h>

// formerly known as KernelbasedLIF


Neuron_SRM_01::Neuron_SRM_01()
{
  @tau_m = 0.0;
  @tau_ref = 0.0;
  @ref_weight = 0.0;
  @mem_pot = 0.0;
  @const_threshold = 0.0;
}

void
Neuron_SRM_01::dump(jsonHash *into)
{
}

void
Neuron_SRM_01::load(jsonHash *data)
{
  super::load(data);

  @tau_m = data->get_number("tau_m", 0.0);
  @tau_ref = data->get_number("tau_ref", 0.0);
  @ref_weight = data->get_number("ref_weight", 0.0);
  @mem_pot = data->get_number("mem_pot", 0.0);
  @const_threshold = data->get_number("const_threshold", 0.0);
}

void
Neuron_SRM_01::stimulate(simtime at, real weight, NeuralEntity *source)
{
  if (at >= @last_fire_time + @abs_refr_duration)
  {
    ++@simulator->stat_event_counter;
    super::stimulate(at, weight, source);
  }
}

void
Neuron_SRM_01::process(simtime at)
{
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
}

void
Neuron_SRM_01::fire(simtime at)
{
  @simulator->stat_record_fire_event(at, this);
  @mem_pot = 0.0;
  @last_fire_time = at;
  fire_synapses(at);
}
