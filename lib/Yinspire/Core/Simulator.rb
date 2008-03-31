require 'Yinspire/Core/NeuralEntity'
require 'Yinspire/Core/Scheduling/Simulator'

class Simulator

  #
  # The tolerance (time difference) up to which local stimuli are
  # accumulated.
  #
  property :stimuli_tolerance, 'simtime', :init => Infinity

  #
  # Statistics counter
  #
  property :event_counter, 'uint'
  property :fire_counter, 'uint'

  stub_method :record_fire, {:at => 'simtime'},{:weight => 'real'},{:source => NeuralEntity}

  #
  # Overwrite!
  #
  def record_fire(at, weight, source)
  end

  attr_reader :entities

  def initialize
    @entities = Hash.new
  end

  def run(stop_at=nil)
    schedule_run(stop_at || Infinity)
  end
 
end
