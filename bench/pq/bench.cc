#include "classic_hold.h"
#include <time.h>
#include <stdlib.h>
#include <iostream>
#include <string>
#include "bench_binaryheap.h"

template<class ET, class PQ, class ACC>
void measure_binary_heap(Distribution *dis, 
    int queue_size,
    int warmup_cycles,
    int empty_hold_cycles,
    int hold_cycles)
{
  PQ pq;
  ClassicHold<PQ, ACC> ch(&pq, dis);

  std::cout << "Method:           " << "Classic Hold" << std::endl;
  std::cout << "Algorithm:        " << ACC::algorithm_name() << std::endl;
  std::cout << "ElementSize:      " << sizeof(ET) << std::endl;
  std::cout << "ElementType:      " << ET::element_type() << std::endl;
  std::cout << "Distribution:     "; dis->output_name(std::cout); std::cout << std::endl;
  std::cout << "QueueSize:        " << queue_size << std::endl;
  std::cout << "WarmupCycles:     " << warmup_cycles << std::endl; 
  std::cout << "EmptyHoldCycles:  " << empty_hold_cycles << std::endl; 
  std::cout << "HoldCycles:       " << hold_cycles << std::endl; 
  std::cout << "CompilerOptFlags: " << _COMPILER_OPTFLAGS_ << std::endl;
  std::cout << "CompilerName:     " << _COMPILER_NAME_ << std::endl;
  std::cout << "CompileDate:      " << _COMPILE_DATE_ << std::endl;
  std::cout << "Uname:            " << _UNAME_ << std::endl;
  std::cout << "CpuFreq:          " << _CPUFREQ_ << std::endl;

  double hold_time = ch.measure(queue_size, warmup_cycles, empty_hold_cycles, hold_cycles);

  std::cout << "HoldTime:         " << hold_time << std::endl;
  std::cout << std::endl;
}

#define MEASURE_BH(et) measure_binary_heap< \
  BenchBinaryHeap::et, \
  BenchBinaryHeap::T<BenchBinaryHeap::et>::PQ, \
  BenchBinaryHeap::T<BenchBinaryHeap::et>::ACC>( \
      dis, queue_size, warmup_cycles, \
      empty_hold_cycles, hold_cycles);

#define ARG_GET(varname, meth) \
  if (argp < argc) { \
    varname = meth(argv[argp++]); \
  } else { \
    throw #varname " required"; \
  }

void run(int argc, char **argv)
{
  Distribution *dis;
  int queue_size;
  int warmup_cycles;
  int empty_hold_cycles;
  int hold_cycles;
  std::string distribution;
  std::string algorithm;
  std::string element_type;

  int argp = 1; 

  ARG_GET(queue_size, atoi);
  ARG_GET(warmup_cycles, atoi);
  ARG_GET(empty_hold_cycles, atoi);
  ARG_GET(hold_cycles, atoi);

  ARG_GET(distribution, std::string);

  if (distribution == "Random")
  {
    dis = new RandomDistribution();
  }
  else if (distribution == "Exponential")
  {
    double exponential_a;
    ARG_GET(exponential_a, atof);
    dis = new ExponentialDistribution(exponential_a);
  }
  else if (distribution == "Uniform")
  {
    double uniform_a, uniform_b;
    ARG_GET(uniform_a, atof);
    ARG_GET(uniform_b, atof);
    dis = new UniformDistribution(uniform_a, uniform_b);
  }
  else if (distribution == "Triangular")
  {
    double triangular_a, triangular_b;
    ARG_GET(triangular_a, atof);
    ARG_GET(triangular_b, atof);
    dis = new TriangularDistribution(triangular_a, triangular_b);
  }
  else if (distribution == "NegativeTriangular")
  {
    double negtriangular_a, negtriangular_b;
    ARG_GET(negtriangular_a, atof);
    ARG_GET(negtriangular_b, atof);
    dis = new NegativeTriangularDistribution(negtriangular_a, negtriangular_b);
  }
  else
  {
    throw "invalid distribution";
  }

  ARG_GET(algorithm, std::string);

  if (algorithm == "BinaryHeap")
  {
    ARG_GET(element_type, std::string);

    if (element_type == "FLOAT")
    {
      MEASURE_BH(ET_FLOAT);
    }
    else if (element_type == "DOUBLE")
    {
      MEASURE_BH(ET_DOUBLE);
    }
    else if (element_type == "STIMULI")
    {
      MEASURE_BH(ET_STIMULI);
    }
    else
    {
      throw "invalid element type";
    }
  }
  else
  {
    throw "invalid algorithm";
  }

  if (argp != argc)
  {
    throw "too much arguments";
  } 
}

int main(int argc, char** argv)
{
  try {
    run(argc, argv);
  } catch (const char *err)
  {
    std::cerr << "ERROR: " << err << std::endl; 
    return 1;
  }
  return 0;
}
