require 'cplus2ruby'

Cplus2Ruby.add_type_alias 'real'  => 'float'
Cplus2Ruby.add_type_alias 'simtime' => 'float'
Cplus2Ruby.add_type_alias 'uint'  => 'unsigned int'
Cplus2Ruby.settings :default_body_when_nil => 'THROW("abstract method");'

Infinity = 1.0/0.0

Cplus2Ruby << %{
  #include <assert.h>
  #include <math.h>
  #include "Algorithms/Array.h"
  #include "Algorithms/BinaryHeap.h"
  #include "Algorithms/IndexedBinaryHeap.h"
  #include "Allocators/RubyMemoryAllocator.h"

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
  LIB_DIR = File.expand_path(File.dirname(__FILE__))

  def self.commit(file, force_compilation=false)
    cflags = "-DNDEBUG -O3 -fomit-frame-pointer -Winline -Wall -I#{LIB_DIR} -I${PWD}"
    ldflags = ""
    Cplus2Ruby.commit(file, force_compilation, cflags, ldflags)

    Cplus2Ruby.model.entities.each do |klass|
      next unless klass.ancestors.include?(NeuralEntity) 
      NeuralEntity.entity_type_map[klass.name] = klass 
      NeuralEntity.entity_type_map_reverse[klass] = klass.name
      lc = NeuralEntity.entity_ann_load_cache[klass] = Hash.new
      dc = NeuralEntity.entity_ann_dump_cache[klass] = Array.new

      klass.recursive_annotations.each {|name, h|
        next unless h[:marshal]
        lc[name.to_sym] = lc[name.to_s] = :"#{name}="
        dc << name.to_sym 
      }
    end
  end

end # module Yinspire
