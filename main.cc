#include "yinspire.h"
#include <iostream>

int main(int argc, char** argv)
{
  Simulator sim;
  stime stop_at;
  real tolerance = -INFINITY;
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

  std::cout << "net: " << net << std::endl;
  std::cout << "stop_at: " << stop_at << std::endl;
  std::cout << "tolerance: " << tolerance << std::endl;

  sim.stimuli_tolerance = tolerance;
  sim.load(net);
  sim.run(stop_at);

  std::cout << sim.event_counter << std::endl;
  std::cout << sim.fire_counter << std::endl;
  return 0;
}
