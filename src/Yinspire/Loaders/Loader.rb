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
    @entities = Hash.new
    @simulator = simulator

    #
    # initialize annotation cache
    #
    @ann_cache = {}
    Cplus2Ruby.model.entities.each do |klass|
      @ann_cache[klass] = {} 
      klass.recursive_annotations.each {|name, h|
        next unless h[:marshal]
        @ann_cache[klass][name.to_sym] = 
        @ann_cache[klass][name.to_s] = "#{name}="
      }
    end

    #
    # Collect valid entity classes.
    #
    @entity_classes = {}
    ObjectSpace.each_object(Class) {|klass|
      @entity_classes[klass.name] = klass if klass.ancestors.include?(NeuralEntity)
    }
  end

  protected

  #
  # Create an object with id +id+ of class +entity_type+, where
  # +entity_type+ is a string.
  #
  # Argument +data+ is a hash that contains the property values.
  #
  def create_entity(entity_type, id, data)
    entity_class = @entity_classes[entity_type] || raise(ArgumentError)
    entity = entity_class.new
    entity.id = id
    entity.simulator = @simulator
    load_entity(entity_class, entity, data)
    @entities[id] = entity
  end

  def load_entity(klass, entity, data)
    data.each do |key, val|
      meth = @ann_cache[klass][key]
      entity.send(meth, val) if meth
    end
  end

end
