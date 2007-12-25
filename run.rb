require 'yinspire'
exit if ARGV.empty?

sim = Simulator.new
sim.stimuli_tolerance = 0.0 
sim.load('gereon2005.json')
GC.start
GC.disable

stop_at = ARGV[0].to_f 
sim.run(stop_at)

puts "stop_at: #{stop_at}"
puts "events: #{sim.event_counter}"
puts "fires:  #{sim.fire_counter}"
