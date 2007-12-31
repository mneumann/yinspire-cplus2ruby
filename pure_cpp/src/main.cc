#include "simulator.h"
#include <iostream>

#include "synapse.h"
#include "neuron_srm_01.h"

#define DEF_TYPE(t) NeuralEntity *make_##t() { return new t(); }
#define REG_TYPE(t, s) (s)->entity_register_type(#t, make_##t)

DEF_TYPE(Synapse)
DEF_TYPE(Neuron_SRM_01)

int main(int argc, char** argv)
{
  Simulator sim;
  simtime stop_at;
  real tolerance = 0.0;
  char *net;

  if (argc == 3 || argc == 4)
  {
    net = argv[1];
    stop_at = atof(argv[2]);

    if (argc == 4)
    {
      tolerance = atof(argv[3]);
    }
  }
  else
  {
    std::cout << "USAGE: yinspire net stop_at [tolerance]" << std::endl;
    return 1;
  }

  REG_TYPE(Synapse, &sim);
  REG_TYPE(Neuron_SRM_01, &sim);

  std::cout << "net: " << net << std::endl;
  std::cout << "stop_at: " << stop_at << std::endl;
  std::cout << "tolerance: " << tolerance << std::endl;

  sim.load(net);
  sim.run(stop_at);

  std::cout << sim.stat_event_counter << std::endl;
  std::cout << sim.stat_fire_counter << std::endl;
  return 0;
}
