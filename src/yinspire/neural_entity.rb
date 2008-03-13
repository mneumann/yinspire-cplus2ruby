#
# NeuralEntity is the base class of all entities in a neural net, i.e.
# Neurons and Synapses.
#
class NeuralEntity

  require 'yinspire/scheduling/neural_entity'

  def initialize(id=nil, simulator=nil, &block)
    self.id = id
    self.simulator = simulator
    block.call(self) if block
  end

  #
  # Each NeuralEntity has an +id+ associated which uniquely identifies
  # itself within a Simulator instance. This +id+ is usually assigned by the
  # Simulator (during loading or constructing a neural net) and SHOULD
  # NOT be changed afterwards (because it's used as a key in a Hash).
  #
  property :id

  #
  # Each NeuralEntity has a reference back to the Simulator. This is
  # used for example to update it's scheduling or to report a fire
  # event.
  #
  # Like +id+, this is assigned by the Simulator.
  #
  property :simulator, Simulator

  #
  # Connect +self+ with +target+.
  #
  def connect(target) raise "abstract method" end

  #
  # Disconnect +self+ from all connections.
  #
  def disconnect(target) raise "abstract method" end

  #
  # Iterates over each connection. To be overwritten by subclasses!
  #
  def each_connection() raise "abstract method" end
 
  #
  # Disconnect +self+ from all connections.
  #
  def disconnect_all
    each_connection {|conn| disconnect(conn) }
  end

  virtual :stimulate, :process, :process_stepped

  #
  # Stimulate an entity +at+ a specific time with a specific +weight+
  # and from a specific +source+.
  #
  # Overwrite!
  #
  method :stimulate, {:at => 'simtime'},{:weight => 'real'},{:source => NeuralEntity}, nil

  #
  # This method is called when a NeuralEntity reaches it's scheduling
  # time.
  #
  # Overwrite if you need this behaviour!
  #
  method :process, {:at => 'simtime'}, nil

  #
  # This method is called in each time-step, if and only if a
  # NeuralEntity had enabled stepped scheduling.
  #
  # Overwrite if you need this behaviour!
  #
  method :process_stepped, {:at => 'simtime'},{:step => 'simtime'}, nil

end
