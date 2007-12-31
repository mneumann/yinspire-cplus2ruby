#ifndef __YINSPIRE__NEURON__
#define __YINSPIRE__NEURON__

#include "neural_entity.h"

class Synapse; // forward declaration

/*
 * The base class of all neurons.
 */
class Neuron : public NeuralEntity
{
    friend class Synapse;
    typedef NeuralEntity super; 

  protected:

    /*
     * Pointers to the first pre/post synapse
     */
    Synapse *first_pre_synapse;
    Synapse *first_post_synapse;

    /*
     * Duration of the absolute refraction period.
     */
    simtime abs_refr_duration; 

    /*
     * Last spike time
     */
    simtime last_spike_time;

    /*
     * Last fire time
     */
    simtime last_fire_time;

    /*
     * Whether this neuron is a hebb neuron or not.
     * A hebb neuron also stimulates it's pre synapses
     * upon firing.
     */
    bool hebb;

  protected:

    /*
     * Constructor
     */
    Neuron();

  public:

    virtual void dump(jsonHash *into);
    virtual void load(jsonHash *data);

    virtual void stimulate(simtime at, real weight, NeuralEntity *source);
    virtual void connect(NeuralEntity *target);
    virtual void disconnect(NeuralEntity *target);
    virtual void each_connection(
      void (*yield)(NeuralEntity *self, NeuralEntity *conn));

  protected:

    void fire_synapses(simtime at);

};

#endif
