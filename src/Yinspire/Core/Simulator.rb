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

  def run(stop_at=nil)
    schedule_run(stop_at || Infinity)
  end
 
end
