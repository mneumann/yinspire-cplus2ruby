require 'Yinspire/Core/Simulator'
require 'Yinspire/Core/Scheduling/NeuralEntity'

#
# NeuralEntity is the base class of all entities in a neural net, i.e.
# Neurons and Synapses.
#
class NeuralEntity

  #
  # Entity type name to class mapping. 
  #
  @@entity_type_map = Hash.new
  def self.entity_type_map() @@entity_type_map end


  #
  # Entity class to type name mapping.
  #
  @@entity_type_map_reverse = Hash.new
  def self.entity_type_map_reverse() @@entity_type_map_reverse end

  def entity_type() @@entity_type_map_reverse[self.class] end

  #
  # Annotation cache for loading entities.
  #
  @@entity_ann_load_cache = Hash.new
  def self.entity_ann_load_cache() @@entity_ann_load_cache end

  #
  # Annotation cache for dumping entities.
  #
  @@entity_ann_dump_cache = Hash.new
  def self.entity_ann_dump_cache() @@entity_ann_dump_cache end

  def self.new_from_name(name, *args, &block)
    (@@entity_type_map[name] || raise(ArgumentError)).new(*args, &block)
  end

  def self.class_from_name(name)
    (@@entity_type_map[name] || raise(ArgumentError))
  end

  def load(hash)
    a = @@entity_ann_load_cache[self.class]
    hash.each {|key, value|
      if meth = a[key]
        send(meth, value)
      end
    }
  end

  def dump
    hash = Hash.new
    @@entity_ann_dump_cache[self.class].each {|key|
      hash[key] = send(key)
    }
    hash
  end

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
