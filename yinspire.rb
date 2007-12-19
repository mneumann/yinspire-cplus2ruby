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

# Forward declarations
class Neuron < NeuralEntity; end
class Synapse < NeuralEntity; end

require 'simulator'
require 'neural_entity'
require 'neuron'
require 'synapse'

if ENV['YINSPIRE_ALWAYS_RECOMPILE'] or !File.exist?('./yinspire.so') 
  CplusRuby.compile_and_load('yinspire.cc', 
    "-no-integrated-cpp -B ${PWD}/tools -O3 -Winline -Wall -I${PWD}",
    "-lstdc++")
else
  require './yinspire.so'
end

if __FILE__ == $0
=begin
  1000.times do
    x = NeuralEntity.new
    p x.schedule_at
    p x.stimuli_pq_to_a

    n = Neuron.new
    p n
    n.each_connection do |c| p c end
  end
=end
  sim = Simulator.new

  n = Neuron.new
  n.simulator = sim

  #s = Synapse.new
  #s2 = Synapse.new

  #n.connect(s)
  #n.connect(s2)

  sim.stimuli_tolerance = 0.001
  10_000_000.times do
    n.stimulate(10.0, 10.0, nil)
  end

  p n.stimuli_pq_to_a

  n.each_connection do |c| p c end

  #s.each_connection do |c| p c end
  #s2.each_connection do |c| p c end

end
