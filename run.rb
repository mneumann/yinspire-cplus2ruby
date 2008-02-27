$LOAD_PATH.unshift "src"
$LOAD_PATH.unshift "tools"

require 'yinspire'
require 'yinspire/neuron_input'
require 'yinspire/neuron_output'

Yinspire.startup

sim = Simulator.new
sim.stimuli_tolerance = 0.0 
#sim.load('/tmp/gereon2005.json')

inputs = (0..9).map {|i|
  Neuron_Input.new("inp_#{i}", sim)
}

outputs = (0..9).map {|i|
  Neuron_Output.new("out_#{i}", sim)
}

synapses = (0..9).map {|i|
  Synapse.new("syn_#{i}", sim) {|s|
    s.delay = 0.4
    s.weight = 10.0
  }
}

(0..9).each {|i|
  inputs[i].connect(synapses[i])
  synapses[i].connect(outputs[i])
}

(0..9).each {|i|
  inputs[i].stimulate(0.0+i, 1.0, nil)
}

stop_at = ARGV[0].to_f 

puts "stop_at: #{stop_at}"

sim.run(stop_at)

puts "events: #{sim.event_counter}"
puts "fires:  #{sim.fire_counter}"
