require 'tools/cplus2ruby'

Cplus2Ruby.add_type_alias 'real'  => 'float'
Cplus2Ruby.add_type_alias 'stime' => 'float'
Cplus2Ruby.add_type_alias 'uint'  => 'unsigned int'

INFINITY = 1.0/0.0

SII = {static: true, inline: true, internal: true}

Cplus2Ruby << %{
  #include <math.h>

  #define real_exp expf
  #define real_fabs fabsf

  #define MIN(a,b) ((a) < (b) ? (a) : (b))
  #define MAX(a,b) ((a) > (b) ? (a) : (b))
}

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

if ENV['YINSPIRE_ALWAYS_RECOMPILE'] or !File.exist?('./yinspire.so') 
  Cplus2Ruby.compile_and_load('work/yinspire', 
    "-no-integrated-cpp -B ${PWD}/tools -O3 -fomit-frame-pointer -Winline -Wall -I#{Dir.pwd} -I${PWD}", "")
else
  require './work/yinspire.so'
end
