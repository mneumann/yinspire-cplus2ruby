require 'tools/cplus2ruby'

Cplus2Ruby.add_type_alias 'real'  => 'float'
Cplus2Ruby.add_type_alias 'simtime' => 'float'
Cplus2Ruby.add_type_alias 'uint'  => 'unsigned int'

Infinity = 1.0/0.0

Cplus2Ruby << %{
  #include <assert.h>
  #include <math.h>
  #include "algo/binary_heap.h"
  #include "algo/indexed_binary_heap.h"
  #include "ruby_memory_allocator.h"

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

class Simulator; include Cplus2Ruby end
class NeuralEntity; include Cplus2Ruby end

# Forward declarations
class Neuron < NeuralEntity; end
class Synapse < NeuralEntity; end

require 'simulator'
require 'neural_entity'
require 'neuron'
require 'synapse'
require 'neuron_srm_01'

begin
  require './work/yinspire.so'
rescue LoadError
  Cplus2Ruby.compile_and_load('work/yinspire', 
    "-DNDEBUG -O3 -fomit-frame-pointer -Winline -Wall -I#{Dir.pwd} -I${PWD}", "-lstdc++")
  require './work/yinspire.so'
end

#
# Generate load/dump methods automatically 
#
Cplus2Ruby.model.each_model_class do |mc|
  if mc.klass.ancestors.include?(NeuralEntity)
    next unless mc.properties.any? {|prop| prop.options[:marshal] }

    load_code = ""
    dump_code = ""
    mc.properties.each do |prop| 
      next unless prop.options[:marshal]

      init = prop.init(Cplus2Ruby.model)
      raise "cannot specify :marshal without :init" if init.nil?
      raise ":init of String not allowed with :marshal" if init.is_a?(String)

      load_code << "  self.#{prop.name} = data['#{prop.name}'] || #{init}\n"
      dump_code << "  into['#{prop.name}'] = self.#{prop.name} if self.#{prop.name} != #{init}\n"
    end
    code = %{
      def load(data)
        #{ mc.klass == NeuralEntity ? '' : 'super' }\n
        #{load_code}
      end
      def dump(into)
        #{ mc.klass == NeuralEntity ? '' : 'super' }\n
        #{dump_code}
      end
    }
    if $DEBUG
      puts "generated load/dump code for #{mc.klass} is:"
      puts code
      puts "-----"
    end
    mc.klass.class_eval code
  end
end
