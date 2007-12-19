require 'tools/cplusruby'

CplusRuby.add_type_alias 'real'  => 'float'
CplusRuby.add_type_alias 'stime' => 'float'
CplusRuby.add_type_alias 'uint'  => 'unsigned int'

SII = {static: true, inline: true, internal: true}

CplusRuby << %{
  #include <math.h>

  #define real_exp expf
  #define real_fabs fabsf

  #define MIN(a,b) ((a) < (b) ? (a) : (b))
  #define MAX(a,b) ((a) > (b) ? (a) : (b))
}

class Simulator; include CplusRuby end
class NeuralEntity; include CplusRuby end

require 'simulator'
require 'neural_entity'
require 'neuron'

if ENV['YINSPIRE_ALWAYS_RECOMPILE'] or !File.exist?('./yinspire.so') 
  CplusRuby.compile_and_load('yinspire.cc', 
    "-no-integrated-cpp -B ${PWD}/tools -O3 -Winline -Wall -I${PWD}",
    "-lstdc++")
else
  require './yinspire.so'
end
