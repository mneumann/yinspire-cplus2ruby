require 'cplus2ruby'

Cplus2Ruby.add_type_alias 'real'  => 'float'
Cplus2Ruby.add_type_alias 'simtime' => 'float'
Cplus2Ruby.add_type_alias 'uint'  => 'unsigned int'
Cplus2Ruby.settings :default_body_when_nil => 'THROW("abstract method");'

Infinity = 1.0/0.0

Cplus2Ruby << %{
  #include <assert.h>
  #include <math.h>
  #include "algo/Array.h"
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

require 'Yinspire/Core/Simulator'
require 'Yinspire/Core/NeuralEntity'
require 'Yinspire/Core/Neuron'
require 'Yinspire/Core/Synapse'

module Yinspire
  ROOT = File.expand_path(File.join(File.dirname(__FILE__), ".."))

  def self.startup(file, force_compilation=false)
    cflags = "-DNDEBUG -O3 -fomit-frame-pointer -Winline -Wall -I#{ROOT}/src -I${PWD}"
    ldflags = ""
    Cplus2Ruby.startup(file, force_compilation, cflags, ldflags)
  end

end # module Yinspire
