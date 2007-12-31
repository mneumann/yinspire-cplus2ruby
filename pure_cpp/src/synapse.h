#ifndef __YINSPIRE__SYNAPSE__
#define __YINSPIRE__SYNAPSE__

#include "neural_entity.h"

class Neuron; // forward declaration

class Synapse : public NeuralEntity
{
    friend class Neuron;
    typedef NeuralEntity super; 

  protected:

    /*
     * The fire weight of a Synapse.
     */
    real weight;

    /*
     * The propagation delay of a Synapse.
     */
    simtime delay;

    /*
     * The pre and post Neurons of the Synapse.
     */
    Neuron *pre_neuron;
    Neuron *post_neuron;

    /*
     * Those two pointers are part of an internal linked-list that
     * starts at a Neuron and connects all pre-synapses of an Neuron
     * together. In the same way it connects all post-synapses of an
     * Neuron together.
     */
    Synapse *next_pre_synapse;
    Synapse *next_post_synapse;

  public:

    /*
     * Constructor
     */
    Synapse();

  public:

    virtual void dump(jsonHash *into);
    virtual void load(jsonHash *data);

    virtual void stimulate(simtime at, real weight, NeuralEntity *source);
    virtual void connect(NeuralEntity *target);
    virtual void disconnect(NeuralEntity *target);
    virtual void each_connection(
      void (*yield)(NeuralEntity *self, NeuralEntity *conn));

};

#endif
