#include "neuron_srm_01.h"
#include "simulator.h"
#include <math.h>

// formerly known as KernelbasedLIF


Neuron_SRM_01::Neuron_SRM_01()
{
  this->tau_m = 0.0;
  this->tau_ref = 0.0;
  this->ref_weight = 0.0;
  this->mem_pot = 0.0;
  this->const_threshold = 0.0;
}

void
Neuron_SRM_01::dump(jsonHash *into)
{
}

void
Neuron_SRM_01::load(jsonHash *data)
{
  super::load(data);

  this->tau_m = data->get_number("tau_m", 0.0);
  this->tau_ref = data->get_number("tau_ref", 0.0);
  this->ref_weight = data->get_number("ref_weight", 0.0);
  this->mem_pot = data->get_number("mem_pot", 0.0);
  this->const_threshold = data->get_number("const_threshold", 0.0);
}

void
Neuron_SRM_01::stimulate(simtime at, real weight, NeuralEntity *source)
{
  if (at >= this->last_fire_time + this->abs_refr_duration)
  {
    ++this->simulator->stat_event_counter;
    super::stimulate(at, weight, source);
  }
}

void
Neuron_SRM_01::process(simtime at)
{
  real weight = stimuli_sum(at);
  const real delta = at - this->last_fire_time - this->abs_refr_duration;

  if (delta < 0.0) return;

  /*
   * Calculate new membrane potential
   */

  this->mem_pot = weight + this->mem_pot * real_exp( -(at - this->last_spike_time)/this->tau_m );
  this->last_spike_time = at;

  /*
   * Calculate dynamic threshold
   */
  const real dynamic_threshold = this->ref_weight * real_exp(-delta/this->tau_ref);

  if (this->mem_pot >= this->const_threshold + dynamic_threshold)
  {
    fire(at);
  }
}

void
Neuron_SRM_01::fire(simtime at)
{
  this->simulator->stat_record_fire_event(at, this);
  this->mem_pot = 0.0;
  this->last_fire_time = at;
  fire_synapses(at);
}
