#
# Common super class of all Dumpers.
#
class Dumper

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

end
