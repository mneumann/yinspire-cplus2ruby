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
    initialize_ann_cache()
  end

  def initialize_ann_cache
    @ann_cache = {}
    Cplus2Ruby.model.entities.each do |klass|
      @ann_cache[klass] = {} 
      klass.recursive_annotations.each {|name, h|
        next unless h[:marshal]
        @ann_cache[klass][name.to_sym] = 
        @ann_cache[klass][name.to_s] = "#{name}="
      }
    end
  end

  protected

  def load_entity(klass, entity, data)
    data.each do |key, val|
      meth = @ann_cache[klass][key]
      entity.send(meth, val) if meth
    end
  end

  def allocate_entity(type, id, data)
    entity_class = Object.const_get(type)
    raise unless entity_class.ancestors.include?(NeuralEntity) # FIXME
    entity = entity_class.new
    entity.id = id
    entity.simulator = @simulator
    load_entity(entity_class, entity, data)
    return entity
  end

end
