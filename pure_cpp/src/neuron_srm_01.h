#ifndef __YINSPIRE__NEURON_SRM_01__
#define __YINSPIRE__NEURON_SRM_01__

#include "neuron.h"

class Neuron_SRM_01 : public Neuron 
{
    typedef Neuron super; 

  protected:

    real tau_m;
    real tau_ref;
    real ref_weight;
    real mem_pot;
    real const_threshold;

  public:

    Neuron_SRM_01();

  public:

    virtual void dump(jsonHash *into);
    virtual void load(jsonHash *data);

    virtual void stimulate(simtime at, real weight, NeuralEntity *source);
    virtual void process(simtime at);

  protected:

    void fire(simtime at);

};

#endif
