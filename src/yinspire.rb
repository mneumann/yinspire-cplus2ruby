require 'rubygems' # for facets
$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), "../../cplus2ruby/src"))
require 'cplus2ruby'

Cplus2Ruby.add_type_alias 'real'  => 'float'
Cplus2Ruby.add_type_alias 'simtime' => 'float'
Cplus2Ruby.add_type_alias 'uint'  => 'unsigned int'

Infinity = 1.0/0.0

Cplus2Ruby << %{
  #include <assert.h>
  #include <math.h>
  #include "algo/binary_heap.h"
  #include "algo/indexed_binary_heap.h"
  #include "alloc/ruby_memory_allocator.h"

  #define real_exp expf
  #define real_fabs fabsf

  #define THROW(str) rb_raise(rb_eRuntimeError, str)

  #define MIN(a,b) ((a) < (b) ? (a) : (b))
  #define MAX(a,b) ((a) > (b) ? (a) : (b))
  
  #define Infinity INFINITY
}

def assert(cond)
  raise "assertion failed" unless cond
end

class Simulator; cplus2ruby end
class NeuralEntity; cplus2ruby end

# Forward declarations
class Neuron < NeuralEntity; end
class Synapse < NeuralEntity; end

require 'yinspire/simulator'
require 'yinspire/neural_entity'
require 'yinspire/neuron'
require 'yinspire/synapse'

YINSPIRE_ROOT = File.expand_path(File.join(File.dirname(__FILE__), ".."))
YINSPIRE_WORK = File.join(YINSPIRE_ROOT, "work")

module Yinspire

  def self.startup(force_compilation=false)
    cflags = "-DNDEBUG -O3 -fomit-frame-pointer -Winline -Wall " + 
             "-I#{YINSPIRE_ROOT}/src -I${PWD}"
    ldflags = "-lstdc++"

    Cplus2Ruby.startup("#{YINSPIRE_WORK}/yinspire", force_compilation,
                       cflags, ldflags)
    #gen_load_dump()
  end

end # module Yinspire
