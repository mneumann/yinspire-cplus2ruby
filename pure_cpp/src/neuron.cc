#include "neuron.h"
#include "synapse.h"
#include <math.h>
#include <assert.h>
#include "simulator.h" // ?

Neuron::Neuron()
{
  this->first_pre_synapse = NULL;
  this->first_post_synapse = NULL;
  this->abs_refr_duration = 0.0;
  this->last_spike_time = -INFINITY; 
  this->last_fire_time = -INFINITY; 
  this->hebb = false;
}

void
Neuron::dump(jsonHash *into)
{
}

void
Neuron::load(jsonHash *data)
{
  super::load(data);

  this->abs_refr_duration = data->get_number("abs_refr_duration", 0.0);
  this->last_spike_time = data->get_number("last_spike_time", -INFINITY);
  this->last_fire_time = data->get_number("last_fire_time", -INFINITY);
  this->hebb = data->get_bool("hebb", false);
}
 
void
Neuron::each_connection(void (*yield)(NeuralEntity *self, NeuralEntity *conn))
{
  for (Synapse *syn = this->first_post_synapse; syn != NULL;
      syn = syn->next_post_synapse)
  {
    yield(this, syn);
  }
}

void
Neuron::stimulate(simtime at, real weight, NeuralEntity *source)
{
  stimuli_add(at, weight);
}

/*
 * Adding a post synapse. Target must be a Synapse.
 *
 * O(1)
 */
void
Neuron::connect(NeuralEntity *target)
{
  Synapse *syn = dynamic_cast<Synapse*>(target);

  if (syn->pre_neuron != NULL || syn->next_post_synapse != NULL)
    throw "Synapse already connected";

  syn->next_post_synapse = this->first_post_synapse;
  this->first_post_synapse = syn;
  syn->pre_neuron = this;
}

/*
 * O(n)
 */
void
Neuron::disconnect(NeuralEntity *target)
{
  Synapse *syn = dynamic_cast<Synapse*>(target);

  if (syn->pre_neuron != this)
    throw "Synapse not connected to this Neuron";

  /*
   * Find the synapse in the linked list that precedes +syn+.
   */
  Synapse *prev = NULL;
  Synapse *curr = this->first_post_synapse;

  while (true)
  {
    if (curr == NULL) break;
    if (curr == syn) break; 
    prev = curr;
    curr = curr->next_post_synapse;
  }

  if (curr != syn)
    throw "Synapse not in post synapse list";

  /*
   * Remove syn from linked list
   */
  if (prev == NULL)
  {
    /*
     * syn is the last synapse in the post synapse list.
     */
    assert(this->first_post_synapse == syn);
    this->first_post_synapse = NULL; 
  }
  else
  {
    prev->next_post_synapse = syn->next_post_synapse;
  }

  syn->pre_neuron = NULL;
  syn->next_post_synapse = NULL;
}

/*
 * NOTE: The stimulation weight is 0.0 below
 * as the synapse will add it's weight to the
 * preceding neurons.
 */
void
Neuron::fire_synapses(simtime at)
{
  if (this->hebb) 
  {
    for (Synapse *syn = this->first_pre_synapse; syn != NULL;
        syn = syn->next_pre_synapse)
    {
      syn->stimulate(at, 0.0, this);
    }
  }
  for (Synapse *syn = this->first_post_synapse; syn != NULL;
      syn = syn->next_post_synapse)
  {
    syn->stimulate(at, 0.0, this);
  }
}
