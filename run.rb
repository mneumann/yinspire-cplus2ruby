$LOAD_PATH.unshift "src"
$LOAD_PATH.unshift "tools"

require 'yinspire'

sim = Simulator.new
sim.stimuli_tolerance = 0.0 
#sim.load('/tmp/gereon2005.json')

n = Neuron_SRM_01.new
n.simulator = sim
n.id = "test"

10.times do |i|
  n.stimulate(0.0+i, 1.0, nil)
end

stop_at = ARGV[0].to_f 

puts "stop_at: #{stop_at}"

sim.run(stop_at)

puts "events: #{sim.event_counter}"
puts "fires:  #{sim.fire_counter}"
