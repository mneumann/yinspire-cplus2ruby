class Simulator

  require 'Yinspire/Scheduling/Simulator'

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

  #
  # An id -> NeuralEntity mapping
  # 
  # Contains all entities known by the simulator.
  #
  attr_reader :entities

  def initialize
    @entities = Hash.new
  end

  def run(stop_at)
    schedule_run(stop_at)
  end
 
  def load_v1(data)
    raise unless data['format'] == 'yinspire.1'

    templates = data['templates']
    entities = data['entities']
    connections = data['connections']
    events = data['events']

    #
    # construct entities
    #
    hash = Hash.new
    entities.each do |id, entity_spec|
      type, data = entity_spec

      if t = templates[type]
        type, template_data = t
        hash.update(template_data)
      end

      hash.update(data) if data

      @entities[id] = allocate_entity(type, id, hash)

      hash.clear
    end

    #
    # connect them
    #
    connections.each do |src, destinations|
      entity = @entities[src]
      destinations.each do |dest|
        entity.connect(@entities[dest])
      end
    end

    #
    # stimulate with events
    #
    events.each do |id, time_series|
      entity = @entities[id]
      time_series.each do |at|
        entity.stimulate(at, Infinity, nil)
      end
    end
  end

  def load_v2(data)
    raise unless data['format'] == 'yinspire.2'

    templates = data['templates']
    entities = data['entities']
    connections = data['connections']
    events = data['events']

    #
    # construct entities
    #
    hash = Hash.new
    entities.each do |arr|
      hash.clear

      id, type, data = *arr

      if t = templates[type]
        type, template_data = *t
        hash.update(template_data)
      end

      if data
        hash.update(data) 
        raise # C++ version is invalid, because it assume that there 
              # is no data! 
      end

      @entities[id] = allocate_entity(type, id, hash)
    end

    #
    # connect them
    #
    connections.each do |arr| #src, destinations|
      src, *destinations = *arr
      raise if destinations.empty?
      entity = @entities[src] || raise
      destinations.each do |dest|
        entity.connect(@entities[dest] || raise)
      end
    end

    #
    # stimulate with events
    #
    events.each do |id, time_series|
      entity = @entities[id] || raise
      time_series.each do |at|
        entity.stimulate(at, Infinity, nil)
      end
    end
  end

  def load(filename)
    @entities = Hash.new
    require 'yaml'
    data = YAML.load(File.read(filename))

    case data['format']
    when 'yinspire.1'
      load_v1(data)
    when 'yinspire.2'
      load_v2(data)
    else
      raise
    end
  end

  private

  def allocate_entity(type, id, data)
    entity_class = Object.const_get(type)
    raise unless entity_class.ancestors.include?(NeuralEntity) # FIXME
    entity = entity_class.new
    entity.id = id
    entity.simulator = self
    entity.load(data)
    return entity
  end
end
