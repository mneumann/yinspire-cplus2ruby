class Simulator
  #
  # The current simulation time.
  #
  property :schedule_current_time, 'stime'

  #
  # The time step used for stepped scheduling.
  #
  property :schedule_step, 'stime', default: '%s = INFINITY'

  #
  # The time of the next step.
  #
  property :schedule_next_step, 'stime', default: '%s = INFINITY'

  #
  # The tolerance (time difference) up to which local stimuli are
  # accumulated.
  #
  property :stimuli_tolerance, 'stime', default: '%s = -INFINITY'

  #
  # Priority queue used to schedule the entities.
  #
  property :schedule_pq, 'IndexedBinaryHeap<NeuralEntity*, MemoryAllocator<NeuralEntity*>, uint, NeuralEntity>', 
    internal: true

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
  property :entities, 'Hash<std::string, NeuralEntity *>', internal: true

  #
  # Start the simulation.
  #
  method :run, {stop_at: 'stime'}, %{
    while (true)
    {
      stime next_stop = MIN(stop_at, @schedule_next_step);

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

  method :record_fire_event, {at: 'stime', source: NeuralEntity}, %{
    @fire_counter++;
  }
  
  # 
  # If an entity has changed it's scheduling time, it has to call this
  # method to reflect the change within the priority queue.
  #
  method :schedule_update, {entity: NeuralEntity}, %{
    @schedule_pq.push_or_update(entity);
  }, inline: true

  helper_code %q{
    struct entities_each_data
    {
      Simulator *simulator;
      jsonHash *templates;
    };

    struct conn_each_data
    {
      Simulator *simulator;
      int index;
      NeuralEntity *from;
    };

    static void each_conn(jsonValue *item, void *data)
    {
      conn_each_data *d = (conn_each_data*)data;
      std::string &id = dynamic_cast<jsonString*>(item)->value;
      NeuralEntity *e = d->simulator->entities[id]; 
      if (d->index == 0)
      {
        d->from = e;
      }
      else
      {
        d->from->connect(e);
      }
      d->index++;
    }

    static void connections_each(jsonValue *item, void *data)
    {
      conn_each_data d;
      d.simulator = (Simulator*)data;
      d.index = 0;
      d.from = NULL;
      dynamic_cast<jsonArray*>(item)->each(each_conn, &d); 
    }

    static void entities_each(jsonValue *item, void *data)
    {
      entities_each_data *d = (entities_each_data*)data;

      jsonArray *entity_spec = dynamic_cast<jsonArray*>(item);
      jsonString *id = dynamic_cast<jsonString*>(entity_spec->get(0));
      jsonString *template_name = dynamic_cast<jsonString*>(entity_spec->get(1));

      jsonArray *t = dynamic_cast<jsonArray*>(d->templates->get(template_name));

      jsonString *type = dynamic_cast<jsonString*>(t->get(0));
      jsonHash *hash = dynamic_cast<jsonHash*>(t->get(1));

      NeuralEntity *entity;

      if (type->value == "Synapse")
      {
        entity = new Synapse();
      }
      else
      {
        entity = new Neuron_SRM_01();
      }

      entity->id = dynamic_cast<jsonString*>(id)->value;
      entity->simulator = d->simulator;
      d->simulator->entities[entity->id] = entity;

      entity->load(hash);
    }

    static void ev_each(jsonValue *val, void *data)
    {
      double at = dynamic_cast<jsonNumber*>(val)->value;
      NeuralEntity *entity = (NeuralEntity*)data;
      entity->stimulate(at, INFINITY, NULL);  
    }

    static void events_each(jsonString *id, jsonValue *val, void *data)
    {
      Simulator *simulator = (Simulator*)data;
      NeuralEntity *entity = simulator->entities[id->value];
      dynamic_cast<jsonArray*>(val)->each(ev_each, entity);
    }
  }

  method :load, {filename: 'char*'}, %{
    jsonHash *data = dynamic_cast<jsonHash*>(jsonParser::parse_file(filename));
    jsonHash *templates = dynamic_cast<jsonHash*>(data->get("templates"));
    jsonArray *entities = dynamic_cast<jsonArray*>(data->get("entities"));
    jsonArray *connections = dynamic_cast<jsonArray*>(data->get("connections"));
    jsonHash *events = dynamic_cast<jsonHash*>(data->get("events"));

    entities_each_data d;
    d.templates = templates;
    d.simulator = this;

    // construct entities
    entities->each(entities_each, &d);

    // connect 
    connections->each(connections_each, this);

    // events
    events->each(events_each, this); 
  } 

end
