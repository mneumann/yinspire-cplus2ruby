require 'rubygems'
$LOAD_PATH.unshift "src"

require 'Yinspire'
require 'Yinspire/Models/Neuron_Input'
require 'Yinspire/Models/Neuron_Output'
require 'Yinspire/Models/Neuron_SRM01'
require 'Yinspire/Models/Neuron_SRM02'
require 'Yinspire/Models/Synapse_Hebb'
require 'Yinspire/Loaders/Loader_JSON'
require 'Yinspire/Loaders/Loader_GraphML'
require 'Yinspire/Loaders/Loader_Yin'

def example_net(sim, n)
  inputs = (0...n).map {|i|
    Neuron_Input.new("inp_#{i}", sim)
  }

  outputs = (0...n).map {|i|
    Neuron_Output.new("out_#{i}", sim)
  }

  synapses = (0...n).map {|i|
    Synapse.new("syn_#{i}", sim) {|s|
      s.delay = 0.4
      s.weight = 10.0
    }
  }

  (0...n).each {|i|
    inputs[i].connect(synapses[i])
    synapses[i].connect(outputs[i])
  }

  (0...n).each {|i|
    inputs[i].stimulate(0.0+i, 1.0, nil)
  }
end

Yinspire.commit('./work/Yinspire')

sim = Simulator.new
sim.stimuli_tolerance = 0.0 

class Neuron_Output
  def fire(at, weight)
    puts "#{id()}\t#{at}\t#{weight}"
  end
end

#loader = Loader_GraphML.new(sim)
#loader.load('examples/nets/skorpion.graphml')

#loader = Loader_JSON.new(sim)
#loader.load('/tmp/gereon2005.json')

loader = Loader_Yin.new(sim)
loader.load('./examples/nets/gereon2005.yin')

#require 'pp'
#pp loader.dump_entities
#example_net(sim, 10_000)

stop_at = ARGV[0].to_f 
puts "stop_at: #{stop_at}"
sim.run(stop_at)
puts "events: #{sim.event_counter}"
puts "fires:  #{sim.fire_counter}"
