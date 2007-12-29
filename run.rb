require 'yinspire'

class NeuralEntity
  def load(data)
  end

  def dump(into)
  end
end

ABS_REFR_DURATION = 'abs_refr_duration'.freeze
LAST_SPIKE_TIME = 'last_spike_time'.freeze
LAST_FIRE_TIME = 'last_fire_time'.freeze
HEBB = 'hebb'.freeze
FLOAT_ZERO = 0.0

class Neuron
  def load(data)
    super
    self.abs_refr_duration = data[ABS_REFR_DURATION] || FLOAT_ZERO
    self.last_spike_time = data[LAST_SPIKE_TIME] || -INFINITY
    self.last_fire_time = data[LAST_FIRE_TIME] || -INFINITY
    self.hebb = data[HEBB] || false
  end

=begin
  def dump(into)
    super
    into['abs_refr_duration'] = self.abs_refr_duration
    into['last_spike_time'] = self.last_spike_time
    into['last_fire_time'] = self.last_fire_time
    into['hebb'] = self.hebb
  end
=end

end

WEIGHT = 'weight'.freeze
DELAY = 'delay'.freeze

class Synapse
  def load(data)
    super
    self.weight = data[WEIGHT] || FLOAT_ZERO
    self.delay = data[DELAY] || FLOAT_ZERO
  end

=begin
  def dump(into)
    super
    into['weight'] = self.weight
    into['delay'] = self.delay
  end
=end
end

TAU_M = 'tau_m'.freeze
TAU_REF = 'tau_ref'.freeze
REF_WEIGHT = 'ref_weight'.freeze
MEM_POT = 'mem_pot'.freeze
CONST_THRESHOLD = 'const_threshold'.freeze

class Neuron_SRM_01
  def load(data)
    super
    self.tau_m = data[TAU_M] || FLOAT_ZERO
    self.tau_ref = data[TAU_REF] || FLOAT_ZERO
    self.ref_weight = data[REF_WEIGHT] || FLOAT_ZERO
    self.mem_pot = data[MEM_POT] || FLOAT_ZERO
    self.const_threshold = data[CONST_THRESHOLD] || FLOAT_ZERO
  end

=begin
  def dump(into)
    super
    into['tau_m'] = self.tau_m
    into['tau_ref'] = self.tau_ref
    into['ref_weight'] = self.ref_weight
    into['mem_pot'] = self.mem_pot
    into['const_threshold'] = self.const_threshold
  end
=end

end

class Simulator

  #attr_reader :entities

  def initialize
    @entities = Hash.new
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
        entity.stimulate(at, INFINITY, nil)
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
        entity.stimulate(at, INFINITY, nil)
      end
    end
  end

  def load_ruby(filename)
    @entities = Hash.new
    require 'yaml'
    data = YAML.load(File.read(filename))

    puts "fileformat: #{data['format']}"

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
    entity = Object.const_get(type).new
    entity.iid = id
    entity.simulator = self
    entity.load(data)

    entity
  end
end


def c_version
  Simulator.new.test_run(ARGV[0].to_f, (ARGV[1] || 0).to_f)
end

def ruby_version
  sim = Simulator.new
  sim.stimuli_tolerance = 0.0 
  sim.load_ruby('/tmp/gereon2005.json')

  stop_at = ARGV[0].to_f 

  puts "stop_at: #{stop_at}"

  sim.run(stop_at)

  puts "events: #{sim.event_counter}"
  puts "fires:  #{sim.fire_counter}"
end

3.times do
  ruby_version()
end
#c_version()
