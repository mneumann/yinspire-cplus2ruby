class Simulator
  #
  # The current simulation time.
  #
  property :schedule_current_time, 'simtime'

  #
  # The time step used for stepped scheduling.
  #
  property :schedule_step, 'simtime', :init => Infinity

  #
  # The time of the next step.
  #
  property :schedule_next_step, 'simtime', :init => Infinity

  #
  # The tolerance (time difference) up to which local stimuli are
  # accumulated.
  #
  property :stimuli_tolerance, 'simtime', :init => Infinity

  #
  # Priority queue used to schedule the entities.
  #
  property :schedule_pq, 'IndexedBinaryHeap<NeuralEntity*, MemoryAllocator<NeuralEntity*>, NeuralEntity>'

  #
  # If stepped scheduling is used, this points to the first entiy in the
  # stepped schedule list.
  #
  property :schedule_stepping_list_root, NeuralEntity

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

  #
  # Start the simulation.
  #
  method :run, {:stop_at => 'simtime'}, %{
    while (true)
    {
      simtime next_stop = MIN(stop_at, @schedule_next_step);

      /* 
       * Calculate all events from the priority queue until the next time
       * step is reached.
       */
      while (!@schedule_pq.empty())
      {
        NeuralEntity *top = @schedule_pq.top();
        if (top->schedule_at >= next_stop)
          break;
        @schedule_current_time = top->schedule_at; 
        @schedule_pq.pop();
        top->process(top->schedule_at);
      }

      if (@schedule_current_time >= stop_at)
        break;

      if (@schedule_stepping_list_root == NULL && @schedule_pq.empty())
        break;

      /* 
       * Calculate the entities that require stepped processing.
       */ 
      @schedule_current_time = @schedule_next_step; 

      if (@schedule_stepping_list_root != NULL)
      {
        // FIXME: collect all entities in an array. then process them.
      }

      @schedule_next_step += @schedule_step;
    }
  }

  method :record_fire_event, {:at => 'simtime'},{:source => NeuralEntity}, %{
    @fire_counter++;
  }
  
  # 
  # If an entity has changed it's scheduling time, it has to call this
  # method to reflect the change within the priority queue.
  #
  method :schedule_update, {:entity => NeuralEntity}, %{
    @schedule_pq.update(entity);
  }, :inline => true

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
