require 'yinspire'

sim = Simulator.new
sim.stimuli_tolerance = 0.0 
sim.load('/tmp/gereon2005.json')

stop_at = ARGV[0].to_f 

puts "stop_at: #{stop_at}"

sim.run(stop_at)

puts "events: #{sim.event_counter}"
puts "fires:  #{sim.fire_counter}"
