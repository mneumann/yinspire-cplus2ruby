require 'Yinspire/Loaders/Loader'
require 'yaml' # YAML is a superset of JSON

class Loader_JSON < Loader

  def load(filename)
    @entities = Hash.new
    data = YAML.load(File.read(filename))

    case data['format']
    when 'yinspire.1'
      load_v1(data)
    when 'yinspire.c'
      load_c(data)
    else
      raise "invalid format"
    end
  end

  protected

  #
  # Format:
  #
  #   {
  #     templates: { 
  #       'MyNeuron' =>  ['Neuron_SRM01', {tau_m: 0.5, :ref_weight: 0.1}],
  #       'MySynapse' => ['Synapse', {weight: 1.0, delay: 0.5}]
  #     },
  #     entities: {
  #       'id1' => ['MyNeuron', {tau_m: 5.1, const_threshold: 0.44}],
  #       'id2' => ['Neuron_SRM01', {}],
  #       'id3' => ['MySynapse'],
  #       'id4' => 'MyNeuron'
  #     },
  #     connections: { 
  #       'id1' => ['id2', 'id3'],
  #       'id2' => ['id1']
  #     },
  #     events: {
  #       'id1' => [100.0, 101.0, timestamp_x, timestamp_y],
  #       'id2' => [444, 555]
  #     }
  #   }
  #
  # Every "section" is optional.
  #
  def load_v1(data)
    templates = data['templates'] || {}
    entities = data['entities'] || {}
    connections = data['connections'] || {}
    events = data['events'] || {}

    #
    # construct entities
    #
    hash = Hash.new
    entities.each do |id, entity_spec|
      type, data = *entity_spec

      if t = templates[type]
        type, template_data = *t
        hash.update(template_data) if template_data
      end

      hash.update(data) if data

      create_entity(type, id, hash)

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

  #
  # This is a version for the pure C++ version of Yinspire. It doesn't
  # use hashes for entities and connections (because the C++ JSON library
  # does not implement efficient hash lookup).
  #
  #   {
  #     templates: { 
  #       'MyNeuron' =>  ['Neuron_SRM01', {tau_m: 0.5, :ref_weight: 0.1}],
  #       'MySynapse' => ['Synapse', {weight: 1.0, delay: 0.5}]
  #     },
  #     entities: [
  #       ['id1', 'MyNeuron'],
  #       ['id2', 'Neuron_SRM01'],
  #       ['id3', 'MySynapse'],
  #       ['id4', 'MyNeuron']
  #     ],
  #     connections: { 
  #       ['id1', 'id2', 'id3'],
  #       ['id2', 'id1']
  #     },
  #     events: {
  #       'id1' => [100.0, 101.0, timestamp_x, timestamp_y],
  #       'id2' => [444, 555]
  #     }
  #   }
  #
  # Every "section" is optional.
  #
  # BUGS:
  #
  # The C++ version does not currently implement to specify an
  # entity like this:
  #
  #   ['id1', 'Neuron_SRM01', {...}]
  #
  def load_c(data)
    templates = data['templates'] || {}
    entities = data['entities'] || [] 
    connections = data['connections'] || []
    events = data['events'] || {}

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
        raise # FIXME: C++ version is invalid, because it assume that there 
              # is no data! 
      end

      create_entity(type, id, hash)
    end

    #
    # connect them
    #
    connections.each do |arr|
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

end
