#include <math.h>
#include <ostream>
#include <boost/random.hpp>

class Distribution
{
  protected:

    boost::mt19937 eng;
    boost::uniform_real<> dis;
    boost::variate_generator<boost::mt19937&, boost::uniform_real<> > gen;

  public:

    Distribution() : gen(eng, dis) {}

    virtual double next() = 0;
    virtual void output_name(std::ostream &o) { o << "undefined"; } 

    void 
      seed(unsigned seed)
      {
        eng.seed(seed);
      }
};

struct RandomDistribution : public Distribution
{
  virtual double next() { return gen(); }
  virtual void output_name(std::ostream &o) { o << "Random"; } 
};

struct ExponentialDistribution : public Distribution
{
  double a;
  ExponentialDistribution(double _a) : a(_a) {}

  virtual double next() { return a * -log(gen()); }

  virtual void output_name(std::ostream &o) { o << "Exponential(" << @a << ")"; } 
};

struct UniformDistribution : public Distribution
{
  double a, b;

  UniformDistribution(double _a, double _b) : a(_a), b(_b) {} 

  virtual double next() { return (a + (b-a)*gen()); }
  virtual void output_name(std::ostream &o) { o << "Uniform(" << @a << "," << @b << ")"; } 
};

struct TriangularDistribution : public Distribution
{
  double a, b;

  TriangularDistribution(double _a, double _b) : a(_a), b(_b) {} 

  virtual double next() { return (a + (b-a)*sqrt(gen())); }
  virtual void output_name(std::ostream &o) { o << "Triangular(" << @a << "," << @b << ")"; } 
};

struct NegativeTriangularDistribution : public Distribution
{
  double a, b;

  NegativeTriangularDistribution(double _a, double _b) : a(_a), b(_b) {} 

  virtual double next() { return (a + (b-a)*(1.0 - sqrt(1.0 - gen()))); }
  virtual void output_name(std::ostream &o) { o << "NegativeTriangular(" << @a << "," << @b << ")"; } 
};
