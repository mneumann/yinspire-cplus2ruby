#
# Common super class of all Loaders.
#
# Uses Cplus2Ruby property annotations to automatically assign
# properties:
#
#   property :name, :marshal => true, :init => 123
#
class Loader

  def initialize(simulator)
    @simulator = simulator
    @entities = @simulator.entities
  end

  def dump_entities
    entities = {}
    @entities.each {|id, entity|
      entities[id] = [entity.entity_type || raise, entity.dump]  
    }
    entities
  end

  protected

  #
  # Create an object with id +id+ of class +entity_type+, where
  # +entity_type+ is a string.
  #
  # Argument +data+ is a hash that contains the property values.
  #
  def create_entity(entity_type, id, data)
    entity = NeuralEntity.new_from_name(entity_type, id, @simulator)
    entity.load(data)
    raise if @entities[id]
    @entities[id] = entity
  end

end
