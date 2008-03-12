#include "synapse.h"
#include "neuron.h"
#include <assert.h>

Synapse::Synapse()
{
  this->weight = 0.0;
  this->delay = 0.0;
  this->pre_neuron = NULL;
  this->post_neuron = NULL;
  this->next_pre_synapse = NULL;
  this->next_post_synapse = NULL;
}

void
Synapse::dump(jsonHash *into)
{
}

void
Synapse::load(jsonHash *data)
{
  super::load(data);

  this->weight = data->get_number("weight", 0.0);
  this->delay = data->get_number("delay", 0.0);
}


void
Synapse::stimulate(simtime at, real weight, NeuralEntity *source) 
{
  /* 
   * Only propagate the stimulation if it doesn't originate from the
   * post Neuron.  Stimuli from a post Neuron are handled by a specific
   * Synapse class (e.g. Hebb).
   *
   * We ignore the weight parameter that is passed by the Neuron.
   */ 
  if (source != this->post_neuron)
  {
    this->post_neuron->stimulate(at + this->delay, this->weight, this);
  }
}


/*
 * Adding a pre synapse. Target must be a Neuron.
 *
 * O(1)
 */
void
Synapse::connect(NeuralEntity *target)
{
  Neuron *neuron = dynamic_cast<Neuron*>(target);

  if (this->post_neuron != NULL || this->next_pre_synapse != NULL)
    throw "Synapse already connected";

  this->next_pre_synapse = neuron->first_pre_synapse;
  neuron->first_pre_synapse = this;
  this->post_neuron = neuron;
}

/*
 * O(n)
 */
void
Synapse::disconnect(NeuralEntity *target)
{
  Neuron *neuron = dynamic_cast<Neuron*>(target);

  if (this->post_neuron != neuron)
    throw "Synapse not connected to this Neuron";

  /*
   * Find the synapse in the linked list that precedes +this+.
   */
  Synapse *prev = NULL;
  Synapse *curr = neuron->first_pre_synapse;

  while (true)
  {
    if (curr == NULL) break;
    if (curr == this) break; 
    prev = curr;
    curr = curr->next_pre_synapse;
  }

  if (curr != this)
    throw "Synapse not in pre synapse list";

  /*
   * Remove ourself (this) from linked list
   */
  if (prev == NULL)
  {
    /*
     * we are the last synapse in the pre synapse list.
     */
    assert(neuron->first_pre_synapse == this);
    neuron->first_pre_synapse = NULL; 
  }
  else
  {
    prev->next_pre_synapse = this->next_pre_synapse;
  }

  this->post_neuron = NULL;
  this->next_pre_synapse = NULL;
}

void
Synapse::each_connection(void (*yield)(NeuralEntity *self, NeuralEntity *conn))
{
  yield(this, this->post_neuron);
}
